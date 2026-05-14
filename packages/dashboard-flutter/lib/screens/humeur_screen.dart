import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';

class HumeurScreen extends StatefulWidget {
  final Patient patient;
  const HumeurScreen({super.key, required this.patient});

  @override
  State<HumeurScreen> createState() => _HumeurScreenState();
}

class _HumeurScreenState extends State<HumeurScreen> {
  String _selected = 'bien';
  double _intensite = 7;
  final Set<String> _tags = {'Sommeil'};
  final _notesCtrl = TextEditingController();

  static const _humeurs = [
    _HumeurDef(id: 'tres_bien', label: 'Très bien', emoji: '😊'),
    _HumeurDef(id: 'bien', label: 'Bien', emoji: '😊'),
    _HumeurDef(id: 'neutre', label: 'Neutre', emoji: '😐'),
    _HumeurDef(id: 'anxieux', label: 'Anxieux', emoji: '😰'),
    _HumeurDef(id: 'triste', label: 'Triste', emoji: '😢'),
  ];

  static const _tagsDisponibles = [
    'Douleur',
    'Sommeil',
    'Appétit',
    'Interactions',
    'Agitation',
    'Confusion',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          children: [
            const Text('Humeur du patient',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('${widget.patient.prenom} ${widget.patient.nom}',
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comment évaluez-vous son humeur ?',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15))
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            _HumeurGrid(
              humeurs: _humeurs,
              selected: _selected,
              onSelect: (v) => setState(() => _selected = v),
            )
                .animate()
                .fadeIn(delay: 60.ms, duration: 300.ms),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intensité de l\'état',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_intensite.round()}/10',
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: AppColors.blueLight,
                thumbColor: AppColors.blue,
                overlayColor: AppColors.blue.withOpacity(0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: _intensite,
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (v) => setState(() => _intensite = v),
              ),
            ).animate().fadeIn(delay: 140.ms),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Léger (0)',
                    style: TextStyle(
                        color: AppColors.textGrey, fontSize: 11)),
                Text('Fort (10)',
                    style: TextStyle(
                        color: AppColors.textGrey, fontSize: 11)),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),
            const Text('Notes rapides & Observations',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14))
                .animate()
                .fadeIn(delay: 180.ms),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagsDisponibles.map((tag) {
                final active = _tags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (active) {
                      _tags.remove(tag);
                    } else {
                      _tags.add(tag);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.blue.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AppColors.blue
                              : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          const Icon(Icons.check,
                              size: 12, color: AppColors.blue),
                          const SizedBox(width: 4),
                        ] else ...[
                          const Text('+ ',
                              style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 12)),
                        ],
                        Text(tag,
                            style: TextStyle(
                                color: active
                                    ? AppColors.blue
                                    : AppColors.textGreyDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Ajoutez des détails sur l\'état du patient, des événements marquants...',
                hintStyle: const TextStyle(
                    color: AppColors.textGrey, fontSize: 12),
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
                  borderSide: BorderSide(
                      color: AppColors.blue.withOpacity(0.4)),
                ),
              ),
            ).animate().fadeIn(delay: 240.ms),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler',
                        style: TextStyle(
                            color: AppColors.textGreyDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final state = context.read<AppState>();
                      final humeurLabel = _humeurs
                          .firstWhere((h) => h.id == _selected)
                          .label;
                      final p = state.patients
                          .firstWhere((x) => x.id == widget.patient.id);
                      p.humeur = humeurLabel;
                      state.notifyListenersPublic();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Humeur enregistrée avec succès'),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Enregistrer',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 280.ms),
          ],
        ),
      ),
    );
  }
}

class _HumeurGrid extends StatelessWidget {
  final List<_HumeurDef> humeurs;
  final String selected;
  final ValueChanged<String> onSelect;
  const _HumeurGrid(
      {required this.humeurs,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: humeurs
          .map((h) => _HumeurChip(
                def: h,
                isSelected: selected == h.id,
                onTap: () => onSelect(h.id),
              ))
          .toList(),
    );
  }
}

class _HumeurChip extends StatelessWidget {
  final _HumeurDef def;
  final bool isSelected;
  final VoidCallback onTap;
  const _HumeurChip(
      {required this.def,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pink.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isSelected ? AppColors.pink : AppColors.border,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(def.label,
                style: TextStyle(
                    color: isSelected
                        ? AppColors.pink
                        : AppColors.textGreyDark,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _HumeurDef {
  final String id, label, emoji;
  const _HumeurDef(
      {required this.id, required this.label, required this.emoji});
}
