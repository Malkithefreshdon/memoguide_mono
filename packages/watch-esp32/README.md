# MemoGuide — Bracelet T-Watch S3

Firmware embarqué pour la **LILYGO T-Watch S3** (ESP32-S3).  
Développé avec **PlatformIO** + framework **Arduino** sous **VS Code**.

---

## Table des matières

1. [Matériel — Specs de la T-Watch S3](#1-matériel--specs-de-la-t-watch-s3)
2. [Pinout & adresses I2C](#2-pinout--adresses-i2c)
3. [Architecture du projet](#3-architecture-du-projet)
4. [Fonctionnalités implémentées](#4-fonctionnalités-implémentées)
5. [Setup de l'environnement](#5-setup-de-lenvironnement)
6. [Extensions VS Code recommandées](#6-extensions-vs-code-recommandées)
7. [Build, flash & monitor](#7-build-flash--monitor)
8. [Capteurs — détails techniques](#8-capteurs--détails-techniques)
9. [Gestion d'énergie (AXP2101)](#9-gestion-dénergie-axp2101)
10. [FreeRTOS — architecture des tâches](#10-freertos--architecture-des-tâches)
11. [Différences T-Watch S3 vs S3 Plus](#11-différences-t-watch-s3-vs-s3-plus)
12. [Ressources & liens](#12-ressources--liens)

---

## 1. Matériel — Specs de la T-Watch S3

| Composant | Détail |
|-----------|--------|
| **MCU** | ESP32-S3 — Dual-core Tensilica LX7 @ 240 MHz |
| **Flash** | 16 MB (QIO) |
| **PSRAM** | 8 MB (OPI) |
| **RAM** | 512 KB |
| **WiFi** | 802.11 b/g/n (2.4 GHz) |
| **Bluetooth** | BLE 5.0 |
| **Écran** | 1.54" IPS LCD, 240×240 px, driver ST7789V |
| **Tactile** | Capacitif FT6336U (I2C) |
| **IMU** | BMA423 — 3 axes accel + podomètre matériel |
| **PMU** | AXP2101 — gestion d'énergie + chargeur LiPo |
| **Haptique** | DRV2605 — moteur vibration |
| **Batterie** | 400–470 mAh LiPo (modèle standard) |
| **Charge** | USB-C |
| **USB/JTAG** | CDC + JTAG intégré ESP32-S3 |

> **T-Watch S3 Plus** ajoute : batterie 940 mAh, GPS (UBlox MIA-M10Q), capteur cardiaque MAX30102 — voir [section 10](#10-différences-t-watch-s3-vs-s3-plus).

---

## 2. Pinout & adresses I2C

> Vérifier contre le schéma officiel LILYGO avant de modifier :  
> https://github.com/Xinyuan-LilyGO/LilyGoLib

### Bus I2C principal (GPIO 10 SDA / GPIO 11 SCL — 400 kHz)

| Périphérique | Adresse | Interruption |
|---|---|---|
| AXP2101 (PMU) | `0x34` | GPIO 21 |
| BMA423 (IMU) | `0x19` | GPIO 14 (INT1) |
| PCF8563 (RTC) | `0x51` | — |
| DRV2605 (haptique) | `0x5A` | — |

### Bus I2C touch (GPIO 23 SDA / GPIO 32 SCL)

| Périphérique | Adresse | Interruption |
|---|---|---|
| FT6336U (touch) | `0x38` | GPIO 38 |

### Écran SPI (ST7789V)

| Signal | GPIO |
|--------|------|
| MOSI | 13 |
| SCLK | 18 |
| CS | 12 |
| DC | 38 |
| RST | via AXP2101 |
| Backlight | 45 (PWM) |

### LoRa SPI (SX1262)

| Signal | GPIO |
|--------|------|
| MOSI | 1 |
| MISO | 4 |
| SCK | 3 |
| CS | 5 |
| RST | 8 |
| BUSY | 7 |
| DIO1 | 9 |

### Audio I2S & Microphone PDM

| Signal | GPIO |
|--------|------|
| I2S BCK | 48 |
| I2S WS | 15 |
| I2S DOUT | 46 |
| MIC DATA | 47 |
| MIC SCLK | 44 |

### Divers

| Périphérique | GPIO |
|---|---|
| Émetteur IR | 2 |
| Bouton latéral | 0 (boot) |

### Alimentation

| Rail AXP2101 | Tension | Alimente |
|---|---|---|
| DCDC1 | 3.3 V | MCU ESP32-S3 |
| ALDO2 | 3.3 V | Touch, IMU, RTC |
| ALDO3 | 3.3 V | LCD |
| BLDO1 | 2.8 V | Rétroéclairage |

---

## 3. Architecture du projet

```
watch-esp32/
├── src/
│   ├── main.cpp                  # Entrée, init, tâches FreeRTOS
│   ├── display/
│   │   ├── display.h             # API écran publique
│   │   └── display.cpp           # LovyanGFX (ST7789V) — home, dev, guidage
│   ├── sensors/
│   │   ├── accelerometer.h/cpp   # BMA423 (accel, podomètre, détection de chute)
│   │   └── power.h/cpp           # AXP2101 (PMU)
│   └── connectivity/
│       ├── wifi_manager.h/cpp    # WiFi
│       ├── audio_stream.h/cpp    # Stream audio UDP
│       ├── ble_localization.h/cpp# iBeacon BLE
│       └── guidance.h/cpp        # Guidage HTTP/SSE
├── data/
│   └── images/
│       ├── logo.png              # Logo MemoGuide complet (splash)
│       └── logo_icon.png         # Icône MemoGuide (cadran home)
├── include/
│   └── config.h                  # Pins, adresses I2C, constantes
├── platformio.ini                # Config build PlatformIO
└── README.md
```

### Flux d'exécution

```
setup()
  ├── Wire.begin(10, 11)     → I2C principal (AXP2101, BMA423, RTC)
  ├── Wire1.begin(23, 32)    → I2C touch (FT6336U)
  ├── power_init()           → AXP2101 : alimente les rails
  ├── LittleFS.begin()       → Partition images (logo, logo_icon)
  ├── display_init()         → ST7789V via LovyanGFX
  ├── display_show_splash()  → logo.png 5 s sur fond blanc
  ├── accel_init()           → BMA423
  ├── wifi_connect() + NTP   → Heure temps réel (pool.ntp.org)
  ├── audio_stream_init()
  ├── localization_init()
  └── FreeRTOS tasks
        ├── task_sensor  (core 0, 100 ms) → IMU + détection de chute
        ├── task_display (core 1,  33 ms) → rendu écran 30 fps
        ├── task_localization (core 0)    → BLE iBeacon
        ├── guidance_task    (core 0)     → guidage HTTP/SSE
        └── task_touch       (core 1,  50 ms) → FT6336U → toggle UI
```

---

## 4. Fonctionnalités implémentées

### Splash screen

Au démarrage, la montre affiche le logo MemoGuide (`data/images/logo.png`) sur fond blanc pendant **5 secondes** avant de laisser place à l'interface principale.

> Les images sont chargées depuis la partition **LittleFS**. Si LittleFS n'est pas monté (filesystem jamais uploadé), un écran texte de fallback s'affiche.

---

### Interface Home (cadran par défaut)

L'interface par défaut est un **cadran minimaliste** sur fond blanc :

| Zone | Contenu |
|------|---------|
| Haut droite | Niveau de batterie (%, rouge si < 20%) |
| Centre | Heure **HH:MM** en grande police rose-crimson (NTP) |
| Bas centre | Logo icône MemoGuide (`data/images/logo_icon.png`) |

**Heure** : synchronisée via NTP (serveur `pool.ntp.org`, fuseau `Europe/Paris` — UTC+1 hiver, UTC+2 été). Affiche `--:--` jusqu'à la première synchronisation WiFi.

---

### Interface Dev (dashboard debug)

Mode diagnostic pour le développement, fond noir :

| Zone | Contenu |
|------|---------|
| Header | `MemoGuide [DEV]` + batterie |
| Accéléromètre | X, Y, Z en m/s², tension batterie |
| Balises BLE | Liste des beacons avec RSSI coloré |
| Gateway | Compteur TX + uptime |

---

### Bascule Home ↔ Dev (tactile)

Un **toucher de l'écran** bascule entre l'interface Home et l'interface Dev.

- Implémenté dans `task_touch` (core 1, polling 50 ms)
- Lecture du registre `TD_STATUS` (0x02) du FT6336U via I2C
- Déclenchement sur le **front montant** (0 → ≥1 point de contact)

---

### Détection de chute

Algorithme embarqué à deux phases dans `accel_update()` (10 Hz) :

| Phase | Condition | Seuil |
|-------|-----------|-------|
| **Libre chute** | Magnitude < seuil | < 3 m/s² (≈ 0.3g) |
| **Impact** | Magnitude > seuil dans les 600 ms | > 19.6 m/s² (≈ 2g) |

En cas de chute confirmée :
- Log série : `[FALL] Chute détectée — magnitude impact: XX.XX m/s²`
- **Overlay rouge clignotant** affiché 5 secondes par-dessus n'importe quel mode (home ou dev) :

```
┌────────────────────────────────┐
│      CHUTE DETECTEE            │  ← rouge clignotant à 1 Hz
│    Appel d'urgence...          │
└────────────────────────────────┘
```

API publique :
```cpp
bool accel_fall_detected();  // true pendant 5 s après la chute
void accel_clear_fall();     // acquitter manuellement
```

---

### Assets LittleFS (`data/images/`)

| Fichier | Usage | Taille |
|---------|-------|--------|
| `logo.png` | Splash screen au démarrage | ~11 KB |
| `logo_icon.png` | Cadran home (sous l'heure) | ~17 KB |

Les PNG sont chargés via `heap_caps_malloc` (PSRAM 8MB en priorité) puis décodés avec `drawPng()` de LovyanGFX.

> **Note** : LovyanGFX ne supporte pas `fs::LittleFSFS` dans `DataWrapperT`. La solution retenue lit le fichier en RAM puis appelle `drawPng(buffer, size)` au lieu de `drawPngFile()`.

---

## 5. Setup de l'environnement

### Prérequis système

- **macOS / Linux / Windows**
- **Python 3.8+** (requis par PlatformIO)
- **VS Code** (https://code.visualstudio.com)
- **Driver USB-C** : sur Windows, installer le pilote CP210x ou CH340 selon la révision de ta carte. Sur macOS/Linux, aucun driver supplémentaire n'est nécessaire.

### Étape 1 — Installer PlatformIO dans VS Code

1. Ouvrir VS Code
2. Aller dans `Extensions` (⌘⇧X / Ctrl+Shift+X)
3. Rechercher `PlatformIO IDE` → Installer
4. Redémarrer VS Code
5. PlatformIO télécharge automatiquement les toolchains ESP32 au premier build (~500 MB)

### Étape 2 — Cloner le projet

```bash
git clone <url-du-repo> MemoGuide/Memo_Bracelet
cd MemoGuide/Memo_Bracelet
code .
```

### Étape 3 — Installer LilyGoLib (recommandé)

LilyGoLib est la bibliothèque officielle LILYGO qui encapsule tous les drivers.  
Elle n'est pas sur le registre PlatformIO, donc on l'installe manuellement :

```bash
# Depuis la racine du projet
git clone https://github.com/Xinyuan-LilyGO/LilyGoLib.git lib/LilyGoLib
```

Puis dans `platformio.ini`, ajouter :
```ini
lib_extra_dirs = lib
```

> Alternativement, les librairies individuelles déclarées dans `lib_deps` de `platformio.ini` suffisent pour démarrer sans LilyGoLib.

### Étape 4 — Configurer TFT_eSPI

TFT_eSPI nécessite un fichier de configuration pour connaître les pins de ton écran.  
Créer `src/display/User_Setup.h` :

```cpp
#define USER_SETUP_LOADED
#define ST7789_DRIVER

#define TFT_WIDTH   240
#define TFT_HEIGHT  240

#define TFT_MOSI    13
#define TFT_SCLK    15
#define TFT_CS      12
#define TFT_DC      38
#define TFT_RST     -1
#define TFT_BL      45

#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4
#define LOAD_GFXFF

#define SPI_FREQUENCY       40000000
#define SPI_READ_FREQUENCY  20000000
```

Puis dans `platformio.ini` :
```ini
build_flags =
    -DUSER_SETUP_LOADED
    -DUSER_SETUP_INFO="src/display/User_Setup.h"
```

### Étape 5 — Mode flash ESP32-S3

La T-Watch S3 utilise le **USB natif ESP32-S3** (pas de convertisseur UART externe).

**Première fois** (ou si la montre est bloquée) :
1. Maintenir le bouton latéral appuyé
2. Brancher le USB-C tout en maintenant le bouton
3. Relâcher le bouton → la montre est en mode DFU (download mode)
4. Flasher avec PlatformIO

**Pour les flash suivants** : la montre redémarre automatiquement en mode flash grâce à `ARDUINO_USB_CDC_ON_BOOT=1`.

> Sur macOS, le port série apparaît sous `/dev/cu.usbmodem*`.  
> Sur Linux : `/dev/ttyACM0` ou `/dev/ttyUSB0` (ajouter l'utilisateur au groupe `dialout` si permission refusée : `sudo usermod -aG dialout $USER`).

---

## 6. Extensions VS Code recommandées

Le fichier `.vscode/extensions.json` contient la liste complète. VS Code proposera de les installer automatiquement à l'ouverture du projet.

### Indispensables

| Extension | Pourquoi |
|-----------|----------|
| **PlatformIO IDE** (`platformio.platformio-ide`) | Build, flash, monitor série, débogage |
| **C/C++** (`ms-vscode.cpptools`) | IntelliSense, auto-complétion, navigation |

### Très utiles

| Extension | Pourquoi |
|-----------|----------|
| **Error Lens** (`usernamehw.errorlens`) | Erreurs de compilation inline |
| **GitLens** (`eamodio.gitlens`) | Historique git enrichi |
| **Better Comments** (`aaron-bond.better-comments`) | `TODO`, `FIXME`, `HACK` colorisés |
| **Cortex-Debug** (`marus25.cortex-debug`) | JTAG/SWD si tu connectes une sonde J-Link ou OpenOCD |

### Interface PlatformIO dans VS Code

- **Barre latérale gauche** → icône PlatformIO (alien) : accès aux tâches build/upload/monitor
- **Barre en bas** : boutons rapides ✓ Build / → Upload / 🔌 Monitor
- **Raccourcis** :
  - `Ctrl+Alt+B` → Build
  - `Ctrl+Alt+U` → Upload
  - `Ctrl+Alt+S` → Monitor série

---

## 7. Build, flash & monitor

### Via VS Code PlatformIO (recommandé)

Ouvrir la barre latérale PlatformIO (icône fourmi) :

```
PROJECT TASKS
└── twatch_s3
    ├── General
    │   ├── Build                → Compiler
    │   ├── Upload               → Compiler + flasher le firmware
    │   └── Monitor              → Ouvrir le monitor série
    └── Platform
        └── Upload Filesystem Image  → Flasher la partition LittleFS (images)
```

> **Important** : `Upload Filesystem Image` doit être exécuté **au moins une fois** (ou après modification des fichiers dans `data/`) pour que les images s'affichent. Le firmware et le filesystem sont deux partitions Flash distinctes.

### Via CLI PlatformIO

```bash
pio run                          # Build uniquement
pio run -t upload                # Build + flash firmware
pio run -t uploadfs              # Flash la partition LittleFS (images)
pio run -t upload -t monitor     # Flash puis monitor
pio run -e twatch_s3_debug -t upload  # Env debug
pio run -t clean                 # Nettoyer
```

### Ordre de flash recommandé (première installation)

```
1. Upload Filesystem Image  → grave les PNG dans LittleFS
2. Upload                   → grave le firmware
3. Monitor                  → vérifier les logs [FS] au démarrage
```

Les logs de démarrage confirment le bon montage :
```
[FS] LittleFS OK
[FS]  /images/logo.png (11264 o)
[FS]  /images/logo_icon.png (17408 o)
[DISPLAY] LovyanGFX OK — ST7789V 240×240
[NTP] Synchronisation heure en cours...
```

### Décodage des exceptions

Le filtre `esp32_exception_decoder` dans `platformio.ini` traduit automatiquement les adresses des crash dumps en noms de fonctions. En cas de panic, la backtrace apparaît directement dans le monitor.

---

## 8. Capteurs — détails techniques

### BMA423 — Accéléromètre 3 axes + podomètre

- **Interface** : I2C, adresse `0x19`
- **Plages** : ±2g, ±4g, ±8g, ±16g
- **Fréquence** : jusqu'à 1600 Hz
- **Fonctions matérielles** : podomètre, détection de chute, détection de geste (lever de poignet, double-tap), tilt
- **Fichier de config** : le BMA423 nécessite le chargement d'un tableau de 6 kB de configuration pour activer le podomètre — fourni dans la lib officielle (`bma423_config_file[]`)
- **Datasheet** : https://www.bosch-sensortec.com/products/motion-sensors/accelerometers/bma423/
- **Registres clés** :

| Registre | Adresse | Description |
|----------|---------|-------------|
| CHIP_ID | 0x00 | Doit retourner 0x13 |
| ACC_X_LSB | 0x12 | Données accel (6 octets : X, Y, Z) |
| STEP_CNT_0 | 0x1E | Compteur de pas (4 octets) |
| ACC_CONF | 0x40 | ODR (fréquence), bande passante |
| ACC_RANGE | 0x41 | Plage ±g |
| INT1_MAP | 0x56 | Mapping interruptions → INT1 |

### FT6336U — Contrôleur tactile capacitif

- **Interface** : I2C, adresse `0x38`
- **Type** : single/dual touch
- **Résolution** : 240×240 px
- **Interruption** : GPIO 38 (active low — non utilisé, on poll I2C directement)
- **Registres principaux** :

| Registre | Adresse | Description |
|----------|---------|-------------|
| DEV_MODE | 0x00 | Mode : 0=normal, 4=test |
| TD_STATUS | 0x02 | Nombre de points détectés |
| TOUCH1_XH | 0x03 | Coordonnée X [11:8] + event flag |
| TOUCH1_XL | 0x04 | Coordonnée X [7:0] |
| TOUCH1_YH | 0x05 | Coordonnée Y [11:8] |
| TOUCH1_YL | 0x06 | Coordonnée Y [7:0] |
| G_MODE | 0xA4 | Mode interruption : 0=polling, 1=trigger |

### DRV2605 — Pilote haptique

- **Interface** : I2C, adresse `0x5A`
- **Modes** : ERM (moteur excentrique), LRA (actuateur résonant linéaire)
- **Bibliothèque** : `Adafruit_DRV2605` disponible sur PlatformIO
- **Waveforms** : 123 formes d'ondes intégrées (Immersion library)

### MAX30102 — Cardio + SpO2 (T-Watch S3 Plus uniquement)

- **Interface** : I2C, adresse `0x57`
- **LEDs intégrées** : rouge (660 nm) + infrarouge (880 nm)
- **ADC** : 18 bits
- **Algorithme SpO2** : doit être implémenté côté MCU (Maxim fournit des algorithmes de référence)
- **Datasheet** : https://www.analog.com/en/products/max30102.html

---

## 9. Gestion d'énergie (AXP2101)

L'AXP2101 est le PMU (Power Management Unit) central de la montre. **Aucun autre composant ne doit être initialisé avant lui** — c'est lui qui alimente les rails de tension.

### Rails de tension configurés

```
AXP2101
├── DCDC1  → 3.3V  → ESP32-S3 (VDD_3V3)
├── ALDO2  → 3.3V  → Capteurs (BMA423, FT6336U, RTC)
├── ALDO3  → 3.3V  → LCD
└── BLDO1  → 2.8V  → Rétroéclairage LCD
```

### Deep sleep & wake-up

La consommation en deep sleep est d'environ **460–530 µA** (dominée par le PMU).  
Le wake-up peut être déclenché par :
- Interruption AXP2101 (bouton, insertion USB)
- Interruption BMA423 (lever de poignet via INT1 → EXTWAKE)
- Timer RTC

### Stratégie de consommation recommandée

| Mode | Écran | WiFi | IMU | Conso estimée |
|------|-------|------|-----|---------------|
| Actif | ON | ON | ON | ~100–180 mA |
| Actif sans WiFi | ON | OFF | ON | ~40–80 mA |
| Toujours allumé (watch face) | ON dimmed | OFF | ON | ~15–25 mA |
| Light sleep | OFF | OFF | Interruptions | ~2–5 mA |
| Deep sleep | OFF | OFF | OFF | ~0.5 mA |

---

## 10. FreeRTOS — architecture des tâches

ESP32-S3 est dual-core. Les tâches sont distribuées pour éviter les contentions SPI :

```
Core 0                              Core 1
──────────────────────────          ──────────────────────────────
task_sensor      (100 ms)           task_display    (33 ms / 30 fps)
  └── accel_update()                  └── display_update()
       ├── lecture BMA423 I2C               ├── draw_home_frame()   ← mode home
       └── détection de chute              │     ├── heure NTP
                                           │     ├── logo_icon.png
task_localization (2 000 ms)              │     └── batterie %
  └── localization_process()             ├── draw_dev_frame()    ← mode dev
       ├── scan BLE beacons               │     ├── accel X/Y/Z
       └── advertising iBeacon            │     ├── balises BLE
                                           │     └── gateway TX
guidance_task    (event-driven)           ├── draw_guidance_frame() ← navigation
  └── SSE HTTP → display_show_guidance()  └── draw_fall_overlay() ← si chute

                                    task_touch      (50 ms)
                                      └── poll FT6336U TD_STATUS
                                           └── toucher → display_toggle_dev_mode()
```

**Règle importante** : tout accès SPI (LovyanGFX) doit se faire depuis le core 1. Les données partagées entre tâches (AccelData, PowerStatus, BeaconSnapshot) sont des structures copiées par valeur — pas de mutex nécessaire pour ces lectures.

---

## 11. Différences T-Watch S3 vs S3 Plus

| Fonctionnalité | Standard | Plus |
|---|---|---|
| Batterie | 400–470 mAh | 940 mAh |
| GPS | Non | Oui (UBlox MIA-M10Q, UART GPIO 41/42) |
| Cardio / SpO2 | Non | Oui (MAX30102, I2C 0x57) |
| IMU | BMA423 | BMA423 ou MPU9250 (selon révision) |
| Bus I2C capteurs | GPIO 39/40 | GPIO 10/11 (bus secondaire) |
| Prix | ~40 € | ~70 € |

Pour activer le support S3 Plus dans le code :
```ini
; platformio.ini
build_flags =
    -DTWATCH_S3_PLUS
```

---

## 12. Ressources & liens

### Officiels LILYGO

- **LilyGoLib** (repo principal, tous les exemples) : https://github.com/Xinyuan-LilyGO/LilyGoLib
- **Wiki T-Watch S3 Plus** : https://wiki.lilygo.cc/get_started/en/Wearable/T-Watch-S3-PLUS/T-Watch-S3-PLUS.html
- **Page produit** : https://lilygo.cc/products/t-watch-s3

### Librairies

| Lib | Rôle | Lien |
|-----|------|------|
| XPowersLib | AXP2101 PMU | https://github.com/lewisxhe/XPowersLib |
| TFT_eSPI | Écran ST7789V | https://github.com/Bodmer/TFT_eSPI |
| LovyanGFX | Alternative TFT_eSPI (plus rapide) | https://github.com/lovyan03/LovyanGFX |
| LVGL | UI graphique embarquée | https://lvgl.io |
| Arduino-BMA423 | Accéléromètre | https://github.com/boschsensortec/Arduino-BMA423 |

### Datasheets capteurs

| Composant | Lien datasheet |
|-----------|---------------|
| ESP32-S3 | https://www.espressif.com/sites/default/files/documentation/esp32-s3_datasheet_en.pdf |
| BMA423 | https://www.bosch-sensortec.com/products/motion-sensors/accelerometers/bma423/ |
| AXP2101 | https://www.x-powers.com/en.php/Info/product_detail/article_id/95 |
| FT6336U | https://focusllc.com/datasheets/FT6336U.pdf |
| ST7789V | https://www.newhavendisplay.com/appnotes/datasheets/LCDs/ST7789V.pdf |
| MAX30102 | https://www.analog.com/en/products/max30102.html |
| DRV2605 | https://www.ti.com/product/DRV2605 |

### Communauté

- **Thread forum LILYGO** (T-Watch S3) : https://github.com/Xinyuan-LilyGO/LilyGoLib/discussions
- **Specs board espboards.dev** : https://www.espboards.dev/esp32/lilygo-t-watch-s3/
- **Support Zephyr RTOS** : https://docs.zephyrproject.org/latest/boards/lilygo/twatch_s3/doc/index.html

---

> **Note PlatformIO / ESP-IDF** : PlatformIO supporte ESP32-Arduino jusqu'à la version 2.0.17 (basée sur ESP-IDF 4.4.x). Les versions 3.x+ nécessitent Arduino IDE ou ESP-IDF natif. Pour rester sur PlatformIO, garder `platform = espressif32` sans épingler une version trop récente.
