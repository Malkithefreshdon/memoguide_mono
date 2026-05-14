import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/medication.dart';
import '../services/app_state.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';
import 'main_scaffold.dart';
import 'new_alert_screen.dart';
import 'humeur_screen.dart';
import 'edt_screen.dart';

class PatientFiche extends StatelessWidget {
  final Patient patient;
  const PatientFiche({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final p =
            state.patients.firstWhere((x) => x.id == patient.id);
        final statusColor = _statusColor(p.statusType);
        final meds = MockDataService.getMedications(p.id);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('${p.prenom} ${p.nom}',
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textGrey),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PatientHeader(patient: p)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(
                        begin: -0.04,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                _TransmissionsCard(patient: p)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms),
                const SizedBox(height: 12),
                _EmotionalQuickCard(patient: p)
                    .animate()
                    .fadeIn(delay: 115.ms, duration: 350.ms),
                const SizedBox(height: 12),
                _VitauxCard(patient: p)
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 350.ms),
                const SizedBox(height: 12),
                _MedsCard(meds: meds)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 350.ms),
                const SizedBox(height: 12),
                _InfoPersoCard(patient: p)
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 350.ms),
                const SizedBox(height: 12),
                _LocalisationCard(patient: p)
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 350.ms),
                const SizedBox(height: 20),
                _OuvrirCarteButton(
                  onTap: () {
                    state.selectPatient(p.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const MainScaffold(initialIndex: 1)),
                    );
                  },
                )
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 350.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        delay: 380.ms,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: AppColors.red,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => NewAlertScreen(patient: p)),
            ),
            child:
                const Icon(Icons.warning_amber, color: Colors.white),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'alert':
        return AppColors.red;
      case 'moving':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.green;
    }
  }
}

class _PatientHeader extends StatelessWidget {
  final Patient patient;
  const _PatientHeader({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              _Avatar(patient: patient, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${patient.prenom} ${patient.nom}',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                        '${patient.age} ans • ${patient.dateNaissance}',
                        style: const TextStyle(
                            color: AppColors.textGreyDark,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.medical_information_outlined,
                            size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              patient.pathologies.isNotEmpty
                                  ? patient.pathologies.first
                                  : '',
                              style: const TextStyle(
                                  color: AppColors.textGreyDark,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Ch. ${patient.chambre}',
                    style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (patient.pathologies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: patient.pathologies
                  .map((t) => _Tag(t, color: AppColors.pink))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransmissionsCard extends StatelessWidget {
  final Patient patient;
  const _TransmissionsCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transmissions',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              GestureDetector(
                onTap: () => _showAddTransmission(context),
                child: const Text('+ Ajouter',
                    style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Aucune transmission pour aujourd\'hui.',
              style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransmission(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Nouvelle transmission',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppColors.textGrey, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Décrivez l\'observation ou le message à transmettre...',
                  hintStyle: const TextStyle(
                      color: AppColors.textGrey, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Transmission enregistrée'),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionalQuickCard extends StatelessWidget {
  final Patient patient;
  const _EmotionalQuickCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text('État & Emploi du temps',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  icon: Icons.mood_rounded,
                  label: 'Humeur',
                  sub: patient.humeur.isNotEmpty
                      ? patient.humeur
                      : 'Non renseignée',
                  color: AppColors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            HumeurScreen(patient: patient)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Emploi du temps',
                  sub: 'Voir le planning',
                  color: AppColors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EdtScreen(patient: patient)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatefulWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<_QuickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.96 : 1.0),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon,
                  size: 16, color: widget.color),
            ),
            const SizedBox(height: 8),
            Text(widget.label,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text(widget.sub,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _VitauxCard extends StatelessWidget {
  final Patient patient;
  const _VitauxCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final bpmOk =
        patient.heartRate >= 50 && patient.heartRate <= 120;
    final spo2Ok = patient.spO2 >= 95;
    final tempOk =
        patient.temperature >= 36.0 && patient.temperature <= 37.5;

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Signes Vitaux',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Row(
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Mis à jour il y a 3 min',
                      style: TextStyle(
                          color: AppColors.textGrey, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _VitalBox(
                  label: 'Rythme Cardiaque',
                  icon: Icons.favorite,
                  iconColor: AppColors.pink,
                  value: '${patient.heartRate}',
                  unit: 'bpm',
                  status: bpmOk ? 'Normal' : 'Anormal',
                  statusOk: bpmOk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VitalBox(
                  label: 'SpO₂',
                  icon: Icons.air_outlined,
                  iconColor: AppColors.blue,
                  value: '${patient.spO2}',
                  unit: '%',
                  status: spo2Ok ? 'Normal' : 'Bas',
                  statusOk: spo2Ok,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VitalBox(
            label: 'Température',
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFFF59E0B),
            value: patient.temperature.toStringAsFixed(1),
            unit: '°C',
            status: tempOk ? 'Normal' : 'Anormal',
            statusOk: tempOk,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _VitalBox extends StatelessWidget {
  final String label, value, unit, status;
  final IconData icon;
  final Color iconColor;
  final bool statusOk;
  final bool wide;
  const _VitalBox({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusOk,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textGreyDark,
                        fontSize: 12)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text('$value $unit',
                      key: ValueKey(value),
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(status,
                    style: TextStyle(
                        color: statusOk
                            ? AppColors.green
                            : AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 13, color: iconColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.textGreyDark,
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: RichText(
                    key: ValueKey(value),
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: value,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                                color: AppColors.textGreyDark,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(status,
                    style: TextStyle(
                        color:
                            statusOk ? AppColors.green : AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}

class _MedsCard extends StatelessWidget {
  final List<Medication> meds;
  const _MedsCard({required this.meds});

  Color _medColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Médicaments',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Gestion des médicaments disponible prochainement'),
                    backgroundColor: AppColors.blue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                child: const Text('+ Ajouter/Modifier',
                    style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < meds.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _MedRow(med: meds[i], color: _medColor(meds[i].couleur))
                .animate()
                .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                .slideX(
                    begin: -0.04,
                    end: 0,
                    delay: (i * 60).ms,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  final Medication med;
  final Color color;
  const _MedRow({required this.med, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.medication_outlined,
              size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(med.nom,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text(med.horaire,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(med.dosage,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _InfoPersoCard extends StatelessWidget {
  final Patient patient;
  const _InfoPersoCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text('Informations Personnelles',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.cake_outlined,
            iconColor: AppColors.blue,
            child: Row(
              children: [
                Text(patient.dateNaissance,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${patient.age} ans',
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          _InfoRow(
            icon: Icons.phone_outlined,
            iconColor: AppColors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(patient.contactUrgence,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textGrey),
              ],
            ),
          ),
          if (patient.allergies.isNotEmpty) ...[
            const Divider(height: 16),
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              iconColor: AppColors.red,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: patient.allergies
                    .map((a) => _Tag(a,
                        color: AppColors.red, small: true))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _LocalisationCard extends StatelessWidget {
  final Patient patient;
  const _LocalisationCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Localisation Actuelle',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle,
                        size: 6, color: AppColors.green),
                    SizedBox(width: 4),
                    Text('En direct',
                        style: TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.blue),
              const SizedBox(width: 4),
              Text(patient.zone,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 100,
              color: const Color(0xFFE9EEF4),
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  final px =
                      ((patient.posX / 10.0) * w).clamp(12.0, w - 36);
                  final py =
                      ((patient.posY / 8.0) * h).clamp(12.0, h - 36);
                  return Stack(
                    children: [
                      Positioned(
                          left: 8,
                          top: 8,
                          child: _MiniRoomLabel('Chambre ${patient.chambre}')),
                      Positioned(
                          left: 8,
                          bottom: 8,
                          child: _MiniRoomLabel('Poste de soin')),
                      Positioned(
                          right: 8,
                          bottom: 8,
                          child: _MiniRoomLabel('Couloir')),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        left: px,
                        top: py,
                        child: _MiniPin(patient: patient),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoomLabel extends StatelessWidget {
  final String label;
  const _MiniRoomLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: AppColors.blue,
          fontSize: 8,
          fontWeight: FontWeight.w500));
}

class _MiniPin extends StatelessWidget {
  final Patient patient;
  const _MiniPin({required this.patient});
  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.blue,
      AppColors.pink,
      AppColors.orange,
      AppColors.green,
    ];
    final color = colors[patient.id.hashCode.abs() % colors.length];
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Center(
        child: Text(patient.initiales,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _OuvrirCarteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OuvrirCarteButton({required this.onTap});
  @override
  State<_OuvrirCarteButton> createState() => _OuvrirCarteButtonState();
}

class _OuvrirCarteButtonState extends State<_OuvrirCarteButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppColors.pink.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ouvrir la carte',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Patient patient;
  final double size;
  const _Avatar({required this.patient, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.blue,
      AppColors.pink,
      AppColors.orange,
      AppColors.green,
    ];
    final color = colors[patient.id.hashCode.abs() % colors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.8), color],
        ),
      ),
      child: Center(
        child: Text(patient.initiales,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Tag(this.label, {required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600)),
    );
  }
}
