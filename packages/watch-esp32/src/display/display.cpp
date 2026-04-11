#include "display.h"
#include "config.h"
#include <Arduino.h>
#include <LovyanGFX.hpp>
#include "sensors/accelerometer.h"
#include "sensors/power.h"
#include "connectivity/ble_localization.h"

// ============================================================
// Configuration LovyanGFX pour T-Watch S3 (ST7789V, SPI2_HOST)
// Pins : MOSI=13, SCLK=18, CS=12, DC=38, BL=45
// ============================================================

class LGFX : public lgfx::LGFX_Device {
    lgfx::Panel_ST7789  _panel;
    lgfx::Bus_SPI       _bus;
    lgfx::Light_PWM     _light;

public:
    LGFX() {
        // --- Bus SPI ---
        {
            auto cfg = _bus.config();
            cfg.spi_host    = SPI2_HOST;       // host SPI hardware explicite
            cfg.spi_mode    = 3;
            cfg.freq_write  = 40000000;
            cfg.freq_read   = 16000000;
            cfg.spi_3wire   = true;
            cfg.use_lock    = true;
            cfg.dma_channel = SPI_DMA_CH_AUTO;
            cfg.pin_sclk    = PIN_DISPLAY_SCLK;  // 18
            cfg.pin_mosi    = PIN_DISPLAY_MOSI;  // 13
            cfg.pin_miso    = -1;
            cfg.pin_dc      = PIN_DISPLAY_DC;    // 38
            _bus.config(cfg);
            _panel.setBus(&_bus);
        }

        // --- Panel ST7789V ---
        {
            auto cfg = _panel.config();
            cfg.pin_cs       = PIN_DISPLAY_CS;   // 12
            cfg.pin_rst      = PIN_DISPLAY_RST;  // -1 (via AXP2101)
            cfg.pin_busy     = -1;
            cfg.panel_width  = DISPLAY_WIDTH;    // 240
            cfg.panel_height = DISPLAY_HEIGHT;   // 240
            cfg.offset_x        = 0;
            cfg.offset_y        = 0;
            cfg.offset_rotation = 0;
            cfg.readable        = false;
            cfg.invert          = true;           // ST7789V sur T-Watch nécessite l'inversion
            cfg.rgb_order       = false;
            cfg.dlen_16bit      = false;
            cfg.bus_shared      = false;
            _panel.config(cfg);
        }

        // --- Rétroéclairage PWM ---
        {
            auto cfg = _light.config();
            cfg.pin_bl    = PIN_DISPLAY_BL;  // 45
            cfg.invert    = false;
            cfg.freq      = 5000;
            cfg.pwm_channel = 7;             // canal 7 pour éviter les conflits
            _light.config(cfg);
            _panel.setLight(&_light);
        }

        setPanel(&_panel);
    }
};

static LGFX lcd;
static lgfx::LGFX_Sprite sprite(&lcd);  // double-buffer — évite le flickering

bool display_init() {
    lcd.init();
    lcd.setRotation(DISPLAY_ROTATION);
    lcd.setBrightness(200);
    lcd.fillScreen(TFT_BLACK);

    sprite.setColorDepth(16);
    sprite.createSprite(240, 240);  // alloué en PSRAM si disponible

    Serial.println("[DISPLAY] LovyanGFX OK — ST7789V 240x240 sur SPI2_HOST");
    return true;
}

void display_show_splash() {
    lcd.fillScreen(lcd.color565(0, 0, 255));  // fond bleu
    lcd.setTextColor(TFT_WHITE);
    lcd.setTextSize(2);
    lcd.setCursor(40, 100);
    lcd.print("T-Watch S3");
    lcd.setTextColor(lcd.color565(0, 255, 255));
    lcd.setCursor(50, 126);
    lcd.print("MemoGuide");
    delay(1500);
}

// ============================================================
// Couleurs palette
// ============================================================
static constexpr uint16_t C_BG       = TFT_BLACK;
static constexpr uint16_t C_HEADER   = 0x0010;  // bleu nuit
static constexpr uint16_t C_CYAN     = TFT_CYAN;
static constexpr uint16_t C_WHITE    = TFT_WHITE;
static constexpr uint16_t C_YELLOW   = TFT_YELLOW;
static constexpr uint16_t C_GREEN    = TFT_GREEN;
static constexpr uint16_t C_ORANGE   = 0xFD20;  // orange
static constexpr uint16_t C_RED      = TFT_RED;
static constexpr uint16_t C_GRAY     = 0x7BEF;  // gris séparateur

// RSSI → couleur indicative
static uint16_t rssi_color(int8_t rssi) {
    if (rssi >= -65) return C_GREEN;
    if (rssi >= -75) return C_YELLOW;
    if (rssi >= -85) return C_ORANGE;
    return C_RED;
}

// Ligne séparatrice horizontale
static void draw_separator(int y) {
    sprite.drawFastHLine(8, y, 224, C_GRAY);
}

void display_update() {
    AccelData    accel   = accel_get_data();
    PowerStatus  power   = power_get_status();
    BeaconSnapshot beacons[MAX_BEACONS];
    int nb_beacons = localization_get_active_beacons(beacons, MAX_BEACONS);
    uint32_t tx_count = localization_get_tx_count();

    sprite.fillScreen(C_BG);

    // ── Header ────────────────────────────────────────────── y=0..19
    sprite.fillRect(0, 0, 240, 20, C_HEADER);
    sprite.setTextColor(C_CYAN, C_HEADER);
    sprite.setTextSize(1);
    sprite.setCursor(6, 6);
    sprite.print("MemoGuide");

    // Batterie — droite du header
    char bat_buf[16];
    uint16_t bat_color = (power.battery_percent < 20) ? C_RED : C_GREEN;
    snprintf(bat_buf, sizeof(bat_buf), "%d%%%s",
             power.battery_percent, power.is_charging ? " CHG" : "");
    sprite.setTextColor(bat_color, C_HEADER);
    sprite.setCursor(240 - (strlen(bat_buf) * 6) - 6, 6);
    sprite.print(bat_buf);

    // ── Accéléromètre ─────────────────────────────────────── y=24..72
    int y = 24;
    sprite.setTextColor(C_CYAN, C_BG);
    sprite.setTextSize(1);
    sprite.setCursor(6, y);
    sprite.print("ACCELEROMETRE");

    y += 12;
    char line[40];
    sprite.setTextColor(C_WHITE, C_BG);
    sprite.setTextSize(2);

    snprintf(line, sizeof(line), "X%+.2f Y%+.2f", accel.x, accel.y);
    sprite.setCursor(6, y);
    sprite.print(line);

    y += 18;
    snprintf(line, sizeof(line), "Z%+.2f", accel.z);
    sprite.setCursor(6, y);
    sprite.print(line);

    // Tension batterie (size 1, à droite de Z)
    sprite.setTextSize(1);
    sprite.setTextColor(C_GRAY, C_BG);
    snprintf(line, sizeof(line), "%.2fV", power.battery_voltage);
    sprite.setCursor(240 - (strlen(line) * 6) - 6, y + 5);
    sprite.print(line);

    y += 18;
    draw_separator(y);

    // ── Balises BLE ───────────────────────────────────────── y=+4..
    y += 6;
    sprite.setTextColor(C_CYAN, C_BG);
    sprite.setTextSize(1);
    sprite.setCursor(6, y);
    snprintf(line, sizeof(line), "BALISES BLE  %d/%d", nb_beacons, MAX_BEACONS);
    sprite.print(line);

    y += 10;

    if (nb_beacons == 0) {
        sprite.setTextColor(C_GRAY, C_BG);
        sprite.setCursor(6, y);
        sprite.print("-- aucun beacon a portee --");
        y += 10;
    } else {
        for (int i = 0; i < nb_beacons; i++) {
            snprintf(line, sizeof(line), " Maj:%-5u Min:%-5u %4ddBm",
                     beacons[i].major, beacons[i].minor, beacons[i].last_rssi);
            sprite.setTextColor(rssi_color(beacons[i].last_rssi), C_BG);
            sprite.setCursor(6, y);
            sprite.print(line);
            y += 10;
        }
    }

    draw_separator(y + 2);

    // ── Gateway TX ────────────────────────────────────────── y=+8..
    y += 10;
    sprite.setTextColor(C_CYAN, C_BG);
    sprite.setTextSize(1);
    sprite.setCursor(6, y);
    sprite.print("GATEWAY");

    y += 12;
    sprite.setTextColor(C_WHITE, C_BG);
    sprite.setTextSize(2);
    snprintf(line, sizeof(line), "TX #%lu", (unsigned long)tx_count);
    sprite.setCursor(6, y);
    sprite.print(line);

    // Uptime en secondes à droite
    sprite.setTextSize(1);
    sprite.setTextColor(C_GRAY, C_BG);
    uint32_t uptime_s = (uint32_t)(esp_timer_get_time() / 1000000ULL);
    snprintf(line, sizeof(line), "up %lus", (unsigned long)uptime_s);
    sprite.setCursor(240 - (strlen(line) * 6) - 6, y + 5);
    sprite.print(line);

    // ── Push vers l'écran ──────────────────────────────────
    sprite.pushSprite(0, 0);
}

void display_clear(uint16_t color) {
    lcd.fillScreen(color);
}

void display_print(const char *text, int16_t x, int16_t y, uint8_t size, uint16_t color) {
    lcd.setTextColor(color, TFT_BLACK);
    lcd.setTextSize(size);
    lcd.setCursor(x, y);
    lcd.print(text);
}

void display_set_brightness(uint8_t level) {
    lcd.setBrightness(level);
}
