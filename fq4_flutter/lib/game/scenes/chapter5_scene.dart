// Chapter 5 "독의 늪" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter5Scene extends Component {
  final GameManager gameManager;

  Chapter5Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (어두운 녹색 - 독의 늪)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF1a2a1a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (Lv6)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 180,
      maxMp: 70,
      attack: 40,
      defense: 28,
      speed: 95,
      luck: 14,
      level: 6,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (Lv6)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 140,
      maxMp: 90,
      attack: 30,
      defense: 20,
      speed: 85,
      luck: 12,
      level: 6,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (Lv6)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 100,
      maxMp: 150,
      attack: 24,
      defense: 18,
      speed: 80,
      luck: 18,
      level: 6,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (Lv6)
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 160,
      maxMp: 30,
      attack: 38,
      defense: 24,
      speed: 85,
      luck: 10,
      level: 6,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 포이즌 스파이더 5체
    final spiderPositions = [
      Vector2(800, 500),
      Vector2(880, 500),
      Vector2(960, 500),
      Vector2(840, 580),
      Vector2(920, 580),
    ];

    for (int i = 0; i < 5; i++) {
      final spider = EnemyUnitComponent(
        unitName: 'Poison Spider ${i + 1}',
        maxHp: 40,
        maxMp: 0,
        attack: 14,
        defense: 6,
        speed: 70,
        luck: 5,
        level: 4,
        position: spiderPositions[i],
        expReward: 18,
        goldReward: 7,
      );
      add(spider);
      gameManager.registerUnit(spider, isPlayer: false);
    }

    // 스왐프 비스트 4체
    final beastPositions = [
      Vector2(1040, 520),
      Vector2(1120, 520),
      Vector2(1040, 600),
      Vector2(1120, 600),
    ];

    for (int i = 0; i < 4; i++) {
      final beast = EnemyUnitComponent(
        unitName: 'Swamp Beast ${i + 1}',
        maxHp: 90,
        maxMp: 0,
        attack: 22,
        defense: 14,
        speed: 35,
        luck: 3,
        level: 5,
        position: beastPositions[i],
        expReward: 35,
        goldReward: 15,
      );
      add(beast);
      gameManager.registerUnit(beast, isPlayer: false);
    }

    // 코럽티드 노블 (보스)
    final boss = BossUnitComponent(
      unitName: 'Corrupted Noble',
      maxHp: 450,
      maxMp: 80,
      attack: 36,
      defense: 22,
      speed: 40,
      luck: 7,
      level: 7,
      position: Vector2(1200, 560),
      expReward: 250,
      goldReward: 100,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
