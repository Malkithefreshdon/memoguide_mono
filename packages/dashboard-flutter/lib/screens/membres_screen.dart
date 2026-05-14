import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  String _query = '';
  String _filterRole = 'Tous';

  static const _roles = [
    'Tous',
    'Infirmier(ère)',
    'Aide-soignant(e)',
    'Médecin',
  ];

  static const _members = [
    _Member(
        name: 'Sophie Martin',
        role: 'Infirmière D.E.',
        status: 'En service',
        phone: '06 12 34 56 78',
        color: AppColors.blue,
        online: true),
    _Member(
        name: 'Marc Leroit',
        role: 'Infirmier D.E.',
        status: 'En service',
        phone: '06 23 45 67 89',
        color: AppColors.pink,
        online: true),
    _Member(
        name: 'Pierre Dubois',
        role: 'Aide-soignant',
        status: 'En service',
        phone: '06 34 56 78 90',
        color: const Color(0xFF8B5CF6),
        online: true),
    _Member(
        name: 'Nadège Koné',
        role: 'Infirmière D.E.',
        status: 'Repos',
        phone: '06 45 67 89 01',
        color: AppColors.green,
        online: false),
    _Member(
        name: 'Jean-Paul Renard',
        role: 'Aide-soignant',
        status: 'Absent',
        phone: '06 56 78 90 12',
        color: AppColors.textGrey,
        online: false),
    _Member(
        name: 'Marie Fonteneau',
        role: 'Médecin',
        status: 'En consultation',
        phone: '06 67 89 01 23',
        color: AppColors.orange,
        online: true),
    _Member(
        name: 'Camille Bertrand',
        role: 'Aide-soignant',
        status: 'En service',
        phone: '06 78 90 12 34',
        color: AppColors.blue,
        online: true),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((m) {
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.role.toLowerCase().contains(q);
      final matchRole = _filterRole == 'Tous' ||
          m.role.toLowerCase().contains(
              _filterRole.toLowerCase().replaceAll('(e)', '').replaceAll('(ère)', '').trim());
      return matchQuery && matchRole;
    }).toList();

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
        title: const Text('Membres',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textGrey),
                      hintText: 'Rechercher un membre...',
                      hintStyle: TextStyle(
                          color: AppColors.textGrey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _roles
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _filterRole = r),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _filterRole == r
                                        ? AppColors.blue
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _filterRole == r
                                            ? AppColors.blue
                                            : AppColors.border),
                                  ),
                                  child: Text(r,
                                      style: TextStyle(
                                          color: _filterRole == r
                                              ? Colors.white
                                              : AppColors.textGreyDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Aucun membre trouvé',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 15)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final m = filtered[i];
                      return _MemberCard(member: m)
                          .animate()
                          .fadeIn(
                              delay: (i * 50).ms, duration: 300.ms)
                          .slideX(
                              begin: 0.05,
                              end: 0,
                              delay: (i * 50).ms,
                              duration: 300.ms,
                              curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final _Member member;
  const _MemberCard({required this.member});

  Color get _statusColor {
    switch (member.status) {
      case 'En service':
      case 'En consultation':
        return AppColors.green;
      case 'Absent':
        return AppColors.red;
      default:
        return AppColors.textGrey;
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
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 46,
                height: 46,
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
                        fontSize: 15),
                  ),
                ),
              ),
              if (member.online)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
            ],
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
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(member.role,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(member.status,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.message_outlined,
                          size: 14, color: AppColors.pink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Member {
  final String name, role, status, phone;
  final Color color;
  final bool online;
  const _Member({
    required this.name,
    required this.role,
    required this.status,
    required this.phone,
    required this.color,
    required this.online,
  });
}
