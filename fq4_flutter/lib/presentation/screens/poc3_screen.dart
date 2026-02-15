import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/poc3_layout_test.dart';
import '../widgets/battle_control_panel.dart';
import '../../poc/infrastructure/poc_game_adapter.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_verification_card.dart';
import 'poc_screen_mixin.dart';

/// POC-3: 세로 모드 레이아웃 테스트 화면
class Poc3Screen extends StatefulWidget {
  const Poc3Screen({super.key});

  @override
  State<Poc3Screen> createState() => _Poc3ScreenState();
}

class _Poc3ScreenState extends State<Poc3Screen> with PocScreenMixin {
  late final LayoutTestGame _game;
  late final PocGameAdapter _adapter;
  List<({String name, double hpRatio})> _allies = [];
  List<({String name, double hpRatio})> _enemies = [];

  @override
  void initState() {
    super.initState();
    _game = LayoutTestGame();
    _adapter = PocGameAdapter(definition: PocManifest.byId('poc-3')!);

    _game.onUnitsUpdated = _onUnitsUpdated;

    // 게임 로드 후 시작
    _adapter.start();
  }

  void _onUnitsUpdated(List<UnitInfo> allies, List<UnitInfo> enemies) {
    safeSetState(() {
      _allies = allies
          .map((u) => (name: u.name, hpRatio: u.hpRatio))
          .toList();
      _enemies = enemies
          .map((u) => (name: u.name, hpRatio: u.hpRatio))
          .toList();
    });

    // 유닛 3개 이상이면 평가
    final totalUnits = _allies.length + _enemies.length;
    if (!_adapter.hasResult && totalUnits >= 3) {
      _adapter.evaluate({
        'allies': _allies.length,
        'enemies': _enemies.length,
        'totalUnits': totalUnits,
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
                    'POC-3: Portrait Layout',
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
            // Flame GameWidget (top 60% = flex 3)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: GameWidget(game: _game),
              ),
            ),
            // Flutter UI panel (bottom 40% = flex 2)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: BattleControlPanel(
                      allies: _allies,
                      enemies: _enemies,
                      buttonALabel: 'Spawn Unit',
                      buttonBLabel: 'Damage Random',
                      onButtonA: () => _game.spawnTestUnit(),
                      onButtonB: () => _game.damageRandomUnit(),
                    ),
                  ),
                  if (_adapter.hasResult)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: PocVerificationCard(
                        pocName: 'POC-3: Portrait Layout',
                        result: _adapter.result,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
