import 'dart:math';

// ═══════════════════════════════════════════════
// Service de géolocalisation intérieure par BLE
// Trilatération à partir de 3 beacons ESP32 fixes
// ═══════════════════════════════════════════════

class LocationService {
  // ═══ Position des beacons dans l'EHPAD (en mètres) ═══
  // À ajuster selon ton plan réel quand tu poses les beacons
  static const Map<String, Map<String, double>> beaconPositions = {
    'BEACON-A': {'x': 0.0,  'y': 0.0},
    'BEACON-B': {'x': 10.0, 'y': 0.0},
    'BEACON-C': {'x': 5.0,  'y': 8.0},
  };

  // ═══ Zones définies dans l'EHPAD ═══
  static const List<Map<String, dynamic>> zones = [
    {
      'nom': 'Chambre 312',
      'xMin': 0.0, 'xMax': 4.0,
      'yMin': 0.0, 'yMax': 3.0,
    },
    {
      'nom': 'Hall',
      'xMin': 0.0, 'xMax': 10.0,
      'yMin': 3.0, 'yMax': 5.0,
    },
    {
      'nom': 'Salle à manger',
      'xMin': 5.0, 'xMax': 10.0,
      'yMin': 5.0, 'yMax': 8.0,
    },
    {
      'nom': 'Salle de repos',
      'xMin': 0.0, 'xMax': 5.0,
      'yMin': 5.0, 'yMax': 8.0,
    },
    {
      'nom': 'Couloir',
      'xMin': 0.0, 'xMax': 10.0,
      'yMin': 7.0, 'yMax': 8.0,
    },
  ];

  // ═══ Convertit RSSI en distance (mètres) ═══
  static double rssiToDistance(int rssi, {int txPower = -59}) {
    if (rssi == 0) return -1;
    double ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) return pow(ratio, 10).toDouble();
    return 0.89976 * pow(ratio, 7.7095) + 0.111;
  }

  // ═══ Trilatération : calcule position XY ═══
  static Map<String, double> trilaterate(
      Map<String, double> distances) {
    double ax = beaconPositions['BEACON-A']!['x']!;
    double ay = beaconPositions['BEACON-A']!['y']!;
    double bx = beaconPositions['BEACON-B']!['x']!;
    double by = beaconPositions['BEACON-B']!['y']!;
    double cx = beaconPositions['BEACON-C']!['x']!;
    double cy = beaconPositions['BEACON-C']!['y']!;

    double dA = distances['BEACON-A'] ?? 5;
    double dB = distances['BEACON-B'] ?? 5;
    double dC = distances['BEACON-C'] ?? 5;

    double A = 2 * (bx - ax), B = 2 * (by - ay);
    double C = dA * dA - dB * dB - ax * ax + bx * bx
        - ay * ay + by * by;
    double D = 2 * (cx - bx), E = 2 * (cy - by);
    double F = dB * dB - dC * dC - bx * bx + cx * cx
        - by * by + cy * cy;

    double x = (C * E - F * B) / (E * A - B * D);
    double y = (C * D - A * F) / (B * D - A * E);

    return {'x': x.clamp(0, 10), 'y': y.clamp(0, 8)};
  }

  // ═══ Détermine la zone à partir de la position ═══
  static String getZone(double x, double y) {
    for (var zone in zones) {
      if (x >= zone['xMin'] && x <= zone['xMax'] &&
          y >= zone['yMin'] && y <= zone['yMax']) {
        return zone['nom'];
      }
    }
    return 'Zone inconnue';
  }

  // ═══ Vérifie si le patient est dans une zone autorisée ═══
  static bool isInAuthorizedZone(
      double x, double y, List<String> authorizedZones) {
    String currentZone = getZone(x, y);
    return authorizedZones.contains(currentZone);
  }
}