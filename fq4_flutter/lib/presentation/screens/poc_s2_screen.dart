// POC-S2 Screen: 사거리 타입 간 상성 유효성 검증 화면
//
// 목적: 무기 사거리 상성(melee>longRange, midRange>melee, longRange>midRange)이
// 전투 결과에 실제로 영향을 미치는지 100회 자동 시뮬레이션으로 통계 검증.
// 상단 65%: Flame 전투 시각화
// 하단 35%: 3개 매치별 승률 바 그래프 + 시뮬레이션 로그
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_s2_range_rps.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-S2: 사거리 상성 유효성 검증 화면
class PocS2Screen extends StatefulWidget {
  const PocS2Screen({super.key});

  @override
  State<PocS2Screen> createState() => _PocS2ScreenState();
}

class _PocS2ScreenState extends State<PocS2Screen> with PocScreenMixin {
  late PocS2Game _game;
  late PocGameAdapter _adapter;

  String _statusText = 'Preparing simulation...';
  List<S2UnitInfo> _units = [];
  Map<String, dynamic> _metrics = {};
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s2')!);
    _initGame();
  }

  void _initGame() {
    _game = PocS2Game();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
    // S2 is auto-simulation, start immediately
    _adapter.start();
  }

  void _onStatusUpdate(String status) {
    safeSetState(() => _statusText = status);
  }

  void _onUnitsUpdated(List<S2UnitInfo> units) {
    safeSetState(() => _units = units);
  }

  void _onMetricsUpdated(Map<String, dynamic> metrics) {
    safeSetState(() => _metrics = metrics);
    // Auto-evaluate when simulation completes
    if (!_adapter.hasResult) {
      final complete = metrics['simulationComplete'] as bool? ?? false;
      if (complete) {
        _adapter.evaluate(metrics);
        safeSetState(() {});
      }
    }
  }

  void _resetGame() {
    setState(() {
      battleLogs.clear();
      _statusText = 'Preparing simulation...';
      _units = [];
      _metrics = {};
    });
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s2')!);
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC-S2: Range RPS Simulation'),
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

          // 상단: Flame 게임 (flex: 2)
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
                // 진행률 표시
                Positioned(
                  right: 12,
                  top: 12,
                  child: _buildProgressChip(),
                ),
              ],
            ),
          ),

          _buildSpeedBar(),

          // 하단 패널 (flex: 1)
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0D1117),
              child: Column(
                children: [
                  // 3매치 승률 바 그래프
                  _buildMatchResults(),
                  // 현재 라운드 유닛 상태
                  _buildCurrentRoundUnits(),
                  // 시뮬레이션 로그
                  Expanded(child: _buildSimLog()),
                  // 검증 결과
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-S2: Range RPS',
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
      color: const Color(0xFF3A1A5C),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POC-S2: Range RPS Effectiveness Verification (Auto-Simulation)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Verify weapon range RPS (melee>long, mid>melee, long>mid) '
            'produces statistically significant win rates via 30 rounds per matchup.',
            style: TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChip() {
    final totalRounds = _metrics['totalRounds'] as int? ?? 0;
    final maxRounds = _metrics['maxTotalRounds'] as int? ?? 90;
    final complete = _metrics['simulationComplete'] as bool? ?? false;
    final progress = maxRounds > 0 ? totalRounds / maxRounds : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: complete
            ? Colors.green.shade900.withValues(alpha: 0.8)
            : Colors.blue.shade900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation(
                  complete ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            complete ? 'DONE' : '$totalRounds/$maxRounds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 3매치별 승률 바 그래프
  Widget _buildMatchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMatchBar(
              'Melee vs Long',
              'Melee',
              'Long',
              Colors.red,
              Colors.blue,
              _metrics['match1_sideARate'] as double? ?? 0,
              _metrics['match1_sideAWins'] as int? ?? 0,
              _metrics['match1_sideBWins'] as int? ?? 0,
              _metrics['match1_total'] as int? ?? 0,
              _metrics['match1_passed'] as bool? ?? false,
              1.3,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMatchBar(
              'Mid vs Melee',
              'Mid',
              'Melee',
              Colors.yellow,
              Colors.red,
              _metrics['match2_sideARate'] as double? ?? 0,
              _metrics['match2_sideAWins'] as int? ?? 0,
              _metrics['match2_sideBWins'] as int? ?? 0,
              _metrics['match2_total'] as int? ?? 0,
              _metrics['match2_passed'] as bool? ?? false,
              1.2,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMatchBar(
              'Long vs Mid',
              'Long',
              'Mid',
              Colors.blue,
              Colors.yellow,
              _metrics['match3_sideARate'] as double? ?? 0,
              _metrics['match3_sideAWins'] as int? ?? 0,
              _metrics['match3_sideBWins'] as int? ?? 0,
              _metrics['match3_total'] as int? ?? 0,
              _metrics['match3_passed'] as bool? ?? false,
              1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBar(
    String title,
    String sideALabel,
    String sideBLabel,
    Color sideAColor,
    Color sideBColor,
    double sideARate,
    int sideAWins,
    int sideBWins,
    int total,
    bool passed,
    double expectedMultiplier,
  ) {
    final pctA = (sideARate * 100).toStringAsFixed(0);
    final pctB = ((1 - sideARate) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: passed
            ? Colors.green.withValues(alpha: 0.08)
            : total > 0
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: passed
              ? Colors.green.withValues(alpha: 0.4)
              : total > 0
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 타이틀
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${expectedMultiplier}x advantage',
            style: const TextStyle(color: Colors.white38, fontSize: 8),
          ),
          const SizedBox(height: 3),
          // 승률 바 (양쪽)
          SizedBox(
            height: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Row(
                children: [
                  Expanded(
                    flex: (sideARate * 100).round().clamp(1, 99),
                    child: Container(color: sideAColor.withValues(alpha: 0.7)),
                  ),
                  Expanded(
                    flex: ((1 - sideARate) * 100).round().clamp(1, 99),
                    child: Container(color: sideBColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          // 승수 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sideALabel $pctA%',
                style: TextStyle(color: sideAColor, fontSize: 8),
              ),
              Text(
                '$sideBLabel $pctB%',
                style: TextStyle(color: sideBColor, fontSize: 8),
              ),
            ],
          ),
          Text(
            '$sideAWins:$sideBWins ($total rounds)',
            style: const TextStyle(color: Colors.white54, fontSize: 8),
          ),
          // PASS/FAIL
          if (total > 0)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: passed
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                passed ? 'PASS' : 'FAIL',
                style: TextStyle(
                  color: passed ? Colors.green : Colors.red,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 현재 라운드 유닛 상태 표시
  Widget _buildCurrentRoundUnits() {
    if (_units.isEmpty) return const SizedBox.shrink();

    final sideA = _units.where((u) => u.isAlly).toList();
    final sideB = _units.where((u) => !u.isAlly).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final u in sideA) ...[
              _buildUnitMini(u, true),
              const SizedBox(width: 4),
            ],
            Container(
              width: 1, height: 20, color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            for (final u in sideB) ...[
              _buildUnitMini(u, false),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitMini(S2UnitInfo unit, bool isAlly) {
    final isDead = unit.currentHp <= 0;
    final color = _rangeColor(unit.weaponRange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDead ? Colors.grey.shade900 : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isDead ? Colors.grey.shade700 : color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        '${unit.name} ${isDead ? "X" : "${unit.currentHp}"}',
        style: TextStyle(
          color: isDead ? Colors.white30 : Colors.white70,
          fontSize: 8,
        ),
      ),
    );
  }

  Color _rangeColor(String range) {
    return switch (range) {
      'melee' => Colors.red,
      'midRange' => Colors.yellow,
      'longRange' => Colors.blue,
      _ => Colors.grey,
    };
  }

  Widget _buildSimLog() {
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
                  'Simulation Log',
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
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                _metricChip(
                  'Match',
                  '${_metrics['currentMatch'] ?? 1}/${_metrics['matchCount'] ?? 3}',
                ),
                _metricChip(
                  'Rounds',
                  '${_metrics['totalRounds'] ?? 0}/${_metrics['maxTotalRounds'] ?? 90}',
                ),
              ],
            ),
          ),
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
