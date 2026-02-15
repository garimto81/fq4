import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../../poc/poc_t0_game.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// Phase 0 POC: Gocha-Kyara AI/수동 전환 검증 화면
///
/// 가로 레이아웃 (1280x800)
/// 상단 65%: Flame 게임 + AUTO/MANUAL 모드 오버레이
/// 하단 35%: 유닛 상태, 전투 로그, 메트릭, 버튼
class PocT0Screen extends StatefulWidget {
  const PocT0Screen({super.key});

  @override
  State<PocT0Screen> createState() => _PocT0ScreenState();
}

class _PocT0ScreenState extends State<PocT0Screen> with PocScreenMixin {
  late PocT0Game _game;
  late PocGameAdapter _adapter;

  String _currentMode = 'AUTO';
  String _statusText = 'Preparing...';
  List<UnitInfo> _units = [];
  Map<String, dynamic> _metrics = {};
  bool _started = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-t0')!);
    _initGame();
  }

  void _initGame() {
    _game = PocT0Game();
    _game.onStatusUpdate = _onStatusUpdate;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onLogAdded = (log) => addLog(log);
    _game.onMetricsUpdated = _onMetricsUpdated;
  }

  void _onStatusUpdate(String status) {
    safeSetState(() {
      _statusText = status;
      // AUTO/MANUAL 추출
      if (status.startsWith('MANUAL')) {
        _currentMode = 'MANUAL';
      } else if (status.startsWith('AUTO')) {
        _currentMode = 'AUTO';
      }
    });
  }

  void _onUnitsUpdated(List<UnitInfo> units) {
    safeSetState(() => _units = units);
  }

  void _onMetricsUpdated(Map<String, dynamic> metrics) {
    safeSetState(() => _metrics = metrics);
    // Auto-evaluate when battle ends
    if (!_adapter.hasResult) {
      final alliesAlive = metrics['alliesAlive'] as int? ?? 0;
      final enemiesAlive = metrics['enemiesAlive'] as int? ?? 0;
      if (alliesAlive == 0 || enemiesAlive == 0) {
        _adapter.evaluate(metrics);
        safeSetState(() {});
      }
    }
  }

  void _resetGame() {
    setState(() {
      battleLogs.clear();
      _currentMode = 'AUTO';
      _statusText = 'Preparing...';
      _units = [];
      _metrics = {};
      _started = false;
    });
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-t0')!);
    _initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Phase 0: Gocha-Kyara POC'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/poc-hub'),
        ),
      ),
      body: Column(
        children: [
          // 상단: Flame 게임 + 오버레이 (flex: 2)
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                // Flame 게임
                GameWidget(game: _game),

                // AUTO/MANUAL 모드 표시 (좌측 상단)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _buildModeChip(),
                ),

                // 상태 텍스트 (좌측 상단, 모드 아래)
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

                // 조작 안내 (우측 상단)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('WASD: Move', style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text('Space: Attack', style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text('Q/E: Switch Unit', style: TextStyle(color: Colors.white54, fontSize: 9)),
                        Text('3s idle -> Auto', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      ],
                    ),
                  ),
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
                  // 유닛 상태 바
                  _buildUnitStatusSection(),

                  // 전투 로그
                  Expanded(child: _buildBattleLog()),

                  // 검증 결과
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: PocVerificationCard(
                        pocName: 'POC-T0: Gocha-Kyara AI/Manual Switch',
                        result: _adapter.result,
                      ),
                    ),

                  // 메트릭 + 버튼
                  _buildMetricsAndButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AUTO/MANUAL 모드 칩
  Widget _buildModeChip() {
    final isManual = _currentMode == 'MANUAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isManual ? Colors.orange.shade800 : Colors.green.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isManual ? Colors.orange : Colors.green,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isManual ? Icons.gamepad : Icons.smart_toy,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _currentMode,
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

  /// 유닛 상태 섹션
  Widget _buildUnitStatusSection() {
    final allies = _units.where((u) => u.isAlly).toList();
    final enemies = _units.where((u) => !u.isAlly).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 아군
            for (final u in allies) ...[
              _buildUnitChip(u),
              const SizedBox(width: 6),
            ],
            // 구분선
            if (allies.isNotEmpty && enemies.isNotEmpty)
              Container(
                width: 1,
                height: 28,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            // 적
            for (final u in enemies) ...[
              _buildUnitChip(u),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  /// 유닛 칩 위젯
  Widget _buildUnitChip(UnitInfo unit) {
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
          // 이름
          Text(
            unit.name,
            style: TextStyle(
              color: isDead ? Colors.white30 : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          // HP 바
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
          // HP 텍스트
          Text(
            isDead ? 'DEAD' : '${unit.currentHp}',
            style: TextStyle(
              color: isDead ? Colors.red.shade300 : Colors.white60,
              fontSize: 9,
            ),
          ),
          // 수동 모드 표시
          if (unit.isManualMode) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
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

  /// 전투 로그 리스트
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

  /// 메트릭 + 버튼
  Widget _buildMetricsAndButtons() {
    final inputLatency = _metrics['inputLatency'] as double? ?? 0;
    final battleTime = _metrics['battleTime'] as double? ?? 0;
    final alliesAlive = _metrics['alliesAlive'] as int? ?? 0;
    final enemiesAlive = _metrics['enemiesAlive'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // 메트릭
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                _metricChip('Latency', '${inputLatency.toStringAsFixed(1)}ms'),
                _metricChip('Time', '${battleTime.toStringAsFixed(1)}s'),
                _metricChip('Allies', '$alliesAlive'),
                _metricChip('Enemies', '$enemiesAlive'),
              ],
            ),
          ),
          // 버튼
          if (!_started)
            _actionButton('BATTLE START', Colors.red.shade700, () {
              _game.startBattle();
              _adapter.start();
              setState(() => _started = true);
            }),
          if (_started) ...[
            _actionButton('RESET', Colors.grey.shade700, _resetGame),
          ],
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
