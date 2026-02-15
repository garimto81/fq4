// Chapter 8 "마왕의 영역" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter8Scene extends Component {
  final GameManager gameManager;

  Chapter8Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (매우 어두운 영역)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF0a0a1a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (플레이어) Lv9
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 200,
      maxMp: 80,
      attack: 46,
      defense: 30,
      speed: 90,
      luck: 15,
      level: 9,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (AI balanced) Lv9
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 150,
      maxMp: 100,
      attack: 36,
      defense: 22,
      speed: 80,
      luck: 12,
      level: 9,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (AI defensive) Lv9
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 100,
      maxMp: 160,
      attack: 28,
      defense: 18,
      speed: 75,
      luck: 18,
      level: 9,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (AI aggressive) Lv9
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 170,
      maxMp: 40,
      attack: 40,
      defense: 26,
      speed: 82,
      luck: 10,
      level: 9,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);

    // 미라 (AI balanced) Lv9
    final mira = AIUnitComponent(
      unitName: 'Mira',
      maxHp: 90,
      maxMp: 170,
      attack: 24,
      defense: 16,
      speed: 78,
      luck: 20,
      level: 9,
      isPlayerSide: true,
      position: Vector2(480, 680),
      personality: Personality.balanced,
    );
    mira.squadId = 0;
    add(mira);
    gameManager.registerUnit(mira, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 데몬 6체
    final demonPositions = [
      Vector2(900, 500),
      Vector2(1000, 500),
      Vector2(1100, 500),
      Vector2(950, 600),
      Vector2(1050, 600),
      Vector2(1000, 700),
    ];

    for (int i = 0; i < 6; i++) {
      final demon = EnemyUnitComponent(
        unitName: 'Demon ${i + 1}',
        maxHp: 100,
        maxMp: 40,
        attack: 30,
        defense: 16,
        speed: 55,
        luck: 5,
        level: 8,
        position: demonPositions[i],
        expReward: 40,
        goldReward: 18,
      );
      add(demon);
      gameManager.registerUnit(demon, isPlayer: false);
    }

    // 스켈레톤 3체
    final skeletonPositions = [
      Vector2(1200, 550),
      Vector2(1150, 650),
      Vector2(1250, 650),
    ];

    for (int i = 0; i < 3; i++) {
      final skeleton = EnemyUnitComponent(
        unitName: 'Skeleton ${i + 1}',
        maxHp: 70,
        maxMp: 0,
        attack: 24,
        defense: 20,
        speed: 40,
        luck: 3,
        level: 7,
        position: skeletonPositions[i],
        expReward: 30,
        goldReward: 12,
      );
      add(skeleton);
      gameManager.registerUnit(skeleton, isPlayer: false);
    }
  }
}
