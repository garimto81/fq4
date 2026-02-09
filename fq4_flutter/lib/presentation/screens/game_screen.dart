import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/fq4_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FQ4Game _game;

  @override
  void initState() {
    super.initState();
    _game = FQ4Game();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) => _buildHud(context),
          'pause': (context, game) => _buildPauseOverlay(context),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }

  Widget _buildHud(BuildContext context) {
    return const Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chapter 1',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Text(
          'PAUSED',
          style: TextStyle(color: Colors.white, fontSize: 32),
        ),
      ),
    );
  }
}
