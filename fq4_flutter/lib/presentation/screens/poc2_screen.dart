import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../game/systems/battle_controller.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc2_autobattle_test.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-2: AI 자동전투 파이프라인 테스트 화면
class Poc2Screen extends StatefulWidget {
  const Poc2Screen({super.key});

  @override
  State<Poc2Screen> createState() => _Poc2ScreenState();
}

class _Poc2ScreenState extends State<Poc2Screen> with PocScreenMixin {
  late final AutoBattleTestGame _game;
  late final PocGameAdapter _adapter;
  final List<BattleLogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  String _battleStateText = 'PREPARING';
  bool _started = false;
  double _currentSpeed = 1.0;

  // Unit status
  List<_UiUnitStatus> _allies = [];
  List<_UiUnitStatus> _enemies = [];

  @override
  void initState() {
    super.initState();
    _game = AutoBattleTestGame();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-2')!);

    _game.onBattleStateChanged = _onBattleStateChanged;
    _game.onLogAdded = _onLogAdded;
    _game.onUnitsUpdated = _onUnitsUpdated;
  }

  void _onBattleStateChanged(BattleState state) {
    safeSetState(() {
      _battleStateText = state.name.toUpperCase();
    });

    // 전투 종료 시 평가
    if (!_adapter.hasResult &&
        (state == BattleState.victory || state == BattleState.defeat)) {
      _adapter.evaluate({
        'battleState': state.name,
        'allies': _allies.length,
        'enemies': _enemies.length,
      });
    }
  }

  void _onLogAdded(BattleLogEntry entry) {
    safeSetState(() {
      _logs.add(entry);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onUnitsUpdated(List allies, List enemies) {
    safeSetState(() {
      _allies = allies.map((u) => _UiUnitStatus(
        name: u.name as String,
        hpRatio: u.hpRatio as double,
        hp: u.hp as int,
        maxHp: u.maxHp as int,
        fatigue: u.fatigue as double,
        isDead: u.isDead as bool,
        state: u.state as String,
      )).toList();
      _enemies = enemies.map((u) => _UiUnitStatus(
        name: u.name as String,
        hpRatio: u.hpRatio as double,
        hp: u.hp as int,
        maxHp: u.maxHp as int,
        fatigue: u.fatigue as double,
        isDead: u.isDead as bool,
        state: u.state as String,
      )).toList();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Game viewport (top 40%)
          Expanded(
            flex: 4,
            child: GameWidget(game: _game),
          ),
          _buildSpeedBar(),
          // Unit status (20%)
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'POC-2: Auto Battle [$_battleStateText]',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_started)
                        ElevatedButton(
                          onPressed: () {
                            _adapter.start();
                            _game.startBattle();
                            setState(() => _started = true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('START BATTLE'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Allies
                  ..._allies.map((u) => _buildUnitBar(u, true)),
                  const Divider(color: Colors.white24, height: 8),
                  // Enemies
                  ..._enemies.map((u) => _buildUnitBar(u, false)),
                ],
              ),
            ),
          ),
          // Battle log (bottom 40%)
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF161B22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFF21262D),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Battle Log',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${_logs.length} entries',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '[${log.time.toStringAsFixed(1)}s] ${log.message}',
                            style: TextStyle(
                              color: _getLogColor(log.type),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Verification card + Back button
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        if (_adapter.hasResult)
                          PocVerificationCard(
                            pocName: 'POC-2: AI Auto-Battle',
                            result: _adapter.result,
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/poc-hub'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitBar(_UiUnitStatus unit, bool isAlly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            isAlly ? '★' : '☠',
            style: TextStyle(
              color: isAlly ? Colors.blue : Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 70,
            child: Text(
              unit.name,
              style: TextStyle(
                color: unit.isDead ? Colors.white30 : Colors.white,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: unit.hpRatio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: unit.isDead
                        ? Colors.grey
                        : unit.hpRatio > 0.5
                            ? Colors.green
                            : unit.hpRatio > 0.25
                                ? Colors.yellow
                                : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: Text(
              unit.isDead ? 'DEAD' : '${unit.hp}/${unit.maxHp}',
              style: TextStyle(
                color: unit.isDead ? Colors.red.shade300 : Colors.white60,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
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

  Color _getLogColor(LogType type) {
    return switch (type) {
      LogType.combat => Colors.white70,
      LogType.death => Colors.red.shade300,
      LogType.ai => Colors.blue.shade300,
      LogType.system => Colors.yellow.shade300,
    };
  }
}

class _UiUnitStatus {
  final String name;
  final double hpRatio;
  final int hp;
  final int maxHp;
  final double fatigue;
  final bool isDead;
  final String state;

  const _UiUnitStatus({
    required this.name,
    required this.hpRatio,
    required this.hp,
    required this.maxHp,
    required this.fatigue,
    required this.isDead,
    required this.state,
  });
}
