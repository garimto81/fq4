import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc1_rive_test.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-1: Rive + Flame 렌더링 통합 테스트 화면
class Poc1Screen extends StatefulWidget {
  const Poc1Screen({super.key});

  @override
  State<Poc1Screen> createState() => _Poc1ScreenState();
}

class _Poc1ScreenState extends State<Poc1Screen> with PocScreenMixin {
  late final RiveTestGame _game;
  late final PocGameAdapter _adapter;
  String _status = 'Loading...';
  double _fps = 0;

  @override
  void initState() {
    super.initState();
    _game = RiveTestGame();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-1')!);

    _game.onStatusUpdate = (status, fps) {
      safeSetState(() {
        _status = status;
        _fps = fps;
      });

      // FPS 업데이트 시 평가
      if (!_adapter.hasResult && _fps > 0) {
        _adapter.evaluate({'fps': _fps, 'rendererActive': true});
        safeSetState(() {});
      }
    };

    // 게임 시작
    _adapter.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Game viewport (top 70%)
          Expanded(
            flex: 7,
            child: GameWidget(game: _game),
          ),
          // Control panel (bottom 30%)
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + FPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'POC-1: Rive + Flame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _fps >= 30 ? Colors.green.shade900 : Colors.red.shade900,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_fps.toStringAsFixed(1)} FPS',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Spacer(),
                  // Verification card
                  if (_adapter.hasResult)
                    PocVerificationCard(
                      pocName: 'POC-1: Rive + Flame',
                      result: _adapter.result,
                    ),
                  const SizedBox(height: 8),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _game.spawnMultipleUnits(),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Spawn 6 Units'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/poc-hub'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
