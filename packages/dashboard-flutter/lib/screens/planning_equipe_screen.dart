import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class PlanningEquipeScreen extends StatefulWidget {
  const PlanningEquipeScreen({super.key});

  @override
  State<PlanningEquipeScreen> createState() =>
      _PlanningEquipeScreenState();
}

class _PlanningEquipeScreenState extends State<PlanningEquipeScreen>
    with SingleTickerProviderStateMixin {
  bool _isWeekView = false;
  DateTime _currentDate = DateTime.now();

  late AnimationController _toggleCtrl;

  @override
  void initState() {
    super.initState();
    _toggleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _toggleCtrl.dispose();
    super.dispose();
  }

  static const _members = [
    _MemberShift(
        name: 'Sophie Martin',
        role: 'Infirmière',
        shift: 'Matin (07h–15h)',
        color: AppColors.blue,
        present: true),
    _MemberShift(
        name: 'Pierre Dubois',
        role: 'Aide-soignant',
        shift: 'Après-midi (15h–23h)',
        color: AppColors.pink,
        present: true),
    _MemberShift(
        name: 'Nadège Koné',
        role: 'Infirmière',
        shift: 'Nuit (23h–07h)',
        color: const Color(0xFF8B5CF6),
        present: true),
    _MemberShift(
        name: 'Jean-Paul Renard',
        role: 'Aide-soignant',
        shift: 'Congé',
        color: AppColors.textGrey,
        present: false),
    _MemberShift(
        name: 'Marie Fonteneau',
        role: 'Infirmière',
        shift: 'Matin (07h–15h)',
        color: AppColors.green,
        present: true),
  ];

  String _formatDate(DateTime d) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
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
        title: const Text('Planning équipe',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Jour/Semaine + date nav
            Row(
              children: [
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _ToggleBtn(
                        label: 'Jour',
                        active: !_isWeekView,
                        onTap: () =>
                            setState(() => _isWeekView = false),
                      ),
                      _ToggleBtn(
                        label: 'Semaine',
                        active: _isWeekView,
                        onTap: () =>
                            setState(() => _isWeekView = true),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _currentDate = _currentDate.subtract(
                        Duration(days: _isWeekView ? 7 : 1));
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.chevron_left,
                        size: 16, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_formatDate(_currentDate),
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _currentDate = _currentDate
                        .add(Duration(days: _isWeekView ? 7 : 1));
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textGrey),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),

            // Coverage
            _CoverageCard()
                .animate()
                .fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 16),

            // Absences banner
            _AbsenceBanner()
                .animate()
                .fadeIn(delay: 140.ms, duration: 350.ms),
            const SizedBox(height: 16),

            // Members timeline
            const Text('Plannings du jour',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14))
                .animate()
                .fadeIn(delay: 180.ms, duration: 300.ms),
            const SizedBox(height: 10),
            for (int i = 0; i < _members.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShiftCard(member: _members[i])
                    .animate()
                    .fadeIn(delay: (200 + i * 60).ms, duration: 300.ms)
                    .slideX(
                        begin: 0.06,
                        end: 0,
                        delay: (200 + i * 60).ms,
                        duration: 300.ms,
                        curve: Curves.easeOutCubic),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textGreyDark,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Row(
            children: [
              Text('Couverture du service',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Spacer(),
              Text('75%',
                  style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.green),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _CoverStat(
                  label: 'En poste', value: '9', color: AppColors.green),
              const SizedBox(width: 16),
              _CoverStat(
                  label: 'Absents', value: '2', color: AppColors.red),
              const SizedBox(width: 16),
              _CoverStat(
                  label: 'En pause',
                  value: '1',
                  color: AppColors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CoverStat(
      {required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$value $label',
            style: const TextStyle(
                color: AppColors.textGreyDark, fontSize: 11)),
      ],
    );
  }
}

class _AbsenceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('1 absence non remplacée · Jean-Paul Renard',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          const Text('Gérer',
              style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final _MemberShift member;
  const _ShiftCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: member.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(
                    color: member.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(member.role,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: member.present
                  ? member.color.withOpacity(0.1)
                  : AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(member.shift,
                style: TextStyle(
                    color: member.present
                        ? member.color
                        : AppColors.textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MemberShift {
  final String name, role, shift;
  final Color color;
  final bool present;
  const _MemberShift({
    required this.name,
    required this.role,
    required this.shift,
    required this.color,
    required this.present,
  });
}
