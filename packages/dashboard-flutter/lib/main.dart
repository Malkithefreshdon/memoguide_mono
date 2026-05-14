import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EhpadApp(),
    ),
  );
}

class EhpadApp extends StatelessWidget {
  const EhpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final transitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SlideFadeTransitionsBuilder(),
        TargetPlatform.iOS: _SlideFadeTransitionsBuilder(),
        TargetPlatform.linux: _SlideFadeTransitionsBuilder(),
        TargetPlatform.macOS: _SlideFadeTransitionsBuilder(),
        TargetPlatform.windows: _SlideFadeTransitionsBuilder(),
        TargetPlatform.fuchsia: _SlideFadeTransitionsBuilder(),
      },
    );

    return MaterialApp(
      title: 'MemoGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC8185A)),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        pageTransitionsTheme: transitions,
      ),
      home: const SplashScreen(),
    );
  }
}

class _SlideFadeTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(eased);
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
