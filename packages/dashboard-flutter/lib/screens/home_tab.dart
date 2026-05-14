import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'patient_fiche.dart';
import 'profile_screen.dart';
import 'equipe_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final filtered = state.patients.where((p) {
          final q = _query.toLowerCase();
          return q.isEmpty ||
              p.nom.toLowerCase().contains(q) ||
              p.prenom.toLowerCase().contains(q) ||
              p.chambre.contains(q);
        }).toList();

        final activeAlerts = state.unreadAlerts;
        final moving = state.patients
            .where((p) => p.statusType == 'moving')
            .length;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  onProfile: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                  onEquipe: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EquipeScreen()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      const SizedBox(height: 16),
                      _Greeting()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(
                              begin: -0.05,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic),
                      const SizedBox(height: 14),
                      _SearchBar(
                        onChanged: (v) =>
                            setState(() => _query = v),
                      )
                          .animate()
                          .fadeIn(
                              delay: 80.ms, duration: 350.ms),
                      const SizedBox(height: 16),
                      _KpiRow(
                        total: state.patients.length,
                        alerts: activeAlerts,
                        moving: moving,
                      )
                          .animate()
                          .fadeIn(
                              delay: 150.ms, duration: 350.ms),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Patient List',
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.border),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.tune,
                                    size: 14,
                                    color: AppColors.textGreyDark),
                                SizedBox(width: 4),
                                Text('Filter',
                                    style: TextStyle(
                                        color:
                                            AppColors.textGreyDark,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      for (int i = 0; i < filtered.length; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: _PatientCard(
                            patient: filtered[i],
                            onTap: () {
                              state.selectPatient(filtered[i].id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PatientFiche(
                                        patient: filtered[i])),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(
                                  delay: (250 + i * 60).ms,
                                  duration: 350.ms)
                              .slideX(
                                  begin: 0.06,
                                  end: 0,
                                  delay: (250 + i * 60).ms,
                                  duration: 350.ms,
                                  curve: Curves.easeOutCubic),
                        ),
                    ],
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

class _Header extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onEquipe;
  const _Header({required this.onProfile, required this.onEquipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Image.asset('assets/logo_icon.png',
              width: 26, height: 26, errorBuilder: (_, __, ___) {
            return Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite,
                  color: Colors.white, size: 14),
            );
          }),
          const SizedBox(width: 6),
          const Text(
            'MemoGuide',
            style: TextStyle(
                color: AppColors.pink,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onEquipe,
            icon: const Icon(Icons.group_outlined,
                size: 13, color: AppColors.textGreyDark),
            label: const Text('Mon équipe',
                style: TextStyle(
                    color: AppColors.textGreyDark, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blueLight),
              child: const Icon(Icons.person_outline,
                  size: 18, color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 18
            ? 'Good afternoon,'
            : 'Good evening,';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: const TextStyle(
                color: AppColors.textGreyDark, fontSize: 13)),
        const SizedBox(height: 3),
        const Text(
          'Nurse Marie Lambert 👋',
          style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focus = false;
  final _node = FocusNode();

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
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _focus
                ? AppColors.blue.withOpacity(0.4)
                : AppColors.border),
        boxShadow: _focus
            ? [
                BoxShadow(
                    color: AppColors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      child: TextField(
        focusNode: _node,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Rechercher un patient...',
          hintStyle: const TextStyle(
              color: AppColors.textGrey, fontSize: 13),
          prefixIcon: Icon(Icons.search,
              color: _focus
                  ? AppColors.blue
                  : AppColors.textGrey,
              size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int total, alerts, moving;
  const _KpiRow(
      {required this.total,
      required this.alerts,
      required this.moving});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            value: '$total',
            label: 'Total\nPatients',
            sub: 'All monitored',
            color: AppColors.blue,
            bg: AppColors.blueLight,
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            value: '$alerts',
            label: 'Active\nAlerts',
            sub: 'Needs attention',
            color: AppColors.red,
            bg: AppColors.redLight,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            value: '$moving',
            label: 'Moving',
            sub: 'In motion',
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFF7ED),
            icon: Icons.directions_walk_rounded,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value, label, sub;
  final Color color, bg;
  final IconData icon;
  const _KpiCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(value,
                key: ValueKey(value),
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textGreyDark, fontSize: 10),
              maxLines: 2),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _pressed = false;

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

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final statusColor = _statusColor(p.statusType);

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              _Avatar(patient: p, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.prenom} ${p.nom}',
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Room ${p.chambre}',
                        style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.favorite,
                            size: 12, color: AppColors.pink),
                        const SizedBox(width: 3),
                        AnimatedSwitcher(
                          duration:
                              const Duration(milliseconds: 250),
                          child: Text('${p.heartRate} bpm',
                              key: ValueKey(p.heartRate),
                              style: const TextStyle(
                                  color: AppColors.pink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p.statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textGrey),
                      const SizedBox(width: 2),
                      Text(p.currentLocation,
                          style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
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
        child: Text(
          patient.initiales,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
