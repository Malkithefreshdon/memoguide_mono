import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_scaffold.dart';

const _kPink = Color(0xFFC8185A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const MainScaffold(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                    parent: anim, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/splash.png', width: 250)
                .animate()
                .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text(
              'La sérénité au poignet',
              style: TextStyle(
                color: _kPink,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, duration: 600.ms),
            const SizedBox(height: 40),
            const _LoadingDots(),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
              color: _kPink, shape: BoxShape.circle),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: (i * 180).ms,
            )
            .fadeIn(duration: 500.ms)
            .then()
            .fadeOut(duration: 500.ms);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [dot(0), dot(1), dot(2)],
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 400.ms);
  }
}
