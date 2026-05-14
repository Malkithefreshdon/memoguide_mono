import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  static const _discussions = [
    _DiscussionData(
      id: '1',
      name: 'Équipe Soins U3B',
      lastMsg: 'Sophie: La relève est prête pour 18h',
      time: '17:42',
      unread: 3,
      isGroup: true,
      color: AppColors.blue,
    ),
    _DiscussionData(
      id: '2',
      name: 'Sophie Martin',
      lastMsg: 'J\'ai mis à jour la fiche de M. Renard',
      time: '16:15',
      unread: 1,
      isGroup: false,
      color: AppColors.pink,
    ),
    _DiscussionData(
      id: '3',
      name: 'Pierre Dubois',
      lastMsg: 'OK pour les médicaments de la chambre 101',
      time: '14:30',
      unread: 0,
      isGroup: false,
      color: const Color(0xFF8B5CF6),
    ),
    _DiscussionData(
      id: '4',
      name: 'Urgences & Alertes',
      lastMsg: 'Chute signalée — Henri Moreau ch.101',
      time: '12:08',
      unread: 0,
      isGroup: true,
      color: AppColors.red,
    ),
    _DiscussionData(
      id: '5',
      name: 'Nadège Koné',
      lastMsg: 'Bonne garde à tous !',
      time: '08:00',
      unread: 0,
      isGroup: false,
      color: AppColors.green,
    ),
  ];

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
        title: const Text('Discussions',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.textGrey),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
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
                      hintText: 'Rechercher une discussion...',
                      hintStyle: TextStyle(
                          color: AppColors.textGrey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.blue,
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: AppColors.blue,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Toutes'),
                  Tab(text: 'Non lues'),
                  Tab(text: 'Groupes'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DiscussionList(
              discussions: _discussions, query: _query),
          _DiscussionList(
              discussions:
                  _discussions.where((d) => d.unread > 0).toList(),
              query: _query),
          _DiscussionList(
              discussions:
                  _discussions.where((d) => d.isGroup).toList(),
              query: _query),
        ],
      ),
    );
  }
}

class _DiscussionList extends StatelessWidget {
  final List<_DiscussionData> discussions;
  final String query;
  const _DiscussionList(
      {required this.discussions, required this.query});

  @override
  Widget build(BuildContext context) {
    final filtered = discussions.where((d) {
      final q = query.toLowerCase();
      return q.isEmpty || d.name.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('Aucune discussion',
            style: TextStyle(color: Colors.grey[400], fontSize: 15)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 0, indent: 72),
      itemBuilder: (ctx, i) {
        final d = filtered[i];
        return _DiscussionTile(data: d)
            .animate()
            .fadeIn(delay: (i * 50).ms, duration: 300.ms)
            .slideX(
                begin: 0.05,
                end: 0,
                delay: (i * 50).ms,
                duration: 300.ms,
                curve: Curves.easeOutCubic);
      },
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final _DiscussionData data;
  const _DiscussionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: data.color.withOpacity(data.isGroup ? 0.15 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: data.isGroup
              ? Icon(Icons.groups_rounded,
                  size: 22, color: data.color)
              : Text(
                  data.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                      color: data.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
        ),
      ),
      title: Text(data.name,
          style: TextStyle(
              color: AppColors.textDark,
              fontWeight:
                  data.unread > 0 ? FontWeight.bold : FontWeight.w500,
              fontSize: 14)),
      subtitle: Text(data.lastMsg,
          style: TextStyle(
              color: data.unread > 0
                  ? AppColors.textGreyDark
                  : AppColors.textGrey,
              fontSize: 12,
              fontWeight: data.unread > 0
                  ? FontWeight.w500
                  : FontWeight.normal),
          overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(data.time,
              style: TextStyle(
                  color: data.unread > 0
                      ? AppColors.blue
                      : AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: data.unread > 0
                      ? FontWeight.bold
                      : FontWeight.normal)),
          const SizedBox(height: 4),
          if (data.unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${data.unread}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () {},
    );
  }
}

class _DiscussionData {
  final String id, name, lastMsg, time;
  final int unread;
  final bool isGroup;
  final Color color;
  const _DiscussionData({
    required this.id,
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.isGroup,
    required this.color,
  });
}
