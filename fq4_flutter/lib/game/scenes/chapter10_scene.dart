// Chapter 10 "마왕과의 대결" 전투 씬
import 'dart:ui';
import 'package:flame/components.dart';
import '../managers/game_manager.dart';
import '../components/units/units.dart';
import '../../core/constants/ai_constants.dart';

class Chapter10Scene extends Component {
  final GameManager gameManager;

  Chapter10Scene({required this.gameManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 맵 배경 (완전한 어둠)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(2560, 1600),
      paint: Paint()..color = const Color(0xFF0a0a0a),
    ));

    // 플레이어 부대 스폰
    _spawnPlayerSquad();

    // 적 스폰
    _spawnEnemies();
  }

  void _spawnPlayerSquad() {
    // 아레스 (플레이어) Lv12 (최대 레벨)
    final ares = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 250,
      maxMp: 100,
      attack: 58,
      defense: 36,
      speed: 95,
      luck: 18,
      level: 12,
      position: Vector2(400, 600),
    );
    add(ares);
    gameManager.registerUnit(ares, isPlayer: true, squadId: 0);

    // 타로 (AI balanced) Lv12
    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 190,
      maxMp: 130,
      attack: 44,
      defense: 28,
      speed: 86,
      luck: 15,
      level: 12,
      isPlayerSide: true,
      position: Vector2(360, 640),
      personality: Personality.balanced,
    );
    taro.squadId = 0;
    add(taro);
    gameManager.registerUnit(taro, isPlayer: true, squadId: 0);

    // 알레인 (AI defensive) Lv12
    final alein = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 130,
      maxMp: 200,
      attack: 34,
      defense: 24,
      speed: 80,
      luck: 22,
      level: 12,
      isPlayerSide: true,
      position: Vector2(440, 640),
      personality: Personality.defensive,
    );
    alein.squadId = 0;
    add(alein);
    gameManager.registerUnit(alein, isPlayer: true, squadId: 0);

    // 가렌 (AI aggressive) Lv12
    final garen = AIUnitComponent(
      unitName: 'Garen',
      maxHp: 210,
      maxMp: 50,
      attack: 50,
      defense: 32,
      speed: 88,
      luck: 13,
      level: 12,
      isPlayerSide: true,
      position: Vector2(320, 680),
      personality: Personality.aggressive,
    );
    garen.squadId = 0;
    add(garen);
    gameManager.registerUnit(garen, isPlayer: true, squadId: 0);

    // 미라 (AI balanced) Lv12
    final mira = AIUnitComponent(
      unitName: 'Mira',
      maxHp: 120,
      maxMp: 210,
      attack: 30,
      defense: 22,
      speed: 83,
      luck: 24,
      level: 12,
      isPlayerSide: true,
      position: Vector2(480, 680),
      personality: Personality.balanced,
    );
    mira.squadId = 0;
    add(mira);
    gameManager.registerUnit(mira, isPlayer: true, squadId: 0);
  }

  void _spawnEnemies() {
    // 데몬 8체 (강화)
    final demonPositions = [
      Vector2(900, 450),
      Vector2(1000, 450),
      Vector2(1100, 450),
      Vector2(850, 550),
      Vector2(950, 550),
      Vector2(1050, 550),
      Vector2(1150, 550),
      Vector2(1000, 650),
    ];

    for (int i = 0; i < 8; i++) {
      final demon = EnemyUnitComponent(
        unitName: 'Demon ${i + 1}',
        maxHp: 150,
        maxMp: 60,
        attack: 38,
        defense: 20,
        speed: 60,
        luck: 6,
        level: 11,
        position: demonPositions[i],
        expReward: 60,
        goldReward: 25,
      );
      add(demon);
      gameManager.registerUnit(demon, isPlayer: false);
    }

    // 보스: 마왕
    final boss = BossUnitComponent(
      unitName: 'Demon King',
      maxHp: 1500,
      maxMp: 200,
      attack: 60,
      defense: 40,
      speed: 50,
      luck: 10,
      level: 15,
      position: Vector2(1400, 550),
      expReward: 1000,
      goldReward: 500,
    );
    add(boss);
    gameManager.registerUnit(boss, isPlayer: false);
  }
}
