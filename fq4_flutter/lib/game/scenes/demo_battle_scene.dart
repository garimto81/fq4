import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/player_unit_component.dart';
import '../components/units/ai_unit_component.dart';
import '../components/units/enemy_unit_component.dart';
import '../components/units/boss_unit_component.dart';
import '../../core/constants/ai_constants.dart';

/// 데모 전투 씬 - 테스트/프로토타입용
class DemoBattleScene extends Component {
  final GameManager gameManager;

  DemoBattleScene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (간단한 색상 박스)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF1a3a1a),
    ));

    // 플레이어 부대 0
    _spawnPlayerSquad0();

    // 플레이어 부대 1
    _spawnPlayerSquad1();

    // 적 부대
    _spawnEnemies();
  }

  void _spawnPlayerSquad0() {
    // 아레스 (리더, 플레이어 조작)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 120,
      maxMp: 40,
      attack: 28,
      defense: 18,
      speed: 85,
      luck: 10,
      level: 3,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (아군 AI)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 90,
      maxMp: 60,
      attack: 22,
      defense: 12,
      speed: 75,
      luck: 8,
      level: 2,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (아군 AI, 서포트)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 65,
      maxMp: 100,
      attack: 16,
      defense: 10,
      speed: 70,
      luck: 14,
      level: 2,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);
  }

  void _spawnPlayerSquad1() {
    // 부대 1 (원거리)
    for (int i = 0; i < 2; i++) {
      final archer = AIUnitComponent(
        unitName: 'Archer ${i + 1}',
        maxHp: 50,
        maxMp: 30,
        attack: 18,
        defense: 6,
        speed: 90,
        luck: 12,
        level: 2,
        isPlayerSide: true,
        position: Vector2(350 + i * 50.0, 700),
        personality: Personality.defensive,
      );
      archer.squadId = 1;
      add(archer);
      gameManager.registerUnit(archer, isPlayer: true, squadId: 1);
    }
  }

  void _spawnEnemies() {
    // 고블린 5체
    for (int i = 0; i < 5; i++) {
      final goblin = EnemyUnitComponent(
        unitName: 'Goblin ${i + 1}',
        maxHp: 35,
        maxMp: 0,
        attack: 10,
        defense: 4,
        speed: 45,
        luck: 3,
        level: 1,
        position: Vector2(800 + (i % 3) * 80.0, 500 + (i ~/ 3) * 80.0),
        expReward: 12,
        goldReward: 5,
      );
      add(goblin);
      gameManager.registerUnit(goblin, isPlayer: false);
    }

    // 고블린 치프 (보스)
    final boss = BossUnitComponent(
      unitName: 'Goblin Chief',
      maxHp: 200,
      maxMp: 30,
      attack: 20,
      defense: 12,
      speed: 40,
      luck: 5,
      level: 3,
      position: Vector2(1000, 550),
      expReward: 100,
      goldReward: 50,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
