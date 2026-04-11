#pragma once
#include <stdint.h>

// ============================================================
// power.h — Gestion d'énergie AXP2101 (PMU)
// I2C addr : 0x34
//
// Rôle dans la T-Watch S3 :
//   - Alimentation de l'écran, du MCU, des capteurs
//   - Chargement de la batterie LiPo
//   - Mesure tension/courant batterie
//   - Déclenchement du deep sleep / wake-up
// ============================================================

struct PowerStatus {
    float    battery_voltage;   // Volts
    int8_t   battery_percent;   // 0–100 %
    bool     is_charging;
    bool     is_plugged;
};

bool        power_init();
PowerStatus power_get_status();
void        power_activity();             // Réinitialise le timer d'inactivité (appeler sur chaque input touch)
void        power_check_sleep();          // Déclenche deep sleep si inactif
void        power_set_dcdc_voltage(uint8_t rail, uint16_t mv); // Configurer un rail
void        power_shutdown();             // Éteindre la montre
