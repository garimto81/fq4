import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/title_screen.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/poc1_screen.dart';
import 'presentation/screens/poc2_screen.dart';
import 'presentation/screens/poc3_screen.dart';
import 'presentation/screens/poc4_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/poc_t0_screen.dart';
import 'presentation/screens/poc_s1_screen.dart';
import 'presentation/screens/poc_s2_screen.dart';
import 'presentation/screens/poc_s3_screen.dart';
import 'presentation/screens/poc_s4_screen.dart';
import 'presentation/screens/poc_s5_screen.dart';
import 'presentation/screens/poc_hub_screen.dart';

final _router = GoRouter(
  initialLocation: '/poc-hub',
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
    // POC Hub
    GoRoute(
      path: '/poc-hub',
      builder: (context, state) => const PocHubScreen(),
    ),
    // POC routes
    GoRoute(
      path: '/poc1',
      builder: (context, state) => const Poc1Screen(),
    ),
    GoRoute(
      path: '/poc2',
      builder: (context, state) => const Poc2Screen(),
    ),
    GoRoute(
      path: '/poc3',
      builder: (context, state) => const Poc3Screen(),
    ),
    GoRoute(
      path: '/poc4',
      builder: (context, state) => const Poc4Screen(),
    ),
    GoRoute(
      path: '/battle',
      builder: (context, state) => const BattleScreen(),
    ),
    GoRoute(
      path: '/phase0',
      builder: (context, state) => const PocT0Screen(),
    ),
    // Strategic Combat POC routes
    GoRoute(
      path: '/poc-s1',
      builder: (context, state) => const PocS1Screen(),
    ),
    GoRoute(
      path: '/poc-s2',
      builder: (context, state) => const PocS2Screen(),
    ),
    GoRoute(
      path: '/poc-s3',
      builder: (context, state) => const PocS3Screen(),
    ),
    GoRoute(
      path: '/poc-s4',
      builder: (context, state) => const PocS4Screen(),
    ),
    GoRoute(
      path: '/poc-s5',
      builder: (context, state) => const PocS5Screen(),
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
