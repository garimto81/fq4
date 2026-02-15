// POC-S5 Screen: AI Flanking Behavior Verification
//
// 목적: AI가 동적 적 상대로 측면/후방 기동을 적극 시도하는지 실시간 확인.
// 상단 65%: Flame 전투 시각화
// 하단 35%: 방향별/성격별 flanking 통계 + 전투 로그
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_s5_flanking.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-S5: AI Flanking Behavior Verification Screen
class PocS5Screen extends StatefulWidget {
  const PocS5Screen({super.key});

  @override
  State<PocS5Screen> createState() => _PocS5ScreenState();
}

class _PocS5ScreenState extends State<PocS5Screen> with PocScreenMixin {
  late PocS5Game _game;
  late PocGameAdapter _adapter;

  String _statusText = 'Preparing...';
  List<S5UnitInfo> _units = [];
  Map<String, dynamic> _metrics = {};
  bool _started = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s5')!);
    _initGame();
  }

  void _initGame() {
    _game = PocS5Game();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
  }

  void _onStatusUpdate(String status) {
    safeSetState(() => _statusText = status);
  }

  void _onUnitsUpdated(List<S5UnitInfo> units) {
    safeSetState(() => _units = units);
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
      _statusText = 'Preparing...';
      _units = [];
      _metrics = {};
      _started = false;
    });
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s5')!);
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC-S5: AI Flanking'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/poc-hub'),
        ),
      ),
      body: Column(
        children: [
          // POC 목적 배너
          _buildPurposeBanner(),

          // 상단: Flame 게임 (flex: 2 = 약 65%)
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GameWidget(game: _game),
                // 상태 표시
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ],
            ),
          ),

          _buildSpeedBar(),

          // 하단 패널 (flex: 1 = 약 35%)
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0D1117),
              child: Column(
                children: [
                  // 유닛 상태 바
                  _buildUnitStatusSection(),
                  // Flanking 통계
                  _buildFlankingStats(),
                  // 전투 로그
                  Expanded(child: _buildBattleLog()),
                  // 검증 결과
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-S5: AI Flanking Behavior',
                        result: _adapter.result,
                      ),
                    ),
                  // 버튼
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A3A5C),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POC-S5: AI Flanking Behavior Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Verify that AI actively seeks flanking and rear attack positions against moving targets. '
            'All personality types attempt flanking with different probabilities.',
            style: TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitStatusSection() {
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
              const SizedBox(width: 6),
            ],
            if (allies.isNotEmpty && enemies.isNotEmpty)
              Container(
                width: 1,
                height: 28,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            for (final u in enemies) ...[
              _buildUnitChip(u),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitChip(S5UnitInfo unit) {
    final hpRatio = unit.hpRatio;
    final isDead = unit.currentHp <= 0;
    final Color chipColor;
    if (!unit.isAlly) {
      chipColor = const Color(0xFFAA44FF);
    } else {
      chipColor = switch (unit.personality) {
        'aggressive' => const Color(0xFFFF4444),
        'balanced' => const Color(0xFFFFCC44),
        'defensive' => const Color(0xFF4488FF),
        _ => Colors.grey,
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDead ? Colors.grey.shade900 : chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDead ? Colors.grey.shade700 : chipColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unit.name,
            style: TextStyle(
              color: isDead ? Colors.white30 : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            height: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hpRatio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: hpColor(hpRatio),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isDead ? 'DEAD' : '${unit.currentHp}',
            style: TextStyle(
              color: isDead ? Colors.red.shade300 : Colors.white60,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Flanking 통계 패널
  Widget _buildFlankingStats() {
    final frontAttacks = _metrics['frontAttacks'] as int? ?? 0;
    final sideAttacks = _metrics['sideAttacks'] as int? ?? 0;
    final backAttacks = _metrics['backAttacks'] as int? ?? 0;
    final totalAttacks = _metrics['totalAttacks'] as int? ?? 0;
    final flankingAttempts = _metrics['flankingAttempts'] as int? ?? 0;
    final backAttackRatio = _metrics['backAttackRatio'] as double? ?? 0.0;
    final sideBackRatio = _metrics['sideBackRatio'] as double? ?? 0.0;
    final aggressiveFlankRate = _metrics['aggressiveFlankRate'] as double? ?? 0.0;
    final balancedFlankRate = _metrics['balancedFlankRate'] as double? ?? 0.0;
    final defensiveFlankRate = _metrics['defensiveFlankRate'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          // Row 1: Direction stats
          Row(
            children: [
              Expanded(
                child: _buildDirectionCard(
                  'FRONT',
                  frontAttacks,
                  totalAttacks,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDirectionCard(
                  'SIDE',
                  sideAttacks,
                  totalAttacks,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDirectionCard(
                  'BACK',
                  backAttacks,
                  totalAttacks,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Flanking behavior stats
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'Flank Attempts',
                  '$flankingAttempts',
                  Colors.cyan,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'Back Atk Ratio',
                  '${(backAttackRatio * 100).toStringAsFixed(1)}%',
                  Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'Side+Back Ratio',
                  '${(sideBackRatio * 100).toStringAsFixed(1)}%',
                  sideBackRatio >= 0.25 ? Colors.green : Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: Per-personality breakdown
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'AGG Flank',
                  '${(aggressiveFlankRate * 100).toStringAsFixed(0)}%',
                  const Color(0xFFFF4444),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'BAL Flank',
                  '${(balancedFlankRate * 100).toStringAsFixed(0)}%',
                  const Color(0xFFFFCC44),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'DEF Flank',
                  '${(defensiveFlankRate * 100).toStringAsFixed(0)}%',
                  const Color(0xFF4488FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final ratio = total > 0 ? count / total : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade900,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          Text(
            '$count ($pct%)',
            style: const TextStyle(color: Colors.white70, fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // 배틀 시간
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                _metricChip(
                  'Time',
                  '${(_metrics['battleTime'] as double? ?? 0).toStringAsFixed(1)}s',
                ),
                _metricChip(
                  'Total',
                  '${_metrics['totalAttacks'] ?? 0} hits',
                ),
                _metricChip(
                  'Flanks',
                  '${_metrics['flankingAttempts'] ?? 0}',
                ),
              ],
            ),
          ),
          if (!_started)
            _actionButton('BATTLE', Colors.red.shade700, () {
              _game.startBattle();
              _adapter.start();
              setState(() => _started = true);
            }),
          if (_started)
            _actionButton('RESET', Colors.grey.shade700, _resetGame),
          const SizedBox(width: 6),
          _actionButton('BACK', Colors.grey.shade800, () => context.go('/poc-hub')),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
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
