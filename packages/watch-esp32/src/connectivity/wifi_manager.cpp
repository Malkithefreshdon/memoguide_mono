#include "wifi_manager.h"
#include "config.h"
#include <Arduino.h>
#include <WiFi.h>
#include <time.h>

bool wifi_connect(const char *ssid, const char *password, uint32_t timeout_ms) {
    Serial.printf("[WIFI] Connexion à \"%s\"...\n", ssid);
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    const uint32_t start = millis();
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - start > timeout_ms) {
            Serial.println("[WIFI] Timeout");
            return false;
        }
        delay(250);
    }

    Serial.printf("[WIFI] Connecté — IP : %s\n", WiFi.localIP().toString().c_str());
    return true;
}

void wifi_disconnect() {
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
}

bool wifi_is_connected() {
    return WiFi.status() == WL_CONNECTED;
}

bool ntp_sync(const char *ntp_server) {
    if (!wifi_is_connected()) {
        Serial.println("[WIFI] NTP : pas de connexion WiFi");
        return false;
    }

    configTime(0, 0, ntp_server);  // UTC — ajuster timezone selon besoin
    Serial.printf("[WIFI] Sync NTP via %s...\n", ntp_server);

    // Attendre que l'heure soit synchronisée
    struct tm timeinfo;
    const uint32_t start = millis();
    while (!getLocalTime(&timeinfo, 1000)) {
        if (millis() - start > 10000) {
            Serial.println("[WIFI] NTP timeout");
            return false;
        }
    }

    char buf[32];
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
    Serial.printf("[WIFI] Heure synchronisée : %s UTC\n", buf);
    return true;
}
