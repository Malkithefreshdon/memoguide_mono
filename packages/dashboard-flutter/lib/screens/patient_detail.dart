import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import 'edt_screen.dart';

const kPink = Color(0xFFC8185A);

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          icon: const Icon(Icons.chevron_left,
              color: Color(0xFF333333), size: 20),
          label: const Text('Retour',
              style: TextStyle(
                  color: Color(0xFF333333), fontSize: 14)),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          final p = state.patients
              .firstWhere((x) => x.id == patient.id);
          final isAlert = p.heartRate > 120 || p.heartRate < 50;
          return Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    const _EhpadMap(),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _HeartRateCard(
                        heartRate: p.heartRate,
                        isAlert: isAlert,
                      ),
                    ),
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final w = MediaQuery.of(context).size.width;
                        final h = MediaQuery.of(context).size.height * 0.35;
                        // Mappe la position p.posX/posY (0..10/0..8) vers la mini-carte
                        final left = (p.posX / 10.0) * (w - 60) - 18;
                        final top = (p.posY / 8.0) * (h - 80);
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeInOut,
                          left: left.clamp(20.0, w - 60),
                          top: top.clamp(20.0, h - 80),
                          child: Column(
                            children: [
                              Icon(Icons.location_on,
                                  color: p.fallDetected
                                      ? Colors.red
                                      : kPink,
                                  size: 36),
                              Text(p.prenom,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2))],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Text('Chambre : ',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14)),
                              Text(p.chambre,
                                  style: const TextStyle(
                                      color: kPink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey, size: 18),
                            ]),
                            const Icon(Icons.share,
                                color: Colors.grey, size: 20),
                          ],
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            child: Hero(
                              tag: 'patient-${p.id}-name',
                              flightShuttleBuilder: (_, __, ___, ____, _____) =>
                                  Material(
                                color: Colors.transparent,
                                child: Text('${p.prenom} ${p.nom}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Text('${p.prenom} ${p.nom}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                        Row(children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Text('Fiche',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13)),
                          ),
                          const Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 8),
                        ..._staggered([
                          _FicheRow('Statut :',
                              p.fallDetected
                                  ? 'Chute'
                                  : 'En chambre',
                              isTag: true,
                              tagColor: p.fallDetected
                                  ? Colors.red
                                  : kPink),
                          _FicheRow('Contact d\'urgence :',
                              '07 01 01 01 01'),
                          _FicheRow('Traitement :', 'Matin et soir'),
                          _FicheRow('Risque de fugues :', 'Élevé',
                              isTag: true, tagColor: Colors.red),
                          _FicheRow('Maladie :', 'Alzheimer'),
                          _FicheRow('Âge et sexe :', '89 ans, M'),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6),
                            child: Row(children: [
                              const Text('Activité : ',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14)),
                              _Tag('Messe 14h', kPink),
                              const SizedBox(width: 6),
                              _Tag('Poterie 16h', kPink),
                            ]),
                          ),
                        ], baseDelayMs: 250),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundIcon(
                                icon: Icons.mic,
                                onTap: () => state.sendVoiceCommand(
                                    p.id, 'urgence')),
                            _RoundIcon(
                                icon: Icons.info_outline,
                                onTap: () {}),
                            _RoundIcon(
                                icon: Icons.calendar_today,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            EdtScreen(patient: p)))),
                            _RoundIcon(
                                icon: Icons.warning_amber_outlined,
                                onTap: () =>
                                    state.simulateFall(p.id),
                                color: Colors.orange,
                                shakeOnTap: true),
                          ],
                        )
                            .animate()
                            .fadeIn(
                                delay: 600.ms, duration: 400.ms),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.near_me,
                                color: Colors.white, size: 18),
                            label: const Text('Itinéraire',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPink,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(30)),
                            ),
                            onPressed: () {},
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: 700.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                delay: 700.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        delay: 150.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _staggered(List<Widget> items,
      {int baseDelayMs = 0}) {
    return [
      for (int i = 0; i < items.length; i++)
        items[i]
            .animate()
            .fadeIn(
                delay: (baseDelayMs + i * 50).ms,
                duration: 350.ms)
            .slideX(
                begin: -0.05,
                end: 0,
                delay: (baseDelayMs + i * 50).ms,
                duration: 350.ms,
                curve: Curves.easeOutCubic),
    ];
  }
}

class _HeartRateCard extends StatefulWidget {
  final int heartRate;
  final bool isAlert;
  const _HeartRateCard({
    required this.heartRate,
    required this.isAlert,
  });

  @override
  State<_HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<_HeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  Duration get _period {
    final bpm = widget.heartRate.clamp(30, 200);
    return Duration(milliseconds: (60000 / bpm).round());
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _period)
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _HeartRateCard old) {
    super.didUpdateWidget(old);
    if (old.heartRate != widget.heartRate) {
      _ctrl.duration = _period;
      _ctrl
        ..stop()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isAlert ? Colors.red : kPink;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.18).animate(
                CurvedAnimation(
                    parent: _ctrl, curve: Curves.easeInOut)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero)
                          .animate(anim),
                      child: c)),
              child: Text('${widget.heartRate}',
                  key: ValueKey(widget.heartRate),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
          ),
          const SizedBox(width: 4),
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.18).animate(
                CurvedAnimation(
                    parent: _ctrl, curve: Curves.easeInOut)),
            child: Icon(Icons.favorite, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EhpadMap extends StatelessWidget {
  const _EhpadMap();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height * 0.35;
    final labels = <Widget>[
      const Positioned(left: 24, top: 24,
          child: Text('Chambre 312',
              style: TextStyle(color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600, fontSize: 13))),
      Positioned(left: 24, top: h * 0.45,
          child: const Text('Hall',
              style: TextStyle(color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600, fontSize: 13))),
      Positioned(left: 24, bottom: 24,
          child: const Text('Salle de repos',
              style: TextStyle(color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600, fontSize: 13))),
      Positioned(right: 24, bottom: 24,
          child: const Text('Salle à manger',
              style: TextStyle(color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600, fontSize: 13))),
      Positioned(left: 24, bottom: h * 0.3,
          child: const Text('Couloir',
              style: TextStyle(color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w600, fontSize: 13))),
    ];
    return SizedBox(
      width: w, height: h,
      child: Stack(
        children: [
          CustomPaint(size: Size(w, h), painter: _MapPainter()),
          for (int i = 0; i < labels.length; i++)
            _AnimatedLabel(delayMs: i * 80, child: labels[i]),
        ],
      ),
    );
  }
}

class _AnimatedLabel extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _AnimatedLabel({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 350.ms);
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(
        20, 20, size.width - 40, size.height - 40), paint);
    canvas.drawLine(Offset(20, size.height * 0.38),
        Offset(size.width * 0.52, size.height * 0.38), paint);
    canvas.drawLine(Offset(size.width * 0.52, 20),
        Offset(size.width * 0.52, size.height * 0.38), paint);
    canvas.drawLine(Offset(20, size.height * 0.65),
        Offset(size.width * 0.42, size.height * 0.65), paint);
    canvas.drawLine(
        Offset(size.width * 0.42, size.height * 0.65),
        Offset(size.width * 0.42, size.height - 20), paint);
    canvas.drawLine(
        Offset(size.width * 0.42, size.height * 0.52),
        Offset(size.width - 20, size.height * 0.52), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FicheRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTag;
  final Color tagColor;
  const _FicheRow(this.label, this.value,
      {this.isTag = false, this.tagColor = kPink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        isTag
            ? _Tag(value, tagColor)
            : Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _RoundIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool shakeOnTap;
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.color = kPink,
    this.shakeOnTap = false,
  });

  @override
  State<_RoundIcon> createState() => _RoundIconState();
}

class _RoundIconState extends State<_RoundIcon> {
  bool _pressed = false;
  Key _shakeKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    Widget core = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: 24),
    );

    if (widget.shakeOnTap) {
      core = core
          .animate(key: _shakeKey)
          .shake(
              hz: 8,
              duration: 500.ms,
              offset: const Offset(8, 0));
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (widget.shakeOnTap) {
          setState(() => _shakeKey = UniqueKey());
        }
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: core,
      ),
    );
  }
}
