import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/patient.dart';

const kPink = Color(0xFFC8185A);

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

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
              style: TextStyle(color: Color(0xFF333333), fontSize: 14)),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
        title: const Text('Carte EHPAD',
            style: TextStyle(
                color: Color(0xFF333333), fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AppState>(
        builder: (ctx, state, _) {
          return LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(w, h),
                    painter: _FullMapPainter(),
                  ),
                  ..._buildZoneLabels(w, h),
                  for (final p in state.patients)
                    _AnimatedPatientPin(
                      key: ValueKey('pin-${p.id}'),
                      patient: p,
                      width: w,
                      height: h,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildZoneLabels(double w, double h) {
    final labels = <Widget>[
      Positioned(left: 30, top: 30,
          child: _ZoneLabel('Chambre 312')),
      Positioned(left: 30, top: h * 0.3,
          child: _ZoneLabel('Hall')),
      Positioned(left: 30, top: h * 0.55,
          child: _ZoneLabel('Couloir')),
      Positioned(left: 30, bottom: 40,
          child: _ZoneLabel('Salle de repos')),
      Positioned(right: 30, bottom: 40,
          child: _ZoneLabel('Salle à manger')),
      Positioned(right: 30, top: 30,
          child: _ZoneLabel('Chambre 302')),
    ];
    return [
      for (int i = 0; i < labels.length; i++)
        labels[i].animate().fadeIn(
            delay: (i * 80).ms, duration: 400.ms),
    ];
  }
}

class _AnimatedPatientPin extends StatelessWidget {
  final Patient patient;
  final double width;
  final double height;
  const _AnimatedPatientPin({
    super.key,
    required this.patient,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final px = (patient.posX / 10.0) * width;
    final py = (patient.posY / 8.0) * height;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      left: px - 30,
      top: py - 45,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(patient.fallDetected),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: patient.fallDetected ? Colors.red : kPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    patient.fallDetected
                        ? '⚠️ CHUTE'
                        : '${patient.heartRate} bpm',
                    key: ValueKey(patient.fallDetected
                        ? 'fall'
                        : 'bpm-${patient.heartRate}'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            _PinIcon(
              fall: patient.fallDetected,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2)],
              ),
              child: Text(patient.prenom,
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinIcon extends StatelessWidget {
  final bool fall;
  const _PinIcon({required this.fall});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.location_on,
        color: fall ? Colors.red : kPink, size: 28);
    if (!fall) return icon;

    return SizedBox(
      width: 60,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _Halo(),
          icon
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.25, 1.25),
                  duration: 600.ms,
                  curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _Halo extends StatefulWidget {
  const _Halo();

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return CustomPaint(
          size: const Size(60, 60),
          painter: _HaloPainter(t),
        );
      },
    );
  }
}

class _HaloPainter extends CustomPainter {
  final double t;
  _HaloPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 1.4;
    final r = 6 + maxR * t;
    final paint = Paint()
      ..color = Colors.red.withOpacity((1 - t) * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) => old.t != t;
}

class _ZoneLabel extends StatelessWidget {
  final String label;
  const _ZoneLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: Color(0xFF4A90D9),
            fontWeight: FontWeight.w600,
            fontSize: 13));
  }
}

class _FullMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
        Rect.fromLTWH(20, 20, size.width - 40, size.height - 40), paint);
    canvas.drawLine(Offset(20, size.height * 0.35),
        Offset(size.width * 0.5, size.height * 0.35), paint);
    canvas.drawLine(Offset(size.width * 0.5, 20),
        Offset(size.width * 0.5, size.height * 0.35), paint);
    canvas.drawLine(Offset(20, size.height * 0.6),
        Offset(size.width * 0.45, size.height * 0.6), paint);
    canvas.drawLine(Offset(size.width * 0.45, size.height * 0.6),
        Offset(size.width * 0.45, size.height - 20), paint);
    canvas.drawLine(Offset(size.width * 0.45, size.height * 0.5),
        Offset(size.width - 20, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
