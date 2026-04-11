# MontrAge — RPi Zero 2W Gateway Setup

Guide complet : activation Bluetooth → debug → déploiement permanent.

---

## Table des matières

1. [Activation du Bluetooth](#1-activation-du-bluetooth)
2. [Installation des dépendances](#2-installation-des-dépendances)
3. [Configuration des variables d'environnement](#3-configuration-des-variables-denvironnement)
4. [Lancer le gateway en mode debug](#4-lancer-le-gateway-en-mode-debug)
5. [Débogage avancé](#5-débogage-avancé)
6. [Déploiement permanent (systemd)](#6-déploiement-permanent-systemd)
7. [Gérer le service systemd](#7-gérer-le-service-systemd)
8. [Modifier la configuration](#8-modifier-la-configuration)
9. [Désactiver le démarrage automatique](#9-désactiver-le-démarrage-automatique)
10. [Format des données dynamiques](#10-format-des-données-dynamiques)
11. [Fonctionnalité Audio (Test BLE)](#11-fonctionnalité-audio-test-ble)

---

## 1. Activation du Bluetooth

### Vérifier l'état du Bluetooth

```bash
hciconfig
```

Résultat attendu une fois actif :

```
hci0:   Type: Primary  Bus: UART
        BD Address: XX:XX:XX:XX:XX:XX
        UP RUNNING       ← doit afficher ça
```

### Si le Bluetooth est DOWN

```bash
# Débloquer rfkill (bloque souvent au premier démarrage)
sudo rfkill unblock bluetooth

# Démarrer l'interface
sudo hciconfig hci0 up

# Vérifier
hciconfig
rfkill list
```

### Activer le service Bluetooth au boot

```bash
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
sudo systemctl status bluetooth
```

### Tester que le scan BLE fonctionne

```bash
# Scan passif 10 secondes — doit afficher des appareils BLE autour
sudo timeout 10 hcitool lescan
```

---

## 2. Installation des dépendances

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip bluetooth bluez python3-dev libglib2.0-dev
pip3 install bleak httpx --break-system-packages
```

Vérifier les versions installées :

```bash
python3 -c "import bleak; print('bleak', bleak.__version__)"
python3 -c "import httpx; print('httpx', httpx.__version__)"
```

---

## 3. Configuration des variables d'environnement

Le script `gateway.py` se configure entièrement via variables d'environnement :

| Variable | Description | Défaut |
|---|---|---|
| `API_URL` | URL complète de l'endpoint `/api/location` | `http://localhost:3000/api/location` |
| `API_KEY` | Clé secrète (header `x-api-key`) | `dev-secret-key` |
| `GATEWAY_ID` | Identifiant de cette gateway | `gateway_01` |
| `SEND_EVERY` | Intervalle d'envoi en secondes | `2.0` |

*(Note : L'identifiant de la montre (`watch_id`) n'est plus configuré ici, il est lu dynamiquement depuis chaque trame Bluetooth reçue de chaque montre.)*

### En mode test (temporaire, disparaît à la déconnexion SSH)

```bash
export API_URL=https://ton-vps.com/api/location
export API_KEY=ta-clé-secrète
export GATEWAY_ID=gateway_salon
export SEND_EVERY=2.0
```

---

## 4. Lancer le gateway en mode debug

Une fois les variables exportées :

```bash
python3 ~/gateway.py
```

Exemple de sortie attendue :

```
10:32:01  INFO     === MontrAge Gateway ===
10:32:01  INFO       API      : https://ton-vps.com/api/location
10:32:01  INFO       Gateway  : gateway_salon
10:32:01  INFO       Intervalle : 2.0s
10:32:01  INFO     Scan BLE en cours...

10:32:03  INFO       [BLE REÇU] AA:BB:CC:DD:EE:FF -> Watch:1 | Beacons:[{'major': 1, 'minor': 101, 'rssi': -65}]
10:32:03  INFO       Envoyé → Chambre Malcom (confiance 87%)
10:32:05  INFO       Envoyé → Chambre Malcom (confiance 91%)
```

Pour voir les logs BLE bruts (chaque advertisement reçu) :

```bash
# Passer le logger en DEBUG
python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)
" && python3 ~/gateway.py
```

Ou modifier temporairement dans `gateway.py` :

```python
# Ligne à changer
logging.basicConfig(level=logging.DEBUG, ...)
```

---

## 5. Débogage avancé

### La montre n'est pas détectée

**Vérifier que le BLE scan fonctionne côté système :**

```bash
# Scanner les appareils BLE autour (30s)
sudo timeout 30 hcitool lescan --duplicates
```

**Vérifier le payload manufacturer data brut :**

```bash
# Installer bluetoothctl et inspecter
sudo btmgmt find
```

**Script de diagnostic — affiche tous les manufacturer data reçus :**

```python
# debug_scan.py
import asyncio
from bleak import BleakScanner

async def main():
    def cb(device, adv):
        if adv.manufacturer_data:
            print(f"{device.address}  RSSI={adv.rssi}  MFG={dict(adv.manufacturer_data)}")
    async with BleakScanner(detection_callback=cb):
        await asyncio.sleep(30)

asyncio.run(main())
```

```bash
python3 debug_scan.py
```

Tu dois voir une ligne avec `company_id=65535` (0xFFFF) quand la montre broadcast.

### L'API ne répond pas

```bash
# Tester la connexion à l'API manuellement depuis le Pi
curl -X POST https://ton-vps.com/api/location \
  -H "Content-Type: application/json" \
  -H "x-api-key: ta-clé-secrète" \
  -d '{"gateway_id":"gateway_salon","watch_id":"watch_001","timestamp":1711032304000,"rssi_data":[{"beacon_id":"beacon_1_101","major":1,"minor":101,"rssi":-60}]}'
```

### Erreur "Operation not permitted" sur le scan BLE

```bash
# Donner les permissions BLE à Python sans sudo
sudo setcap cap_net_raw,cap_net_admin+eip $(readlink -f $(which python3))
```

### Redémarrer l'interface BLE si elle se bloque

```bash
sudo hciconfig hci0 down
sudo hciconfig hci0 up
# ou
sudo systemctl restart bluetooth
```

---

## 6. Déploiement permanent (systemd)

Une fois que le gateway fonctionne correctement en mode debug, on le transforme en service système.

### Créer le fichier de service

```bash
sudo nano /etc/systemd/system/memo-gateway.service
```

Contenu à coller (adapter les valeurs) :

```ini
[Unit]
Description=MemoGuide BLE Gateway
After=network-online.target bluetooth.target
Wants=network-online.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin

# Variables d'environnement
Environment=API_URL=https://ton-vps.com/api/location
Environment=API_KEY=ta-clé-secrète
Environment=GATEWAY_ID=gateway_chambre
Environment=SEND_EVERY=2.0

# Lancement
ExecStart=/usr/bin/python3 /home/admin/gateway.py

# Redémarrage automatique si crash
Restart=always
RestartSec=5

# Logs
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Activer et démarrer le service

```bash
# Recharger la config systemd
sudo systemctl daemon-reload

# Activer le démarrage automatique au boot
sudo systemctl enable memo-gateway

# Démarrer immédiatement
sudo systemctl start memo-gateway

# Vérifier le statut
sudo systemctl status memo-gateway
```

Sortie attendue :

```
● memo-gateway.service - MemoGuide BLE Gateway
   Loaded: loaded (/etc/systemd/system/memo-gateway.service; enabled)
   Active: active (running) since ...    ← doit être "active (running)"
```

---

## 7. Gérer le service systemd

### Voir les logs en direct

```bash
journalctl -u memo-gateway -f
```

### Voir les 50 dernières lignes de logs

```bash
journalctl -u memo-gateway -n 50
```

### Voir les logs depuis le dernier démarrage

```bash
journalctl -u memo-gateway -b
```

### Démarrer / Arrêter / Redémarrer

```bash
sudo systemctl start   memo-gateway
sudo systemctl stop    memo-gateway
sudo systemctl restart memo-gateway
```

---

## 8. Modifier la configuration

### Modifier une variable d'environnement (API_URL, API_KEY, etc.)

```bash
sudo nano /etc/systemd/system/memo-gateway.service
```

Modifier la ligne `Environment=` concernée, puis :

```bash
sudo systemctl daemon-reload
sudo systemctl restart memo-gateway
```

### Mettre à jour gateway.py

```bash
# Arrêter le service
sudo systemctl stop memo-gateway

# Modifier le fichier
nano ~/gateway.py

# Relancer
sudo systemctl start memo-gateway

# Vérifier les logs
journalctl -u memo-gateway -f
```

---

## 9. Désactiver le démarrage automatique

### Désactiver uniquement le boot automatique (le service reste utilisable manuellement)

```bash
sudo systemctl disable memo-gateway
```

### Arrêter ET désactiver

```bash
sudo systemctl stop    memo-gateway
sudo systemctl disable memo-gateway
```

### Supprimer complètement le service

```bash
sudo systemctl stop    memo-gateway
sudo systemctl disable memo-gateway
sudo rm /etc/systemd/system/memo-gateway.service
sudo systemctl daemon-reload
```

---

## 10. Format des données dynamiques

La gateway intercepte désormais un payload BLE **100% dynamique** envoyé par la(les) montre(s), d'une taille de 29 octets max :

1. **En-tête (2 octets)** : `Company ID` (0xFFFF) extrait par Bleak.
2. **Magic Byte (1 octet)** : `0xAA` en début de trame.
3. **Watch ID (1 octet)** : Identifiant matériel de la montre. La gateway préfixera automatiquement (ex: `watch_001`).
4. **Balises (par blocs de 5 octets)** : Pour chaque balise à portée, la montre envoie le `Major High`, `Major Low`, `Minor High`, `Minor Low` et le `RSSI` signé.

L'API reçoit un compte rendu complet indépendant de la table de routage, ce qui permet à la Gateway de se comporter comme un simple relai aveugle.

---

## 11. Fonctionnalité Audio (Test BLE)

La montre (`Memo_Montre`) agit comme un **périphérique Bluetooth (Peripheral)** pour recevoir un flux audio. Ce flux est lu par l'amplificateur interne MAX98357A (I2S).

### Spécifications Bluetooth & Audio

- **Nom du périphérique** : `Memo_Montre`
- **Service Audio (UUID)** : `12345678-1234-5678-1234-56789abcdef0`
- **Caractéristique RX (UUID)** : `12345678-1234-5678-1234-56789abcdef1` (Mode: *Write Without Response*)
- **MTU** : 247 octets (Payload max par paquet : **244 octets**)
- **Format audio strict exigé** : PCM Brut, **16 kHz, 16-bit, Stéréo**

### Préparer un fichier audio

Si votre fichier n'est pas au bon format, vous devez le convertir pour éviter toute distorsion matérielle de l'amplificateur MAX98357A. La méthode la plus simple est d'utiliser `ffmpeg` :

```bash
ffmpeg -i votre_son.mp3 -ar 16000 -ac 2 -sample_fmt s16 son_converti.wav
```

### Script de test (`test_audio.py`)

Un script Python `test_audio.py` est disponible sur l'ordinateur de contrôle pour tester l'envoi vers la montre. Il découpe automatiquement le fichier audio dans des paquets optimisés au MTU et maintient la cadence de transmission.

1. Transférez le script et votre fichier audio converti sur le Raspberry Pi :
   ```bash
   scp test_audio.py <utilisateur>@<ip_du_pi>:/home/<utilisateur>/
   scp son_converti.wav <utilisateur>@<ip_du_pi>:/home/<utilisateur>/
   ```

2. Assurez-vous que la librairie Python Bleak est installée sur le Raspberry Pi (la passerelle) :
   ```bash
   pip3 install bleak
   ```

3. Exécutez le script (modifiez la variable `AUDIO_FILE_PATH` dans le code source pour pointer vers votre fichier `.wav` converti) :
   ```bash
   python3 test_audio.py
   ```

---

## Référence rapide

```bash
# Bluetooth
sudo rfkill unblock bluetooth && sudo hciconfig hci0 up

# Test rapide gateway
export API_URL=... && export API_KEY=... && python3 ~/gateway.py

# Logs service en direct
journalctl -u memo-gateway -f

# Redémarrer après modif config
sudo systemctl daemon-reload && sudo systemctl restart memo-gateway

# Statut complet
sudo systemctl status memo-gateway
```
