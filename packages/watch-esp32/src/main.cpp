#include <Arduino.h>
#include <Wire.h>
#include <LittleFS.h>
#include "config.h"
#include "display/display.h"
#include "sensors/accelerometer.h"
#include "sensors/power.h"
#include "connectivity/wifi_manager.h"
#include "connectivity/ble_localization.h"
#include "connectivity/audio_stream.h"
#include "connectivity/guidance.h"

// ============================================================
// Déclarations de tâches FreeRTOS
// ============================================================
static void task_sensor(void *pvParameters);
static void task_display(void *pvParameters);
static void task_localization(void *pvParameters);
static void task_touch(void *pvParameters);

// ============================================================
// setup()
// ============================================================
void setup() {
    Serial.begin(SERIAL_BAUD);
    delay(200);
    Serial.println("\n=== T-Watch S3 — Boot ===");

    // 1. Initialisation des deux bus I2C
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN, I2C_FREQ_HZ);                    // principal : AXP2101, BMA423, RTC (GPIO 10/11)
    Wire1.begin(TOUCH_SDA_PIN, TOUCH_SCL_PIN, TOUCH_I2C_FREQ_HZ);         // touch : FT6236U (GPIO 23/32)

    // Scan + init FT6236U
    Wire1.beginTransmission(TOUCH_I2C_ADDR);
    if (Wire1.endTransmission() == 0) {
        Serial.println("[TOUCH] FT6236U détecté à 0x38");
        // Sortie du mode hibernate → mode normal
        Wire1.beginTransmission(TOUCH_I2C_ADDR);
        Wire1.write(0x00);  // Device Mode register
        Wire1.write(0x00);  // 0x00 = Normal operating mode
        Wire1.endTransmission();
        delay(10);
        // Seuil de détection (0x80) : 22 par défaut, on abaisse à 20 (plus sensible)
        Wire1.beginTransmission(TOUCH_I2C_ADDR);
        Wire1.write(0x80);
        Wire1.write(20);
        Wire1.endTransmission();
    } else {
        Serial.println("[TOUCH] ERREUR — FT6236U non détecté sur Wire1 (SDA=23, SCL=32)");
    }

    // 2. Power management (AXP2101) en premier — alimente les autres composants
    if (!power_init()) {
        Serial.println("[POWER] ERREUR init AXP2101 — arrêt.");
        while (true) delay(1000);
    }

    // 3. LittleFS (images splash + logo_icon)
    if (!LittleFS.begin(false)) {
        Serial.println("[FS] LittleFS non monté — uploadez le filesystem via PlatformIO > Platform > Upload Filesystem Image");
    } else {
        Serial.println("[FS] LittleFS OK");
        // Debug : liste les fichiers présents
        File root = LittleFS.open("/");
        File entry = root.openNextFile();
        while (entry) {
            Serial.printf("[FS]  %s (%u o)\n", entry.name(), (unsigned)entry.size());
            entry = root.openNextFile();
        }
        // Vérification des assets requis
        if (!LittleFS.exists("/images/logo.png"))
            Serial.println("[FS] MANQUANT: /images/logo.png");
        if (!LittleFS.exists("/images/logo_icon.png"))
            Serial.println("[FS] MANQUANT: /images/logo_icon.png");
    }

    // 4. Écran + splash 5s
    display_init();
    display_show_splash();

    // 4. Accéléromètre (BMA423)
    if (!accel_init()) {
        Serial.println("[SENSOR] ERREUR init BMA423 — les données IMU ne seront pas disponibles.");
    }

    // 5. WiFi + NTP + audio stream UDP + guidage HTTP
    if (wifi_connect(WIFI_SSID, WIFI_PASSWORD)) {
        // NTP — France (UTC+1 hiver, UTC+2 été)
        configTime(3600, 3600, "pool.ntp.org", "time.google.com");
        Serial.println("[NTP] Synchronisation heure en cours...");
        audio_stream_init();
        guidance_init();
    } else {
        Serial.println("[MAIN] WiFi indisponible — audio stream et guidage désactivés.");
    }

    // 6. Localisation BLE iBeacon
    localization_init();

    // 7. Tâches FreeRTOS
    xTaskCreatePinnedToCore(task_sensor,       "sensor",  4096,  nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(task_display,      "display", 8192,  nullptr, 2, nullptr, 1);
    xTaskCreatePinnedToCore(task_localization, "ble_loc", 8192,  nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(guidance_task,     "guidance", 4096, nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(task_touch,        "touch",   4096,  nullptr, 2, nullptr, 1);

    Serial.println("[MAIN] Initialisation terminée.");
}

// ============================================================
// loop() — inutilisé (logique dans les tâches FreeRTOS)
// ============================================================
void loop() {
    // Garder le task watchdog Arduino satisfait tout en laissant les tâches FreeRTOS travailler
    delay(1000);
}

// ============================================================
// Tâche : lecture capteurs (core 0)
// ============================================================
static void task_sensor(void *pvParameters) {
    TickType_t last_wake = xTaskGetTickCount();
    const TickType_t period = pdMS_TO_TICKS(100);  // 10 Hz
    uint32_t log_counter = 0;

    for (;;) {
        accel_update();

        // Log toutes les 5 secondes (50 cycles × 100ms)
        if (++log_counter >= 50) {
            log_counter = 0;
            AccelData d = accel_get_data();
            PowerStatus p = power_get_status();
            Serial.printf("[STATUS] Accel x=%.2f y=%.2f z=%.2f | Bat=%.2fV (%d%%) %s\n",
                d.x, d.y, d.z,
                p.battery_voltage, p.battery_percent,
                p.is_charging ? "CHG" : "");
        }

        // Deep sleep désactivé pendant le développement
        // Décommenter en production : power_check_sleep();

        vTaskDelayUntil(&last_wake, period);
    }
}

// ============================================================
// Tâche : rendu écran (core 1)
// ============================================================
static void task_display(void *pvParameters) {
    TickType_t last_wake = xTaskGetTickCount();
    const TickType_t period = pdMS_TO_TICKS(33);  // ~30 FPS

    for (;;) {
        display_update();
        vTaskDelayUntil(&last_wake, period);
    }
}

// ============================================================
// Tâche : localisation BLE iBeacon (core 0)
// Cycle : arrêt scan → build payload → advertising → reprise scan
// ============================================================
static void task_localization(void *pvParameters) {
    TickType_t last_wake = xTaskGetTickCount();
    const TickType_t period = pdMS_TO_TICKS(LOCALIZATION_PERIOD_MS);

    for (;;) {
        localization_process();
        vTaskDelayUntil(&last_wake, period);
    }
}

// ============================================================
// Tâche : détection tactile FT6336U — toggle home ↔ dev (core 1)
// Poll le registre TD_STATUS (0x02) sur Wire1 toutes les 50 ms.
// Le toggle se déclenche sur le front montant du toucher (0→n).
// ============================================================
static void task_touch(void *pvParameters) {
    bool was_touched = false;
    uint32_t diag_count = 0;  // logs de diagnostic les 20 premières secondes

    for (;;) {
        // Lecture TD_STATUS : bits [3:0] = nombre de points actifs
        Wire1.beginTransmission(TOUCH_I2C_ADDR);
        Wire1.write(0x02);
        uint8_t i2c_err = Wire1.endTransmission(false);
        Wire1.requestFrom((uint8_t)TOUCH_I2C_ADDR, (uint8_t)1);
        uint8_t td = Wire1.available() ? (Wire1.read() & 0x0F) : 0;

        if (diag_count < 400) {  // ~20 s de logs (400 × 50ms)
            if (diag_count % 20 == 0) {  // log toutes les secondes
                Serial.printf("[TOUCH] I2C err=%d  TD_STATUS=0x%02X  td=%d  was=%d\n",
                              i2c_err, td, td, was_touched);
            }
            diag_count++;
        }

        bool is_touched = (td > 0 && i2c_err == 0);
        if (is_touched && !was_touched) {
            Serial.println("[TOUCH] Toucher détecté → toggle mode");
            display_toggle_dev_mode();
        }
        was_touched = is_touched;

        vTaskDelay(pdMS_TO_TICKS(50));
    }
}
