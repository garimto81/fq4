// Chapter 6 "불의 산" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter6Scene extends Component {
  final GameManager gameManager;

  Chapter6Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (어두운 적색 - 화산)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF3a1a1a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (Lv7)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 200,
      maxMp: 80,
      attack: 44,
      defense: 32,
      speed: 100,
      luck: 16,
      level: 7,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (Lv7)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 160,
      maxMp: 100,
      attack: 34,
      defense: 24,
      speed: 90,
      luck: 14,
      level: 7,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (Lv7)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 115,
      maxMp: 170,
      attack: 28,
      defense: 22,
      speed: 85,
      luck: 20,
      level: 7,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (Lv7)
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 180,
      maxMp: 40,
      attack: 42,
      defense: 28,
      speed: 90,
      luck: 12,
      level: 7,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 와이번 4체
    final wyvernPositions = [
      Vector2(800, 500),
      Vector2(900, 500),
      Vector2(800, 590),
      Vector2(900, 590),
    ];

    for (int i = 0; i < 4; i++) {
      final wyvern = EnemyUnitComponent(
        unitName: 'Wyvern ${i + 1}',
        maxHp: 80,
        maxMp: 0,
        attack: 26,
        defense: 12,
        speed: 80,
        luck: 6,
        level: 5,
        position: wyvernPositions[i],
        expReward: 30,
        goldReward: 12,
      );
      add(wyvern);
      gameManager.registerUnit(wyvern, isPlayer: false);
    }

    // 골렘 3체
    final golemPositions = [
      Vector2(1020, 530),
      Vector2(1120, 530),
      Vector2(1070, 610),
    ];

    for (int i = 0; i < 3; i++) {
      final golem = EnemyUnitComponent(
        unitName: 'Golem ${i + 1}',
        maxHp: 160,
        maxMp: 0,
        attack: 30,
        defense: 28,
        speed: 20,
        luck: 2,
        level: 6,
        position: golemPositions[i],
        expReward: 50,
        goldReward: 25,
      );
      add(golem);
      gameManager.registerUnit(golem, isPlayer: false);
    }

    // 데몬 제너럴 (보스)
    final boss = BossUnitComponent(
      unitName: 'Demon General',
      maxHp: 600,
      maxMp: 120,
      attack: 42,
      defense: 28,
      speed: 45,
      luck: 8,
      level: 8,
      position: Vector2(1200, 570),
      expReward: 350,
      goldReward: 150,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
