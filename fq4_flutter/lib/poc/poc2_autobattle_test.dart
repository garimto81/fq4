import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../game/components/units/ai_unit_component.dart';
import '../game/components/units/enemy_unit_component.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';

/// POC-2: AI 자동전투 파이프라인 테스트
class AutoBattleTestGame extends FlameGame {
  static const double viewWidth = 800;
  static const double viewHeight = 1280;

  late final BattleController battleController;
  late final CombatSystem combatSystem;
  double speedMultiplier = 1.0;

  // Callbacks for Flutter UI
  void Function(BattleState state)? onBattleStateChanged;
  void Function(BattleLogEntry entry)? onLogAdded;
  void Function(List<Poc2UnitStatus> allies, List<Poc2UnitStatus> enemies)? onUnitsUpdated;

  double _uiUpdateTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(viewWidth, viewHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    combatSystem = CombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = onBattleStateChanged;
    battleController.onLogAdded = onLogAdded;
    await world.add(battleController);

    _spawnUnits();
  }

  void _spawnUnits() {
    // Allies: Ares Lv5, Taro Lv3
    final ares = AIUnitComponent(
      unitName: 'Ares',
      maxHp: 120,
      maxMp: 30,
      attack: 25,
      defense: 15,
      speed: 80,
      luck: 10,
      level: 5,
      isPlayerSide: true,
      position: Vector2(200, 500),
      personality: Personality.aggressive,
    );
    ares.isPlayerControlled = false;
    ares.battleController = battleController;
    ares.combatSystem = combatSystem;

    final taro = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 90,
      maxMp: 50,
      attack: 20,
      defense: 10,
      speed: 70,
      luck: 8,
      level: 3,
      isPlayerSide: true,
      position: Vector2(200, 650),
      personality: Personality.balanced,
    );
    taro.isPlayerControlled = false;
    taro.battleController = battleController;
    taro.combatSystem = combatSystem;

    // Enemies: Goblin A, Goblin B
    final goblinA = EnemyUnitComponent(
      unitName: 'Goblin A',
      maxHp: 60,
      maxMp: 0,
      attack: 15,
      defense: 5,
      speed: 50,
      luck: 3,
      level: 3,
      position: Vector2(600, 500),
      expReward: 15,
      goldReward: 8,
    );
    goblinA.battleController = battleController;
    goblinA.combatSystem = combatSystem;

    final goblinB = EnemyUnitComponent(
      unitName: 'Goblin B',
      maxHp: 60,
      maxMp: 0,
      attack: 15,
      defense: 5,
      speed: 50,
      luck: 3,
      level: 3,
      position: Vector2(600, 650),
      expReward: 15,
      goldReward: 8,
    );
    goblinB.battleController = battleController;
    goblinB.combatSystem = combatSystem;

    // Register and add
    world.add(ares);
    world.add(taro);
    world.add(goblinA);
    world.add(goblinB);

    battleController.registerAlly(ares);
    battleController.registerAlly(taro);
    battleController.registerEnemy(goblinA);
    battleController.registerEnemy(goblinB);

    // Add visual renderers
    world.add(_UnitVisual(unit: ares, color: const Color(0xFF4488FF)));
    world.add(_UnitVisual(unit: taro, color: const Color(0xFF44CC88)));
    world.add(_UnitVisual(unit: goblinA, color: const Color(0xFFFF4444)));
    world.add(_UnitVisual(unit: goblinB, color: const Color(0xFFFF6644)));
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  void startBattle() {
    battleController.startBattle();
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

    // Update UI periodically
    _uiUpdateTimer += dt;
    if (_uiUpdateTimer >= 0.1) {
      _uiUpdateTimer = 0;
      _notifyUnitsUpdated();
    }
  }

  void _notifyUnitsUpdated() {
    if (onUnitsUpdated == null) return;

    final allies = battleController.allies.map((u) => Poc2UnitStatus(
      name: u.unitName,
      hp: u.currentHp,
      maxHp: u.maxHp,
      fatigue: u.fatigue,
      isDead: u.isDead,
      state: u.state.name,
    )).toList();

    final enemies = battleController.enemies.map((u) => Poc2UnitStatus(
      name: u.unitName,
      hp: u.currentHp,
      maxHp: u.maxHp,
      fatigue: u.fatigue,
      isDead: u.isDead,
      state: u.state.name,
    )).toList();

    onUnitsUpdated?.call(allies, enemies);
  }

  BattleState get battleState => battleController.state;
  double get battleTime => battleController.battleTime;
  List<BattleLogEntry> get logs => battleController.battleLog;
}

/// Unit status for Flutter UI
class Poc2UnitStatus {
  final String name;
  final int hp;
  final int maxHp;
  final double fatigue;
  final bool isDead;
  final String state;

  const Poc2UnitStatus({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.fatigue,
    required this.isDead,
    required this.state,
  });

  double get hpRatio => maxHp > 0 ? hp / maxHp : 0;
}

/// Simple visual for units (colored rect + HP bar)
class _UnitVisual extends PositionComponent {
  final UnitComponent unit;
  final Color color;

  _UnitVisual({required this.unit, required this.color});

  @override
  void update(double dt) {
    super.update(dt);
    position = unit.position;
    size = Vector2(32, 32);
  }

  @override
  void render(Canvas canvas) {
    if (unit.isDead) {
      // Dead: grey X
      final paint = Paint()
        ..color = const Color(0xFF666666)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(4, 4), Offset(size.x - 4, size.y - 4), paint);
      canvas.drawLine(Offset(size.x - 4, 4), Offset(4, size.y - 4), paint);
      return;
    }

    // Body
    final bodyPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // HP bar background
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x, 4),
      Paint()..color = const Color(0xFF333333),
    );

    // HP bar
    final hpRatio = unit.hpRatio;
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF00CC00)
        : hpRatio > 0.25
            ? const Color(0xFFCCCC00)
            : const Color(0xFFCC0000);
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x * hpRatio, 4),
      Paint()..color = hpColor,
    );

    // Name label
    final paragraphBuilder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 9,
    ))
      ..pushStyle(TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(unit.unitName);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ParagraphConstraints(width: size.x + 20));
    canvas.drawParagraph(paragraph, Offset(-10, -18));

    // State label
    if (unit.state == UnitState.attacking) {
      final atkParagraph = ParagraphBuilder(ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 8,
      ))
        ..pushStyle(TextStyle(color: const Color(0xFFFFFF00)))
        ..addText('ATK');
      final p = atkParagraph.build();
      p.layout(ParagraphConstraints(width: size.x));
      canvas.drawParagraph(p, Offset(0, size.y + 2));
    }

    super.render(canvas);
  }
}
