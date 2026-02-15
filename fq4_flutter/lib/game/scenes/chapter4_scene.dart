// Chapter 4 "얼어붙은 성채" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter4Scene extends Component {
  final GameManager gameManager;

  Chapter4Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (어두운 청색 - 얼어붙은 성채)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF1a1a3a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (Lv5)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 160,
      maxMp: 60,
      attack: 36,
      defense: 24,
      speed: 90,
      luck: 12,
      level: 5,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (Lv4)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 120,
      maxMp: 80,
      attack: 26,
      defense: 16,
      speed: 80,
      luck: 10,
      level: 4,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (Lv4)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 85,
      maxMp: 130,
      attack: 20,
      defense: 14,
      speed: 75,
      luck: 16,
      level: 4,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (Lv4, aggressive)
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 140,
      maxMp: 20,
      attack: 32,
      defense: 20,
      speed: 80,
      luck: 8,
      level: 4,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 아이스 울프 6체
    final wolfPositions = [
      Vector2(800, 500),
      Vector2(880, 500),
      Vector2(960, 500),
      Vector2(800, 580),
      Vector2(880, 580),
      Vector2(960, 580),
    ];

    for (int i = 0; i < 6; i++) {
      final wolf = EnemyUnitComponent(
        unitName: 'Ice Wolf ${i + 1}',
        maxHp: 50,
        maxMp: 0,
        attack: 16,
        defense: 8,
        speed: 60,
        luck: 4,
        level: 3,
        position: wolfPositions[i],
        expReward: 20,
        goldReward: 8,
      );
      add(wolf);
      gameManager.registerUnit(wolf, isPlayer: false);
    }

    // 프로스트 자이언트 3체
    final giantPositions = [
      Vector2(1040, 520),
      Vector2(1120, 520),
      Vector2(1080, 600),
    ];

    for (int i = 0; i < 3; i++) {
      final giant = EnemyUnitComponent(
        unitName: 'Frost Giant ${i + 1}',
        maxHp: 120,
        maxMp: 0,
        attack: 28,
        defense: 18,
        speed: 30,
        luck: 3,
        level: 4,
        position: giantPositions[i],
        expReward: 45,
        goldReward: 20,
      );
      add(giant);
      gameManager.registerUnit(giant, isPlayer: false);
    }

    // 리치 (보스)
    final boss = BossUnitComponent(
      unitName: 'Lich',
      maxHp: 400,
      maxMp: 100,
      attack: 32,
      defense: 20,
      speed: 35,
      luck: 6,
      level: 6,
      position: Vector2(1200, 560),
      expReward: 200,
      goldReward: 80,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
