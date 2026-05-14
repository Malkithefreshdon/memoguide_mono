#pragma once
#include <stdint.h>

// ============================================================
// accelerometer.h — BMA423 (3 axes + compteur de pas)
// I2C addr : 0x19
// Fonctionnalités utilisées :
//   - Accélération sur 3 axes (m/s²)
//   - Compteur de pas (podomètre matériel)
//   - Détection de geste (lever du poignet, double tap)
//   - Interruption sur INT1
// ============================================================

struct AccelData {
    float x, y, z;   // m/s² (ou g selon config)
    uint32_t steps;   // Compteur de pas (NVM interne)
    bool wrist_up;    // Geste "lever du poignet"
};

bool      accel_init();
void      accel_update();           // Appelé périodiquement (tâche FreeRTOS)
AccelData accel_get_data();
void      accel_reset_steps();

// Détection de chute : libre chute (<0.3g) suivie d'un impact (>2g)
bool      accel_fall_detected();    // true pendant 5s après détection
void      accel_clear_fall();       // acquitter manuellement
