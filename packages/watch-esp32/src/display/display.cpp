#include "display.h"
#include "config.h"
#include <Arduino.h>
#include <LovyanGFX.hpp>
#include <LittleFS.h>
#include <time.h>
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
        {
            auto cfg = _bus.config();
            cfg.spi_host    = SPI2_HOST;
            cfg.spi_mode    = 3;
            cfg.freq_write  = 40000000;
            cfg.freq_read   = 16000000;
            cfg.spi_3wire   = true;
            cfg.use_lock    = true;
            cfg.dma_channel = SPI_DMA_CH_AUTO;
            cfg.pin_sclk    = PIN_DISPLAY_SCLK;
            cfg.pin_mosi    = PIN_DISPLAY_MOSI;
            cfg.pin_miso    = -1;
            cfg.pin_dc      = PIN_DISPLAY_DC;
            _bus.config(cfg);
            _panel.setBus(&_bus);
        }
        {
            auto cfg = _panel.config();
            cfg.pin_cs          = PIN_DISPLAY_CS;
            cfg.pin_rst         = PIN_DISPLAY_RST;
            cfg.pin_busy        = -1;
            cfg.panel_width     = DISPLAY_WIDTH;
            cfg.panel_height    = DISPLAY_HEIGHT;
            cfg.offset_x        = 0;
            cfg.offset_y        = 0;
            cfg.offset_rotation = 0;
            cfg.readable        = false;
            cfg.invert          = true;
            cfg.rgb_order       = false;
            cfg.dlen_16bit      = false;
            cfg.bus_shared      = false;
            _panel.config(cfg);
        }
        {
            auto cfg = _light.config();
            cfg.pin_bl      = PIN_DISPLAY_BL;
            cfg.invert      = false;
            cfg.freq        = 5000;
            cfg.pwm_channel = 7;
            _light.config(cfg);
            _panel.setLight(&_light);
        }
        setPanel(&_panel);
    }
};

static LGFX lcd;
static lgfx::LGFX_Sprite sprite(&lcd);

// ── Modes ─────────────────────────────────────────────────────────────────────
static volatile bool s_dev_mode      = false;  // home par défaut
static volatile bool s_guidance_mode = false;
static char s_guide_arrow[16] = "";
static char s_guide_line1[48] = "";
static char s_guide_line2[48] = "";

// ── Palette ───────────────────────────────────────────────────────────────────
static constexpr uint16_t C_BG     = TFT_BLACK;
static constexpr uint16_t C_HEADER = 0x0010;   // bleu nuit
static constexpr uint16_t C_CYAN   = TFT_CYAN;
static constexpr uint16_t C_WHITE  = TFT_WHITE;
static constexpr uint16_t C_YELLOW = TFT_YELLOW;
static constexpr uint16_t C_GREEN  = TFT_GREEN;
static constexpr uint16_t C_ORANGE = 0xFD20;   // orange
static constexpr uint16_t C_RED    = TFT_RED;
static constexpr uint16_t C_GRAY   = 0x7BEF;   // gris
// Rose-crimson MemoGuide (R=210, G=0, B=80 → RGB565)
static constexpr uint16_t C_ACCENT = 0xD00A;

// ── PNG depuis LittleFS ────────────────────────────────────────────────────────
// LovyanGFX ne supporte pas fs::LittleFSFS → on lit en RAM puis drawPng() sur buffer.
// scale 0.0 = auto-fit dans maxW×maxH (LovyanGFX ≥1.x).
static bool draw_png_littlefs(lgfx::LGFXBase *target, const char *path,
                               int32_t x, int32_t y,
                               int32_t maxW = 0, int32_t maxH = 0) {
    if (!LittleFS.exists(path)) {
        Serial.printf("[FS] Fichier introuvable: %s\n", path);
        return false;
    }
    File f = LittleFS.open(path, "r");
    if (!f) {
        Serial.printf("[FS] Impossible d'ouvrir: %s\n", path);
        return false;
    }
    size_t sz = f.size();
    Serial.printf("[FS] PNG %s — %u octets\n", path, (unsigned)sz);

    // Allocation PSRAM en priorité (8MB dispo sur S3), sinon SRAM
    uint8_t *buf = (uint8_t *)heap_caps_malloc(sz, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (!buf) buf = (uint8_t *)malloc(sz);
    if (!buf) {
        Serial.println("[FS] Allocation échouée");
        f.close();
        return false;
    }
    f.read(buf, sz);
    f.close();

    bool ok = target->drawPng(buf, sz, x, y, maxW, maxH, 0, 0, 0.0f, 0.0f);
    Serial.printf("[FS] drawPng → %s\n", ok ? "OK" : "ECHEC");
    free(buf);
    return ok;
}

// ── Initialisation ────────────────────────────────────────────────────────────
bool display_init() {
    lcd.init();
    lcd.setRotation(DISPLAY_ROTATION);
    lcd.setBrightness(200);
    lcd.fillScreen(TFT_BLACK);
    sprite.setColorDepth(16);
    sprite.createSprite(240, 240);
    Serial.println("[DISPLAY] LovyanGFX OK — ST7789V 240×240");
    return true;
}

// ── Splash screen (5 s) ───────────────────────────────────────────────────────
void display_show_splash() {
    lcd.fillScreen(TFT_WHITE);
    // logo.png centré, mise à l'échelle automatique dans 220×140
    // scale 0,0 = auto-fit dans les bornes maxWidth×maxHeight (LovyanGFX ≥1.x)
    if (!draw_png_littlefs(&lcd, "/images/logo.png", 10, 50, 220, 140)) {
        // Fallback texte si LittleFS non monté ou fichier absent
        lcd.setTextColor(C_ACCENT, TFT_WHITE);
        lcd.setTextSize(3);
        lcd.setCursor(30, 90);
        lcd.print("MemoGuide");
        lcd.setTextSize(1);
        lcd.setTextColor(0x7BEF, TFT_WHITE);
        lcd.setCursor(40, 125);
        lcd.print("La serenite au poignet");
    }
    delay(5000);
}

// ── Helpers internes ─────────────────────────────────────────────────────────
static uint16_t rssi_color(int8_t rssi) {
    if (rssi >= -65) return C_GREEN;
    if (rssi >= -75) return C_YELLOW;
    if (rssi >= -85) return C_ORANGE;
    return C_RED;
}

static void draw_separator(int y) {
    sprite.drawFastHLine(8, y, 224, C_GRAY);
}

// ── Overlay chute — appliqué par-dessus n'importe quel mode ──────────────────
static void draw_fall_overlay() {
    bool blink = ((esp_timer_get_time() / 500000ULL) % 2) == 0;
    if (!blink) return;
    sprite.fillRect(0, 88, 240, 64, C_RED);
    sprite.setTextColor(C_WHITE, C_RED);
    sprite.setTextSize(2);
    // "CHUTE DETECTEE" = 14 chars × 12 px/char (size 2)
    sprite.setCursor((240 - 14 * 12) / 2, 100);
    sprite.print("CHUTE DETECTEE");
    sprite.setTextSize(1);
    sprite.setCursor(55, 124);
    sprite.print("Appel d'urgence...");
}

// ── Mode HOME : cadran horloge ────────────────────────────────────────────────
static void draw_home_frame() {
    sprite.fillScreen(TFT_WHITE);

    // Batterie — haut droite
    PowerStatus power = power_get_status();
    char bat_buf[12];
    snprintf(bat_buf, sizeof(bat_buf), "%d%%", power.battery_percent);
    uint16_t bat_col = (power.battery_percent < 20)
                       ? C_RED
                       : sprite.color565(80, 80, 80);
    sprite.setTextColor(bat_col, TFT_WHITE);
    sprite.setTextSize(1);
    sprite.setCursor(240 - (int16_t)(strlen(bat_buf) * 6) - 4, 4);
    sprite.print(bat_buf);

    // Heure — grosse police rose-crimson, centrée verticalement ~haut tiers
    struct tm timeinfo;
    char time_str[8] = "--:--";
    if (getLocalTime(&timeinfo, 0)) {
        snprintf(time_str, sizeof(time_str), "%02d:%02d",
                 timeinfo.tm_hour, timeinfo.tm_min);
    }
    sprite.setTextColor(C_ACCENT, TFT_WHITE);
    sprite.setTextSize(6);
    int16_t tw = (int16_t)sprite.textWidth(time_str);
    sprite.setCursor((240 - tw) / 2, 52);
    sprite.print(time_str);

    // Logo icon — centré sous l'heure, max 90×108 px
    draw_png_littlefs(&sprite, "/images/logo_icon.png", 75, 122, 90, 108);
}

// ── Mode DEV : dashboard capteurs ────────────────────────────────────────────
static void draw_dev_frame() {
    AccelData   accel = accel_get_data();
    PowerStatus power = power_get_status();
    BeaconSnapshot beacons[MAX_BEACONS];
    int nb_beacons = localization_get_active_beacons(beacons, MAX_BEACONS);
    uint32_t tx_count = localization_get_tx_count();

    sprite.fillScreen(C_BG);

    // Header
    sprite.fillRect(0, 0, 240, 20, C_HEADER);
    sprite.setTextColor(C_CYAN, C_HEADER);
    sprite.setTextSize(1);
    sprite.setCursor(6, 6);
    sprite.print("MemoGuide [DEV]");

    char bat_buf[16];
    uint16_t bat_color = (power.battery_percent < 20) ? C_RED : C_GREEN;
    snprintf(bat_buf, sizeof(bat_buf), "%d%%%s",
             power.battery_percent, power.is_charging ? " CHG" : "");
    sprite.setTextColor(bat_color, C_HEADER);
    sprite.setCursor(240 - (int16_t)(strlen(bat_buf) * 6) - 6, 6);
    sprite.print(bat_buf);

    // Accéléromètre
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

    sprite.setTextSize(1);
    sprite.setTextColor(C_GRAY, C_BG);
    snprintf(line, sizeof(line), "%.2fV", power.battery_voltage);
    sprite.setCursor(240 - (int16_t)(strlen(line) * 6) - 6, y + 5);
    sprite.print(line);

    y += 18;
    draw_separator(y);

    // Balises BLE
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

    // Gateway TX
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

    sprite.setTextSize(1);
    sprite.setTextColor(C_GRAY, C_BG);
    uint32_t uptime_s = (uint32_t)(esp_timer_get_time() / 1000000ULL);
    snprintf(line, sizeof(line), "up %lus", (unsigned long)uptime_s);
    sprite.setCursor(240 - (int16_t)(strlen(line) * 6) - 6, y + 5);
    sprite.print(line);
}

// ── Mode GUIDAGE : flèches navigation ─────────────────────────────────────────
static void draw_guidance_arrow(const char *type) {
    const uint16_t col = C_CYAN;
    if (strcmp(type, "right") == 0) {
        sprite.fillRect(40, 88, 115, 16, col);
        sprite.fillTriangle(150, 66, 205, 96, 150, 126, col);
    } else if (strcmp(type, "left") == 0) {
        sprite.fillRect(85, 88, 115, 16, col);
        sprite.fillTriangle(90, 66, 35, 96, 90, 126, col);
    } else if (strcmp(type, "straight") == 0) {
        sprite.fillRect(112, 70, 16, 85, col);
        sprite.fillTriangle(88, 75, 152, 75, 120, 32, col);
    } else if (strcmp(type, "stairs_up") == 0) {
        for (int i = 0; i < 4; i++) {
            sprite.fillRect(50 + i * 34, 138 - i * 26, 38, 5, col);
            sprite.fillRect(80 + i * 34, 113 - i * 26, 5, 26, col);
        }
        sprite.fillTriangle(162, 40, 200, 60, 185, 80, col);
    } else if (strcmp(type, "elevator") == 0) {
        sprite.drawRect(82, 38, 76, 104, col);
        sprite.fillRect(112, 60, 16, 65, col);
        sprite.fillTriangle(92, 68, 148, 68, 120, 38, col);
    } else if (strcmp(type, "arrived") == 0) {
        sprite.fillRect(0, 28, 240, 142, sprite.color565(0, 50, 0));
        const uint16_t g = C_GREEN;
        for (int t = -5; t <= 5; t++) {
            sprite.drawLine(52 + t, 100, 95 + t, 143, g);
            sprite.drawLine(95 + t, 143, 188 + t, 58, g);
        }
    }
}

static void draw_guidance_frame() {
    sprite.fillScreen(C_BG);
    sprite.fillRect(0, 0, 240, 20, C_HEADER);
    sprite.setTextColor(C_CYAN, C_HEADER);
    sprite.setTextSize(1);
    sprite.setCursor(6, 6);
    sprite.print("MemoGuide");

    draw_guidance_arrow(s_guide_arrow);

    sprite.setTextSize(2);
    sprite.setTextColor(C_WHITE, C_BG);
    int16_t w = (int16_t)sprite.textWidth(s_guide_line1);
    sprite.setCursor((240 - w) / 2, 178);
    sprite.print(s_guide_line1);

    sprite.setTextSize(1);
    sprite.setTextColor(C_GRAY, C_BG);
    w = (int16_t)sprite.textWidth(s_guide_line2);
    sprite.setCursor((240 - w) / 2, 207);
    sprite.print(s_guide_line2);
}

// ── display_update : routage + push ──────────────────────────────────────────
void display_update() {
    if (s_guidance_mode)     draw_guidance_frame();
    else if (s_dev_mode)     draw_dev_frame();
    else                     draw_home_frame();

    if (accel_fall_detected()) draw_fall_overlay();

    sprite.pushSprite(0, 0);
}

// ── API publique ──────────────────────────────────────────────────────────────
void display_toggle_dev_mode() {
    s_dev_mode = !s_dev_mode;
    Serial.printf("[DISPLAY] Mode %s\n", s_dev_mode ? "DEV" : "HOME");
}

void display_show_guidance(const char *arrow, const char *line1, const char *line2) {
    strlcpy(s_guide_arrow, arrow, sizeof(s_guide_arrow));
    strlcpy(s_guide_line1, line1, sizeof(s_guide_line1));
    strlcpy(s_guide_line2, line2, sizeof(s_guide_line2));
    s_guidance_mode = true;
}

void display_exit_guidance() {
    s_guidance_mode = false;
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
