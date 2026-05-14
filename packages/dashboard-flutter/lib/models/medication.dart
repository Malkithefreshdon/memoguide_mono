class Medication {
  final String nom;
  final String dosage;
  final String horaire;
  final String couleur;

  const Medication({
    required this.nom,
    required this.dosage,
    required this.horaire,
    this.couleur = '#C8185A',
  });
}
