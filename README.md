# MemoGuide — Monorepo

Montre connectée d'assistance pour les personnes atteintes d'Alzheimer.

## Structure

```
MemoGuide/
├── packages/
│   ├── watch-esp32/        # C/C++ — LILYGO T-Watch S3 (PlatformIO)
│   ├── watch-nrf/          # C    — nRF5340 (Zephyr / West)
│   ├── gateway-rpi/        # Python — Raspberry Pi gateway BLE → HTTP
│   └── dashboard-nuxt/     # Vue/Nuxt 3 — Dashboard web
├── docs/
│   └── protocol/           # Protocoles BLE, API REST, WebSocket
├── scripts/                # Scripts de build et d'automatisation
├── .devcontainer/          # Environnement de dev unifié (VS Code)
└── Taskfile.yml            # Tâches de build cross-packages
```

## Démarrage rapide

### Prérequis

- [Task](https://taskfile.dev/) — `brew install go-task`
- Node.js 22+, Python 3.12+, PlatformIO, West

### Commandes principales

```bash
# Dashboard (Nuxt dev server)
task dev:dashboard

# Gateway Python
task dev:gateway

# Firmware ESP32
task build:esp32
task flash:esp32

# Firmware nRF / Zephyr
task build:nrf
task flash:nrf

# Tout builder
task build:all
```

### Avec Devcontainer (VS Code)

Ouvrir le repo dans VS Code → **Reopen in Container** — tout l'outillage est installé automatiquement.

## Packages

| Package | Technologie | Cible |
|---|---|---|
| `watch-esp32` | C/C++ PlatformIO | LILYGO T-Watch S3 |
| `watch-nrf` | C Zephyr | nRF5340 DK |
| `gateway-rpi` | Python | Raspberry Pi |
| `dashboard-nuxt` | Nuxt 3 / Vue | Web / navigateur |

## Documentation

Voir [`docs/protocol/`](docs/protocol/README.md) pour les protocoles BLE et API.

python audio_relay.py \
    --source dashboard \
    --target 192.168.1.30 \
    --dashboard ws://192.168.1.86/api/audio
