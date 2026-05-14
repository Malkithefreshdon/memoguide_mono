#pragma once

// Charge instructions.json depuis LittleFS et démarre le serveur HTTP sur le port 80.
// Doit être appelé après wifi_connect().
bool guidance_init();

// Tâche FreeRTOS : appelle server.handleClient() en boucle.
void guidance_task(void *pv);
