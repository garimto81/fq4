// Chapter 9 "최후의 결전" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter9Scene extends Component {
  final GameManager gameManager;

  Chapter9Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (피빛 어둠)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF1a0a0a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (플레이어) Lv10
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 220,
      maxMp: 90,
      attack: 50,
      defense: 32,
      speed: 92,
      luck: 16,
      level: 10,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (AI balanced) Lv10
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 165,
      maxMp: 110,
      attack: 38,
      defense: 24,
      speed: 82,
      luck: 13,
      level: 10,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (AI defensive) Lv10
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 110,
      maxMp: 175,
      attack: 30,
      defense: 20,
      speed: 77,
      luck: 19,
      level: 10,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (AI aggressive) Lv10
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 185,
      maxMp: 45,
      attack: 44,
      defense: 28,
      speed: 84,
      luck: 11,
      level: 10,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);

    // 미라 (AI balanced) Lv10
    final mira = AIUnitComponent(
      unitName: 'Mira',
      maxHp: 100,
      maxMp: 185,
      attack: 26,
      defense: 18,
      speed: 80,
      luck: 21,
      level: 10,
      isPlayerSide: true,
      position: Vector2(480, 680),
      personality: Personality.balanced,
    );
    mira.squadId = 0;
    add(mira);
    gameManager.registerUnit(mira, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 데몬 5체
    final demonPositions = [
      Vector2(950, 500),
      Vector2(1050, 500),
      Vector2(900, 600),
      Vector2(1000, 600),
      Vector2(1100, 600),
    ];

    for (int i = 0; i < 5; i++) {
      final demon = EnemyUnitComponent(
        unitName: 'Demon ${i + 1}',
        maxHp: 120,
        maxMp: 50,
        attack: 34,
        defense: 18,
        speed: 55,
        luck: 5,
        level: 9,
        position: demonPositions[i],
        expReward: 50,
        goldReward: 22,
      );
      add(demon);
      gameManager.registerUnit(demon, isPlayer: false);
    }

    // 오크 4체
    final orcPositions = [
      Vector2(1200, 550),
      Vector2(1300, 550),
      Vector2(1150, 650),
      Vector2(1250, 650),
    ];

    for (int i = 0; i < 4; i++) {
      final orc = EnemyUnitComponent(
        unitName: 'Orc ${i + 1}',
        maxHp: 100,
        maxMp: 0,
        attack: 28,
        defense: 22,
        speed: 45,
        luck: 4,
        level: 8,
        position: orcPositions[i],
        expReward: 40,
        goldReward: 18,
      );
      add(orc);
      gameManager.registerUnit(orc, isPlayer: false);
    }

    // 보스: 데몬 장군
    final boss = BossUnitComponent(
      unitName: 'Demon General',
      maxHp: 800,
      maxMp: 150,
      attack: 52,
      defense: 34,
      speed: 48,
      luck: 8,
      level: 10,
      position: Vector2(1400, 600),
      expReward: 500,
      goldReward: 250,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
