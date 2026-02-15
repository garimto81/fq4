import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/poc5_integrated_battle.dart';
import '../../game/systems/battle_controller.dart';
import '../widgets/unit_status_bar.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-5: 통합 전투 화면 (Rive + 자동전투 + 세로 + 배속)
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with PocScreenMixin {
  late final IntegratedBattleGame _game;
  late final PocGameAdapter _adapter;
  final List<BattleLogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  String _battleState = 'PREPARING';
  double _battleTime = 0;
  double _currentSpeed = 1.0;
  bool _started = false;

  List<_UiUnit> _allies = [];
  List<_UiUnit> _enemies = [];

  @override
  void initState() {
    super.initState();
    _game = IntegratedBattleGame();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-5')!);

    _game.onBattleStateChanged = _onBattleStateChanged;
    _game.onLogAdded = _onLogAdded;
    _game.onUnitsUpdated = _onUnitsUpdated;
    _game.onTimeUpdated = _onTimeUpdated;
  }

  void _onBattleStateChanged(BattleState state) {
    safeSetState(() => _battleState = state.name.toUpperCase());

    // 전투 종료 시 평가
    if (!_adapter.hasResult &&
        (state == BattleState.victory || state == BattleState.defeat)) {
      _adapter.evaluate({
        'battleState': state.name,
        'battleTime': _battleTime,
        'allies': _allies.length,
        'enemies': _enemies.length,
      });
      safeSetState(() {});
    }
  }

  void _onLogAdded(BattleLogEntry entry) {
    safeSetState(() => _logs.add(entry));
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
      _allies = allies.map((u) => _UiUnit(
        name: u.name as String,
        hp: u.hp as int,
        maxHp: u.maxHp as int,
        isDead: u.isDead as bool,
      )).toList();
      _enemies = enemies.map((u) => _UiUnit(
        name: u.name as String,
        hp: u.hp as int,
        maxHp: u.maxHp as int,
        isDead: u.isDead as bool,
      )).toList();
    });
  }

  void _onTimeUpdated(double time) {
    safeSetState(() => _battleTime = time);
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
      body: SafeArea(
        child: Column(
          children: [
            // Flame game viewport (top, flex 4)
            Expanded(
              flex: 4,
              child: GameWidget(game: _game),
            ),
            // Speed controls + timer
            Container(
              color: const Color(0xFF21262D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Speed buttons
                  for (final speed in [1.0, 2.0, 4.0, 8.0, 16.0]) ...[
                    _buildSpeedChip(speed),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  // Timer
                  Text(
                    _formatTime(_battleTime),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // State badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _stateColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _battleState,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            // Unit status bars
            Container(
              color: const Color(0xFF0D1117),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  for (final u in _allies)
                    UnitStatusBar(
                      name: u.name,
                      hpRatio: u.hpRatio,
                      isAlly: true,
                      compact: true,
                    ),
                  if (_enemies.isNotEmpty)
                    const Divider(color: Colors.white12, height: 6),
                  for (final u in _enemies)
                    UnitStatusBar(
                      name: u.name,
                      hpRatio: u.hpRatio,
                      isAlly: false,
                      compact: true,
                    ),
                ],
              ),
            ),
            // Battle log (bottom)
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF161B22),
                child: Column(
                  children: [
                    // Log header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: const Color(0xFF21262D),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Battle Log',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          if (!_started)
                            TextButton(
                              onPressed: () {
                                _adapter.start();
                                _game.startBattle();
                                setState(() => _started = true);
                              },
                              child: const Text(
                                'START',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Log entries
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(6),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              '[${log.time.toStringAsFixed(1)}s] ${log.message}',
                              style: TextStyle(
                                color: _getLogColor(log.type),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Verification card + Back button
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          if (_adapter.hasResult)
                            PocVerificationCard(
                              pocName: 'POC-5: Integrated Battle',
                              result: _adapter.result,
                            ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/poc-hub'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Back', style: TextStyle(fontSize: 12)),
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
      ),
    );
  }

  Widget _buildSpeedChip(double speed) {
    final isActive = (_currentSpeed - speed).abs() < 0.1;
    return GestureDetector(
      onTap: () {
        _game.setSpeed(speed);
        setState(() => _currentSpeed = speed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber.shade800 : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isActive ? '▶${speed.toStringAsFixed(0)}x' : '${speed.toStringAsFixed(0)}x',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _stateColor => switch (_battleState) {
    'FIGHTING' => Colors.red.shade800,
    'VICTORY' => Colors.green.shade800,
    'DEFEAT' => Colors.grey.shade800,
    _ => Colors.blue.shade800,
  };

  Color _getLogColor(LogType type) => switch (type) {
    LogType.combat => Colors.white70,
    LogType.death => Colors.red.shade300,
    LogType.ai => Colors.blue.shade300,
    LogType.system => Colors.yellow.shade300,
  };
}

class _UiUnit {
  final String name;
  final int hp;
  final int maxHp;
  final bool isDead;
  double get hpRatio => maxHp > 0 ? hp / maxHp : 0;

  const _UiUnit({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.isDead,
  });
}
