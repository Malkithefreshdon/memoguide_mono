import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class MonPlanningScreen extends StatefulWidget {
  const MonPlanningScreen({super.key});

  @override
  State<MonPlanningScreen> createState() => _MonPlanningScreenState();
}

class _MonPlanningScreenState extends State<MonPlanningScreen> {
  DateTime _currentDate = DateTime.now();

  static const _gardes = [
    _GardeData(
        day: 'Lundi',
        date: '12 mai',
        type: 'Matin',
        hours: '07h – 15h',
        color: AppColors.blue,
        patients: 8),
    _GardeData(
        day: 'Mercredi',
        date: '14 mai',
        type: 'Après-midi',
        hours: '15h – 23h',
        color: AppColors.pink,
        patients: 6),
    _GardeData(
        day: 'Vendredi',
        date: '16 mai',
        type: 'Matin',
        hours: '07h – 15h',
        color: AppColors.blue,
        patients: 7),
    _GardeData(
        day: 'Samedi',
        date: '17 mai',
        type: 'Nuit',
        hours: '23h – 07h',
        color: const Color(0xFF8B5CF6),
        patients: 5),
  ];

  static const _tasks = [
    _TaskData(
        time: '08:00',
        title: 'Prise en charge M. Moreau',
        sub: 'Chambre 101 — Soins matinaux',
        color: AppColors.pink,
        done: true),
    _TaskData(
        time: '09:30',
        title: 'Distribution médicaments',
        sub: 'Unité 3B — 8 patients',
        color: AppColors.blue,
        done: true),
    _TaskData(
        time: '11:00',
        title: 'Visite Mme Bernard',
        sub: 'Chambre 108 — Surveillance cardiaque',
        color: AppColors.red,
        done: false),
    _TaskData(
        time: '14:00',
        title: 'Transmission équipe de l\'après-midi',
        sub: 'Salle de soins — Relève',
        color: AppColors.green,
        done: false),
    _TaskData(
        time: '14:30',
        title: 'Fin de garde',
        sub: 'Passation avec Pierre Dubois',
        color: AppColors.textGrey,
        done: false),
  ];

  String _formatDate(DateTime d) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mon planning',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile summary
            _ProfileSummaryCard()
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(
                    begin: -0.04,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 20),

            // Gardes à venir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gardes à venir',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('${_gardes.length} cette semaine',
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12)),
              ],
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gardes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _GardeCard(garde: _gardes[i])
                    .animate()
                    .fadeIn(delay: (100 + i * 60).ms, duration: 300.ms)
                    .slideX(
                        begin: 0.08,
                        end: 0,
                        delay: (100 + i * 60).ms,
                        duration: 300.ms,
                        curve: Curves.easeOutCubic),
              ),
            ),
            const SizedBox(height: 20),

            // Today's timeline
            Row(
              children: [
                const Text('Aujourd\'hui',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(width: 8),
                Text(_formatDate(_currentDate),
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12)),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 12),
            for (int i = 0; i < _tasks.length; i++)
              _TaskRow(task: _tasks[i], isLast: i == _tasks.length - 1)
                  .animate()
                  .fadeIn(delay: (320 + i * 70).ms, duration: 300.ms)
                  .slideY(
                      begin: 0.04,
                      end: 0,
                      delay: (320 + i * 70).ms,
                      duration: 300.ms,
                      curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6BAED6), AppColors.blue],
              ),
            ),
            child: const Center(
              child: Text('ML',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marc Leroit',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 3),
                Text('Infirmier D.E. · Unité 3B',
                    style: TextStyle(
                        color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(value: '4', label: 'Gardes'),
              const SizedBox(height: 4),
              _MiniStat(value: '12', label: 'Patients'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 11)),
      ],
    );
  }
}

class _GardeCard extends StatelessWidget {
  final _GardeData garde;
  const _GardeCard({required this.garde});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: garde.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: garde.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(garde.day,
              style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(garde.date,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: garde.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(garde.type,
                style: TextStyle(
                    color: garde.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(garde.hours,
              style: const TextStyle(
                  color: AppColors.textGreyDark, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final _TaskData task;
  final bool isLast;
  const _TaskRow({required this.task, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 36,
              alignment: Alignment.centerRight,
              child: Text(task.time,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 11)),
            ),
            const SizedBox(height: 4),
            if (!isLast)
              Container(width: 2, height: 48, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        // Dot
        Column(
          children: [
            const SizedBox(height: 2),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: task.done ? task.color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: task.color,
                    width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: task.done
                    ? AppColors.bg
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: task.done
                        ? AppColors.border
                        : task.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: TextStyle(
                          color: task.done
                              ? AppColors.textGrey
                              : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null)),
                  const SizedBox(height: 2),
                  Text(task.sub,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GardeData {
  final String day, date, type, hours;
  final Color color;
  final int patients;
  const _GardeData({
    required this.day,
    required this.date,
    required this.type,
    required this.hours,
    required this.color,
    required this.patients,
  });
}

class _TaskData {
  final String time, title, sub;
  final Color color;
  final bool done;
  const _TaskData({
    required this.time,
    required this.title,
    required this.sub,
    required this.color,
    required this.done,
  });
}
