// POC-S4 Screen: Player Strategic Intervention Effect Verification
//
// Purpose: "Verify that player's direct control of 1 unit with back attacks
// and weapon-type exploitation causes a meaningful difference in battle
// outcomes compared to pure AI auto-battle."
//
// Layout: 65% FlameGame (top) + 35% comparison dashboard (bottom)

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_s4_intervention.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

class PocS4Screen extends StatefulWidget {
  const PocS4Screen({super.key});

  @override
  State<PocS4Screen> createState() => _PocS4ScreenState();
}

class _PocS4ScreenState extends State<PocS4Screen> with PocScreenMixin {
  late PocS4InterventionGame _game;
  late PocGameAdapter _adapter;

  String _statusText = 'Preparing battle...';
  List<S4UnitInfo> _units = [];
  Map<String, dynamic> _metrics = {};
  bool _isManualMode = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s4')!);
    _initGame();
  }

  void _initGame() {
    _game = PocS4InterventionGame();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
  }

  void _onStatusUpdate(String status) {
    safeSetState(() => _statusText = status);
  }

  void _onUnitsUpdated(List<S4UnitInfo> units) {
    safeSetState(() => _units = units);
  }

  void _onMetricsUpdated(Map<String, dynamic> metrics) {
    safeSetState(() => _metrics = metrics);
    // Auto-evaluate when battle ends (S4 requires manual input, auto-resets)
    if (!_adapter.hasResult) {
      final autoRuns = metrics['autoBattles'] as int? ?? 0;
      final manualRuns = metrics['manualBattles'] as int? ?? 0;
      if (autoRuns >= 2 && manualRuns >= 2) {
        _adapter.evaluate(metrics);
        safeSetState(() {});
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      _game.switchMode(_isManualMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC-S4: Strategic Intervention Effect'),
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
              'Verification: Player direct control (back attacks, weapon exploitation) vs AI auto-battle outcome comparison',
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

                // Mode chip (top-left)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _buildModeChip(),
                ),

                // Status (below mode chip)
                Positioned(
                  left: 12,
                  top: 48,
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

                // Controls guide (top-right)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _isManualMode ? 'MANUAL CONTROLS:' : 'AUTO MODE',
                          style: TextStyle(
                            color: _isManualMode
                                ? Colors.orange.shade300
                                : Colors.green.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isManualMode) ...[
                          const SizedBox(height: 2),
                          const Text('WASD: Move unit',
                              style: TextStyle(color: Colors.white54, fontSize: 9)),
                          const Text('Q/E: Switch unit',
                              style: TextStyle(color: Colors.white54, fontSize: 9)),
                          const Text('Auto-attack in range',
                              style: TextStyle(color: Colors.green, fontSize: 9)),
                          const Text('Aim for enemy backs!',
                              style: TextStyle(color: Colors.orange, fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
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
                  // Mode switch + comparison stats
                  _buildComparisonDashboard(),

                  // Unit status
                  _buildUnitStatus(),

                  // Battle log
                  Expanded(child: _buildBattleLog()),

                  // Verification result
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-S4: Player Strategic Intervention',
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

  /// AUTO/MANUAL mode chip
  Widget _buildModeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isManualMode ? Colors.orange.shade800 : Colors.green.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isManualMode ? Colors.orange : Colors.green,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isManualMode ? Icons.gamepad : Icons.smart_toy,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _isManualMode ? 'MANUAL' : 'AUTO',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Comparison dashboard: AUTO vs MANUAL stats side by side
  Widget _buildComparisonDashboard() {
    final autoWins = (_metrics['autoWins'] as int?) ?? 0;
    final manualWins = (_metrics['manualWins'] as int?) ?? 0;
    final avgAutoTime = (_metrics['avgAutoTime'] as double?) ?? 0;
    final avgManualTime = (_metrics['avgManualTime'] as double?) ?? 0;
    final autoBackPct = (_metrics['autoBackAttackPct'] as double?) ?? 0;
    final manualBackPct = (_metrics['manualBackAttackPct'] as double?) ?? 0;
    final autoBattles = (_metrics['autoBattles'] as int?) ?? 0;
    final manualBattles = (_metrics['manualBattles'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // AUTO column
          Expanded(
            child: _statsColumn(
              'AUTO',
              Colors.green,
              [
                ('Wins', '$autoWins'),
                ('Battles', '$autoBattles'),
                ('Avg Time', '${avgAutoTime.toStringAsFixed(1)}s'),
                ('Back Atk', '${autoBackPct.toStringAsFixed(1)}%'),
              ],
            ),
          ),

          // VS divider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Mode switch button
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: _toggleMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isManualMode
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      _isManualMode ? 'Switch AUTO' : 'Switch MANUAL',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MANUAL column
          Expanded(
            child: _statsColumn(
              'MANUAL',
              Colors.orange,
              [
                ('Wins', '$manualWins'),
                ('Battles', '$manualBattles'),
                ('Avg Time', '${avgManualTime.toStringAsFixed(1)}s'),
                ('Back Atk', '${manualBackPct.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsColumn(
    String title,
    Color color,
    List<(String label, String value)> stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        for (final stat in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${stat.$1}: ',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                Text(
                  stat.$2,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Unit status bar
  Widget _buildUnitStatus() {
    final allies = _units.where((u) => u.isAlly).toList();
    final enemies = _units.where((u) => !u.isAlly).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final u in allies) ...[
              _buildUnitChip(u),
              const SizedBox(width: 4),
            ],
            if (allies.isNotEmpty && enemies.isNotEmpty)
              Container(
                width: 1,
                height: 28,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
            for (final u in enemies) ...[
              _buildUnitChip(u),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitChip(S4UnitInfo unit) {
    final isDead = unit.currentHp <= 0;
    final Color chipColor;
    if (!unit.isAlly) {
      chipColor = const Color(0xFFFF4444);
    } else if (unit.isManualMode) {
      chipColor = const Color(0xFFFFCC44);
    } else {
      chipColor = const Color(0xFF4488FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDead ? Colors.grey.shade900 : chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDead
              ? Colors.grey.shade700
              : unit.isManualMode
                  ? Colors.orange
                  : chipColor.withValues(alpha: 0.5),
          width: unit.isManualMode ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unit.name,
            style: TextStyle(
              color: isDead ? Colors.white30 : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 30,
            height: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: unit.hpRatio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: hpColor(unit.hpRatio),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            isDead ? 'X' : '${unit.currentHp}',
            style: TextStyle(
              color: isDead ? Colors.red.shade300 : Colors.white60,
              fontSize: 8,
            ),
          ),
          if (unit.isManualMode) ...[
            const SizedBox(width: 3),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
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

  /// Bottom bar
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
              'POC-S4: Auto vs Manual intervention comparison - battles auto-reset after 3s',
              style: TextStyle(color: Colors.white30, fontSize: 9),
            ),
          ),
          _actionButton(
            _isManualMode ? 'SWITCH AUTO' : 'SWITCH MANUAL',
            _isManualMode ? Colors.green.shade700 : Colors.orange.shade700,
            _toggleMode,
          ),
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
