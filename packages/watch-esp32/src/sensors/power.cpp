#include "power.h"
#include "config.h"
#include <Arduino.h>
#include <Wire.h>
#include <XPowersLib.h>
#include <esp_sleep.h>

static XPowersAXP2101 axp;
static uint32_t _last_activity_ms = 0;
static const uint32_t SLEEP_TIMEOUT_MS = 30000;

bool power_init() {
    // Wire doit être initialisé avant cet appel (dans main.cpp)
    if (!axp.begin(Wire, AXP2101_I2C_ADDR, I2C_SDA_PIN, I2C_SCL_PIN)) {
        Serial.println("[POWER] AXP2101 non détecté");
        return false;
    }

    // --- Rails de tension ---
    axp.setALDO1Voltage(2800); axp.enableALDO1();   // capteurs analogiques
    axp.setALDO2Voltage(3300); axp.enableALDO2();   // touch, BMA423, RTC
    axp.setALDO3Voltage(3300); axp.enableALDO3();   // LCD
    axp.setBLDO1Voltage(2800); axp.enableBLDO1();   // rétroéclairage

    // --- Chargeur ---
    axp.setChargerConstantCurr(XPOWERS_AXP2101_CHG_CUR_500MA);
    axp.setChargeTargetVoltage(XPOWERS_AXP2101_CHG_VOL_4V2);
    axp.enableBattDetection();

    // --- Interruptions (USB insert + bouton) ---
    axp.disableIRQ(XPOWERS_AXP2101_ALL_IRQ);
    axp.enableIRQ(XPOWERS_AXP2101_VBUS_INSERT_IRQ | XPOWERS_AXP2101_PKEY_SHORT_IRQ);

    _last_activity_ms = millis();
    Serial.println("[POWER] AXP2101 OK");
    return true;
}

PowerStatus power_get_status() {
    PowerStatus s;
    s.battery_voltage = axp.getBattVoltage() / 1000.0f;
    s.battery_percent = axp.getBatteryPercent();
    s.is_charging     = axp.isCharging();
    s.is_plugged      = axp.isVbusIn();
    return s;
}

void power_activity() {
    _last_activity_ms = millis();
}

void power_check_sleep() {
    if ((millis() - _last_activity_ms) < SLEEP_TIMEOUT_MS) return;

    Serial.println("[POWER] Timeout → deep sleep");

    // Éteindre le rétroéclairage directement (canal PWM 0, défini dans display.cpp)
    ledcWrite(0, 0);

    esp_sleep_enable_ext0_wakeup((gpio_num_t)AXP2101_INT_PIN, 0);
    esp_deep_sleep_start();
}

void power_set_dcdc_voltage(uint8_t rail, uint16_t mv) {
    switch (rail) {
        case 1: axp.setDC1Voltage(mv); break;
        case 2: axp.setDC2Voltage(mv); break;
        case 3: axp.setDC3Voltage(mv); break;
        case 4: axp.setDC4Voltage(mv); break;
        case 5: axp.setDC5Voltage(mv); break;
        default: Serial.printf("[POWER] Rail invalide : %d\n", rail);
    }
}

void power_shutdown() {
    Serial.println("[POWER] Extinction...");
    ledcWrite(0, 0);
    delay(100);
    axp.shutdown();
}
