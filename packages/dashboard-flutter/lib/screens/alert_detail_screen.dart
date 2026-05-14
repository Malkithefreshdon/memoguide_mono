import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../theme.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  Color _alertColor(String type) {
    switch (type) {
      case 'fall':
        return AppColors.red;
      case 'heart_rate':
        return AppColors.pink;
      case 'zone_exit':
        return AppColors.orange;
      default:
        return AppColors.blue;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'fall':
        return Icons.man_rounded;
      case 'heart_rate':
        return Icons.favorite;
      case 'zone_exit':
        return Icons.logout;
      default:
        return Icons.info_outline;
    }
  }

  String _alertLabel(String type) {
    switch (type) {
      case 'fall':
        return 'Chute détectée';
      case 'heart_rate':
        return 'Alerte cardiaque';
      case 'zone_exit':
        return 'Sortie de zone';
      default:
        return 'Alerte';
    }
  }

  String _alertDescription(String type) {
    switch (type) {
      case 'fall':
        return 'Une chute a été détectée par le bracelet MemoGuide. Le capteur d\'accélération a enregistré un impact brutal suivi d\'une immobilité prolongée.';
      case 'heart_rate':
        return 'Le rythme cardiaque du patient est en dehors des valeurs normales. Une surveillance rapprochée est recommandée. Vérifiez l\'état général du patient.';
      case 'zone_exit':
        return 'Le patient a quitté sa zone autorisée. Sa localisation actuelle ne correspond pas aux zones définies dans son dossier. Une intervention peut être nécessaire.';
      default:
        return 'Une alerte a été générée par le système MemoGuide. Veuillez vérifier l\'état du patient et prendre les mesures nécessaires.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);
    final icon = _alertIcon(alert.type);
    final label = _alertLabel(alert.type);
    final desc = _alertDescription(alert.type);
    final dateStr =
        DateFormat('dd/MM/yyyy à HH:mm').format(alert.createdAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Détail de l\'alerte',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppColors.textGreyDark,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!alert.lu)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Nouveau',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(
                    begin: -0.04,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 20),

            // Patient info
            _SectionCard(
              title: 'Patient concerné',
              child: Row(
                children: [
                  _Avatar(name: alert.patientNom),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.patientNom,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Text('Patient ID : #${alert.patientId}',
                            style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 12),

            // Description
            _SectionCard(
              title: 'Détails cliniques',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.message,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(desc,
                      style: const TextStyle(
                          color: AppColors.textGreyDark,
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 140.ms, duration: 350.ms),
            const SizedBox(height: 12),

            // Timeline / Historique
            _SectionCard(
              title: 'Historique de l\'événement',
              child: Column(
                children: [
                  _TimelineItem(
                    time: DateFormat('HH:mm').format(alert.createdAt),
                    label: 'Alerte générée',
                    sub: 'Détectée par le bracelet MemoGuide',
                    color: color,
                    isFirst: true,
                  ),
                  _TimelineItem(
                    time: DateFormat('HH:mm').format(
                        alert.createdAt.add(const Duration(minutes: 1))),
                    label: 'Notification envoyée',
                    sub: 'Infirmier de garde notifié',
                    color: AppColors.blue,
                  ),
                  _TimelineItem(
                    time: alert.lu
                        ? DateFormat('HH:mm').format(
                            alert.createdAt.add(const Duration(minutes: 3)))
                        : '--:--',
                    label: alert.lu ? 'Alerte lue' : 'En attente de lecture',
                    sub: alert.lu
                        ? 'Prise en charge confirmée'
                        : 'Aucune action enregistrée',
                    color:
                        alert.lu ? AppColors.green : AppColors.textGrey,
                    isLast: true,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: 12),

            // Actions recommandées
            _SectionCard(
              title: 'Actions recommandées',
              child: Column(
                children: _actionsFor(alert.type)
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  e.key < _actionsFor(alert.type).length - 1
                                      ? 8
                                      : 0),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.pink.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          color: AppColors.pink,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(
                                        color: AppColors.textGreyDark,
                                        fontSize: 13,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            )
                .animate()
                .fadeIn(delay: 260.ms, duration: 350.ms),
            const SizedBox(height: 28),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Accuser réception',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 320.ms, duration: 350.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 320.ms,
                    duration: 350.ms,
                    curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }

  List<String> _actionsFor(String type) {
    switch (type) {
      case 'fall':
        return [
          'Se rendre immédiatement auprès du patient',
          'Évaluer les éventuelles blessures et appeler les secours si nécessaire',
          'Renseigner l\'incident dans le dossier patient',
          'Informer le médecin de garde et la famille',
        ];
      case 'heart_rate':
        return [
          'Vérifier l\'état général du patient (conscience, douleurs)',
          'Mesurer manuellement la fréquence cardiaque et la tension',
          'Contacter le médecin de garde si les valeurs persistent',
          'Renseigner l\'observation dans le dossier patient',
        ];
      case 'zone_exit':
        return [
          'Localiser le patient sur la carte de l\'établissement',
          'Se rendre auprès du patient pour le raccompagner',
          'Évaluer son état émotionnel et mental',
          'Informer l\'équipe et revoir les autorisations de zone si nécessaire',
        ];
      default:
        return [
          'Évaluer la situation du patient',
          'Renseigner l\'incident dans le dossier',
          'Informer le médecin de garde si nécessaire',
        ];
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pink.withOpacity(0.7), AppColors.pink],
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time, label, sub;
  final Color color;
  final bool isFirst, isLast;
  const _TimelineItem({
    required this.time,
    required this.label,
    required this.sub,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 12, color: AppColors.border),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 12, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(sub,
                    style: const TextStyle(
                        color: AppColors.textGreyDark, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
