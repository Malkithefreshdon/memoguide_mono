# Système de Localisation BLE — Référence Technique
> Plateforme source : nRF52840 + Zephyr RTOS  
> Cible de portage : ESP32-S3 (Arduino / ESP-IDF)

---

## 1. Vue d'ensemble

La montre ne connaît pas sa position GPS. Elle se localise **indirectement** :

1. Elle **scanne** en continu les balises iBeacon fixes dans la pièce.
2. Elle **agrège** jusqu'à 5 balises (major, minor, RSSI) dans une table interne.
3. Toutes les **2 secondes**, elle **broadcaste** ces données via BLE vers une gateway (Raspberry Pi) qui calcule la pièce probable.

La gateway est le seul point qui connaît la topologie des pièces (quel beacon est dans quelle pièce). La montre ne fait que relayer les mesures.

---

## 2. Format iBeacon scanné

La montre cherche les publicités BLE contenant le pattern Apple iBeacon.

### Signature binaire dans le payload brut (manufacturer data)

```
Offset  Valeur   Description
+0      0x4C     Apple Company ID (LSB)
+1      0x00     Apple Company ID (MSB)
+2      0x02     iBeacon type
+3      0x15     iBeacon length (21 bytes restants)
+4..19  UUID     UUID 128 bits (16 octets, non utilisé par la montre)
+20     Major MSB
+21     Major LSB  → major = (data[20] << 8) | data[21]
+22     Minor MSB
+23     Minor LSB  → minor = (data[22] << 8) | data[23]
+24     TX Power   (non utilisé par la montre)
```

### Algorithme de parsing (robuste, sans dépendance à la structure AD)

```c
// Cherche le pattern 4C 00 02 15 dans tout le buffer brut
for (int i = 0; i + 25 <= len; i++) {
    if (data[i] == 0x4C && data[i+1] == 0x00 &&
        data[i+2] == 0x02 && data[i+3] == 0x15) {
        major = (data[i+20] << 8) | data[i+21];
        minor = (data[i+22] << 8) | data[i+23];
        return true;
    }
}
```

> **Pourquoi cette méthode ?** Elle parcourt le buffer brut sans supposer la structure des AD records. Plus robuste face aux variations d'encodage des beacons.

### Paramètres de scan BLE

| Paramètre   | Valeur                         | Note                              |
|-------------|--------------------------------|-----------------------------------|
| Type        | ACTIVE                         | Demande les scan responses        |
| Filtre      | AUCUN (pas de dédup)           | Reçoit tous les paquets, même répétés |
| Interval    | BT_GAP_SCAN_FAST_INTERVAL      | ~100 ms (nRF) / ~100 ms (ESP32)  |
| Window      | BT_GAP_SCAN_FAST_WINDOW        | ~50 ms (nRF) / à ajuster ESP32)  |

---

## 3. Table interne des balises

```c
#define MAX_BEACONS      5
#define BEACON_TIMEOUT_MS 5000   // balise expirée après 5 s sans signal

typedef struct {
    uint16_t major;
    uint16_t minor;
    int8_t   last_rssi;      // dBm, signé
    int64_t  last_seen_ms;   // timestamp uptime ms
    bool     is_active;
} beacon_info_t;

static beacon_info_t discovered_beacons[MAX_BEACONS];
```

### Logique de mise à jour (dans le callback de scan)

```
Si beacon (major, minor) déjà dans la table :
    → mettre à jour last_rssi et last_seen_ms
    → return

Sinon :
    Si slot vide disponible → utiliser ce slot
    Sinon → remplacer la balise la plus ancienne (oldest last_seen_ms)
    → écrire major, minor, rssi, timestamp, is_active = true
```

---

## 4. Format du payload BLE diffusé (vers la gateway)

La montre rebroadcaste ses mesures sous forme de **Manufacturer Specific Data**.

### Structure du payload (max 29 octets, limite BLE = 31)

```
Octet 0 : Company ID LSB = 0xFF
Octet 1 : Company ID MSB = 0xFF
Octet 2 : Magic byte     = 0xAA  (identifie le protocole MemoGuide)
Octet 3 : Watch ID       = 0x01  (ID unique par montre, à changer)

Puis pour chaque balise active (5 max × 5 octets = 25 octets) :
  Octet N+0 : Major MSB
  Octet N+1 : Major LSB
  Octet N+2 : Minor MSB
  Octet N+3 : Minor LSB
  Octet N+4 : RSSI (uint8_t, cast depuis int8_t)
```

**Taille totale max** : 4 + (5 × 5) = **29 octets**  
**Taille min** (aucune balise) : 4 octets (header seul)

### Exemple de payload avec 2 balises

```
FF FF AA 01  01 00 00 01 B2  01 00 00 02 B5
│  │  │  │  │     │     │   │     │     │
│  │  │  │  Major  Minor RSSI Major  Minor RSSI
│  │  │  Watch ID=1        beacon 2
│  │  Magic
Company 0xFFFF
```

`B2` = 0xB2 = 178 → cast en int8_t = **-78 dBm**  
`B5` = 0xB5 = 181 → cast en int8_t = **-75 dBm**

---

## 5. Structure du paquet BLE Advertisement diffusé

```
AD Record 1 : Flags         = BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR
AD Record 2 : Complete Name = "Memo_Montre"
AD Record 3 : Manufacturer  = [payload décrit ci-dessus, longueur dynamique]

Scan Response :
  Complete Name = "Memo_Montre"
```

L'advertising est **Connectable & Scannable** (`BT_LE_ADV_CONN_FAST_2`).  
La longueur du champ Manufacturer Data est **recalculée à chaque cycle** en fonction du nombre de balises actives.

---

## 6. Cycle d'exécution (main loop)

```
Toutes les 2 secondes :
  1. [background] Callback scan_cb accumule les beacons dans la table
  2. localization_process() est appelé :
     a. STOP scan  (libère la radio — contrainte single-radio nRF52840)
     b. Parcours la table : expire les balises > 5 s, construit le payload
     c. STOP advertising (si déjà actif)
     d. START advertising avec le nouveau payload
     e. Log série des balises actives
     f. RESTART scan iBeacon
```

> **Contrainte critique (nRF52840)** : le scan et l'advertising **ne peuvent pas coexister simultanément** sur la même radio. Il faut arrêter le scan avant de lancer l'advertising, puis relancer le scan.  
> Sur ESP32-S3, les modes coexistent mieux mais il faut vérifier les limitations du SDK.

---

## 7. Configuration BLE (prj.conf → à transposer en menuconfig/sdkconfig)

```
CONFIG_BT=y
CONFIG_BT_OBSERVER=y       # capacité de scan
CONFIG_BT_BROADCASTER=y    # capacité d'advertising
CONFIG_BT_PERIPHERAL=y     # connexions GATT entrantes
CONFIG_BT_CENTRAL=n        # pas de connexion sortante
CONFIG_BT_EXT_ADV=n        # advertising classique (legacy), pas Extended

CONFIG_BT_DEVICE_NAME="Memo_Montre"
CONFIG_BT_L2CAP_TX_MTU=247
CONFIG_BT_BUF_ACL_RX_SIZE=251
```

---

## 8. Identifiants à configurer par montre

| Constante     | Valeur actuelle | Rôle                                          |
|---------------|-----------------|-----------------------------------------------|
| `WATCH_ID`    | `1`             | Identifiant unique de la montre dans le réseau|
| `COMPANY_ID`  | `0xFFFF`        | Company ID BLE (non officiel, usage interne)  |
| `MAGIC_BYTE`  | `0xAA`          | Marque le protocole MemoGuide                 |

---

## 9. Portage ESP32-S3 — points d'attention

### Équivalences Zephyr → ESP-IDF / Arduino

| Concept Zephyr                    | ESP32-S3 (ESP-IDF)                        |
|-----------------------------------|-------------------------------------------|
| `bt_le_scan_start()`              | `esp_ble_gap_start_scanning()`            |
| `bt_le_scan_stop()`               | `esp_ble_gap_stop_scanning()`             |
| `bt_le_adv_start()`               | `esp_ble_gap_start_advertising()`         |
| `bt_le_adv_stop()`                | `esp_ble_gap_stop_advertising()`          |
| Callback `scan_cb(addr, rssi, adv_type, buf)` | `ESP_GAP_BLE_SCAN_RESULT_EVT` → `scan_rst.scan_rst` |
| `k_uptime_get()` (ms)             | `esp_timer_get_time() / 1000` (ms)        |
| `buf->data`, `buf->len`           | `scan_result->scan_rst.ble_adv`, `scan_result->scan_rst.adv_data_len` |

### Accès au payload brut dans le callback ESP-IDF

```c
case ESP_GAP_BLE_SCAN_RESULT_EVT: {
    esp_ble_gap_cb_param_t *p = (esp_ble_gap_cb_param_t *)param;
    if (p->scan_rst.search_evt == ESP_GAP_SEARCH_INQ_RES_EVT) {
        uint8_t *adv_data = p->scan_rst.ble_adv;
        uint8_t  adv_len  = p->scan_rst.adv_data_len;
        int8_t   rssi     = p->scan_rst.rssi;
        // → appeler parse_ibeacon(adv_data, adv_len, &major, &minor)
    }
}
```

### Payload Manufacturer Data en advertising (ESP-IDF)

```c
// Construire le raw advertising data manuellement
uint8_t adv_raw[31];
int idx = 0;

// AD Record : Flags
adv_raw[idx++] = 2;       // length
adv_raw[idx++] = 0x01;    // type = Flags
adv_raw[idx++] = 0x06;    // General Discoverable + No BR/EDR

// AD Record : Manufacturer Specific
uint8_t mfg[29] = { 0xFF, 0xFF, 0xAA, WATCH_ID, ... };
uint8_t mfg_len = 4 + (nb_beacons * 5);
adv_raw[idx++] = mfg_len + 1;  // length du AD record
adv_raw[idx++] = 0xFF;         // type = Manufacturer Specific
memcpy(&adv_raw[idx], mfg, mfg_len);
idx += mfg_len;

esp_ble_gap_config_adv_data_raw(adv_raw, idx);
```

### Coexistence scan + advertising sur ESP32-S3

L'ESP32-S3 supporte théoriquement le scan et l'advertising simultanés. Toutefois :
- Avec une seule antenne 2.4 GHz, des **interférences temporelles** peuvent dégrader la détection.
- Recommandation : conserver le **même cycle stop/start** que sur nRF pour garantir la fiabilité (arrêt scan → advertising → redémarrage scan).
- Si performance insuffisante : utiliser le **Bluetooth 5 avec Extended Advertising** (supporté par ESP32-S3) pour séparer les fenêtres temporelles.

---

## 10. Résumé des constantes clés

```c
// Identification protocole
#define COMPANY_ID_LO     0xFF
#define COMPANY_ID_HI     0xFF
#define MAGIC_BYTE        0xAA
#define WATCH_ID          1       // Changer pour chaque montre

// Table de beacons
#define MAX_BEACONS       5
#define BEACON_TIMEOUT_MS 5000    // ms avant d'expirer une balise

// iBeacon signature
// data[i] == 0x4C && data[i+1] == 0x00 && data[i+2] == 0x02 && data[i+3] == 0x15

// Cycle principal
#define LOCALIZATION_PERIOD_MS  2000   // k_sleep(K_SECONDS(2))
```

---

## 11. Diagramme de séquence simplifié

```
[Beacons iBeacon]  →  (BLE 2.4GHz)  →  [Montre : scan_cb()]
                                              │
                                         Table[5] beacons
                                         (major, minor, RSSI)
                                              │
                                    toutes les 2s : localization_process()
                                              │
                                         STOP scan
                                         BUILD payload
                                         START adv (Manufacturer Data)
                                         RESTART scan
                                              │
                                         (BLE 2.4GHz)
                                              │
                                     [Gateway Raspberry Pi]
                                              │
                                        Décode payload
                                        → identifie la pièce
                                        → met à jour l'interface
```
