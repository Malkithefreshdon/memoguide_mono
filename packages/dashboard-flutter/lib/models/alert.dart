class AlertModel {
  final String id;
  final String patientId;
  final String patientNom;
  final String type;
  final String message;
  bool lu;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.type,
    required this.message,
    this.lu = false,
    required this.createdAt,
  });
}