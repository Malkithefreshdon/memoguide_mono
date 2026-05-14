#include "accelerometer.h"
#include "config.h"
#include <Arduino.h>
#include <Wire.h>

// NOTE : La lib BMA423 officielle (boschsensortec/Arduino-BMA423)
// peut être remplacée par le driver inclus dans LilyGoLib si tu
// utilises ce framework. Dans ce cas, supprimer la dépendance
// dans platformio.ini et inclure le header correspondant.

// Registres BMA423 (extrait du datasheet)
#define BMA423_REG_CHIP_ID      0x00
#define BMA423_CHIP_ID_VAL      0x13
#define BMA423_REG_ACC_X_LSB    0x12
#define BMA423_REG_STEP_CNT_0   0x1E

static bool    _initialized = false;
static AccelData _data = {};

// ── Détection de chute ────────────────────────────────────────────────────
// Seuils en m/s²
static constexpr float FALL_FREE_FALL_THRESHOLD = 3.0f;   // < 0.3g → libre chute
static constexpr float FALL_IMPACT_THRESHOLD    = 19.6f;  // > 2g   → impact
static constexpr uint32_t FALL_WINDOW_MS        = 600;    // fenêtre libre chute → impact
static constexpr uint32_t FALL_DISPLAY_MS       = 5000;   // durée affichage alerte

static bool     _free_fall_pending = false;
static uint32_t _free_fall_time_ms = 0;
static bool     _fall_detected     = false;
static uint32_t _fall_detect_time_ms = 0;

// --- Helpers I2C bas niveau ---
static bool bma423_write(uint8_t reg, uint8_t val) {
    Wire.beginTransmission(BMA423_I2C_ADDR);
    Wire.write(reg);
    Wire.write(val);
    return Wire.endTransmission() == 0;
}

static bool bma423_read(uint8_t reg, uint8_t *buf, uint8_t len) {
    Wire.beginTransmission(BMA423_I2C_ADDR);
    Wire.write(reg);
    if (Wire.endTransmission(false) != 0) return false;
    Wire.requestFrom((uint8_t)BMA423_I2C_ADDR, len);
    for (uint8_t i = 0; i < len && Wire.available(); i++) buf[i] = Wire.read();
    return true;
}

bool accel_init() {
    // Vérification du chip ID
    uint8_t chip_id = 0;
    if (!bma423_read(BMA423_REG_CHIP_ID, &chip_id, 1)) {
        Serial.printf("[SENSOR] BMA423 non détecté sur I2C 0x%02X\n", BMA423_I2C_ADDR);
        return false;
    }
    if (chip_id != BMA423_CHIP_ID_VAL) {
        Serial.printf("[SENSOR] BMA423 chip ID inattendu : 0x%02X (attendu 0x%02X)\n",
                      chip_id, BMA423_CHIP_ID_VAL);
        return false;
    }

    // Soft reset puis attente (le BMA423 prend ~2ms pour redémarrer)
    bma423_write(0x7E, 0xB6);
    delay(100);

    // Activation de l'accéléromètre
    // Note : ACC_RANGE doit être écrit APRÈS PWR_CTRL sur BMA423
    bma423_write(0x7D, 0x04);  // PWR_CTRL  : accéléromètre ON
    delay(5);
    bma423_write(0x40, 0xA8);  // ACC_CONF  : 100Hz, perf mode
    bma423_write(0x41, 0x00);  // ACC_RANGE : ±2g (défaut matériel — ±4g nécessite le fichier de config ASIC)
    delay(5);

    // Vérification lecture-retour du range configuré
    uint8_t range_val = 0xFF;
    bma423_read(0x41, &range_val, 1);
    Serial.printf("[SENSOR] ACC_RANGE = 0x%02X (%s)\n", range_val,
        range_val == 0x00 ? "±2g" : range_val == 0x01 ? "±4g" :
        range_val == 0x02 ? "±8g" : range_val == 0x03 ? "±16g" : "?");

    // Activation du podomètre
    // (nécessite le chargement du fichier de config BMA423 — voir datasheet §4.9)
    // TODO : charger bma423_config_file[] depuis progmem

    // Interruption lever de poignet sur INT1
    // TODO : configurer INT1_MAP, INT1_IO_CTRL

    _initialized = true;
    Serial.printf("[SENSOR] BMA423 OK — chip ID 0x%02X\n", chip_id);
    return true;
}

void accel_update() {
    if (!_initialized) return;

    // Lecture des 6 octets d'accélération (X, Y, Z — 12 bits chacun)
    uint8_t raw[6];
    if (!bma423_read(BMA423_REG_ACC_X_LSB, raw, 6)) return;

    int16_t ax = (int16_t)((raw[1] << 8) | raw[0]) >> 4;
    int16_t ay = (int16_t)((raw[3] << 8) | raw[2]) >> 4;
    int16_t az = (int16_t)((raw[5] << 8) | raw[4]) >> 4;

    // Conversion en m/s² pour ±2g, 12-bit signé (valeurs -2048..+2047)
    // 1g = 1024 LSB → scale = (2g × 9.80665) / 2048 = 0.009581 m/s²/LSB
    const float scale = (2.0f * 9.80665f) / 2048.0f;
    _data.x = ax * scale;
    _data.y = ay * scale;
    _data.z = az * scale;

    // Lecture compteur de pas (4 octets)
    uint8_t step_raw[4];
    if (bma423_read(BMA423_REG_STEP_CNT_0, step_raw, 4)) {
        _data.steps = (uint32_t)step_raw[0]
                    | ((uint32_t)step_raw[1] << 8)
                    | ((uint32_t)step_raw[2] << 16)
                    | ((uint32_t)step_raw[3] << 24);
    }

    // ── Machine à états : libre chute → impact ────────────────────────────
    float mag = sqrtf(_data.x * _data.x + _data.y * _data.y + _data.z * _data.z);
    uint32_t now = (uint32_t)(millis());

    if (!_free_fall_pending) {
        if (mag < FALL_FREE_FALL_THRESHOLD) {
            _free_fall_pending = true;
            _free_fall_time_ms = now;
        }
    } else {
        if (now - _free_fall_time_ms > FALL_WINDOW_MS) {
            // Fenêtre expirée sans impact → fausse alerte
            _free_fall_pending = false;
        } else if (mag > FALL_IMPACT_THRESHOLD) {
            // Impact détecté après libre chute → chute confirmée
            _free_fall_pending    = false;
            _fall_detected        = true;
            _fall_detect_time_ms  = now;
            Serial.printf("[FALL] Chute détectée — magnitude impact: %.2f m/s²\n", mag);
        }
    }

    // Expiration automatique de l'alerte après FALL_DISPLAY_MS
    if (_fall_detected && (now - _fall_detect_time_ms > FALL_DISPLAY_MS)) {
        _fall_detected = false;
    }
}

AccelData accel_get_data() {
    return _data;
}

void accel_reset_steps() {
    // Le reset du compteur se fait via la commande 0xB2 sur le registre CMD
    bma423_write(0x7E, 0xB2);
    _data.steps = 0;
}

bool accel_fall_detected() {
    return _fall_detected;
}

void accel_clear_fall() {
    _fall_detected = false;
}
