import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/poc4_speed_test.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-4: 배속 시스템 테스트 화면
class Poc4Screen extends StatefulWidget {
  const Poc4Screen({super.key});

  @override
  State<Poc4Screen> createState() => _Poc4ScreenState();
}

class _Poc4ScreenState extends State<Poc4Screen> with PocScreenMixin {
  late final SpeedTestGame _game;
  late final PocGameAdapter _adapter;
  double _currentSpeed = 1.0;
  double _distancePerSec = 0;
  double _battleTime = 0;
  String _battleState = 'PREPARING';

  @override
  void initState() {
    super.initState();
    _game = SpeedTestGame();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-4')!);

    _game.onStatusUpdate = _onStatusUpdate;
  }

  void _onStatusUpdate(
    double speed,
    double distance,
    double battleTime,
    String battleState,
  ) {
    safeSetState(() {
      _currentSpeed = speed;
      _distancePerSec = distance;
      _battleTime = battleTime;
      _battleState = battleState;
    });

    // 전투 종료 시 평가
    if (!_adapter.hasResult && (battleState == 'VICTORY' || battleState == 'DEFEAT')) {
      _adapter.evaluate({
        'distance1x': 150.0, // 예상 1배속 거리
        'distance2x': _distancePerSec,
        'battleState': battleState,
        'currentSpeed': _currentSpeed,
      });
      safeSetState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF21262D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'POC-4: Speed System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                    onPressed: () => context.go('/poc-hub'),
                  ),
                ],
              ),
            ),
            // Game viewport (60%)
            Expanded(
              flex: 3,
              child: GameWidget(game: _game),
            ),
            // Controls (40%)
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF0D1117),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Speed buttons
                    Row(
                      children: [
                        const Text(
                          'Speed: ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        for (final speed in SpeedTestGame.speedOptions) ...[
                          _buildSpeedButton(speed),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Metrics
                    _buildMetric('Current Speed', '${_currentSpeed.toStringAsFixed(0)}x'),
                    _buildMetric(
                      'Distance/sec',
                      '${_distancePerSec.toStringAsFixed(1)} px/s '
                          '(expected: ${(150 * _currentSpeed).toStringAsFixed(0)})',
                    ),
                    _buildMetric('Battle Time', '${_battleTime.toStringAsFixed(1)}s'),
                    _buildMetric('Battle State', _battleState),
                    const Spacer(),
                    // Verification card
                    if (_adapter.hasResult)
                      PocVerificationCard(
                        pocName: 'POC-4: Speed Test',
                        result: _adapter.result,
                      ),
                    const SizedBox(height: 8),
                    // Start battle button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _adapter.start();
                          _game.startBattle();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Start Battle (speed test)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    final isActive = (_currentSpeed - speed).abs() < 0.1;
    return ElevatedButton(
      onPressed: () => _game.setSpeed(speed),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.amber.shade800 : Colors.grey.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text('${speed.toStringAsFixed(0)}x'),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
