import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';

class NewAlertScreen extends StatefulWidget {
  final Patient patient;
  const NewAlertScreen({super.key, required this.patient});

  @override
  State<NewAlertScreen> createState() => _NewAlertScreenState();
}

class _NewAlertScreenState extends State<NewAlertScreen> {
  String _incidentType = 'fall';
  String _urgencyLevel = 'immediate';
  final _detailsCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _send(AppState state) async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    state.simulateFall(widget.patient.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alerte envoyée avec succès'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
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
        title: const Text('Nouvelle Alerte',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 18, color: AppColors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PatientChip(patient: widget.patient)
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            _SectionTitle(number: 1, label: 'Type d\'incident')
                .animate()
                .fadeIn(delay: 60.ms, duration: 300.ms),
            const SizedBox(height: 12),
            _IncidentGrid(
              selected: _incidentType,
              onSelect: (v) => setState(() => _incidentType = v),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 20),
            _SectionTitle(number: 2, label: 'Niveau d\'urgence')
                .animate()
                .fadeIn(delay: 160.ms, duration: 300.ms),
            const SizedBox(height: 12),
            _UrgencyRow(
              selected: _urgencyLevel,
              onSelect: (v) => setState(() => _urgencyLevel = v),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 20),
            _SectionTitle(
                    number: 3, label: 'Détails & Localisation')
                .animate()
                .fadeIn(delay: 260.ms, duration: 300.ms),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Où se trouve le patient ?',
                hintStyle: const TextStyle(
                    color: AppColors.textGrey, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                      BorderSide(color: AppColors.blue.withOpacity(0.5)),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 28),
            _SendButton(
              sending: _sending,
              onTap: () => _send(state),
            )
                .animate()
                .fadeIn(delay: 360.ms, duration: 300.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 360.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _PatientChip extends StatelessWidget {
  final Patient patient;
  const _PatientChip({required this.patient});

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Center(
              child: Text(patient.initiales,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${patient.prenom} ${patient.nom}',
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text('Chambre ${patient.chambre} • ${patient.age} ans',
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final int number;
  final String label;
  const _SectionTitle({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}

class _IncidentGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _IncidentGrid({required this.selected, required this.onSelect});

  static const _incidents = [
    _IncidentDef(id: 'fall', label: 'Chute', icon: Icons.accessibility_new_rounded, color: AppColors.blue),
    _IncidentDef(id: 'escape', label: 'Fugue', icon: Icons.directions_run_rounded, color: AppColors.orange),
    _IncidentDef(id: 'pain', label: 'Douleur', icon: Icons.sentiment_dissatisfied_rounded, color: AppColors.textGreyDark),
    _IncidentDef(id: 'other', label: 'Autre', icon: Icons.more_horiz_rounded, color: AppColors.textGreyDark),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: _incidents
          .map((inc) => _IncidentTile(
                def: inc,
                isSelected: selected == inc.id,
                onTap: () => onSelect(inc.id),
              ))
          .toList(),
    );
  }
}

class _IncidentDef {
  final String id, label;
  final IconData icon;
  final Color color;
  const _IncidentDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _IncidentTile extends StatefulWidget {
  final _IncidentDef def;
  final bool isSelected;
  final VoidCallback onTap;
  const _IncidentTile({required this.def, required this.isSelected, required this.onTap});
  @override
  State<_IncidentTile> createState() => _IncidentTileState();
}

class _IncidentTileState extends State<_IncidentTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? widget.def.color : AppColors.textGreyDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.def.color.withOpacity(0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.def.color
                  : AppColors.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.def.icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(widget.def.label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgencyRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _UrgencyRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UrgencyChip(
            id: 'immediate',
            label: 'Immédiate',
            color: AppColors.red,
            selected: selected == 'immediate',
            onTap: () => onSelect('immediate'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _UrgencyChip(
            id: 'important',
            label: 'Importante',
            color: const Color(0xFFF59E0B),
            selected: selected == 'important',
            onTap: () => onSelect('important'),
          ),
        ),
      ],
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String id, label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _UrgencyChip({required this.id, required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? color : AppColors.textGreyDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onTap;
  const _SendButton({required this.sending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.red.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sending)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            else ...[
              const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('Envoyer l\'alerte immédiate',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
