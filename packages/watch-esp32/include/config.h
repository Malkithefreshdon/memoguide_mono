#pragma once

// ============================================================
// config.h — Pinout & adresses I2C pour la LILYGO T-Watch S3
// Source : pinout vérifié hardware
// ============================================================

// ------------------------------------------------------------
// Écran (ST7789V — SPI)
// ------------------------------------------------------------
#define DISPLAY_WIDTH       240
#define DISPLAY_HEIGHT      240

#define PIN_DISPLAY_MOSI    13
#define PIN_DISPLAY_SCLK    18
#define PIN_DISPLAY_CS      12
#define PIN_DISPLAY_DC      38
#define PIN_DISPLAY_RST     -1   // Contrôlé via AXP2101
#define PIN_DISPLAY_BL      45   // Rétroéclairage (PWM)

#define DISPLAY_ROTATION    0    // 0=portrait, 1=paysage, 2, 3

// ------------------------------------------------------------
// Bus I2C principal — AXP2101, BMA423, RTC, DRV2605
// ------------------------------------------------------------
#define I2C_SDA_PIN         10
#define I2C_SCL_PIN         11
#define I2C_FREQ_HZ         400000

// ------------------------------------------------------------
// Bus I2C touch — FT6336U uniquement
// ------------------------------------------------------------
#define TOUCH_SDA_PIN       39
#define TOUCH_SCL_PIN       40
#define TOUCH_INT_PIN       16
#define TOUCH_I2C_ADDR      0x38

// ------------------------------------------------------------
// Accéléromètre (BMA423 — I2C principal)
// ------------------------------------------------------------
#define BMA423_I2C_ADDR     0x19
#define BMA423_INT1_PIN     14
#define BMA423_RANGE_G      2      // ±2g (défaut sans fichier config ASIC)

// ------------------------------------------------------------
// Gestion d'énergie (AXP2101 — I2C principal)
// ------------------------------------------------------------
#define AXP2101_I2C_ADDR    0x34
#define AXP2101_INT_PIN     21

// ------------------------------------------------------------
// RTC (PCF8563 — I2C principal)
// ------------------------------------------------------------
#define RTC_I2C_ADDR        0x51

// ------------------------------------------------------------
// Rétroaction haptique (DRV2605 — I2C principal)
// ------------------------------------------------------------
#define DRV2605_I2C_ADDR    0x5A

// ------------------------------------------------------------
// LoRa (SX1262 — SPI dédié)
// ------------------------------------------------------------
#define LORA_MOSI_PIN       1
#define LORA_MISO_PIN       4
#define LORA_SCK_PIN        3
#define LORA_CS_PIN         5
#define LORA_RST_PIN        8
#define LORA_BUSY_PIN       7
#define LORA_DIO1_PIN       9

// ------------------------------------------------------------
// Sortie audio I2S (MAX98357A ou équivalent)
// ------------------------------------------------------------
#define AUDIO_BCK_PIN       48
#define AUDIO_WS_PIN        15
#define AUDIO_DOUT_PIN      46

// ------------------------------------------------------------
// Microphone PDM
// ------------------------------------------------------------
#define MIC_DATA_PIN        47
#define MIC_SCLK_PIN        44

// ------------------------------------------------------------
// Émetteur IR
// ------------------------------------------------------------
#define IR_SENDER_PIN       2

// ------------------------------------------------------------
// Bouton latéral
// ------------------------------------------------------------
#define BTN_SIDE_PIN        0   // GPIO0 — boot button réutilisé

// ------------------------------------------------------------
// Paramètres système
// ------------------------------------------------------------
#define SERIAL_BAUD         115200
#define WATCHDOG_TIMEOUT_S  30

#define LOG_TAG_MAIN        "MAIN"
#define LOG_TAG_DISPLAY     "DISPLAY"
#define LOG_TAG_SENSOR      "SENSOR"
#define LOG_TAG_POWER       "POWER"
#define LOG_TAG_WIFI        "WIFI"

// ------------------------------------------------------------
// Localisation BLE iBeacon → Gateway
// ------------------------------------------------------------
#define BLE_DEVICE_NAME         "Memo_Montre"
#define COMPANY_ID_LO           0xFF
#define COMPANY_ID_HI           0xFF
#define BLE_MAGIC_BYTE          0xAA
#define WATCH_ID                1        // Changer pour chaque montre (1..255)

#define MAX_BEACONS             5        // Balises simultanées max dans la table
#define BEACON_TIMEOUT_MS       5000     // ms avant d'expirer une balise sans signal
#define LOCALIZATION_PERIOD_MS  2000     // ms entre chaque cycle de diffusion
