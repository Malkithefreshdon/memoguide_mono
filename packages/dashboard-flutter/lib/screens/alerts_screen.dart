import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/alert.dart';
import '../theme.dart';
import 'new_alert_screen.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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

  Color _alertColor(String type) {
    switch (type) {
      case 'fall':
        return AppColors.red;
      case 'heart_rate':
        return AppColors.pink;
      case 'zone_exit':
        return AppColors.orange;
      default:
        return AppColors.blue;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'fall':
        return Icons.man_rounded;
      case 'heart_rate':
        return Icons.favorite;
      case 'zone_exit':
        return Icons.logout;
      default:
        return Icons.info_outline;
    }
  }

  String _alertLabel(String type) {
    switch (type) {
      case 'fall':
        return 'Chute';
      case 'heart_rate':
        return 'Cardiaque';
      case 'zone_exit':
        return 'Zone';
      default:
        return type;
    }
  }

  bool _isCritical(AlertModel a) =>
      a.type == 'fall' || (a.type == 'heart_rate' && !a.lu);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final allAlerts = state.alerts;
      final unread = allAlerts.where((a) => !a.lu).toList();
      final critical = allAlerts.where(_isCritical).toList();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Text('Alertes',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(width: 8),
              if (unread.isNotEmpty)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, anim) =>
                      ScaleTransition(scale: anim, child: c),
                  child: Container(
                    key: ValueKey(unread.length),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${unread.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded,
                  color: AppColors.textGrey),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.pink,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.pink,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Toutes (${allAlerts.length})'),
              Tab(text: 'Non lues (${unread.length})'),
              Tab(text: 'Critiques'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.red,
          onPressed: () {
            if (state.patients.isEmpty) return;
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) =>
                    NewAlertScreen(patient: state.selectedPatient),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _AlertList(
              alerts: allAlerts,
              alertColor: _alertColor,
              alertIcon: _alertIcon,
              alertLabel: _alertLabel,
              isCritical: _isCritical,
              onMarkRead: (id) => state.markAlertRead(id),
            ),
            _AlertList(
              alerts: unread,
              alertColor: _alertColor,
              alertIcon: _alertIcon,
              alertLabel: _alertLabel,
              isCritical: _isCritical,
              onMarkRead: (id) => state.markAlertRead(id),
              emptyMessage: 'Toutes les alertes ont été lues',
            ),
            _AlertList(
              alerts: critical,
              alertColor: _alertColor,
              alertIcon: _alertIcon,
              alertLabel: _alertLabel,
              isCritical: _isCritical,
              onMarkRead: (id) => state.markAlertRead(id),
              emptyMessage: 'Aucune alerte critique',
            ),
          ],
        ),
      );
    });
  }
}

class _AlertList extends StatelessWidget {
  final List<AlertModel> alerts;
  final Color Function(String) alertColor;
  final IconData Function(String) alertIcon;
  final String Function(String) alertLabel;
  final bool Function(AlertModel) isCritical;
  final void Function(String) onMarkRead;
  final String emptyMessage;

  const _AlertList({
    required this.alerts,
    required this.alertColor,
    required this.alertIcon,
    required this.alertLabel,
    required this.isCritical,
    required this.onMarkRead,
    this.emptyMessage = 'Aucune alerte',
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                    color: Colors.grey[300], size: 64)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            Text(emptyMessage,
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 15))
                .animate()
                .fadeIn(delay: 150.ms, duration: 350.ms),
          ],
        ),
      );
    }

    final highPriority =
        alerts.where((a) => isCritical(a) && !a.lu).toList();
    final rest =
        alerts.where((a) => !(isCritical(a) && !a.lu)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (highPriority.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('Priorité Haute',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${highPriority.length}',
                    style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 10),
          for (int i = 0; i < highPriority.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertCard(
                alert: highPriority[i],
                color: alertColor(highPriority[i].type),
                icon: alertIcon(highPriority[i].type),
                label: alertLabel(highPriority[i].type),
                isHighPriority: true,
                onMarkRead: () => onMarkRead(highPriority[i].id),
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AlertDetailScreen(alert: highPriority[i]),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (i * 60).ms, duration: 350.ms)
                  .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: (i * 60).ms,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic),
            ),
          const SizedBox(height: 8),
        ],
        if (rest.isNotEmpty) ...[
          if (highPriority.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                      color: AppColors.textGrey,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('Récentes',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 10),
          ],
          for (int i = 0; i < rest.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlertCard(
                alert: rest[i],
                color: alertColor(rest[i].type),
                icon: alertIcon(rest[i].type),
                label: alertLabel(rest[i].type),
                onMarkRead: () => onMarkRead(rest[i].id),
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertDetailScreen(alert: rest[i]),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      delay: ((highPriority.length + i) * 55).ms,
                      duration: 350.ms)
                  .slideX(
                      begin: 0.08,
                      end: 0,
                      delay: ((highPriority.length + i) * 55).ms,
                      duration: 350.ms,
                      curve: Curves.easeOutCubic),
            ),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final Color color;
  final IconData icon;
  final String label;
  final bool isHighPriority;
  final VoidCallback onMarkRead;
  final VoidCallback onDetail;

  const _AlertCard({
    required this.alert,
    required this.color,
    required this.icon,
    required this.label,
    this.isHighPriority = false,
    required this.onMarkRead,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(alert.createdAt);
    final dateStr = DateFormat('dd/MM').format(alert.createdAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighPriority && !alert.lu
              ? color.withOpacity(0.5)
              : alert.lu
                  ? Colors.transparent
                  : color.withOpacity(0.25),
          width: isHighPriority ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighPriority
                ? color.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(alert.patientNom,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark)),
                          ),
                          Text('$dateStr · $timeStr',
                              style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(alert.message,
                                style: const TextStyle(
                                    color: AppColors.textGreyDark,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (c, anim) =>
                                ScaleTransition(scale: anim, child: c),
                            child: !alert.lu
                                ? Container(
                                    key: const ValueKey('unread'),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle),
                                  )
                                    .animate(
                                        onPlay: (c) =>
                                            c.repeat(reverse: true))
                                    .fadeIn(
                                        duration: 700.ms, begin: 0.4)
                                : const SizedBox(
                                    key: ValueKey('read'),
                                    width: 8,
                                    height: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isHighPriority && !alert.lu) ...[
            const Divider(height: 0, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkRead,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: color.withOpacity(0.4)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Marquer lue',
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Voir le détail',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onDetail,
                  child: const Text('Voir le détail →',
                      style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
