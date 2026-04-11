# MemoGuide 🧭

MemoGuide (ou MontrAge) est un écosystème IoT complet de localisation d'intérieur (Indoor Tracking) et de communication, pensé pour le suivi et l'assistance via des dispositifs portables (wearables). 

Le système s'articule autour de montres connectées, de balises BLE (iBeacons) réparties dans les pièces, d'une passerelle locale (Gateway), et d'un tableau de bord web affichant les données en temps réel.

---

## 🌟 Fonctionnalités Principales (Features)

### 📍 1. Localisation d'Intérieur par Proximité (Indoor Tracking BLE)
La plateforme permet de localiser l'utilisateur avec précision (pièce par pièce).
- **Scan iBeacons** : La montre capte en continu les signaux des balises BLE fixes présentes dans l'environnement.
- **Broadcast Dynamique** : Sans avoir besoin de se connecter, la montre compile les balises détectées et leur puissance de signal (RSSI), et diffuse ces informations via Payload BLE (Manufacturer Data).
- **Trilatération & Estimation** : La passerelle (Gateway) intercepte ces relevés et les relaie au serveur central, qui calcule la pièce exacte ou la proximité (ex: *Chambre Malcom*, *Couloir*) grâce aux données RSSI.

### 🌐 2. Suivi de Position & Monitoring Temps Réel
Un espace de supervision pour visualiser l'état du système instantanément.
- **Flux Server-Sent Events (SSE)** : Le dashboard (développé en Nuxt 3) reflète la position de la montre en direct, poussant les mises à jour UI sans rafraîchissement de page.
- **Floorplan & API Réactive** : L'interface modélise les données remontées de la Gateway et positionne dynamiquement les utilisateurs, tout en gardant une API simple et rapide via requêtes HTTP synchrones de la passerelle.

### 🔊 3. Streaming Audio BLE (Communication directe)
Un canal de communication permettant de transmettre du son directement du réseau vers le poignet de l'utilisateur.
- **GATT Audio Service Custom** : La montre agit en tant que périphérique BLE et dispose d'une interface (Write Without Response) pour absorber un flux PCM brut fragmenté (chunking MTU BLE).
- **Amplification Matérielle (I2S)** : La montre décode ce flux audio basse latence (16 kHz, 16-bit) et pilote directement un amplificateur audio matériel (MAX98357A) via le protocole I2S, garantissant ainsi une écoute claire (par exemple pour des instructions, des alarmes ou une synthèse vocale).

### ⚡ 4. Interface Wearable & Gestion d'Énergie Avancée
Le système inclut nativement la gestion d'Interfaces Homme-Machine embarquées autonomes.
- **Systèmes bas Niveau (RTOS & C++)** : Appui sur Zephyr RTOS (nRF) et FreeRTOS/Arduino (ESP32-S3) favorisant une architecture logicielle multitâche non-bloquante.
- **Interactions Capteurs** : Pilotage du hardware interne : podomètre, détection des gestes (lever de poignet) via l'accéléromètre, retours haptiques (moteur DRV2605), et écran tactile capacitif.
- **Low Power (Mode très basse consommation)** : Gestion pointue des Power Management Units (PMU AXP2101) et des interruptions, alternant entre Deep Sleep, Light Sleep et mode actif pour maximiser la durée de vie de la batterie pour un usage au quotidien.

---

## 🧩 Architecture du Projet & Modules

Ce dépôt regroupe les 4 blocs applicatifs qui forment l'architecture de **MemoGuide**. Chacun dispose de son propre environnement :

### ⌚ [Memo_Montre](./Memo_Montre/) 
**Firmware BLE / Localisation — nRF52840 DK (Zephyr RTOS)**
- Composant clé pour le "scanner" environnemental (écoute les iBeacons périodiquement).
- Gère la réception de l'audio via BLE (GATT) et pilote la carte son MAX98357A (DAC) en I2S.
- Construit avec CMake et les outils nordiques (west).

### ⌚ [Memo_Bracelet](./Memo_Bracelet/)
**Firmware UI / Capteurs — LilyGo T-Watch S3 (ESP32-S3)**
- Logique IHM orientée affichage (écran ST7789V, driver capacitif tactile FT6336U).
- Implémentation de la gestion de batterie fine et de l'accéléromètre.
- Projet PlatformIO (framework Arduino/FreeRTOS).

### 📡 [Memo_Gateway](./Memo_Gateway/)
**Passerelle BLE-to-API — Raspberry Pi Zero 2W (Python)**
- Le "nez" du système: scan les packets beacons de toutes les montres et décode les flux *Manufacturer Specific Data*.
- Pousse toutes les données à l'API via HTTPS, agissant comme routeur fiable.
- Héberge les scripts utilitaires (test d'envoi de fichier audio `.wav` vers la montre en Bluetooth).

### 🖥️ [Memo_Dash](./Memo_Dash/)
**Web App Dashboard — Serveur et Frontend (Nuxt 3)**
- Cerveau applicatif qui modélise avec les tableaux `BEACONS` et interpole les signaux RSSI pour deviner dans quelle salle se situe le porteur.
- Fournit l'interface utilisateur (*Floorplan*), et l'API Endpoint centralisée (`/api/location`).

---

## 🚀 Pour commencer

L'exécution et la compilation de chaque composant diffèrent. Vous trouverez un `README.md` très détaillé pour maîtriser chaque brique :

- ➡️ **[Compiler Zephyr et flasher la Montre Nordic](./Memo_Montre/README.md)**
- ➡️ **[Configurer PlatformIO et flasher la T-Watch ESP32](./Memo_Bracelet/README.md)**
- ➡️ **[Mettre en place et auto-démarrer la gateway sur Raspberry Pi](./Memo_Gateway/README.md)**
- ➡️ **[Lancer et déployer l'API et le Frontend web Nuxt](./Memo_Dash/README.md)**
