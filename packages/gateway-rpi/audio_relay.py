#!/usr/bin/env python3
"""
audio_relay.py — Relay audio vers l'ESP32 via UDP

Deux modes :
  --source file      (défaut) Lit un WAV et l'envoie en UDP — test standalone
  --source dashboard           Se connecte au dashboard WebSocket et relay les chunks live

Usage :
  python audio_relay.py --source file      --target 192.168.1.42 --file test_16khz.wav --loop
  python audio_relay.py --source dashboard --target 192.168.1.42 --dashboard ws://192.168.1.10:3000/api/audio
"""

import asyncio
import wave
import struct
import socket
import argparse
import ssl

AUDIO_UDP_PORT = 5005
CHUNK_SIZE     = 512
BYTES_PER_SEC  = 16000 * 2 * 2  # 16kHz × stéréo × 16-bit = 64 000 B/s


# ── Helpers ───────────────────────────────────────────────────────────────────

def make_udp_socket() -> socket.socket:
    return socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def load_wav(path: str) -> bytes:
    with wave.open(path, "rb") as f:
        channels     = f.getnchannels()
        sample_width = f.getsampwidth()
        rate         = f.getframerate()
        raw          = f.readframes(f.getnframes())

    print(f"[WAV] {path} : {channels}ch  {sample_width*8}bit  {rate}Hz  {len(raw)} B")

    if rate != 16000:
        print(f"[WAV] ATTENTION : {rate}Hz ≠ 16000Hz — le son sera décalé")

    if channels == 1:
        samples = struct.unpack(f"<{len(raw)//2}h", raw)
        raw = struct.pack(f"<{len(samples)*2}h", *[v for s in samples for v in (s, s)])
        print(f"[WAV] Mono→stéréo : {len(raw)} B")

    return raw


# ── Mode 1 : fichier WAV ──────────────────────────────────────────────────────

async def relay_file(pcm: bytes, target_ip: str, loop: bool) -> None:
    import time
    sock = make_udp_socket()
    print(f"[RELAY-FILE] Cible : {target_ip}:{AUDIO_UDP_PORT}")

    while True:
        print(f"[RELAY-FILE] Démarrage ({len(pcm)} B)…")
        bytes_sent = 0
        t0 = time.monotonic()

        for i in range(0, len(pcm), CHUNK_SIZE):
            chunk = pcm[i : i + CHUNK_SIZE]
            sock.sendto(chunk, (target_ip, AUDIO_UDP_PORT))
            bytes_sent += len(chunk)

            expected = bytes_sent / BYTES_PER_SEC
            drift    = expected - (time.monotonic() - t0)
            if drift > 0.001:
                await asyncio.sleep(drift)

        print(f"[RELAY-FILE] Terminé — {bytes_sent} B en {time.monotonic() - t0:.2f}s")
        if not loop:
            break
        print("[RELAY-FILE] Boucle…")

    sock.close()


# ── Mode 2 : dashboard WebSocket ──────────────────────────────────────────────

async def relay_dashboard(dashboard_url: str, target_ip: str) -> None:
    try:
        import websockets
    except ImportError:
        print("[RELAY-WS] Erreur : module 'websockets' manquant.")
        print("           Installer : pip install websockets")
        return

    sock = make_udp_socket()
    print(f"[RELAY-WS] Connexion → {dashboard_url}")
    print(f"[RELAY-WS] Cible UDP  → {target_ip}:{AUDIO_UDP_PORT}")

    # wss:// avec cert auto-signé (dev) : désactive la vérification
    ssl_ctx = None
    if dashboard_url.startswith("wss://"):
        ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ssl_ctx.check_hostname = False
        ssl_ctx.verify_mode = ssl.CERT_NONE

    while True:
        try:
            async with websockets.connect(dashboard_url, ssl=ssl_ctx) as ws:
                await ws.send('{"role":"gateway"}')
                print("[RELAY-WS] Enregistré — en attente d'audio du navigateur…")

                async for message in ws:
                    if isinstance(message, bytes):
                        sock.sendto(message, (target_ip, AUDIO_UDP_PORT))

        except Exception as e:
            print(f"[RELAY-WS] Déconnecté ({e}) — reconnexion dans 3s…")
            await asyncio.sleep(3)

    sock.close()


# ── Main ──────────────────────────────────────────────────────────────────────

async def main() -> None:
    ap = argparse.ArgumentParser(description="Relay audio → ESP32 via UDP")
    ap.add_argument("--source",    choices=["file", "dashboard"], default="file")
    ap.add_argument("--target",    required=True,  help="IP de la montre ESP32")
    ap.add_argument("--file",      default="test_16khz.wav", help="(mode file) Fichier WAV")
    ap.add_argument("--loop",      action="store_true",       help="(mode file) Boucle")
    ap.add_argument("--dashboard", default="ws://localhost:3000/api/audio",
                    help="(mode dashboard) URL WebSocket du dashboard")
    args = ap.parse_args()

    if args.source == "file":
        pcm = load_wav(args.file)
        await relay_file(pcm, args.target, args.loop)
    else:
        await relay_dashboard(args.dashboard, args.target)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[RELAY] Arrêté.")
