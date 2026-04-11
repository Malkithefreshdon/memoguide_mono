#pragma once
#include <stdint.h>
#include <stdbool.h>

// ============================================================
// ble_localization.h — Localisation BLE iBeacon → Gateway
//
// Cycle toutes les 2s :
//   1. Arrêt scan
//   2. Expire balises > 5s, construit payload Manufacturer Data
//   3. Arrêt advertising → mise à jour → redémarrage advertising
//   4. Redémarrage scan
//
// La gateway (Raspberry Pi) reçoit le payload et détermine la pièce.
// ============================================================

// Snapshot d'une balise active (pour affichage)
struct BeaconSnapshot {
    uint16_t major;
    uint16_t minor;
    int8_t   last_rssi;  // dBm
};

// Initialise le stack BLE, configure le scan iBeacon et l'advertising.
// À appeler une seule fois dans setup().
void localization_init();

// À appeler toutes les 2 secondes depuis une tâche FreeRTOS dédiée.
// Construit et diffuse le payload vers la gateway.
void localization_process();

// Retourne les balises actives (pour l'écran ou le debug).
// Retourne le nombre de balises copiées dans `out` (max max_count).
int      localization_get_active_beacons(BeaconSnapshot *out, int max_count);

// Nombre total de payloads diffusés depuis le boot.
uint32_t localization_get_tx_count();
