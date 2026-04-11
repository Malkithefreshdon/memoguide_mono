#pragma once
#include <stdint.h>

// ============================================================
// display.h — Pilote écran ST7789V via TFT_eSPI
// Résolution : 240×240, SPI
// ============================================================

bool     display_init();
void     display_show_splash();
void     display_update();

// Helpers de dessin (wrappers légers autour de TFT_eSPI)
void     display_clear(uint16_t color = 0x0000);
void     display_print(const char *text, int16_t x, int16_t y, uint8_t size = 2, uint16_t color = 0xFFFF);
void     display_set_brightness(uint8_t level);  // 0–255
