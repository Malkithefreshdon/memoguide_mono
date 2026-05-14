#include "audio_stream.h"
#include "../../include/config.h"

#include <Arduino.h>
#include <WiFiUdp.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/stream_buffer.h>
#include "driver/i2s.h"
#include "esp_log.h"
#include <string.h>

static const char      *TAG      = "AUDIO";
static const i2s_port_t I2S_PORT = I2S_NUM_0;

// ── Tailles du pipeline ──────────────────────────────────────
// I2S_BLOCK_SIZE  : granularité d'écriture vers le DMA (= 32ms)
// RING_BUF_SIZE   : absorbe le jitter UDP (~500ms de marge)
// PRELOAD_BYTES   : données accumulées avant de démarrer l'I2S
//                   (latence initiale : 256ms — élimine les underflows)
#define I2S_BLOCK_SIZE   512
#define RING_BUF_SIZE    (32 * 1024)
#define PRELOAD_BYTES    (8 * I2S_BLOCK_SIZE)   // 256ms

static StreamBufferHandle_t s_stream   = NULL;
static WiFiUDP              s_udp;
static uint8_t              s_udp_buf[I2S_BLOCK_SIZE * 2];
static uint8_t              s_i2s_block[I2S_BLOCK_SIZE];
static const uint8_t        s_silence[I2S_BLOCK_SIZE] = {0};

// ── API publique ─────────────────────────────────────────────
int audio_play_chunk(const void *buf, size_t len)
{
    if (!s_stream) return -1;
    // Non-bloquant : on drop si le ring buffer est saturé
    // (mieux que bloquer la tâche UDP et perdre des paquets suivants)
    size_t sent = xStreamBufferSend(s_stream, buf, len, 0);
    return (sent == len) ? 0 : -1;
}

// ── Tâche I2S feeder (core 1, prio 5) ───────────────────────
// Séparer reception UDP et écriture I2S en deux tâches évite que
// la latence de i2s_write() retarde la lecture des paquets suivants.
static void i2s_feeder_task(void *pv)
{
    // Pré-charge : on attend d'avoir PRELOAD_BYTES dans le buffer avant
    // de commencer à jouer. Absorbe le démarrage du relay et le jitter initial.
    while (xStreamBufferBytesAvailable(s_stream) < PRELOAD_BYTES) {
        vTaskDelay(pdMS_TO_TICKS(5));
    }
    ESP_LOGI(TAG, "Pré-charge OK → démarrage I2S");

    for (;;) {
        if (xStreamBufferBytesAvailable(s_stream) >= I2S_BLOCK_SIZE) {
            xStreamBufferReceive(s_stream, s_i2s_block, I2S_BLOCK_SIZE, portMAX_DELAY);
            size_t written;
            i2s_write(I2S_PORT, s_i2s_block, I2S_BLOCK_SIZE, &written, pdMS_TO_TICKS(100));
        } else {
            // Underflow : sortir du silence plutôt que des données aléatoires
            size_t written;
            i2s_write(I2S_PORT, s_silence, I2S_BLOCK_SIZE, &written, pdMS_TO_TICKS(100));
        }
    }
}

// ── Tâche UDP receiver (core 0, prio 4) ─────────────────────
static void udp_task(void *pv)
{
    s_udp.begin(AUDIO_UDP_PORT);
    ESP_LOGI(TAG, "UDP port %d ouvert", AUDIO_UDP_PORT);

    for (;;) {
        int pkt = s_udp.parsePacket();
        if (pkt > 0 && pkt <= (int)sizeof(s_udp_buf)) {
            int len = s_udp.read(s_udp_buf, pkt);
            if (len > 0) audio_play_chunk(s_udp_buf, (size_t)len);
        } else {
            vTaskDelay(pdMS_TO_TICKS(1));
        }
    }
}

// ── Init ─────────────────────────────────────────────────────
bool audio_stream_init()
{
    // --- Ring buffer ---
    s_stream = xStreamBufferCreate(RING_BUF_SIZE, 1);
    if (!s_stream) {
        ESP_LOGE(TAG, "xStreamBufferCreate échoué (mémoire insuffisante ?)");
        return false;
    }

    // --- I2S : DMA agrandi pour limiter les interruptions ---
    i2s_config_t cfg = {
        .mode                 = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
        .sample_rate          = AUDIO_SAMPLE_RATE,
        .bits_per_sample      = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format       = I2S_CHANNEL_FMT_RIGHT_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags     = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count        = 16,   // 16 descripteurs DMA (était 8)
        .dma_buf_len          = 256,  // 256 frames par descripteur (était 128)
        .use_apll             = false,
        .tx_desc_auto_clear   = true, // silence sur underflow DMA
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

    // --- Tâches ---
    xTaskCreatePinnedToCore(i2s_feeder_task, "audio_i2s", 4096, NULL, 5, NULL, 1);
    xTaskCreatePinnedToCore(udp_task,        "audio_udp", 4096, NULL, 4, NULL, 0);

    ESP_LOGI(TAG, "Audio init OK | ring=%dKB preload=%dms DMA=%dKB",
             RING_BUF_SIZE / 1024,
             (PRELOAD_BYTES * 1000) / (AUDIO_SAMPLE_RATE * 2 * 2),
             (16 * 256 * 4) / 1024);
    return true;
}
