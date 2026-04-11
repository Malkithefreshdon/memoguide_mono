# Guide du monorepo MemoGuide

## Table des matières

1. [Architecture et concepts](#1-architecture-et-concepts)
2. [Premier démarrage](#2-premier-démarrage)
3. [Travailler au quotidien](#3-travailler-au-quotidien)
4. [Git — la mécanique des submodules](#4-git--la-mécanique-des-submodules)
5. [Taskfile — toutes les commandes](#5-taskfile--toutes-les-commandes)
6. [CI/CD GitHub Actions](#6-cicd-github-actions)
7. [Devcontainer](#7-devcontainer)
8. [Flux de travail recommandés](#8-flux-de-travail-recommandés)
9. [Pièges à éviter](#9-pièges-à-éviter)

---

## 1. Architecture et concepts

```
MemoGuide/                        ← repo racine (git init ici)
├── packages/
│   ├── watch-esp32/              ← C/C++ PlatformIO   [tracké directement]
│   ├── watch-nrf/                ← C Zephyr/West      [submodule → memo_montre.git]
│   ├── gateway-rpi/              ← Python             [tracké directement]
│   └── dashboard-nuxt/           ← Nuxt 3             [submodule → memo_app.git]
├── docs/                         ← protocoles, guides
├── scripts/                      ← automatisations
├── .github/workflows/ci.yml      ← CI conditionnelle par package
├── .devcontainer/                ← environnement unifié VS Code
├── Taskfile.yml                  ← toutes les commandes en un endroit
├── .gitmodules                   ← déclaration des submodules
└── .gitattributes                ← LF forcé, diff drivers par langage
```

### Deux types de packages

| Type | Packages | Comportement git |
|---|---|---|
| **Tracké directement** | `watch-esp32`, `gateway-rpi` | Leurs fichiers vivent dans le repo racine |
| **Submodule** | `watch-nrf`, `dashboard-nuxt` | Le repo racine enregistre juste un **pointeur de commit** |

Un submodule, c'est simplement ça : le repo racine sait "à quel commit de tel repo externe pointe ce dossier".
Quand tu travailles dans `packages/watch-nrf/`, tu es littéralement dans un autre repo git — avec sa propre branche, ses propres remotes, son propre historique.

---

## 2. Premier démarrage

### Sur ta machine (déjà configurée)

```bash
# Task est nécessaire pour toutes les commandes
brew install go-task

# Installer les dépendances JS et Python
task install

# Vérifier que les submodules sont bien initialisés
git submodule status
# Résultat attendu : les deux lignes sans préfixe "-"
# -eecb113... packages/dashboard-nuxt   ← "-" = non initialisé
#  eecb113... packages/dashboard-nuxt   ← OK
```

### Sur une nouvelle machine (clone complet)

```bash
# --recurse-submodules clone aussi watch-nrf et dashboard-nuxt d'un coup
git clone --recurse-submodules git@github.com:Malkithefreshdon/memeguide.git

cd MemoGuide
task install
```

Si tu as oublié `--recurse-submodules` :

```bash
# Initialiser et cloner les submodules après coup
git submodule update --init --recursive
```

---

## 3. Travailler au quotidien

### Démarrer une session de dev

```bash
# Terminal 1 — Dashboard web
task dev:dashboard      # http://localhost:3000

# Terminal 2 — Gateway Python
task dev:gateway

# Voir toutes les commandes disponibles
task --list
```

### Avant de commencer à coder

```bash
# Mettre à jour tout le repo (racine + submodules)
git pull
git submodule update --remote --merge
```

---

## 4. Git — la mécanique des submodules

C'est la partie la plus importante à comprendre pour éviter les erreurs.

### Comment le repo racine voit les submodules

```bash
git log --oneline
# 7128f90 chore: init monorepo MemoGuide

git show HEAD:packages/watch-nrf
# tree HEAD:packages/watch-nrf
# → affiche juste un hash de commit, pas des fichiers
# C'est le "gitlink" — un pointeur vers un commit dans l'autre repo
```

Le repo racine ne stocke **pas** les fichiers de `watch-nrf`. Il stocke seulement :
> "Le dossier `packages/watch-nrf` correspond au commit `926df95` de `memo_montre.git`"

### Travailler dans un submodule (watch-nrf ou dashboard-nuxt)

```bash
cd packages/watch-nrf

# Tu es maintenant dans un repo git indépendant
git status          # status du submodule, pas du monorepo
git branch          # audio_v1 (sa propre branche)
git log --oneline   # son propre historique

# Modifier, commiter, pousser — exactement comme avant
git add src/audio_trx.c
git commit -m "feat(ble): improve audio streaming"
git push origin audio_v1

# Revenir à la racine et mettre à jour le pointeur
cd ../..
git add packages/watch-nrf
git commit -m "chore(watch-nrf): bump to latest audio_v1"
```

**Règle d'or** : après avoir poussé dans un submodule, **toujours faire un commit dans le repo racine** pour mettre à jour le pointeur. Sinon tes collègues (ou toi demain) auront une version désynchronisée.

### Schéma du flux git complet

```
┌─────────────────────────────────────────────────────────────┐
│  REPO RACINE (MemoGuide)                                     │
│                                                             │
│  packages/watch-nrf ──────► gitlink: 926df95               │
│  packages/dashboard-nuxt ─► gitlink: eecb113               │
│  packages/watch-esp32 ────► fichiers directs               │
│  packages/gateway-rpi ────► fichiers directs               │
└─────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌─────────────────┐      ┌──────────────────────┐
│ memo_montre.git │      │    memo_app.git       │
│ branche audio_v1│      │    branche main       │
│ (GitHub)        │      │    (GitHub)           │
└─────────────────┘      └──────────────────────┘
```

### Mettre à jour un submodule vers son dernier commit

```bash
# Mettre à jour watch-nrf vers le dernier commit de audio_v1
git submodule update --remote packages/watch-nrf

# Vérifier ce qui a changé
git diff packages/watch-nrf

# Commiter le nouveau pointeur dans le monorepo
git add packages/watch-nrf
git commit -m "chore(watch-nrf): bump to latest audio_v1"
```

### Vérifier l'état de synchronisation

```bash
git submodule status

# Préfixes possibles :
#   (rien)  → commit local correspond au pointeur enregistré
#   -       → submodule non initialisé (git submodule update --init)
#   +       → submodule est en avance sur le pointeur enregistré (penser à bumper)
#   U       → conflit de merge dans le submodule
```

---

## 5. Taskfile — toutes les commandes

```bash
task --list    # affiche la liste complète avec descriptions
```

| Commande | Action |
|---|---|
| `task dev:dashboard` | Lance Nuxt en mode dev (`localhost:3000`) |
| `task build:dashboard` | Build Nuxt pour la prod |
| `task dev:gateway` | Lance la gateway Python |
| `task test:gateway` | Tests audio Python |
| `task build:esp32` | Compile le firmware ESP32 (PlatformIO) |
| `task flash:esp32` | Flash sur le T-Watch S3 connecté en USB |
| `task monitor:esp32` | Ouvre le serial monitor |
| `task clean:esp32` | Supprime les artefacts de build ESP32 |
| `task build:nrf` | Compile le firmware Zephyr |
| `task flash:nrf` | Flash via J-Link |
| `task clean:nrf` | Supprime `packages/watch-nrf/build/` |
| `task build:all` | Compile esp32 + nrf + dashboard |
| `task install` | `npm install` + `pip install` |
| `task lint` | Lint du dashboard |

### Ajouter une tâche

Ouvre `Taskfile.yml` à la racine. Exemple pour ajouter un test Python :

```yaml
test:gateway:unit:
  desc: "Run unit tests for gateway"
  dir: "{{.GATEWAY_DIR}}"
  cmds:
    - python3 -m pytest tests/
```

---

## 6. CI/CD GitHub Actions

Le fichier `.github/workflows/ci.yml` contient des jobs **sélectifs** : seul le job correspondant au package modifié tourne.

### Jobs disponibles

| Job | Se déclenche quand |
|---|---|
| `dashboard` | Fichiers dans `packages/dashboard-nuxt/` modifiés, ou commit contient `[all]` |
| `gateway` | Toujours (léger, lint Python seulement) |
| `watch-esp32` | Toujours (build PlatformIO) |
| `watch-nrf` | Toujours (build Zephyr dans container dédié) |

### Forcer tous les jobs

Inclure `[all]` dans le message de commit :

```bash
git commit -m "chore: update dependencies [all]"
```

### Ce que chaque job fait

- **dashboard** : `npm ci` + `nuxt build`
- **gateway** : `flake8` lint Python
- **watch-esp32** : `pio run` avec cache de la toolchain
- **watch-nrf** : `west build` dans un container Zephyr officiel

---

## 7. Devcontainer

Le `.devcontainer/` permet d'ouvrir le projet dans un environnement de dev identique sur n'importe quelle machine, sans rien installer manuellement.

### Lancer le devcontainer

Dans VS Code : `Cmd+Shift+P` → **Dev Containers: Reopen in Container**

Au premier lancement, `.devcontainer/setup.sh` installe automatiquement :
- **Task** (le runner de tâches)
- **PlatformIO Core** (pour l'ESP32)
- **West** (pour Zephyr/nRF)
- Les dépendances Python de la gateway

### Extensions VS Code installées automatiquement

| Extension | Pour quoi |
|---|---|
| `platformio.platformio-ide` | Build/flash ESP32 avec UI |
| `nordic-semiconductor.nrf-connect` | Build/debug Zephyr |
| `ms-python.python` + `pylance` | Gateway Python |
| `Vue.volar` | Dashboard Nuxt |
| `task.vscode-task` | Raccourcis Taskfile dans la sidebar |
| `eamodio.gitlens` | Visualisation git avancée |

---

## 8. Flux de travail recommandés

### Scénario A — Je travaille sur le firmware nRF

```bash
# 1. Se mettre à jour
git pull && git submodule update --remote --merge

# 2. Rentrer dans le submodule
cd packages/watch-nrf

# 3. Créer une branche feature (dans le submodule)
git checkout -b feat/fall-detection

# 4. Coder, tester, commiter
git add src/imu.c
git commit -m "feat(imu): add fall detection threshold"
git push origin feat/fall-detection
# → Ouvrir une PR sur memo_montre.git
# → Merger dans audio_v1

# 5. Bumper le pointeur dans le monorepo
cd ../..
git submodule update --remote packages/watch-nrf
git add packages/watch-nrf
git commit -m "chore(watch-nrf): bump fall detection feature"
git push
```

### Scénario B — Je travaille sur le dashboard

Identique au scénario A mais avec `packages/dashboard-nuxt` et la branche `main`.

### Scénario C — Je travaille sur la gateway ou l'ESP32

Plus simple : ces packages sont trackés directement dans le monorepo.

```bash
# 1. Modifier les fichiers
vi packages/gateway-rpi/gateway.py

# 2. Commiter directement dans le monorepo
git add packages/gateway-rpi/gateway.py
git commit -m "feat(gateway): add BLE reconnection logic"
git push
```

### Scénario D — Changement cross-package (ex: protocole BLE)

```bash
# 1. Mettre à jour docs/protocol/README.md
# 2. Modifier watch-esp32 (envoi BLE)
# 3. Modifier watch-nrf (réception BLE) → commit dans le submodule + bump
# 4. Modifier gateway-rpi (parsing)
# 5. Un seul commit racine pour tout synchroniser

git add docs/ packages/watch-esp32/ packages/gateway-rpi/ packages/watch-nrf
git commit -m "feat(protocol): update BLE packet format v2 [all]"
```

---

## 9. Pièges à éviter

### Ne pas oublier de bumper le pointeur submodule

```bash
# MAUVAIS — tu as poussé dans watch-nrf mais pas mis à jour le monorepo
cd packages/watch-nrf && git push   # ← fait
cd ../..                            # ← tu t'arrêtes là = erreur

# BON
cd ../..
git add packages/watch-nrf
git commit -m "chore(watch-nrf): bump"
git push
```

### Ne pas commiter depuis la racine des fichiers submodule

```bash
# MAUVAIS — depuis la racine, git ne voit les submodules que comme pointeurs
cd /MemoGuide
git add packages/watch-nrf/src/main.c   # ← git ignore ça silencieusement

# BON — rentrer dans le submodule
cd packages/watch-nrf
git add src/main.c
git commit -m "..."
```

### Ne pas travailler sur HEAD détaché dans un submodule

```bash
git submodule update   # ← par défaut met le submodule en "detached HEAD"

# Pour travailler dessus, toujours se mettre sur une branche explicite
cd packages/watch-nrf
git checkout audio_v1   # ← branche réelle
```

Pour éviter ce problème, utiliser `--merge` lors des updates :

```bash
git submodule update --remote --merge
```

### Ne jamais commiter `.env` ou secrets

Le `.gitignore` bloque `.env` et `.env.*` à la racine.
Chaque submodule a son propre `.gitignore` — vérifier qu'ils bloquent aussi leurs secrets.
