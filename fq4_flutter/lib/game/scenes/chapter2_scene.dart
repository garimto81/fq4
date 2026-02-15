import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

/// Chapter 2 "사막의 시련" 전투 씬
class Chapter2Scene extends Component {
  final GameManager gameManager;

  Chapter2Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (사막색)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFFc2a33d),
    ));

    // 플레이어 부대 0 스폰
    _spawnPlayerSquad0();

    // 플레이어 부대 1 스폰
    _spawnPlayerSquad1();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad0() {
    // 아레스 (레벨 5)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 140,
      maxMp: 50,
      attack: 32,
      defense: 20,
      speed: 90,
      luck: 12,
      level: 5,
      position: Vector2(300, 700),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (레벨 4)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 110,
      maxMp: 70,
      attack: 26,
      defense: 15,
      speed: 80,
      luck: 10,
      level: 4,
      isPlayerSide: true,
      position: Vector2(260, 740),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (레벨 4)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 80,
      maxMp: 120,
      attack: 20,
      defense: 12,
      speed: 75,
      luck: 16,
      level: 4,
      isPlayerSide: true,
      position: Vector2(340, 740),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);
  }

  void _spawnPlayerSquad1() {
    // 부대 1: 아처 2명 (defensive)
    for (int i = 0; i < 2; i++) {
      final archer = AIUnitComponent(
        unitName: 'Archer ${i + 1}',
        maxHp: 55,
        maxMp: 35,
        attack: 20,
        defense: 8,
        speed: 95,
        luck: 12,
        level: 3,
        isPlayerSide: true,
        position: Vector2(250 + i * 50.0, 800),
        personality: Personality.defensive,
      );
      archer.squadId = 1;
      add(archer);
      gameManager.registerUnit(archer, isPlayer: true, squadId: 1);
    }
  }

  void _spawnEnemies() {
    // 밴디트 4체
    final banditPositions = [
      Vector2(900, 600),
      Vector2(1000, 620),
      Vector2(1100, 600),
      Vector2(1000, 700),
    ];

    for (int i = 0; i < 4; i++) {
      final bandit = EnemyUnitComponent(
        unitName: 'Bandit ${i + 1}',
        maxHp: 50,
        maxMp: 10,
        attack: 15,
        defense: 8,
        speed: 55,
        luck: 5,
        level: 3,
        position: banditPositions[i],
        expReward: 18,
        goldReward: 8,
      );
      add(bandit);
      gameManager.registerUnit(bandit, isPlayer: false);
    }

    // 밴디트 리더 (보스)
    final boss = BossUnitComponent(
      unitName: 'Bandit Leader',
      maxHp: 350,
      maxMp: 40,
      attack: 28,
      defense: 18,
      speed: 50,
      luck: 8,
      level: 5,
      position: Vector2(1200, 500),
      expReward: 150,
      goldReward: 80,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
