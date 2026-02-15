// Chapter 7 "어둠의 탑" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter7Scene extends Component {
  final GameManager gameManager;

  Chapter7Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (매우 어두운 보라색 - 어둠의 탑)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF2a1a2a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (Lv8)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 220,
      maxMp: 90,
      attack: 48,
      defense: 36,
      speed: 105,
      luck: 18,
      level: 8,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (Lv8)
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 180,
      maxMp: 110,
      attack: 38,
      defense: 28,
      speed: 95,
      luck: 16,
      level: 8,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (Lv8)
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 130,
      maxMp: 190,
      attack: 32,
      defense: 26,
      speed: 90,
      luck: 22,
      level: 8,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (Lv8)
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 200,
      maxMp: 50,
      attack: 46,
      defense: 32,
      speed: 95,
      luck: 14,
      level: 8,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);

    // 미라 (Lv7, defensive - 힐러)
    final mira = AIUnitComponent(
      unitName: 'Mira',
      maxHp: 75,
      maxMp: 150,
      attack: 18,
      defense: 12,
      speed: 75,
      luck: 20,
      level: 7,
      isPlayerSide: true,
      position: Vector2(480, 680),
      personality: Personality.defensive,
    );
    mira.squadId = 0;
    add(mira);
    gameManager.registerUnit(mira, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 섀도우 레이스 5체
    final wraithPositions = [
      Vector2(800, 500),
      Vector2(880, 500),
      Vector2(960, 500),
      Vector2(840, 580),
      Vector2(920, 580),
    ];

    for (int i = 0; i < 5; i++) {
      final wraith = EnemyUnitComponent(
        unitName: 'Shadow Wraith ${i + 1}',
        maxHp: 60,
        maxMp: 0,
        attack: 20,
        defense: 10,
        speed: 75,
        luck: 7,
        level: 6,
        position: wraithPositions[i],
        expReward: 25,
        goldReward: 10,
      );
      add(wraith);
      gameManager.registerUnit(wraith, isPlayer: false);
    }

    // 다크 나이트 4체
    final knightPositions = [
      Vector2(1040, 520),
      Vector2(1120, 520),
      Vector2(1040, 600),
      Vector2(1120, 600),
    ];

    for (int i = 0; i < 4; i++) {
      final knight = EnemyUnitComponent(
        unitName: 'Dark Knight ${i + 1}',
        maxHp: 130,
        maxMp: 0,
        attack: 34,
        defense: 24,
        speed: 45,
        luck: 5,
        level: 7,
        position: knightPositions[i],
        expReward: 55,
        goldReward: 30,
      );
      add(knight);
      gameManager.registerUnit(knight, isPlayer: false);
    }

    // 폴른 히어로 (보스)
    final boss = BossUnitComponent(
      unitName: 'Fallen Hero',
      maxHp: 700,
      maxMp: 100,
      attack: 48,
      defense: 32,
      speed: 50,
      luck: 9,
      level: 9,
      position: Vector2(1200, 560),
      expReward: 400,
      goldReward: 200,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
