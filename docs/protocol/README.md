# Protocoles de communication — MemoGuide

## Vue d'ensemble

```
[watch-esp32] ──BLE──► [watch-nrf] ──BLE──► [gateway-rpi] ──HTTP/WS──► [dashboard-nuxt]
     T-Watch S3           nRF5340               Raspberry Pi                 Nuxt 3
```

---

## BLE — Watch → Gateway

### Service UUID
```
Service   : 0x1800  (ou UUID custom à définir)
Caractéristique localisation : 0x2A67
Caractéristique alertes      : 0xFF01 (custom)
```

### Trame de localisation
| Octet | Champ       | Type    | Description              |
|-------|-------------|---------|--------------------------|
| 0–1   | `seq`       | uint16  | Numéro de séquence       |
| 2–5   | `lat`       | float32 | Latitude (degrés)        |
| 6–9   | `lon`       | float32 | Longitude (degrés)       |
| 10    | `battery`   | uint8   | Niveau batterie (0–100%) |
| 11    | `flags`     | uint8   | Bit 0 = SOS, Bit 1 = fall|

---

## HTTP/WebSocket — Gateway → Dashboard

### Endpoint REST (gateway)
```
GET  /api/location        → dernière position connue
GET  /api/history?n=50    → N dernières positions
POST /api/alert           → déclencher une alerte manuelle
```

### WebSocket
```
ws://gateway:8080/ws
```
Événements JSON push :
```json
{ "type": "location", "lat": 48.85, "lon": 2.35, "battery": 72 }
{ "type": "alert",    "kind": "sos", "timestamp": "2026-04-11T10:00:00Z" }
{ "type": "fall",     "confidence": 0.91 }
```

---

## À compléter

- [ ] Définir les UUIDs BLE custom définitifs
- [ ] Documenter le protocole audio (détection chute)
- [ ] Ajouter schéma Protobuf si migration nécessaire
