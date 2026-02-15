import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

/// Chapter 3 "어둠의 숲" 전투 씬
class Chapter3Scene extends Component {
  final GameManager gameManager;

  Chapter3Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (어둠 숲)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF0d1a0d),
    ));

    // 플레이어 부대 0 스폰
    _spawnPlayerSquad0();

    // 플레이어 부대 1 스폰
    _spawnPlayerSquad1();

    // 플레이어 부대 2 스폰
    _spawnPlayerSquad2();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad0() {
    // 아레스 (레벨 7)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 160,
      maxMp: 60,
      attack: 36,
      defense: 24,
      speed: 95,
      luck: 14,
      level: 7,
      position: Vector2(300, 700),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (레벨 6)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 130,
      maxMp: 85,
      attack: 30,
      defense: 18,
      speed: 85,
      luck: 12,
      level: 6,
      isPlayerSide: true,
      position: Vector2(260, 740),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (레벨 6)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 95,
      maxMp: 140,
      attack: 24,
      defense: 14,
      speed: 80,
      luck: 18,
      level: 6,
      isPlayerSide: true,
      position: Vector2(340, 740),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);
  }

  void _spawnPlayerSquad1() {
    // 부대 1: 아처 2명 (레벨 5, defensive)
    for (int i = 0; i < 2; i++) {
      final archer = AIUnitComponent(
        unitName: 'Archer ${i + 1}',
        maxHp: 65,
        maxMp: 40,
        attack: 24,
        defense: 10,
        speed: 100,
        luck: 14,
        level: 5,
        isPlayerSide: true,
        position: Vector2(200 + i * 50.0, 800),
        personality: Personality.defensive,
      );
      archer.squadId = 1;
      add(archer);
      gameManager.registerUnit(archer, isPlayer: true, squadId: 1);
    }
  }

  void _spawnPlayerSquad2() {
    // 부대 2: 나이트 2명 (레벨 5, aggressive)
    for (int i = 0; i < 2; i++) {
      final knight = AIUnitComponent(
        unitName: 'Knight ${i + 1}',
        maxHp: 100,
        maxMp: 20,
        attack: 28,
        defense: 22,
        speed: 70,
        luck: 8,
        level: 5,
        isPlayerSide: true,
        position: Vector2(400 + i * 50.0, 800),
        personality: Personality.aggressive,
      );
      knight.squadId = 2;
      add(knight);
      gameManager.registerUnit(knight, isPlayer: true, squadId: 2);
    }
  }

  void _spawnEnemies() {
    // Dark Soldier 6체
    final soldierPositions = [
      Vector2(1000, 600),
      Vector2(1100, 600),
      Vector2(1200, 600),
      Vector2(1000, 700),
      Vector2(1100, 700),
      Vector2(1200, 700),
    ];

    for (int i = 0; i < 6; i++) {
      final soldier = EnemyUnitComponent(
        unitName: 'Dark Soldier ${i + 1}',
        maxHp: 60,
        maxMp: 15,
        attack: 18,
        defense: 12,
        speed: 50,
        luck: 6,
        level: 5,
        position: soldierPositions[i],
        expReward: 25,
        goldReward: 12,
      );
      add(soldier);
      gameManager.registerUnit(soldier, isPlayer: false);
    }

    // Dark Knight (보스)
    final boss = BossUnitComponent(
      unitName: 'Dark Knight',
      maxHp: 500,
      maxMp: 60,
      attack: 35,
      defense: 25,
      speed: 55,
      luck: 10,
      level: 7,
      position: Vector2(1300, 400),
      expReward: 200,
      goldReward: 120,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
