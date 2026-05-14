import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'patient_fiche.dart';
import 'edt_screen.dart';
import 'new_alert_screen.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final p = state.selectedPatient;
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Carte',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                _PatientCard(patient: p)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(
                        begin: -0.1,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Text('Étage 1',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 350.ms),
                const SizedBox(height: 10),
                _FloorMap(patient: p)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        delay: 200.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 18),
                _QuickStats(
                  patient: p,
                  onTapEdt: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => EdtScreen(patient: p))),
                  onTapFiche: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => PatientFiche(patient: p))),
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms),
                const SizedBox(height: 20),
                _CtaButton(
                  label: 'Démarrer le guidage',
                  icon: Icons.near_me_rounded,
                  color: AppColors.blue,
                  onTap: () =>
                      state.sendVoiceCommand(p.id, 'guidage'),
                )
                    .animate()
                    .fadeIn(delay: 480.ms, duration: 400.ms)
                    .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 480.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                _CtaButton(
                  label: 'Déclencher une alerte',
                  icon: Icons.notifications_active_rounded,
                  color: AppColors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NewAlertScreen(patient: p)),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 560.ms, duration: 400.ms)
                    .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 560.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final secure = !patient.fallDetected &&
        patient.heartRate >= 50 &&
        patient.heartRate <= 120;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PatientFiche(patient: patient)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            _Avatar(patient: patient, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${patient.prenom} ${patient.nom}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${patient.age} ans',
                          style: const TextStyle(
                              color: AppColors.textGreyDark,
                              fontSize: 12)),
                      _Chip(
                        label: patient.unite,
                        color: AppColors.blue,
                        bg: AppColors.blueLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Ch. ${patient.chambre}',
                          style: const TextStyle(
                              color: AppColors.textGreyDark,
                              fontSize: 12)),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: secure
                              ? AppColors.green
                              : AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(patient.statutLabel,
                          style: TextStyle(
                              color: secure
                                  ? AppColors.green
                                  : AppColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Patient patient;
  final double size;
  const _Avatar({required this.patient, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.blue,
      AppColors.pink,
      AppColors.orange,
      AppColors.green,
    ];
    final color = colors[patient.id.hashCode.abs() % colors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.85), color],
        ),
      ),
      child: Center(
        child: Text(
          patient.initiales,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _FloorMap extends StatefulWidget {
  final Patient patient;
  const _FloorMap({required this.patient});

  @override
  State<_FloorMap> createState() => _FloorMapState();
}

class _FloorMapState extends State<_FloorMap> {
  double _zoom = 1.0;
  static const double _minZoom = 0.8;
  static const double _maxZoom = 2.0;
  static const double _zoomStep = 0.2;

  static const _rooms = <_RoomDef>[
    _RoomDef(lx: 0.04, ly: 0.06, w: 0.28, h: 0.22, label: 'Chambre 203'),
    _RoomDef(lx: 0.68, ly: 0.06, w: 0.28, h: 0.22, label: 'Chambre 205'),
    _RoomDef(lx: 0.04, ly: 0.40, w: 0.28, h: 0.22, label: 'Chambre 201'),
    _RoomDef(lx: 0.68, ly: 0.40, w: 0.28, h: 0.22, label: 'Chambre 207'),
    _RoomDef(
        lx: 0.04,
        ly: 0.74,
        w: 0.42,
        h: 0.20,
        label: 'Poste de soin',
        icon: Icons.health_and_safety_outlined),
    _RoomDef(
        lx: 0.54,
        ly: 0.74,
        w: 0.42,
        h: 0.20,
        label: 'Stockage',
        icon: Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 240,
        color: const Color(0xFFE9EEF4),
        child: LayoutBuilder(
          builder: (ctx, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final pinLeft = ((patient.posX / 10.0) * w * _zoom)
                .clamp(20.0, w * _zoom - 56);
            final pinTop = ((patient.posY / 8.0) * h * _zoom)
                .clamp(20.0, h * _zoom - 56);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedScale(
                  scale: _zoom,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(w, h),
                        painter: _FloorPainter(),
                      ),
                      for (final r in _rooms)
                        Positioned(
                          left: r.lx * w,
                          top: r.ly * h,
                          width: r.w * w,
                          height: r.h * h,
                          child: _RoomBox(room: r),
                        ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        left: ((patient.posX / 10.0) * w).clamp(20.0, w - 56),
                        top: ((patient.posY / 8.0) * h).clamp(20.0, h - 56),
                        child: _PatientPin(patient: patient),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.add,
                        onTap: _zoom < _maxZoom
                            ? () => setState(
                                () => _zoom = (_zoom + _zoomStep)
                                    .clamp(_minZoom, _maxZoom))
                            : null,
                      ),
                      const SizedBox(height: 4),
                      _MapButton(
                        icon: Icons.remove,
                        onTap: _zoom > _minZoom
                            ? () => setState(
                                () => _zoom = (_zoom - _zoomStep)
                                    .clamp(_minZoom, _maxZoom))
                            : null,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _MapButton(
                    icon: Icons.my_location,
                    onTap: () => setState(() => _zoom = 1.0),
                    color: AppColors.blue,
                    iconColor: Colors.white,
                  ),
                ),
                if (_zoom != 1.0)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${(_zoom * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoomDef {
  final double lx;
  final double ly;
  final double w;
  final double h;
  final String label;
  final IconData icon;
  const _RoomDef({
    required this.lx,
    required this.ly,
    required this.w,
    required this.h,
    required this.label,
    this.icon = Icons.bed_outlined,
  });
}

class _RoomBox extends StatelessWidget {
  final _RoomDef room;
  const _RoomBox({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(room.icon, size: 14, color: AppColors.textGreyDark),
          const SizedBox(height: 2),
          Text(room.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textGreyDark,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PatientPin extends StatelessWidget {
  final Patient patient;
  const _PatientPin({required this.patient});

  @override
  Widget build(BuildContext context) {
    final isAlert = patient.fallDetected;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isAlert)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red.withOpacity(0.25),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.4, duration: 800.ms)
              .fadeOut(duration: 800.ms, begin: 0.5),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
                color: isAlert ? AppColors.red : AppColors.blue,
                width: 3),
          ),
          child: _Avatar(patient: patient, size: 36),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // bordure principale
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _QuickStats extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTapEdt;
  final VoidCallback onTapFiche;
  const _QuickStats({
    required this.patient,
    required this.onTapEdt,
    required this.onTapFiche,
  });

  @override
  Widget build(BuildContext context) {
    final isAbn =
        patient.heartRate > 120 || patient.heartRate < 50;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Rythme',
            icon: Icons.favorite,
            iconColor: AppColors.pink,
            iconBg: const Color(0xFFFCE7EE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: RichText(
                    key: ValueKey(patient.heartRate),
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${patient.heartRate}',
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: ' bpm',
                          style: TextStyle(
                              color: AppColors.textGreyDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  isAbn ? 'Anormal' : 'Normal',
                  style: TextStyle(
                      color: isAbn
                          ? AppColors.red
                          : AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Fiche',
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.blue,
            iconBg: AppColors.blueLight,
            chevron: true,
            onTap: onTapFiche,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'EDT',
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.pink,
            iconBg: const Color(0xFFFCE7EE),
            chevron: true,
            onTap: onTapEdt,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Humeur',
            icon: Icons.sentiment_satisfied_alt_rounded,
            iconColor: AppColors.orange,
            iconBg: AppColors.orangeLight,
            chevron: true,
            onTap: () {},
            child: Text(
              patient.humeur,
              style: const TextStyle(
                  color: AppColors.textGreyDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget? child;
  final bool chevron;
  final VoidCallback? onTap;
  const _StatCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.child,
    this.chevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                if (chevron)
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textGrey),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressed = false;

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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
