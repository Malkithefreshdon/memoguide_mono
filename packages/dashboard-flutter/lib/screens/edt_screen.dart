import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../services/mock_data_service.dart';
import '../models/schedule.dart';
import '../theme.dart';

class EdtScreen extends StatefulWidget {
  final Patient patient;
  const EdtScreen({super.key, required this.patient});

  @override
  State<EdtScreen> createState() => _EdtScreenState();
}

class _EdtScreenState extends State<EdtScreen> {
  String _mode = 'jour';
  String _category = 'tout';
  String? _expanded;
  final _searchCtrl = TextEditingController();

  static const _categories = [
    _CatDef(id: 'tout', label: 'Tout'),
    _CatDef(id: 'medical', label: 'Médical'),
    _CatDef(id: 'social', label: 'Social'),
    _CatDef(id: 'repas', label: 'Repas'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ScheduleItem> get _items {
    return MockDataService.getSchedule(widget.patient.id);
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
            const Text('Emploi du temps',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
                '${widget.patient.prenom} ${widget.patient.nom}',
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.pink),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Jour / Semaine toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _ModeBtn(
                        label: 'Jour',
                        active: _mode == 'jour',
                        onTap: () =>
                            setState(() => _mode = 'jour'),
                      ),
                      _ModeBtn(
                        label: 'Semaine',
                        active: _mode == 'semaine',
                        onTap: () =>
                            setState(() => _mode = 'semaine'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Date nav
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: AppColors.textGreyDark),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Column(
                      children: [
                        const Text("Aujourd'hui",
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                            'Jeu ${DateTime.now().day} ${_monthShort(DateTime.now().month)}',
                            style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: AppColors.textGreyDark),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une activité...',
                          hintStyle: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              size: 18,
                              color: AppColors.textGrey),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune,
                          size: 18,
                          color: AppColors.textGreyDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Category filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories
                        .map((cat) => Padding(
                              padding: const EdgeInsets.only(
                                  right: 8),
                              child: _CategoryChip(
                                cat: cat,
                                active: _category == cat.id,
                                onTap: () => setState(
                                    () => _category = cat.id),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final isExpanded = _expanded == item.id;
                final isCurrent = i == 1;
                return _EdtRow(
                  item: item,
                  index: i,
                  isExpanded: isExpanded,
                  isCurrent: isCurrent,
                  onTap: () => setState(() =>
                      _expanded = isExpanded ? null : item.id),
                  onRetourCarte: () => Navigator.pop(context),
                )
                    .animate()
                    .fadeIn(
                        delay: (i * 60).ms, duration: 300.ms)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        delay: (i * 60).ms,
                        duration: 300.ms,
                        curve: Curves.easeOutCubic);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4)
                  ]
                : [],
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: active
                        ? AppColors.pink
                        : AppColors.textGreyDark,
                    fontWeight: active
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final _CatDef cat;
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.cat,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              active ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(cat.label,
            style: TextStyle(
                color: active
                    ? Colors.white
                    : AppColors.textGreyDark,
                fontSize: 13,
                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight.normal)),
      ),
    );
  }
}

class _EdtRow extends StatelessWidget {
  final ScheduleItem item;
  final int index;
  final bool isExpanded;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRetourCarte;
  const _EdtRow({
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.isCurrent,
    required this.onTap,
    required this.onRetourCarte,
  });

  Color _itemColor() {
    try {
      return Color(
          int.parse(item.couleur.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.pink;
    }
  }

  IconData _itemIcon() {
    switch (item.icone) {
      case 'repas':
        return Icons.restaurant_outlined;
      case 'medicament':
        return Icons.medication_outlined;
      case 'kine':
        return Icons.sports_gymnastics_outlined;
      case 'toilette':
        return Icons.shower_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.blue : _itemColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.heureDebut,
                      style: TextStyle(
                          color: isCurrent
                              ? AppColors.blue
                              : AppColors.textGreyDark,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13)),
                  if (isCurrent)
                    const Text('En cours',
                        style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Line
            Column(
              children: [
                Container(
                    width: 2,
                    height: 8,
                    color: Colors.transparent),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.blue
                        : AppColors.border,
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.blue
                                .withOpacity(0.3),
                            width: 3)
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                      width: 2,
                      color: isCurrent
                          ? AppColors.blue.withOpacity(0.3)
                          : AppColors.border),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Card
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.blue
                                .withOpacity(0.3),
                            width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    color.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(_itemIcon(),
                                  size: 18, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.titre,
                                      style: TextStyle(
                                          color: AppColors
                                              .textDark,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: isCurrent
                                              ? 14
                                              : 13)),
                                  if (item.icone == 'kine')
                                    const Row(
                                      children: [
                                        Icon(
                                            Icons
                                                .person_outline,
                                            size: 11,
                                            color: AppColors
                                                .textGrey),
                                        SizedBox(width: 3),
                                        Text('Dr. Martin',
                                            style: TextStyle(
                                                color: AppColors
                                                    .textGrey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.textGrey,
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 0),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppColors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                      _locationForItem(
                                          item.icone),
                                      style: const TextStyle(
                                          color: AppColors.blue,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 13,
                                      color: AppColors.textGrey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                        _descriptionForItem(
                                            item.icone),
                                        style: const TextStyle(
                                            color: AppColors
                                                .textGreyDark,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: onRetourCarte,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.blueLight,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .alt_route_rounded,
                                          size: 14,
                                          color: AppColors.blue),
                                      SizedBox(width: 6),
                                      Text('Retour vers Carte',
                                          style: TextStyle(
                                              color:
                                                  AppColors.blue,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _locationForItem(String icone) {
    switch (icone) {
      case 'kine':
        return 'Salle de rééducation (RMC)';
      case 'repas':
        return 'Réfectoire principal';
      case 'toilette':
        return 'Salle de bain chambre';
      default:
        return 'Chambre du patient';
    }
  }

  String _descriptionForItem(String icone) {
    switch (icone) {
      case 'kine':
        return 'Travail sur la mobilité de l\'épaule droite. Exercices doux recommandés.';
      case 'repas':
        return 'Régime sans sel. Aider si nécessaire.';
      case 'medicament':
        return 'Vérifier la prise et noter dans le dossier.';
      case 'toilette':
        return 'Aide partielle. Respect de l\'autonomie.';
      default:
        return 'Aucune note particulière.';
    }
  }
}

class _CatDef {
  final String id, label;
  const _CatDef({required this.id, required this.label});
}
