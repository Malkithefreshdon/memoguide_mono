# Protocoles de communication — MemoGuide

## Vue d'ensemble

```
[iBeacons] ──BLE advertising──► [watch-nrf / watch-esp32] ──BLE manufacturer data──► [gateway-rpi] ──HTTP POST──► [dashboard-nuxt] ──SSE──► [Navigateur]
  (fixes)         NRF52840 ou ESP32-S3              Raspberry Pi Zero 2W               Nuxt 3 / Node.js           Vue 3
```

> Les montres ne se relayent pas entre elles. Chaque montre scanne les iBeacons et diffuse ses données
> directement vers la gateway. Il n'y a pas de WebSocket — la gateway pousse en HTTP, le frontend écoute en SSE.

---

## 1. BLE — iBeacons → Montre (scan)

Les montres scannent en continu les iBeacons Apple standard. La montre cherche la signature
`4C 00 02 15` dans les données manufacturer et extrait :

| Offset | Champ    | Type    | Description                  |
|--------|----------|---------|------------------------------|
| +20    | `major`  | uint8×2 | Major (big-endian)           |
| +22    | `minor`  | uint8×2 | Minor (big-endian)           |

**Paramètres de scan** (NRF52840 et ESP32-S3) :
- Type : ACTIVE
- Intervalle : 100 ms, fenêtre : 50 ms
- Timeout beacon : 5 000 ms (supprimé de la table si plus reçu)
- Capacité table : 5 beacons simultanés max

---

## 2. BLE — Montre → Gateway (advertising)

La montre diffuse toutes les **2 secondes** un paquet BLE avec les données de localisation
dans le champ **Manufacturer Specific Data**.

**Nom BLE** : `Memo_Montre`

### Format de la trame manufacturer data

```
Octet 0 : Company ID LSB = 0xFF
Octet 1 : Company ID MSB = 0xFF
Octet 2 : Magic byte     = 0xAA
Octet 3 : Watch ID       = 0x01..0xFF (configuré par montre)
Octets 4+ : [5 octets × N beacons, max 5 beacons]
```

### Format par beacon (5 octets, répété jusqu'à 5 fois)

| Octets | Champ   | Type    | Description            |
|--------|---------|---------|------------------------|
| 0–1    | `major` | uint16  | Major (big-endian)     |
| 2–3    | `minor` | uint16  | Minor (big-endian)     |
| 4      | `rssi`  | int8    | Signal reçu (dBm, <0) |

**Taille** : 4 octets header + N × 5 octets (min 4, max 29 octets)

**Exemple avec 2 beacons** :
```
FF FF AA 01  01 00 00 01 B2  01 00 00 02 B5
└── header ─┘ └── beacon 1 ─┘ └── beacon 2 ─┘
             major=1,minor=1  major=1,minor=2
             rssi=-78 dBm     rssi=-75 dBm
```

### Constantes BLE

| Constante              | Valeur  | Description                       |
|------------------------|---------|-----------------------------------|
| `COMPANY_ID`           | `0xFFFF`| Non-officiel, usage interne       |
| `MAGIC_BYTE`           | `0xAA`  | Identifiant protocole MemoGuide   |
| `WATCH_ID`             | 1–255   | Identifiant unique par montre     |
| `MAX_BEACONS`          | 5       | Beacons max dans la table         |
| `BEACON_TIMEOUT_MS`    | 5 000   | Expiration si plus de signal      |
| `LOCALIZATION_PERIOD_MS` | 2 000 | Intervalle de diffusion           |

---

## 3. BLE — Caractéristique Audio (watch-nrf uniquement)

Le nRF52840 expose un service GATT pour recevoir de l'audio depuis un autre périphérique.

| Élément          | UUID                                   |
|------------------|----------------------------------------|
| Service          | `12345678-1234-5678-1234-56789abcdef0` |
| Caractéristique  | `12345678-1234-5678-1234-56789abcdef1` |

**Propriétés** : `WRITE | WRITE_WITHOUT_RESPONSE`

**Format audio** :
- Codec : PCM brut (pas de container)
- Fréquence : 16 000 Hz
- Profondeur : 16 bits signé, stéréo
- MTU : 247 octets → payload max 244 octets par write (~7,6 ms d'audio)
- Ring buffer : 16 Ko (~250 ms de buffer)
- Sortie : amplificateur MAX98357A via I2S

---

## 4. HTTP — Gateway → Dashboard

La gateway Python (Bleak + httpx) poste ses données toutes les **2 secondes**.

### POST /api/location

**Authentification** : header `x-api-key` obligatoire

**Corps de la requête** :
```json
{
  "gateway_id": "gateway_01",
  "watch_id": "watch_001",
  "timestamp": 1712345678000,
  "rssi_data": [
    { "beacon_id": "beacon_1_1", "major": 1, "minor": 1, "rssi": -55 },
    { "beacon_id": "beacon_1_2", "major": 1, "minor": 2, "rssi": -82 }
  ]
}
```

**Réponse (200)** :
```json
{
  "success": true,
  "estimated_room": "Chambre Malcom",
  "confidence": 0.87
}
```

**Erreurs** : 401 (clé invalide), 400 (champs manquants)

---

## 5. SSE — Dashboard → Frontend

Le frontend s'abonne à un flux **Server-Sent Events** (pas de WebSocket).

### GET /api/stream

```
Content-Type: text/event-stream
Keepalive: commentaire toutes les 25 s
```

### Événements émis

#### `connected`
```
event: connected
data: {"message":"SSE stream connected","ts":1712345678000}
```

#### `location:update`
Émis à chaque POST `/api/location` reçu de la gateway.
```
event: location:update
data: {
  "watch_id": "watch_001",
  "room": "Chambre Malcom",
  "timestamp": 1712345678000,
  "confidence": 0.87,
  "rssi_data": [
    {"beacon_id":"beacon_1_1","major":1,"minor":1,"rssi":-55}
  ]
}
```

**Calcul de la pièce** (côté dashboard) :
1. Filtrer les beacons sous `-95 dBm`
2. Beacon avec le RSSI le plus élevé → pièce associée (via `db.json`)
3. `confidence = min(1.0, max(0.2, gap_dB / 15))` (gap entre 1er et 2e beacon)

---

## 6. Autres endpoints REST (Dashboard)

| Méthode | Endpoint       | Auth        | Description                              |
|---------|----------------|-------------|------------------------------------------|
| `GET`   | `/api/devices` | Aucune      | Liste watches, beacons, gateways         |
| `POST`  | `/api/devices` | Aucune      | Met à jour nom ou room d'un device       |
| `GET`   | `/api/health`  | Aucune      | `{"status":"ok"}`                        |
| `GET`   | `/api/stream`  | Aucune      | Flux SSE (voir section 5)               |

Les devices sont **auto-découverts** depuis le trafic entrant (premier POST qui les mentionne).

**Stockage** : fichier `db.json` (watches, beacons, gateways avec id, name, room, lastSeen).

---

## 7. Variables d'environnement

| Variable          | Défaut                                    | Utilisé par   |
|-------------------|-------------------------------------------|---------------|
| `API_URL`         | `http://localhost:3000/api/location`      | gateway-rpi   |
| `API_KEY`         | `memo-guide-gateway-xp550e`               | gateway-rpi   |
| `GATEWAY_ID`      | `gateway_01`                              | gateway-rpi   |
| `SEND_EVERY`      | `2.0` (secondes)                          | gateway-rpi   |
| `GATEWAY_API_KEY` | `dev-secret-key`                          | dashboard-nuxt|

---

## À compléter

- [ ] Définir des UUIDs BLE custom définitifs pour le service audio
- [ ] Documenter le protocole audio complet (source, déclenchement)
- [ ] Ajouter la gestion multi-montres (plusieurs watch_id simultanés)
- [ ] Documenter la configuration des iBeacons (UUID, major/minor mapping)
