#pragma once
#include <stdint.h>
#include <stddef.h>

// ============================================================
// audio_stream.h — Réception audio UDP + lecture I2S
//
// Interface identique à audio_trx.h (nRF) pour faciliter
// la portabilité : seul le transport diffère (WiFi vs BLE).
// ============================================================

// Initialise le driver I2S et démarre la tâche d'écoute UDP.
// Appeler après wifi_connect().
// Retourne false si le driver I2S est indisponible.
bool audio_stream_init();

// Envoie un chunk PCM vers le DMA I2S.
// Thread-safe, bloquant jusqu'à 200ms si le DMA est plein.
// buf  : PCM 16kHz, 16-bit, stéréo, little-endian
// len  : taille en octets
// Retourne 0 (OK) ou -1 (erreur I2S).
int audio_play_chunk(const void *buf, size_t len);
