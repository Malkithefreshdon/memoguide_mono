import asyncio
import wave
import time
from bleak import BleakScanner, BleakClient

# --- Configuration ---
DEVICE_NAME = "Memo_Montre"
AUDIO_RX_UUID = "12345678-1234-5678-1234-56789abcdef1"
# ✅ FIX: 512 = 2 × I2S_BLOCK_SIZE → pré-charge exactement 2 blocs I2S par paquet BLE
# Reste dans la limite MTU (247 - 3 = 244)... donc on garde 244 mais on s'assure que
# le firmware gère correctement.
# En fait : utiliser 240 (multiple de 4, frame-aligné stéréo 16-bit)
CHUNK_SIZE = 240
AUDIO_FILE_PATH = "test_16khz.wav"
# ---------------------

async def main():
    print(f"Recherche de '{DEVICE_NAME}'...")
    device = await BleakScanner.find_device_by_name(DEVICE_NAME, timeout=15.0)
    
    if not device:
        print(f"Appareil '{DEVICE_NAME}' introuvable.")
        return
        
    print(f"-> Trouvé (MAC: {device.address})")
    
    print(f"Lecture de : {AUDIO_FILE_PATH}...")
    try:
        with wave.open(AUDIO_FILE_PATH, 'rb') as wav_file:
            channels = wav_file.getnchannels()
            sample_width = wav_file.getsampwidth()
            framerate = wav_file.getframerate()
            n_frames = wav_file.getnframes()
            print(f"Audio : {channels}ch, {sample_width*8}bit, {framerate}Hz")
            pcm_data = wav_file.readframes(n_frames)
            print(f"PCM chargé : {len(pcm_data)} octets")
    except FileNotFoundError:
        print(f"Fichier '{AUDIO_FILE_PATH}' introuvable.")
        return

    print("Connexion...")
    async with BleakClient(device.address) as client:
        print("-> Connecté !")
        
        # ✅ FIX: Laisser le temps au firmware de se préparer après connexion
        await asyncio.sleep(0.5)
        
        print("Transmission audio...")
        start_time = time.monotonic()
        
        # ✅ FIX: Cadence basée sur les bytes réels envoyés (pas le chunk théorique)
        # 16000 Hz * 2 canaux * 2 octets = 64000 octets/sec
        BYTES_PER_SEC = 16000 * 2 * 2  # = 64000
        
        bytes_sent = 0
        stream_start = time.monotonic()
        
        for i in range(0, len(pcm_data), CHUNK_SIZE):
            chunk = pcm_data[i:i + CHUNK_SIZE]
            
            await client.write_gatt_char(AUDIO_RX_UUID, chunk, response=False)
            bytes_sent += len(chunk)
            
            # ✅ FIX: Throttling basé sur le temps réel écoulé vs bytes envoyés
            # → empêche la saturation de la pile BLE sans créer d'underflow
            expected_time = bytes_sent / BYTES_PER_SEC
            elapsed = time.monotonic() - stream_start
            drift = expected_time - elapsed
            if drift > 0.001:  # seulement si on est en avance de >1ms
                await asyncio.sleep(drift)
        
        duration = time.monotonic() - start_time
        print(f"\nTerminé ! {len(pcm_data)} octets en {duration:.2f}s")
        await asyncio.sleep(1)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nInterrompu.")
