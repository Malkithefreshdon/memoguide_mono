class Patient {
  final String id;
  final String nom;
  final String prenom;
  final String chambre;
  final int age;
  final String unite;
  final String dateNaissance;
  final String contactUrgence;
  final List<String> allergies;
  final List<String> pathologies;

  int heartRate;
  int spO2;
  double temperature;
  bool fallDetected;
  double posX;
  double posY;
  String zone;
  String humeur;
  String currentLocation;

  Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.chambre,
    this.age = 80,
    this.unite = 'Unité Alzheimer',
    this.dateNaissance = '01 Jan 1945',
    this.contactUrgence = 'Contact non renseigné',
    this.allergies = const [],
    this.pathologies = const ['Maladie d\'Alzheimer'],
    this.heartRate = 72,
    this.spO2 = 97,
    this.temperature = 36.8,
    this.fallDetected = false,
    this.posX = 5.0,
    this.posY = 4.0,
    this.zone = 'Chambre',
    this.humeur = 'Calme',
    this.currentLocation = 'Chambre',
  });

  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';

  String get statusType {
    if (fallDetected) return 'alert';
    if (heartRate > 120 || heartRate < 50) return 'alert';
    if (zone.contains('Couloir') ||
        zone.contains('Hall') ||
        zone.contains('Lounge') ||
        zone.contains('Jardin') ||
        zone.contains('Corridor') ||
        zone.contains('Salle commune')) return 'moving';
    return 'safe';
  }

  String get statusLabel {
    switch (statusType) {
      case 'alert':
        return 'Alert';
      case 'moving':
        return 'Moving';
      default:
        return 'Safe';
    }
  }

  String get statutLabel => statusLabel;
}
