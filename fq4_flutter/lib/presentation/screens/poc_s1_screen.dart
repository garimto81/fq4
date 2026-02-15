// POC-S1 Screen: 방향별 데미지 차이 검증 화면
//
// 목적: 공격 방향(정면/측면/후면)에 따라 데미지가 실제로 차등 적용되는지 실시간 확인.
// 상단 65%: Flame 전투 시각화
// 하단 35%: 방향별 공격 통계 + 전투 로그
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_s1_direction.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-S1: 방향별 데미지 차이 검증 화면
class PocS1Screen extends StatefulWidget {
  const PocS1Screen({super.key});

  @override
  State<PocS1Screen> createState() => _PocS1ScreenState();
}

class _PocS1ScreenState extends State<PocS1Screen> with PocScreenMixin {
  late PocS1Game _game;
  late PocGameAdapter _adapter;

  String _statusText = 'Preparing...';
  List<S1UnitInfo> _units = [];
  Map<String, dynamic> _metrics = {};
  bool _started = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s1')!);
    _initGame();
  }

  void _initGame() {
    _game = PocS1Game();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
  }

  void _onStatusUpdate(String status) {
    safeSetState(() => _statusText = status);
  }

  void _onUnitsUpdated(List<S1UnitInfo> units) {
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
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-s1')!);
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC-S1: Directional Combat'),
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
                  // 방향별 데미지 통계
                  _buildDirectionalStats(),
                  // 전투 로그
                  Expanded(child: _buildBattleLog()),
                  // 검증 결과
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-S1: Direction-Based Damage',
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
            'POC-S1: Direction-Based Damage Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Verify that attack direction (front/side/back) applies different damage multipliers, '
            'and observe whether AI attempts flanking maneuvers.',
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

  Widget _buildUnitChip(S1UnitInfo unit) {
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

  /// 방향별 데미지 통계 패널
  Widget _buildDirectionalStats() {
    final frontAttacks = _metrics['frontAttacks'] as int? ?? 0;
    final sideAttacks = _metrics['sideAttacks'] as int? ?? 0;
    final backAttacks = _metrics['backAttacks'] as int? ?? 0;
    final totalAttacks = _metrics['totalAttacks'] as int? ?? 0;
    final avgFrontDmg = _metrics['avgFrontDmg']?.toString() ?? '-';
    final avgSideDmg = _metrics['avgSideDmg']?.toString() ?? '-';
    final avgBackDmg = _metrics['avgBackDmg']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // 정면
          Expanded(
            child: _buildDirectionCard(
              'FRONT (1.0x)',
              frontAttacks,
              totalAttacks,
              avgFrontDmg,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          // 측면
          Expanded(
            child: _buildDirectionCard(
              'SIDE (1.3x)',
              sideAttacks,
              totalAttacks,
              avgSideDmg,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          // 후면
          Expanded(
            child: _buildDirectionCard(
              'BACK (1.5x)',
              backAttacks,
              totalAttacks,
              avgBackDmg,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(
    String label,
    int count,
    int total,
    String avgDmg,
    Color color,
  ) {
    final ratio = total > 0 ? count / total : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(6),
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
          const SizedBox(height: 2),
          // 비율 바
          SizedBox(
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade900,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count hits ($pct%)',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
          Text(
            'Avg: $avgDmg dmg',
            style: const TextStyle(color: Colors.white54, fontSize: 8),
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
