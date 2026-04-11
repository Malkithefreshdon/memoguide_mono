#include <Arduino.h>
#include <Wire.h>
#include "config.h"
#include "display/display.h"
#include "sensors/accelerometer.h"
#include "sensors/power.h"
#include "connectivity/wifi_manager.h"
#include "connectivity/ble_localization.h"

// ============================================================
// Déclarations de tâches FreeRTOS
// ============================================================
static void task_sensor(void *pvParameters);
static void task_display(void *pvParameters);
static void task_localization(void *pvParameters);

// ============================================================
// setup()
// ============================================================
void setup() {
    Serial.begin(SERIAL_BAUD);
    delay(200);
    Serial.println("\n=== T-Watch S3 — Boot ===");

    // 1. Initialisation des deux bus I2C
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN, I2C_FREQ_HZ);       // principal : AXP2101, BMA423, RTC (GPIO 10/11)
    Wire1.begin(TOUCH_SDA_PIN, TOUCH_SCL_PIN, I2C_FREQ_HZ);  // touch : FT6336U (GPIO 39/40)

    // 2. Power management (AXP2101) en premier — alimente les autres composants
    if (!power_init()) {
        Serial.println("[POWER] ERREUR init AXP2101 — arrêt.");
        // En production : deep sleep ou reboot
        while (true) delay(1000);
    }

    // 3. Écran
    display_init();
    display_show_splash();

    // 4. Accéléromètre (BMA423)
    if (!accel_init()) {
        Serial.println("[SENSOR] ERREUR init BMA423 — les données IMU ne seront pas disponibles.");
    }

    // 5. WiFi (optionnel au démarrage)
    // wifi_connect("SSID", "PASSWORD");

    // 6. Localisation BLE iBeacon
    localization_init();

    // 7. Tâches FreeRTOS
    xTaskCreatePinnedToCore(task_sensor,       "sensor",  4096,  nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(task_display,      "display", 8192,  nullptr, 2, nullptr, 1);
    xTaskCreatePinnedToCore(task_localization, "ble_loc", 8192,  nullptr, 1, nullptr, 0);

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
