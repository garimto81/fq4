// POC-S3 Screen: 40-unit mass battle performance verification
//
// Purpose: "Verify that 40 units (20 allies + 20 enemies) can engage
// in simultaneous combat at 60 FPS while maintaining natural battle flow."
//
// Layout: 65% FlameGame (top) + 35% performance dashboard (bottom)

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_s3_mass_battle.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

class PocS3Screen extends StatefulWidget {
  const PocS3Screen({super.key});

  @override
  State<PocS3Screen> createState() => _PocS3ScreenState();
}

class _PocS3ScreenState extends State<PocS3Screen> with PocScreenMixin {
  late PocS3MassBattleGame _game;
  late PocGameAdapter _adapter;

  String _statusText = 'Preparing 40 units...';
  Map<String, dynamic> _metrics = {};
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s3')!);
    _initGame();
  }

  void _initGame() {
    _game = PocS3MassBattleGame();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
    // S3 auto-starts
    _adapter.start();
  }

  void _onStatusUpdate(String status) {
    safeSetState(() => _statusText = status);
  }

  void _onMetricsUpdated(Map<String, dynamic> metrics) {
    safeSetState(() => _metrics = metrics);
    // Auto-evaluate when battle ends
    if (!_adapter.hasResult) {
      final state = metrics['battleState'] as String? ?? '';
      if (state == 'victory' || state == 'defeat') {
        _adapter.evaluate(metrics);
        safeSetState(() {});
      }
    }
  }

  void _resetGame() {
    setState(() {
      battleLogs.clear();
      _statusText = 'Preparing 40 units...';
      _metrics = {};
    });
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s3')!);
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC-S3: 40-Unit Mass Battle Performance'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/poc-hub'),
        ),
      ),
      body: Column(
        children: [
          // Purpose banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1A2332),
            child: const Text(
              'Verification: 40 units (20 allies + 20 enemies) simultaneous combat at 60 FPS with natural battle flow',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Game area (65%)
          Expanded(
            flex: 13,
            child: Stack(
              children: [
                GameWidget(game: _game),

                // Status overlay (top-left)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                // FPS indicator (top-right)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _buildFpsIndicator(),
                ),
              ],
            ),
          ),

          _buildSpeedBar(),

          // Dashboard panel (35%)
          Expanded(
            flex: 7,
            child: Container(
              color: const Color(0xFF0D1117),
              child: Column(
                children: [
                  // Performance dashboard
                  _buildPerformanceDashboard(),

                  // Unit summary
                  _buildUnitSummary(),

                  // Battle log
                  Expanded(child: _buildBattleLog()),

                  // 검증 결과
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-S3: Mass Battle Performance',
                        result: _adapter.result,
                      ),
                    ),

                  // Bottom bar
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FPS indicator with color coding
  Widget _buildFpsIndicator() {
    final fps = (_metrics['fps'] as double?) ?? 0;
    final Color fpsColor;
    if (fps >= 60) {
      fpsColor = Colors.green;
    } else if (fps >= 30) {
      fpsColor = Colors.yellow;
    } else {
      fpsColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fpsColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: fpsColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${fps.toStringAsFixed(0)} FPS',
            style: TextStyle(
              color: fpsColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Performance metrics dashboard
  Widget _buildPerformanceDashboard() {
    final fps = (_metrics['fps'] as double?) ?? 0;
    final minFps = (_metrics['minFps'] as double?) ?? 0;
    final avgFps = (_metrics['avgFps'] as double?) ?? 0;
    final aiTickMs = (_metrics['aiTickMs'] as double?) ?? 0;
    final maxAiTickMs = (_metrics['maxAiTickMs'] as double?) ?? 0;
    final p99AiTickMs = (_metrics['p99AiTickMs'] as double?) ?? 0;
    final queriesPerSec = (_metrics['queriesPerSec'] as int?) ?? 0;
    final battleTime = (_metrics['battleTime'] as double?) ?? 0;

    final Color fpsColor;
    if (fps >= 60) {
      fpsColor = Colors.green;
    } else if (fps >= 30) {
      fpsColor = Colors.yellow;
    } else {
      fpsColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // FPS section
          _dashboardSection('FPS', [
            _metricValue('Current', fps.toStringAsFixed(0), fpsColor),
            _metricValue('Min', minFps.toStringAsFixed(0),
                minFps >= 30 ? Colors.white70 : Colors.red),
            _metricValue('Avg', avgFps.toStringAsFixed(0), Colors.white70),
          ]),
          _verticalDivider(),

          // AI Tick section
          _dashboardSection('AI TICK', [
            _metricValue('Last', '${aiTickMs.toStringAsFixed(2)}ms', Colors.white70),
            _metricValue('Max', '${maxAiTickMs.toStringAsFixed(2)}ms', Colors.white70),
            _metricValue('P99', '${p99AiTickMs.toStringAsFixed(2)}ms',
                p99AiTickMs < 5 ? Colors.green : Colors.orange),
          ]),
          _verticalDivider(),

          // Other metrics
          _dashboardSection('SYSTEM', [
            _metricValue('Queries/s', '$queriesPerSec', Colors.white70),
            _metricValue('Time', '${battleTime.toStringAsFixed(1)}s', Colors.white70),
          ]),
        ],
      ),
    );
  }

  Widget _dashboardSection(String title, List<Widget> children) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(spacing: 8, children: children),
        ],
      ),
    );
  }

  Widget _metricValue(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// Unit summary bar
  Widget _buildUnitSummary() {
    final aliveAllies = (_metrics['aliveAllies'] as int?) ?? 0;
    final aliveEnemies = (_metrics['aliveEnemies'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Allies
          Icon(Icons.shield, color: Colors.blue.shade300, size: 14),
          const SizedBox(width: 4),
          Text(
            'Allies: $aliveAllies/20',
            style: TextStyle(
              color: aliveAllies > 10 ? Colors.blue.shade200 : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LinearProgressIndicator(
              value: aliveAllies / 20.0,
              backgroundColor: Colors.grey.shade900,
              color: Colors.blue.shade400,
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 16),

          // Enemies
          Icon(Icons.dangerous, color: Colors.red.shade300, size: 14),
          const SizedBox(width: 4),
          Text(
            'Enemies: $aliveEnemies/20',
            style: TextStyle(
              color: aliveEnemies > 10 ? Colors.red.shade200 : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LinearProgressIndicator(
              value: aliveEnemies / 20.0,
              backgroundColor: Colors.grey.shade900,
              color: Colors.red.shade400,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// Battle log
  Widget _buildBattleLog() {
    return Container(
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            color: const Color(0xFF21262D),
            child: Row(
              children: [
                const Text(
                  'Battle Log',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  '${battleLogs.length} entries',
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: logScrollController,
              padding: const EdgeInsets.all(4),
              itemCount: battleLogs.length,
              itemBuilder: (context, index) {
                final log = battleLogs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.5),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: logColor(log),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom bar with reset button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'POC-S3: 40-unit mass battle - 60 FPS target',
              style: TextStyle(color: Colors.white30, fontSize: 9),
            ),
          ),
          _actionButton('RESET', Colors.grey.shade700, _resetGame),
        ],
      ),
    );
  }

  Widget _buildSpeedBar() {
    return Container(
      color: const Color(0xFF21262D),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Text('Speed: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
          for (final speed in [1.0, 2.0, 4.0, 8.0, 16.0]) ...[
            _buildSpeedChip(speed),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedChip(double speed) {
    final isActive = _currentSpeed == speed;
    return GestureDetector(
      onTap: () {
        _game.setSpeed(speed);
        setState(() => _currentSpeed = speed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${speed.toInt()}x',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}
