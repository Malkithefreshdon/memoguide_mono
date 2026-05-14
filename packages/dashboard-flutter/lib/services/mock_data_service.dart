import '../models/patient.dart';
import '../models/alert.dart';
import '../models/schedule.dart';
import '../models/medication.dart';

class MockDataService {
  static List<Patient> getPatients() {
    return [
      Patient(
        id: '1',
        nom: 'Moreau',
        prenom: 'Henri',
        chambre: '101',
        age: 84,
        unite: 'Unité Alzheimer',
        dateNaissance: '14 Juin 1941',
        contactUrgence: 'Lucie Moreau (Fille) • +33 6 12 34 56 78',
        allergies: const ['Pénicilline', 'Aspirine'],
        pathologies: const ['Maladie d\'Alzheimer', 'Chutes fréquentes'],
        heartRate: 98,
        spO2: 95,
        temperature: 37.2,
        fallDetected: true,
        posX: 4.0,
        posY: 2.5,
        zone: 'Couloir A',
        currentLocation: 'Couloir A',
        humeur: 'Agité',
      ),
      Patient(
        id: '2',
        nom: 'Dupont',
        prenom: 'Jean',
        chambre: '104',
        age: 78,
        unite: 'Unité Alzheimer',
        dateNaissance: '02 Juillet 1946',
        contactUrgence: 'Marie Dupont (Fille) • +33 6 51 34 56 19',
        allergies: const ['Ibuprofène', 'Latex'],
        pathologies: const ['Maladie d\'Alzheimer', 'Chutes fréquentes', 'Dépression'],
        heartRate: 72,
        spO2: 97,
        temperature: 36.8,
        posX: 5.5,
        posY: 3.0,
        zone: 'Chambre 104',
        currentLocation: 'Room 104',
        humeur: 'Calme',
      ),
      Patient(
        id: '3',
        nom: 'Renard',
        prenom: 'Paul',
        chambre: '106',
        age: 81,
        unite: 'Unité Alzheimer',
        dateNaissance: '23 Mars 1943',
        contactUrgence: 'Pierre Renard (Fils) • +33 6 78 90 12 34',
        allergies: const [],
        pathologies: const ['Maladie d\'Alzheimer', 'Hypertension'],
        heartRate: 85,
        spO2: 98,
        temperature: 36.6,
        posX: 3.0,
        posY: 5.5,
        zone: 'Lounge',
        currentLocation: 'Lounge',
        humeur: 'Serein',
      ),
      Patient(
        id: '4',
        nom: 'Bernard',
        prenom: 'Simone',
        chambre: '108',
        age: 76,
        unite: 'Unité protégée',
        dateNaissance: '05 Novembre 1948',
        contactUrgence: 'Jacques Bernard (Mari) • +33 6 45 67 89 01',
        allergies: const ['Pénicilline'],
        pathologies: const ['Démence vasculaire', 'Diabète'],
        heartRate: 125,
        spO2: 94,
        temperature: 37.8,
        posX: 8.5,
        posY: 1.5,
        zone: 'Exit Zone',
        currentLocation: 'Exit Zone',
        humeur: 'Stressée',
      ),
      Patient(
        id: '5',
        nom: 'Lefebvre',
        prenom: 'Marc',
        chambre: '102',
        age: 82,
        unite: 'Unité Alzheimer',
        dateNaissance: '17 Août 1942',
        contactUrgence: 'Sophie Lefebvre (Fille) • +33 6 23 45 67 89',
        allergies: const [],
        pathologies: const ['Maladie d\'Alzheimer'],
        heartRate: 68,
        spO2: 98,
        temperature: 36.5,
        posX: 2.5,
        posY: 3.0,
        zone: 'Chambre 102',
        currentLocation: 'Room 102',
        humeur: 'Calme',
      ),
      Patient(
        id: '6',
        nom: 'Fontaine',
        prenom: 'Claire',
        chambre: '110',
        age: 79,
        unite: 'Unité Alzheimer',
        dateNaissance: '29 Janvier 1946',
        contactUrgence: 'Nathalie Fontaine (Fille) • +33 6 34 56 78 90',
        allergies: const ['Latex'],
        pathologies: const ['Maladie d\'Alzheimer', 'Arthrose'],
        heartRate: 79,
        spO2: 96,
        temperature: 36.9,
        posX: 7.0,
        posY: 6.0,
        zone: 'Jardin',
        currentLocation: 'Garden',
        humeur: 'Joyeuse',
      ),
    ];
  }

  static List<AlertModel> getAlerts() {
    return [
      AlertModel(
        id: 'a1',
        patientId: '1',
        patientNom: 'Henri Moreau',
        type: 'fall',
        message: 'Chute détectée — Henri ch. 101',
        lu: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      AlertModel(
        id: 'a2',
        patientId: '4',
        patientNom: 'Simone Bernard',
        type: 'heart_rate',
        message: 'BPM anormal : 125 bpm',
        lu: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      AlertModel(
        id: 'a3',
        patientId: '4',
        patientNom: 'Simone Bernard',
        type: 'zone_exit',
        message: 'Simone hors zone autorisée : Exit Zone',
        lu: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AlertModel(
        id: 'a4',
        patientId: '2',
        patientNom: 'Jean Dupont',
        type: 'fall',
        message: 'Chute détectée — Jean ch. 104',
        lu: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static List<Medication> getMedications(String patientId) {
    switch (patientId) {
      case '2':
        return const [
          Medication(nom: 'Aspirine', dosage: '100 mg', horaire: '08:00 — Avec le petit-déjeuner', couleur: '#EF4444'),
          Medication(nom: 'Donépézil', dosage: '5 mg', horaire: '21:00 — Avant le coucher', couleur: '#C8185A'),
          Medication(nom: 'Mémantine', dosage: '10 mg', horaire: '12:00 — Midi avec repas', couleur: '#8B5CF6'),
          Medication(nom: 'Lorazépam', dosage: '1 mg', horaire: '20:00 — Si agitation', couleur: '#F59E0B'),
        ];
      case '1':
        return const [
          Medication(nom: 'Donépézil', dosage: '10 mg', horaire: '21:00 — Avant le coucher', couleur: '#C8185A'),
          Medication(nom: 'Risperidone', dosage: '0.5 mg', horaire: '12:00 — Avec repas', couleur: '#8B5CF6'),
        ];
      default:
        return const [
          Medication(nom: 'Donépézil', dosage: '5 mg', horaire: '21:00 — Avant le coucher', couleur: '#C8185A'),
          Medication(nom: 'Paracétamol', dosage: '500 mg', horaire: '08:00 — Si douleur', couleur: '#F59E0B'),
        ];
    }
  }

  static List<ScheduleItem> getSchedule(String patientId) {
    return [
      ScheduleItem(id: 's1', patientId: patientId, titre: 'Petit-déjeuner', heureDebut: '08:00', heureFin: '08:30', couleur: '#FF9800', icone: 'repas'),
      ScheduleItem(id: 's2', patientId: patientId, titre: 'Médicaments matin', heureDebut: '09:00', couleur: '#F44336', icone: 'medicament'),
      ScheduleItem(id: 's3', patientId: patientId, titre: 'Kinésithérapie', heureDebut: '10:30', heureFin: '11:30', couleur: '#2196F3', icone: 'kine'),
      ScheduleItem(id: 's4', patientId: patientId, titre: 'Déjeuner', heureDebut: '12:00', heureFin: '13:00', couleur: '#FF9800', icone: 'repas'),
      ScheduleItem(id: 's5', patientId: patientId, titre: 'Toilette', heureDebut: '14:30', couleur: '#4CAF50', icone: 'toilette'),
      ScheduleItem(id: 's6', patientId: patientId, titre: 'Médicaments soir', heureDebut: '20:00', couleur: '#F44336', icone: 'medicament'),
    ];
  }
}
