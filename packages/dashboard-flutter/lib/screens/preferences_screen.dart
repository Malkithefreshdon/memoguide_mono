import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notifAlertes = true;
  bool _notifTransmissions = true;
  bool _notifPlanning = false;
  bool _notifEquipe = true;
  bool _biometrie = false;
  bool _modeNuit = false;
  String _langue = 'Français';

  static const _langues = ['Français', 'English', 'Español', 'Deutsch'];

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
        title: const Text('Préférences',
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
            _SectionLabel('NOTIFICATIONS')
                .animate()
                .fadeIn(duration: 300.ms),
            _ToggleSection(
              items: [
                _ToggleItem(
                  icon: Icons.warning_rounded,
                  iconColor: AppColors.red,
                  label: 'Alertes patients',
                  sub: 'Chutes, cardiaque, zones',
                  value: _notifAlertes,
                  onChanged: (v) =>
                      setState(() => _notifAlertes = v),
                ),
                _ToggleItem(
                  icon: Icons.note_alt_outlined,
                  iconColor: AppColors.blue,
                  label: 'Transmissions',
                  sub: 'Nouveaux messages de l\'équipe',
                  value: _notifTransmissions,
                  onChanged: (v) =>
                      setState(() => _notifTransmissions = v),
                ),
                _ToggleItem(
                  icon: Icons.calendar_month_outlined,
                  iconColor: AppColors.pink,
                  label: 'Planning',
                  sub: 'Changements de garde',
                  value: _notifPlanning,
                  onChanged: (v) =>
                      setState(() => _notifPlanning = v),
                ),
                _ToggleItem(
                  icon: Icons.groups_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Équipe',
                  sub: 'Messages et activités',
                  value: _notifEquipe,
                  onChanged: (v) =>
                      setState(() => _notifEquipe = v),
                ),
              ],
            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),
            const SizedBox(height: 20),
            _SectionLabel('SÉCURITÉ')
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),
            _ToggleSection(
              items: [
                _ToggleItem(
                  icon: Icons.fingerprint_rounded,
                  iconColor: AppColors.green,
                  label: 'Biométrie',
                  sub: 'Déverrouillage par empreinte',
                  value: _biometrie,
                  onChanged: (v) =>
                      setState(() => _biometrie = v),
                ),
              ],
            ).animate().fadeIn(delay: 140.ms, duration: 350.ms),
            const SizedBox(height: 20),
            _SectionLabel('AFFICHAGE')
                .animate()
                .fadeIn(delay: 180.ms, duration: 300.ms),
            _ToggleSection(
              items: [
                _ToggleItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.textGreyDark,
                  label: 'Mode nuit',
                  sub: 'Thème sombre (bientôt)',
                  value: _modeNuit,
                  onChanged: (v) =>
                      setState(() => _modeNuit = v),
                ),
              ],
            ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
            const SizedBox(height: 20),
            _SectionLabel('LANGUE')
                .animate()
                .fadeIn(delay: 260.ms, duration: 300.ms),
            Container(
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
                children: _langues
                    .asMap()
                    .entries
                    .map(
                      (e) => Column(
                        children: [
                          InkWell(
                            onTap: () =>
                                setState(() => _langue = e.value),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Text(e.value,
                                      style: TextStyle(
                                          color: _langue == e.value
                                              ? AppColors.pink
                                              : AppColors.textDark,
                                          fontWeight:
                                              _langue == e.value
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                          fontSize: 14)),
                                  const Spacer(),
                                  AnimatedSwitcher(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    child: _langue == e.value
                                        ? Icon(Icons.check_circle,
                                            key: ValueKey(e.value),
                                            size: 18,
                                            color: AppColors.pink)
                                        : const SizedBox(
                                            key: ValueKey('empty'),
                                            width: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (e.key < _langues.length - 1)
                            const Divider(
                                height: 0, indent: 16, endIndent: 16),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Préférences enregistrées'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: const Text('Enregistrer',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 360.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }
}

class _ToggleSection extends StatelessWidget {
  final List<_ToggleItem> items;
  const _ToggleSection({required this.items});

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
        children: items
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
                              color:
                                  e.value.iconColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(e.value.icon,
                                size: 18,
                                color: e.value.iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(e.value.label,
                                    style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                Text(e.value.sub,
                                    style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: e.value.value,
                            onChanged: e.value.onChanged,
                            activeColor: AppColors.pink,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                    if (e.key < items.length - 1)
                      const Divider(
                          height: 0, indent: 16, endIndent: 16),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _ToggleItem {
  final IconData icon;
  final Color iconColor;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
}
