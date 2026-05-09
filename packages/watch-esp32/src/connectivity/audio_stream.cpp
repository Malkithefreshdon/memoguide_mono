#include "audio_stream.h"
#include "../../include/config.h"

#include <Arduino.h>
#include <WiFiUdp.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "driver/i2s.h"
#include "esp_log.h"

static const char      *TAG    = "AUDIO";
static const i2s_port_t I2S_PORT = I2S_NUM_0;

static WiFiUDP  s_udp;
static uint8_t  s_buf[AUDIO_CHUNK_SIZE * 2];

// ── I2S write ────────────────────────────────────────────────
int audio_play_chunk(const void *buf, size_t len)
{
    size_t written = 0;
    esp_err_t err = i2s_write(I2S_PORT, buf, len, &written, pdMS_TO_TICKS(200));
    return (err == ESP_OK) ? 0 : -1;
}

// ── Tâche UDP ────────────────────────────────────────────────
static void udp_task(void *pv)
{
    s_udp.begin(AUDIO_UDP_PORT);
    ESP_LOGI(TAG, "Écoute UDP sur port %d", AUDIO_UDP_PORT);

    for (;;) {
        int pkt = s_udp.parsePacket();
        if (pkt > 0 && pkt <= (int)sizeof(s_buf)) {
            int len = s_udp.read(s_buf, pkt);
            if (len > 0) audio_play_chunk(s_buf, (size_t)len);
        } else {
            vTaskDelay(pdMS_TO_TICKS(1));
        }
    }
}

// ── Init ─────────────────────────────────────────────────────
bool audio_stream_init()
{
    i2s_config_t cfg = {
        .mode                 = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
        .sample_rate          = AUDIO_SAMPLE_RATE,
        .bits_per_sample      = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format       = I2S_CHANNEL_FMT_RIGHT_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags     = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count        = 8,
        .dma_buf_len          = 128,
        .use_apll             = false,
        .tx_desc_auto_clear   = true,
        .fixed_mclk           = 0,
    };

    if (i2s_driver_install(I2S_PORT, &cfg, 0, NULL) != ESP_OK) {
        ESP_LOGE(TAG, "i2s_driver_install échoué");
        return false;
    }

    i2s_pin_config_t pins = {
        .mck_io_num   = I2S_PIN_NO_CHANGE,
        .bck_io_num   = AUDIO_BCK_PIN,
        .ws_io_num    = AUDIO_WS_PIN,
        .data_out_num = AUDIO_DOUT_PIN,
        .data_in_num  = I2S_PIN_NO_CHANGE,
    };

    if (i2s_set_pin(I2S_PORT, &pins) != ESP_OK) {
        ESP_LOGE(TAG, "i2s_set_pin échoué");
        return false;
    }

    xTaskCreatePinnedToCore(udp_task, "audio_udp", 8192, NULL, 5, NULL, 1);

    ESP_LOGI(TAG, "Audio stream OK — I2S + UDP:%d", AUDIO_UDP_PORT);
    return true;
}
