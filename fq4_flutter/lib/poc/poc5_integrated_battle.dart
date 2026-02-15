import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../game/components/units/ai_unit_component.dart';
import '../game/components/units/enemy_unit_component.dart';
import '../game/components/units/rive_unit_renderer.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';

/// POC-5: 통합 전투 게임 (Rive + 자동전투 + 세로 + 배속)
class IntegratedBattleGame extends FlameGame {
  static const double viewWidth = 800;
  static const double viewHeight = 768;

  late final BattleController battleController;
  late final CombatSystem combatSystem;

  // POC-4: 배속
  double speedMultiplier = 1.0;

  // Rive renderers
  final List<_UnitWithRenderer> _unitRenderers = [];

  // Callbacks
  void Function(BattleState state)? onBattleStateChanged;
  void Function(BattleLogEntry entry)? onLogAdded;
  void Function(List<Poc5UnitStatusInfo> allies, List<Poc5UnitStatusInfo> enemies)? onUnitsUpdated;
  void Function(double time)? onTimeUpdated;

  double _uiTimer = 0;

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

    await _spawnUnits();
  }

  Future<void> _spawnUnits() async {
    // Allies
    await _spawnAlly(
      name: 'Ares',
      hp: 120, mp: 30, atk: 25, def: 15, spd: 80, luck: 10, level: 5,
      pos: Vector2(180, 300),
      color: const Color(0xFF4488FF),
      personality: Personality.aggressive,
    );
    await _spawnAlly(
      name: 'Taro',
      hp: 90, mp: 50, atk: 20, def: 10, spd: 70, luck: 8, level: 3,
      pos: Vector2(180, 460),
      color: const Color(0xFF44CC88),
      personality: Personality.balanced,
    );

    // Enemies
    await _spawnEnemy(
      name: 'Goblin A',
      hp: 60, mp: 0, atk: 15, def: 5, spd: 50, luck: 3, level: 3,
      pos: Vector2(620, 300),
      color: const Color(0xFFFF4444),
    );
    await _spawnEnemy(
      name: 'Goblin B',
      hp: 60, mp: 0, atk: 15, def: 5, spd: 50, luck: 3, level: 3,
      pos: Vector2(620, 460),
      color: const Color(0xFFFF6644),
    );
  }

  Future<void> _spawnAlly({
    required String name,
    required int hp, required int mp, required int atk, required int def,
    required int spd, required int luck, required int level,
    required Vector2 pos, required Color color,
    Personality personality = Personality.balanced,
  }) async {
    final unit = AIUnitComponent(
      unitName: name,
      maxHp: hp, maxMp: mp,
      attack: atk, defense: def, speed: spd, luck: luck,
      level: level,
      isPlayerSide: true,
      position: pos,
      personality: personality,
    );
    unit.isPlayerControlled = false;
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;

    await world.add(unit);
    battleController.registerAlly(unit);

    // Rive renderer (fallback)
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(48, 48),
      unitColor: color,
      label: name,
    );
    await world.add(renderer);
    await renderer.tryLoadRive('assets/rive/characters/warrior_placeholder.riv');

    _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
  }

  Future<void> _spawnEnemy({
    required String name,
    required int hp, required int mp, required int atk, required int def,
    required int spd, required int luck, required int level,
    required Vector2 pos, required Color color,
  }) async {
    final unit = EnemyUnitComponent(
      unitName: name,
      maxHp: hp, maxMp: mp,
      attack: atk, defense: def, speed: spd, luck: luck,
      level: level,
      position: pos,
    );
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;

    await world.add(unit);
    battleController.registerEnemy(unit);

    // Rive renderer (fallback)
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(48, 48),
      unitColor: color,
      label: name,
    );
    await world.add(renderer);
    await renderer.tryLoadRive('assets/rive/enemies/goblin_placeholder.riv');

    _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
  }

  void startBattle() {
    battleController.startBattle();
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  @override
  void update(double dt) {
    final scaledDt = dt * speedMultiplier;
    super.update(scaledDt);

    // Sync renderer positions and states
    for (final ur in _unitRenderers) {
      ur.renderer.position = ur.unit.position;

      // Sync animation state
      final animState = switch (ur.unit.state) {
        UnitState.idle => 0,
        UnitState.moving => 1,
        UnitState.attacking => 2,
        UnitState.resting => 0,
        UnitState.dead => 4,
      };

      // Check for hurt (recently took damage)
      if (ur.unit.currentHp < ur.lastHp && !ur.unit.isDead) {
        ur.renderer.setAnimState(3); // hurt
        ur.hurtTimer = 0.3;
      } else if (ur.hurtTimer > 0) {
        ur.hurtTimer -= scaledDt;
      } else {
        ur.renderer.setAnimState(animState);
      }
      ur.lastHp = ur.unit.currentHp;
    }

    // UI updates (real time)
    _uiTimer += dt;
    if (_uiTimer >= 0.1) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  void _notifyUI() {
    onTimeUpdated?.call(battleController.battleTime);

    if (onUnitsUpdated == null) return;

    final allies = battleController.allies.map((u) => Poc5UnitStatusInfo(
      name: u.unitName,
      hp: u.currentHp,
      maxHp: u.maxHp,
      isDead: u.isDead,
    )).toList();

    final enemies = battleController.enemies.map((u) => Poc5UnitStatusInfo(
      name: u.unitName,
      hp: u.currentHp,
      maxHp: u.maxHp,
      isDead: u.isDead,
    )).toList();

    onUnitsUpdated?.call(allies, enemies);
  }
}

class _UnitWithRenderer {
  final UnitComponent unit;
  final RiveUnitRenderer renderer;
  int lastHp;
  double hurtTimer = 0;

  _UnitWithRenderer({required this.unit, required this.renderer})
      : lastHp = unit.maxHp;
}

class Poc5UnitStatusInfo {
  final String name;
  final int hp;
  final int maxHp;
  final bool isDead;

  const Poc5UnitStatusInfo({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.isDead,
  });
}
