#include "guidance.h"
#include "audio_stream.h"
#include "../display/display.h"

#include <Arduino.h>
#include <WebServer.h>
#include <LittleFS.h>
#include <ArduinoJson.h>

static const char *TAG = "GUIDE";
static WebServer   s_server(80);

struct Instruction {
    char id[32];
    char arrow[16];
    char line1[48];
    char line2[48];
    char audio[64];
};

static Instruction s_instructions[16];
static int         s_count = 0;

// ── Helpers ───────────────────────────────────────────────────────────────────

static const Instruction *find(const char *id) {
    for (int i = 0; i < s_count; i++)
        if (strcmp(s_instructions[i].id, id) == 0)
            return &s_instructions[i];
    return nullptr;
}

// Lit un fichier PCM mono 16-bit depuis LittleFS et le joue via I2S (stereo L=R).
static void play_pcm(const char *path) {
    File f = LittleFS.open(path, "r");
    if (!f) {
        ESP_LOGW(TAG, "Audio manquant : %s", path);
        return;
    }
    int16_t mono[128];
    int16_t stereo[256];
    while (f.available() >= (int)sizeof(mono)) {
        f.read((uint8_t *)mono, sizeof(mono));
        for (int i = 0; i < 128; i++)
            stereo[i * 2] = stereo[i * 2 + 1] = mono[i];
        audio_play_chunk(stereo, sizeof(stereo));
    }
    f.close();
    ESP_LOGI(TAG, "Audio joue : %s", path);
}

// ── Handlers HTTP ─────────────────────────────────────────────────────────────

static void on_guide() {
    if (!s_server.hasArg("id")) {
        s_server.send(400, "text/plain", "param 'id' manquant");
        return;
    }
    const Instruction *inst = find(s_server.arg("id").c_str());
    if (!inst) {
        s_server.send(404, "text/plain", "instruction inconnue");
        return;
    }
    display_show_guidance(inst->arrow, inst->line1, inst->line2);
    play_pcm(inst->audio);
    s_server.send(200, "application/json", "{\"ok\":true}");
    ESP_LOGI(TAG, "Instruction : %s", inst->id);
}

static void on_stop() {
    display_exit_guidance();
    s_server.send(200, "application/json", "{\"ok\":true}");
    ESP_LOGI(TAG, "Guidage stoppe");
}

// ── Init ──────────────────────────────────────────────────────────────────────

bool guidance_init() {
    if (!LittleFS.begin(true)) {
        ESP_LOGE(TAG, "LittleFS mount failed");
        return false;
    }

    File f = LittleFS.open("/instructions.json", "r");
    if (!f) {
        ESP_LOGW(TAG, "instructions.json absent — 0 instructions chargees");
    } else {
        JsonDocument doc;
        if (!deserializeJson(doc, f)) {
            for (JsonObject o : doc["instructions"].as<JsonArray>()) {
                if (s_count >= 16) break;
                auto &inst = s_instructions[s_count++];
                strlcpy(inst.id,    o["id"]    | "", sizeof(inst.id));
                strlcpy(inst.arrow, o["arrow"] | "", sizeof(inst.arrow));
                strlcpy(inst.line1, o["line1"] | "", sizeof(inst.line1));
                strlcpy(inst.line2, o["line2"] | "", sizeof(inst.line2));
                strlcpy(inst.audio, o["audio"] | "", sizeof(inst.audio));
            }
        }
        f.close();
    }

    s_server.on("/guide", HTTP_GET, on_guide);
    s_server.on("/stop",  HTTP_GET, on_stop);
    s_server.begin();
    ESP_LOGI(TAG, "%d instruction(s) chargee(s) | HTTP port 80", s_count);
    return true;
}

void guidance_task(void *pv) {
    for (;;) {
        s_server.handleClient();
        vTaskDelay(pdMS_TO_TICKS(5));
    }
}
