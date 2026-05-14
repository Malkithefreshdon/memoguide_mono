import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// UUIDs BLE — doivent correspondre au firmware ESP32
// ═══════════════════════════════════════════════
const String kServiceUUID   = '12345678-1234-1234-1234-123456789abc';
const String kHrCharUUID    = '12345678-1234-1234-1234-123456789ab1';
const String kFallCharUUID  = '12345678-1234-1234-1234-123456789ab2';
const String kVoiceCharUUID = '12345678-1234-1234-1234-123456789ab4';

class BleService extends ChangeNotifier {
  // ═══ État connexion ═══
  bool isConnected = false;
  bool isScanning = false;
  String connectionStatus = 'Non connecté';

  // ═══ Données reçues de la montre ═══
  int heartRate = 0;
  bool fallDetected = false;

  // ═══ Callback vers AppState ═══
  Function(int bpm)? onHeartRateReceived;
  Function()? onFallDetected;

  // ═══ Sur Web/ordi : BLE non disponible ═══
  // Quand la montre arrive, on activera le vrai BLE
  final bool _isMockMode = kIsWeb; // true sur Chrome, false sur Android

  // ═══ Scanner pour la montre ═══
  Future<void> startScan() async {
    if (_isMockMode) {
      // Mode ordi/Chrome : on simule une connexion
      connectionStatus = 'Mode simulation (pas de montre)';
      notifyListeners();
      return;
    }

    // ═══ VRAI BLE — activé quand tu as la montre ═══
    // Décommente ce bloc quand tu as l'ESP32 :
    /*
    import 'package:flutter_blue_plus/flutter_blue_plus.dart';

    isScanning = true;
    connectionStatus = 'Recherche de la montre...';
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == 'EHPAD-Watch') {
          FlutterBluePlus.stopScan();
          _connectWatch(r.device);
          break;
        }
      }
    });
    */
  }

  // ═══ Connexion à la montre ═══
  Future<void> _connectWatch(dynamic device) async {
    // Activé quand tu as l'ESP32
    /*
    await device.connect();
    isConnected = true;
    connectionStatus = 'Montre connectée ✓';
    notifyListeners();

    List<dynamic> services = await device.discoverServices();
    for (var service in services) {
      for (var c in service.characteristics) {

        // Rythme cardiaque
        if (c.uuid.toString() == kHrCharUUID) {
          await c.setNotifyValue(true);
          c.onValueReceived.listen((value) {
            heartRate = value[0];
            onHeartRateReceived?.call(heartRate);
            notifyListeners();
          });
        }

        // Détection chute
        if (c.uuid.toString() == kFallCharUUID) {
          await c.setNotifyValue(true);
          c.onValueReceived.listen((value) {
            if (value[0] == 1) {
              fallDetected = true;
              onFallDetected?.call();
              notifyListeners();
            }
          });
        }
      }
    }
    */
  }

  // ═══ Envoyer commande vocale vers la montre ═══
  Future<void> sendVoiceCommand(String command) async {
    if (_isMockMode) {
      debugPrint('🔊 Commande vocale simulée : $command');
      return;
    }

    // Activé quand tu as l'ESP32 :
    /*
    if (!isConnected || _watch == null) return;
    List<dynamic> services = await _watch!.discoverServices();
    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.uuid.toString() == kVoiceCharUUID) {
          await c.write(command.codeUnits);
        }
      }
    }
    */
  }
}