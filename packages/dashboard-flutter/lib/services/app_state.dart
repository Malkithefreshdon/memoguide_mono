import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/alert.dart';
import '../models/schedule.dart';
import 'mock_data_service.dart';
import 'ble_service.dart';
import 'location_service.dart';

class AppState extends ChangeNotifier {
  List<Patient> patients = [];
  List<AlertModel> alerts = [];
  int get unreadAlerts => alerts.where((a) => !a.lu).length;

  String? _selectedPatientId;
  Patient get selectedPatient {
    if (_selectedPatientId == null && patients.isNotEmpty) {
      _selectedPatientId = patients.first.id;
    }
    return patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => patients.first,
    );
  }

  void selectPatient(String id) {
    _selectedPatientId = id;
    notifyListeners();
  }

  late Timer _simulationTimer;
  final Random _rand = Random();
  final BleService bleService = BleService();

  // Zones autorisées par patient
  // Clé = patientId, valeur = liste des zones autorisées
  final Map<String, List<String>> _authorizedZones = {
    '1': ['Chambre 15', 'Hall', 'Salle commune', 'Salle à manger'],
    '2': ['Chambre 07', 'Hall', 'Couloir A', 'Salle à manger'],
    '3': ['Chambre 15', 'Hall'],
    '4': ['Chambre 03', 'Hall', 'Jardin', 'Salle à manger'],
  };

  AppState() {
    patients = MockDataService.getPatients();
    alerts = MockDataService.getAlerts();

    // Connecte les callbacks BLE vers AppState
    bleService.onHeartRateReceived = (int bpm) {
      // Quand la montre envoie un BPM réel,
      // on met à jour le patient concerné
      // (patient ID sera lié à la montre plus tard)
      if (patients.isNotEmpty) {
        patients[0].heartRate = bpm;
        _checkHeartRateAlert(patients[0]);
        notifyListeners();
      }
    };

    bleService.onFallDetected = () {
      if (patients.isNotEmpty) {
        simulateFall(patients[0].id);
      }
    };

    // Démarrer le scan BLE
    // (ne fait rien sur Chrome, actif sur Android avec montre)
    bleService.startScan();

    // Simulation des données (désactivée automatiquement
    // quand le vrai BLE prend le relais)
    _simulationTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateData();
    });
  }

  void _simulateData() {
    // Si BLE connecté, on ne simule plus les données
    if (bleService.isConnected) return;

    for (var p in patients) {
      p.heartRate =
          (p.heartRate + _rand.nextInt(5) - 2).clamp(40, 160);
      p.posX = (p.posX + (_rand.nextDouble() - 0.5) * 0.3)
          .clamp(0, 10);
      p.posY = (p.posY + (_rand.nextDouble() - 0.5) * 0.3)
          .clamp(0, 8);

      // Met à jour la zone en fonction de la position
      p.zone = LocationService.getZone(p.posX, p.posY);
      p.currentLocation = p.zone;

      // Vérifie si le patient est sorti de sa zone
      _checkZoneAlert(p);
    }
    notifyListeners();
  }

  void _checkHeartRateAlert(Patient p) {
    if (p.heartRate > 120 || p.heartRate < 45) {
      _addAlert(AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: p.id,
        patientNom: '${p.prenom} ${p.nom}',
        type: 'heart_rate',
        message: 'BPM anormal : ${p.heartRate} bpm',
        createdAt: DateTime.now(),
      ));
    }
  }

  void _checkZoneAlert(Patient p) {
    final authorized = _authorizedZones[p.id] ?? [];
    if (authorized.isNotEmpty &&
        !LocationService.isInAuthorizedZone(
            p.posX, p.posY, authorized)) {
      // On évite de spammer les alertes (1 max par minute)
      final recentAlert = alerts.any((a) =>
          a.patientId == p.id &&
          a.type == 'zone_exit' &&
          DateTime.now().difference(a.createdAt).inMinutes < 1);
      if (!recentAlert) {
        _addAlert(AlertModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: p.id,
          patientNom: '${p.prenom} ${p.nom}',
          type: 'zone_exit',
          message:
              '${p.prenom} hors zone autorisée : ${p.zone}',
          createdAt: DateTime.now(),
        ));
      }
    }
  }

  void _addAlert(AlertModel alert) {
    alerts.insert(0, alert);
    notifyListeners();
  }

  void simulateFall(String patientId) {
    final p = patients.firstWhere((p) => p.id == patientId);
    p.fallDetected = true;
    _addAlert(AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      patientNom: '${p.prenom} ${p.nom}',
      type: 'fall',
      message:
          'Chute détectée — ${p.prenom} ${p.nom} ch. ${p.chambre}',
      createdAt: DateTime.now(),
    ));
    Future.delayed(const Duration(seconds: 10), () {
      p.fallDetected = false;
      notifyListeners();
    });
  }

  void markAlertRead(String alertId) {
    final a = alerts.firstWhere((a) => a.id == alertId);
    a.lu = true;
    notifyListeners();
  }

  List<ScheduleItem> getSchedule(String patientId) {
    return MockDataService.getSchedule(patientId);
  }

  // Commande vocale — BLE si montre connectée, sinon log
  void sendVoiceCommand(String patientId, String command) {
    bleService.sendVoiceCommand(command);
  }

  void notifyListenersPublic() => notifyListeners();

  // Zones autorisées d'un patient
  List<String> getAuthorizedZones(String patientId) {
    return _authorizedZones[patientId] ?? [];
  }

  // Modifier les zones autorisées d'un patient
  void setAuthorizedZones(
      String patientId, List<String> zones) {
    _authorizedZones[patientId] = zones;
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer.cancel();
    super.dispose();
  }
}