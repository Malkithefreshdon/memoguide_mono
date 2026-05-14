import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/patient.dart';
import 'patient_detail.dart';
import 'alerts_screen.dart';
import 'map_screen.dart';

const kPink = Color(0xFFC8185A);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _search = '';
  bool _searchFocus = false;
  final FocusNode _searchNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchNode.addListener(() {
      setState(() => _searchFocus = _searchNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Image.asset('assets/logo.png', height: 32),
        actions: [
          Consumer<AppState>(
            builder: (ctx, state, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: kPink),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AlertsScreen())),
                ),
                if (state.unreadAlerts > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _BounceBadge(count: state.unreadAlerts),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final fallen = state.patients
              .where((p) => p.fallDetected)
              .toList();
          // Filtre selon la recherche
          final filtered = state.patients.where((p) {
            final q = _search.toLowerCase();
            return q.isEmpty ||
                p.nom.toLowerCase().contains(q) ||
                p.prenom.toLowerCase().contains(q) ||
                p.chambre.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (c, anim) => SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, -1),
                            end: Offset.zero)
                        .animate(anim),
                    child: FadeTransition(opacity: anim, child: c),
                  ),
                  child: fallen.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          key: ValueKey(fallen.map((p) => p.id).join(',')),
                          children: fallen
                              .map((p) => _FallBanner(patient: p))
                              .toList(),
                        ),
                ),
              ),

              // Barre recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 40,
                        decoration: BoxDecoration(
                          color: _searchFocus
                              ? kPink.withOpacity(0.08)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _searchFocus
                                  ? kPink.withOpacity(0.4)
                                  : Colors.transparent),
                        ),
                        child: TextField(
                          focusNode: _searchNode,
                          onChanged: (v) =>
                              setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Rechercher',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: _searchFocus
                                    ? kPink
                                    : Colors.grey,
                                size: 18),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.mic_none,
                          color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(begin: -0.2, end: 0, duration: 400.ms),

              // Compteur + bouton carte
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero)
                                  .animate(a),
                              child: c)),
                      child: Text('${filtered.length} résidents',
                          key: ValueKey(filtered.length),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ),
                    _MapButton(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MapScreen())),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 400.ms),

              // En-têtes colonnes
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(flex: 3,
                        child: Text('Nom',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13))),
                    Expanded(flex: 2,
                        child: Text('Chambre',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13))),
                    Expanded(flex: 2,
                        child: Text('Statut',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13))),
                    SizedBox(width: 32),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Liste filtrée
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('Aucun résultat pour "$_search"',
                                style: const TextStyle(
                                    color: Colors.grey))
                            .animate()
                            .fadeIn(duration: 250.ms))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          return _PatientRow(
                            patient: p,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailScreen(
                                            patient: p))),
                          )
                              .animate()
                              .fadeIn(
                                  delay: (200 + i * 70).ms,
                                  duration: 400.ms)
                              .slideX(
                                  begin: 0.15,
                                  end: 0,
                                  delay: (200 + i * 70).ms,
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic);
                        },
                      ),
              ),

              // Pagination
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEEEEE)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Page 1',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFEEEEEE)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Suivant >',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          );
        },
      ),
    );
  }
}

class _BounceBadge extends StatelessWidget {
  final int count;
  const _BounceBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, anim) {
        final scale = TweenSequence<double>([
          TweenSequenceItem(
              tween: Tween(begin: 0.8, end: 1.3)
                  .chain(CurveTween(curve: Curves.easeOut)),
              weight: 50),
          TweenSequenceItem(
              tween: Tween(begin: 1.3, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeIn)),
              weight: 50),
        ]).animate(anim);
        return ScaleTransition(scale: scale, child: c);
      },
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
            color: kPink, shape: BoxShape.circle),
        constraints: const BoxConstraints(
            minWidth: 16, minHeight: 16),
        child: Text('$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MapButton extends StatefulWidget {
  final VoidCallback onTap;
  const _MapButton({required this.onTap});

  @override
  State<_MapButton> createState() => _MapButtonState();
}

class _MapButtonState extends State<_MapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kPink,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPink.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text('Voir la carte',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _FallBanner extends StatelessWidget {
  final Patient patient;
  const _FallBanner({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kPink,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 600.ms,
                  curve: Curves.easeInOut),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                '🚨 CHUTE — ${patient.prenom} ${patient.nom} — Ch. ${patient.chambre}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .tint(
            color: Colors.white.withOpacity(0.08),
            duration: 900.ms,
            curve: Curves.easeInOut);
  }
}

class _PatientRow extends StatefulWidget {
  final Patient patient;
  final VoidCallback onTap;
  const _PatientRow({required this.patient, required this.onTap});

  @override
  State<_PatientRow> createState() => _PatientRowState();
}

class _PatientRowState extends State<_PatientRow> {
  bool _pressed = false;

  String get _statut {
    if (widget.patient.fallDetected) return 'Chute';
    if (widget.patient.heartRate > 120 ||
        widget.patient.heartRate < 50) return 'Alerte';
    if (widget.patient.heartRate > 100) return 'Actif';
    return 'Inactif';
  }

  Color get _statutColor {
    if (widget.patient.fallDetected) return Colors.red;
    if (widget.patient.heartRate > 120 ||
        widget.patient.heartRate < 50) return Colors.orange;
    if (widget.patient.heartRate > 100) {
      return const Color(0xFF2E7D32);
    }
    return kPink;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: kPink.withOpacity(0.08),
          highlightColor: kPink.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'patient-${widget.patient.id}-name',
                    flightShuttleBuilder: (_, __, ___, ____, _____) =>
                        Material(
                      color: Colors.transparent,
                      child: Text(
                          '${widget.patient.prenom} ${widget.patient.nom}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                          '${widget.patient.prenom} ${widget.patient.nom}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(widget.patient.chambre,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333))),
                ),
                Expanded(
                  flex: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statutColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _statutColor.withOpacity(0.5)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(_statut,
                          key: ValueKey(_statut),
                          style: TextStyle(
                              color: _statutColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.account_circle_outlined,
                    color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
