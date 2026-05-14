import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import 'discussions_screen.dart';
import 'planning_equipe_screen.dart';
import 'membres_screen.dart';

class EquipeScreen extends StatelessWidget {
  const EquipeScreen({super.key});

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
        title: const Text('Mon équipe',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header card
            _TeamHeaderCard()
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(
                    begin: -0.04,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 20),
            const Text('Modules',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15))
                .animate()
                .fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _ModuleCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Discussions',
                  sub: '3 non lues',
                  color: AppColors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DiscussionsScreen()),
                  ),
                ).animate().fadeIn(delay: 120.ms, duration: 300.ms),
                _ModuleCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Planning',
                  sub: 'Garde ce soir',
                  color: AppColors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlanningEquipeScreen()),
                  ),
                ).animate().fadeIn(delay: 160.ms, duration: 300.ms),
                _ModuleCard(
                  icon: Icons.people_alt_outlined,
                  label: 'Membres',
                  sub: '12 soignants',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MembresScreen()),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                _ModuleCard(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Répartition',
                  sub: 'Charge de travail',
                  color: AppColors.orange,
                  onTap: () {},
                ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
                _ModuleCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Performance',
                  sub: 'Stats du mois',
                  color: AppColors.green,
                  onTap: () {},
                ).animate().fadeIn(delay: 280.ms, duration: 300.ms),
                _ModuleCard(
                  icon: Icons.folder_outlined,
                  label: 'Documents',
                  sub: 'Protocoles',
                  color: const Color(0xFF6B7280),
                  onTap: () {},
                ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Activité récente',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15))
                .animate()
                .fadeIn(delay: 350.ms, duration: 300.ms),
            const SizedBox(height: 12),
            _ActivityCard()
                .animate()
                .fadeIn(delay: 400.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _TeamHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Équipe Soins CHU',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    SizedBox(height: 3),
                    Text('Unité 3B — Les Mimosas',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF34C759)),
                    SizedBox(width: 4),
                    Text('En service',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TeamStat(value: '12', label: 'Membres'),
              _TeamStatDiv(),
              _TeamStat(value: '6', label: 'En garde'),
              _TeamStatDiv(),
              _TeamStat(value: '2', label: 'En pause'),
              _TeamStatDiv(),
              _TeamStat(value: '4', label: 'Absents'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamStat extends StatelessWidget {
  final String value, label;
  const _TeamStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _TeamStatDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 28, color: Colors.white.withOpacity(0.3));
  }
}

class _ModuleCard extends StatefulWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
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
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
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
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon,
                  size: 20, color: widget.color),
            ),
            const Spacer(),
            Text(widget.label,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(widget.sub,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  static const _items = [
    _Activity(
        name: 'Sophie Martin',
        action: 'a ajouté une transmission',
        time: 'il y a 5 min',
        color: AppColors.blue),
    _Activity(
        name: 'Pierre Dubois',
        action: 'a mis à jour le planning',
        time: 'il y a 12 min',
        color: AppColors.pink),
    _Activity(
        name: 'Nadège Koné',
        action: 'a envoyé un message',
        time: 'il y a 28 min',
        color: const Color(0xFF8B5CF6)),
    _Activity(
        name: 'Marc Leroit',
        action: 'a posté dans Discussions',
        time: 'il y a 1h',
        color: AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: _items
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: e.value.color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                e.value.name
                                    .split(' ')
                                    .map((w) => w[0])
                                    .take(2)
                                    .join(),
                                style: TextStyle(
                                    color: e.value.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                          text: e.value.name,
                                          style: const TextStyle(
                                              color: AppColors.textDark,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 13)),
                                      TextSpan(
                                          text: ' ${e.value.action}',
                                          style: const TextStyle(
                                              color:
                                                  AppColors.textGreyDark,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(e.value.time,
                                    style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.key < _items.length - 1)
                      const Divider(height: 0, indent: 16, endIndent: 16),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _Activity {
  final String name, action, time;
  final Color color;
  const _Activity(
      {required this.name,
      required this.action,
      required this.time,
      required this.color});
}
