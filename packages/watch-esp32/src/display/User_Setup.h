#define USER_SETUP_LOADED
#define ST7789_DRIVER

#define TFT_WIDTH   240
#define TFT_HEIGHT  240

#define TFT_MOSI    13
#define TFT_SCLK    18
#define TFT_CS      12
#define TFT_DC      38
#define TFT_RST     -1
// Backlight géré manuellement via ledcWrite (PIN_DISPLAY_BL = 45)

#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4
#define LOAD_GFXFF

#define SPI_FREQUENCY       40000000
#define SPI_READ_FREQUENCY  20000000