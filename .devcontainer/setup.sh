#!/usr/bin/env bash
set -e

echo "==> Installing Task runner"
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

echo "==> Installing PlatformIO Core"
pip3 install --upgrade platformio

echo "==> Installing Python gateway dependencies"
pip3 install -r packages/gateway-rpi/requirements.txt 2>/dev/null || true

echo "==> Installing West (Zephyr build tool)"
pip3 install west

echo "==> Setup complete"
