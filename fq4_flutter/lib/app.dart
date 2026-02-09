import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/title_screen.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/settings_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TitleScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class FQ4App extends StatelessWidget {
  const FQ4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'First Queen 4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
