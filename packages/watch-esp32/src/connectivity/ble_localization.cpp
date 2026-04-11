#include "ble_localization.h"
#include "config.h"
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertising.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

// ============================================================
// Table interne des balises
// ============================================================
struct beacon_info_t {
    uint16_t major;
    uint16_t minor;
    int8_t   last_rssi;
    int64_t  last_seen_ms;
    bool     is_active;
};

static beacon_info_t s_beacons[MAX_BEACONS];
static SemaphoreHandle_t s_mutex = nullptr;

static BLEScan        *s_scan       = nullptr;
static BLEAdvertising *s_adv        = nullptr;
static bool            s_adv_started = false;
static uint32_t        s_tx_count    = 0;

// ============================================================
// Parsing iBeacon — parcourt le buffer brut sans supposer
// la structure des AD records (cf. LOCALISATION_SYSTEM_REF §2)
// ============================================================
static bool parse_ibeacon(const uint8_t *data, int len,
                           uint16_t *major, uint16_t *minor) {
    for (int i = 0; i + 25 <= len; i++) {
        if (data[i]   == 0x4C && data[i+1] == 0x00 &&
            data[i+2] == 0x02 && data[i+3] == 0x15) {
            *major = ((uint16_t)data[i+20] << 8) | data[i+21];
            *minor = ((uint16_t)data[i+22] << 8) | data[i+23];
            return true;
        }
    }
    return false;
}

// ============================================================
// Mise à jour de la table des balises (thread-safe)
// ============================================================
static void update_beacon_table(uint16_t major, uint16_t minor, int8_t rssi) {
    int64_t now = (int64_t)(esp_timer_get_time() / 1000);  // uptime ms

    if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(10)) != pdTRUE) return;

    // Déjà présente → mettre à jour
    for (int i = 0; i < MAX_BEACONS; i++) {
        if (s_beacons[i].is_active &&
            s_beacons[i].major == major &&
            s_beacons[i].minor == minor) {
            s_beacons[i].last_rssi    = rssi;
            s_beacons[i].last_seen_ms = now;
            xSemaphoreGive(s_mutex);
            return;
        }
    }

    // Slot vide disponible
    for (int i = 0; i < MAX_BEACONS; i++) {
        if (!s_beacons[i].is_active) {
            s_beacons[i] = { major, minor, rssi, now, true };
            xSemaphoreGive(s_mutex);
            return;
        }
    }

    // Table pleine → remplacer la plus ancienne
    int oldest = 0;
    for (int i = 1; i < MAX_BEACONS; i++) {
        if (s_beacons[i].last_seen_ms < s_beacons[oldest].last_seen_ms)
            oldest = i;
    }
    s_beacons[oldest] = { major, minor, rssi, now, true };
    xSemaphoreGive(s_mutex);
}

// ============================================================
// Callback de scan BLE
// ============================================================
class IBeaconScanCallback : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice device) override {
        if (!device.haveManufacturerData()) return;

        std::string mfg = device.getManufacturerData();
        const uint8_t *data = (const uint8_t *)mfg.data();
        int len = (int)mfg.length();

        uint16_t major, minor;
        if (parse_ibeacon(data, len, &major, &minor)) {
            update_beacon_table(major, minor, (int8_t)device.getRSSI());
        }
    }
};

static IBeaconScanCallback s_scan_cb;

// ============================================================
// Construction du payload Manufacturer Data
// Format : FF FF AA <WATCH_ID> [Major16 Minor16 RSSI8] × N
// Retourne la longueur du payload (4..29 octets)
// ============================================================
static int build_payload(uint8_t *buf) {
    int64_t now = (int64_t)(esp_timer_get_time() / 1000);

    buf[0] = COMPANY_ID_LO;
    buf[1] = COMPANY_ID_HI;
    buf[2] = BLE_MAGIC_BYTE;
    buf[3] = WATCH_ID;
    int idx   = 4;
    int count = 0;

    if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(50)) != pdTRUE) return idx;

    for (int i = 0; i < MAX_BEACONS; i++) {
        if (!s_beacons[i].is_active) continue;

        // Expiration
        if ((now - s_beacons[i].last_seen_ms) > BEACON_TIMEOUT_MS) {
            s_beacons[i].is_active = false;
            continue;
        }

        buf[idx++] = (s_beacons[i].major >> 8) & 0xFF;
        buf[idx++] =  s_beacons[i].major        & 0xFF;
        buf[idx++] = (s_beacons[i].minor >> 8) & 0xFF;
        buf[idx++] =  s_beacons[i].minor        & 0xFF;
        buf[idx++] = (uint8_t)s_beacons[i].last_rssi;
        count++;
    }

    xSemaphoreGive(s_mutex);

    Serial.printf("[BLE_LOC] Payload diffusé — %d balise(s) active(s)\n", count);
    return idx;
}

// ============================================================
// API publique
// ============================================================
void localization_init() {
    s_mutex = xSemaphoreCreateMutex();
    memset(s_beacons, 0, sizeof(s_beacons));

    BLEDevice::init(BLE_DEVICE_NAME);

    // --- Configuration du scan ---
    s_scan = BLEDevice::getScan();
    s_scan->setAdvertisedDeviceCallbacks(&s_scan_cb, /*wantDuplicates=*/true);
    s_scan->setActiveScan(true);
    s_scan->setInterval(100);  // ms
    s_scan->setWindow(50);     // ms

    // --- Advertising — premier démarrage avec payload vide ---
    s_adv = BLEDevice::getAdvertising();

    uint8_t empty_payload[4] = { COMPANY_ID_LO, COMPANY_ID_HI, BLE_MAGIC_BYTE, WATCH_ID };
    BLEAdvertisementData adv_data;
    adv_data.setFlags(0x06);  // General Discoverable | No BR/EDR
    adv_data.setManufacturerData(std::string((char *)empty_payload, 4));
    s_adv->setAdvertisementData(adv_data);

    BLEAdvertisementData scan_resp;
    scan_resp.setName(BLE_DEVICE_NAME);
    s_adv->setScanResponseData(scan_resp);

    s_adv->start();
    s_adv_started = true;

    // --- Démarrage du scan continu ---
    s_scan->start(0, nullptr, false);

    Serial.printf("[BLE_LOC] Init OK — device \"%s\", WATCH_ID=%d\n",
                  BLE_DEVICE_NAME, WATCH_ID);
}

void localization_process() {
    // 1. Arrêt scan (libère la radio)
    s_scan->stop();

    // 2. Construction du payload
    uint8_t payload[29];
    int payload_len = build_payload(payload);

    // 3. Arrêt advertising
    if (s_adv_started) s_adv->stop();

    // 4. Mise à jour du payload
    BLEAdvertisementData adv_data;
    adv_data.setFlags(0x06);
    adv_data.setManufacturerData(std::string((char *)payload, payload_len));
    s_adv->setAdvertisementData(adv_data);

    BLEAdvertisementData scan_resp;
    scan_resp.setName(BLE_DEVICE_NAME);
    s_adv->setScanResponseData(scan_resp);

    // 5. Redémarrage advertising
    s_adv->start();
    s_adv_started = true;
    s_tx_count++;

    // 6. Redémarrage scan
    s_scan->start(0, nullptr, false);
}

int localization_get_active_beacons(BeaconSnapshot *out, int max_count) {
    int64_t now = (int64_t)(esp_timer_get_time() / 1000);
    int count = 0;

    if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(10)) != pdTRUE) return 0;

    for (int i = 0; i < MAX_BEACONS && count < max_count; i++) {
        if (!s_beacons[i].is_active) continue;
        if ((now - s_beacons[i].last_seen_ms) > BEACON_TIMEOUT_MS) continue;

        out[count].major     = s_beacons[i].major;
        out[count].minor     = s_beacons[i].minor;
        out[count].last_rssi = s_beacons[i].last_rssi;
        count++;
    }

    xSemaphoreGive(s_mutex);
    return count;
}

uint32_t localization_get_tx_count() {
    return s_tx_count;
}
