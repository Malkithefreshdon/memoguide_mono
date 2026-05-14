class ScheduleItem {
  final String id;
  final String patientId;
  final String titre;
  final String heureDebut;
  final String? heureFin;
  final String couleur;
  final String icone;

  ScheduleItem({
    required this.id,
    required this.patientId,
    required this.titre,
    required this.heureDebut,
    this.heureFin,
    this.couleur = '#4CAF50',
    this.icone = 'event',
  });
}