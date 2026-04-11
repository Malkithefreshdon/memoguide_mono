#pragma once
#include <stdint.h>
#include <stdbool.h>

// ============================================================
// wifi_manager.h — Connexion WiFi + NTP
// ============================================================

bool  wifi_connect(const char *ssid, const char *password, uint32_t timeout_ms = 10000);
void  wifi_disconnect();
bool  wifi_is_connected();

// Sync RTC via NTP (appelle wifi_connect si nécessaire)
bool  ntp_sync(const char *ntp_server = "pool.ntp.org");
