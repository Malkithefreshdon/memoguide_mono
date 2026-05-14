import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'patient_fiche.dart';

class ResidentsTab extends StatefulWidget {
  const ResidentsTab({super.key});

  @override
  State<ResidentsTab> createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<ResidentsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final list = state.patients.where((p) {
          final q = _query.toLowerCase();
          return q.isEmpty ||
              p.nom.toLowerCase().contains(q) ||
              p.prenom.toLowerCase().contains(q) ||
              p.chambre.contains(q);
        }).toList();
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            title: const Text('Résidents',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _SearchField(
                  onChanged: (v) => setState(() => _query = v),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${list.length} résidents',
                      style: const TextStyle(
                          color: AppColors.textGreyDark,
                          fontSize: 12)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text('Aucun résident',
                              style: const TextStyle(
                                  color: AppColors.textGrey)),
                        )
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final p = list[i];
                            return _ResidentCard(
                              patient: p,
                              onTap: () {
                                state.selectPatient(p.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PatientFiche(patient: p)),
                                );
                              },
                            )
                                .animate()
                                .fadeIn(
                                    delay: (i * 70).ms,
                                    duration: 350.ms)
                                .slideX(
                                    begin: 0.1,
                                    end: 0,
                                    delay: (i * 70).ms,
                                    duration: 350.ms,
                                    curve: Curves.easeOutCubic);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _node = FocusNode();
  bool _focus = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(
        () => setState(() => _focus = _node.hasFocus));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: _focus
                ? AppColors.blue.withOpacity(0.5)
                : AppColors.border),
        boxShadow: _focus
            ? [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: TextField(
        focusNode: _node,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un résident',
          hintStyle: const TextStyle(
              color: AppColors.textGrey, fontSize: 13),
          prefixIcon: Icon(Icons.search,
              color: _focus
                  ? AppColors.blue
                  : AppColors.textGrey,
              size: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _ResidentCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;
  const _ResidentCard({required this.patient, required this.onTap});

  @override
  State<_ResidentCard> createState() => _ResidentCardState();
}

class _ResidentCardState extends State<_ResidentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final secure = !p.fallDetected &&
        p.heartRate >= 50 &&
        p.heartRate <= 120;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.97 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'avatar-${p.id}',
                child: _AvatarBig(patient: p),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.prenom} ${p.nom}',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${p.age} ans • Ch. ${p.chambre}',
                        style: const TextStyle(
                            color: AppColors.textGreyDark,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 300),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: secure
                                ? AppColors.green
                                : AppColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(p.statutLabel,
                            style: TextStyle(
                                color: secure
                                    ? AppColors.green
                                    : AppColors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        const Icon(Icons.favorite,
                            size: 12, color: AppColors.pink),
                        const SizedBox(width: 3),
                        Text('${p.heartRate} bpm',
                            style: const TextStyle(
                                color: AppColors.pink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBig extends StatelessWidget {
  final Patient patient;
  const _AvatarBig({required this.patient});

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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.85), color],
        ),
      ),
      child: Center(
        child: Text(patient.initiales,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
