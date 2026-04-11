#!/usr/bin/env python3
"""
gateway.py — MontrAge BLE Gateway
Scanne les broadcasts de la montre nRF52840,
parse le payload manufacturer data et envoie un JSON à l'API Nuxt.
"""

import asyncio
import httpx
import struct
import time
import os
import logging
from bleak import BleakScanner
from bleak.backends.device import BLEDevice
from bleak.backends.scanner import AdvertisementData

# ── Config ────────────────────────────────────────────────────────────────────
API_URL     = os.getenv("API_URL",     "http://localhost:3000/api/location")
API_KEY     = os.getenv("API_KEY",     "memo-guide-gateway-xp550e")
GATEWAY_ID  = os.getenv("GATEWAY_ID",  "gateway_01")
SEND_EVERY  = float(os.getenv("SEND_EVERY", "2.0"))  # secondes entre chaque envoi

# Manufacturer Data : Company ID 0xFFFF
COMPANY_ID  = 0xFFFF
MAGIC_BYTE  = 0xAA


# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-7s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("gateway")

# ── State partagé ─────────────────────────────────────────────────────────────
latest_beacons: list = []
hw_watch_id = None
watch_mac   = None
last_seen   = 0.0

# ── Parser ────────────────────────────────────────────────────────────────────
def parse_watch_payload(mfg_data: dict):
    """
    Parse le manufacturer data de la montre.
    Format dynamique (après strip company ID) :
    [0] : 0xAA (Magic Byte)
    [1] : WATCH_ID (1 octet)
    [2-6] : [Major H, Major L, Minor H, Minor L, RSSI]
    ...
    Retourne (watch_id, liste_beacons) ou None si payload invalide.
    """
    raw = mfg_data.get(COMPANY_ID)
    if raw is None:
        return None
    if len(raw) < 2 or raw[0] != MAGIC_BYTE:
        return None
        
    wid = raw[1]
    
    # Vérification taille (2 octets header + N * 5 octets)
    if (len(raw) - 2) % 5 != 0:
        return None
        
    parsed_data = []
    num_beacons = (len(raw) - 2) // 5
    for i in range(num_beacons):
        offset = 2 + i * 5
        major_high = raw[offset]
        major_low = raw[offset+1]
        minor_high = raw[offset+2]
        minor_low = raw[offset+3]
        
        # Le RSSI est signé (complément à 2)
        rssi = struct.unpack_from("b", raw, offset + 4)[0]
        major = (major_high << 8) + major_low
        minor = (minor_high << 8) + minor_low
        
        parsed_data.append({
            "major": major,
            "minor": minor,
            "rssi": int(rssi)
        })
        
    return wid, parsed_data

# ── Callback scan ─────────────────────────────────────────────────────────────
def on_advertisement(device: BLEDevice, adv: AdvertisementData):
    global latest_beacons, hw_watch_id, watch_mac, last_seen

    parsed = parse_watch_payload(adv.manufacturer_data)
    if parsed is None:
        return

    wid, beacons = parsed
    latest_beacons = beacons
    hw_watch_id = wid
    watch_mac   = device.address
    last_seen   = time.time()

    log.debug(f"  [BLE REÇU] {watch_mac} -> Watch:{wid} | Beacons:{beacons}")

# ── Envoi API ─────────────────────────────────────────────────────────────────
async def send_to_api(client):
    if last_seen == 0:
        log.warning("Aucun broadcast reçu de la montre, skip.")
        return

    age = time.time() - last_seen
    if age > 10:
        log.warning(f"Dernier broadcast il y a {age:.0f}s — montre hors portée ?")

    payload = {
        "gateway_id": GATEWAY_ID,
        "watch_id": f"watch_{hw_watch_id:03d}",
        "timestamp": int(time.time() * 1000),
        "rssi_data": [
            {
                "beacon_id": f"beacon_{b['major']}_{b['minor']}",
                "major": b["major"],
                "minor": b["minor"],
                "rssi": b["rssi"]
            }
            for b in latest_beacons
        ],
    }

    log.info(f"  [API ENVOI] Payload préparé : {payload}")

    try:
        res = await client.post(
            API_URL,
            json=payload,
            headers={"Content-Type": "application/json", "x-api-key": API_KEY},
            timeout=5.0,
        )
        res.raise_for_status()  # Lever une exception si code HTTP != 2xx
        data = res.json()
        room = data.get("estimated_room", "?")
        conf = int(data.get("confidence", 0) * 100)
        log.info(f"  Envoyé → {room} (confiance {conf}%)")

    except httpx.ConnectError:
        log.error(f"  Impossible de joindre l'API ({API_URL}) — vérifier l'IP ou si le serveur est lancé")
    except httpx.HTTPStatusError as e:
        log.error(f"  API a retourné une erreur {e.response.status_code}")
    except Exception as e:
        log.error(f"  Erreur : {e}")

# ── Main ─────────────────────────────────────────────────────────────────────
async def main():
    log.info("=== MontrAge Gateway ===")
    log.info(f"  API      : {API_URL}")
    log.info(f"  Gateway  : {GATEWAY_ID}")
    log.info(f"  Intervalle : {SEND_EVERY}s")
    log.info("Scan BLE en cours...\n")

    async with BleakScanner(detection_callback=on_advertisement):
        async with httpx.AsyncClient() as client:
            while True:
                await asyncio.sleep(SEND_EVERY)
                await send_to_api(client)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        log.info("Gateway arrêté.")