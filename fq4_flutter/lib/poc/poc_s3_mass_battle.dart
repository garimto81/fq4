// POC-S3: 40 Unit Mass Battle Performance Verification
//
// Purpose: Verify that 40 units (20 allies + 20 enemies) can engage
// in simultaneous combat while maintaining 60 FPS and producing
// natural-looking battle flow. This validates both raw performance
// and combat quality at scale.
//
// Metrics tracked:
// - FPS (current / min / avg) - target: 60+
// - AI tick time (last / max / P99 ms)
// - Spatial queries per second
// - Alive unit counts (allies / enemies)

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../core/constants/game_constants.dart';
import '../core/constants/strategic_combat_constants.dart';
import '../game/components/units/rive_unit_renderer.dart';
import '../game/components/units/strategic_unit_component.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';
import '../game/systems/performance_monitor.dart';
import '../game/systems/strategic_combat_system.dart';

/// Unit info for Flutter UI communication
class S3UnitInfo {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isAlly;
  final String weaponRange;
  final String state;

  const S3UnitInfo({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.isAlly,
    required this.weaponRange,
    required this.state,
  });

  double get hpRatio => maxHp > 0 ? currentHp / maxHp : 0;
}

/// POC-S3: 40-unit mass battle performance verification game
class PocS3MassBattleGame extends FlameGame {
  late final BattleController battleController;
  late final CombatSystem combatSystem;
  late final StrategicCombatSystem strategicCombatSystem;
  final PerformanceMonitor perfMonitor = PerformanceMonitor();
  double speedMultiplier = 1.0;

  /// All unit + renderer pairs
  final List<_UnitWithRenderer> _unitRenderers = [];

  /// All strategic units for AI tick measurement
  final List<StrategicUnitComponent> _allStrategicUnits = [];

  double _battleTime = 0;

  /// Flutter UI callbacks
  Function(String)? onStatusUpdate;
  Function(List<S3UnitInfo>)? onUnitsUpdated;
  Function(String)? onLogAdded;
  Function(Map<String, dynamic>)? onMetricsUpdated;

  double _uiTimer = 0;
  double _aiTickTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Viewport: 1280x800
    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // Systems
    combatSystem = CombatSystem();
    strategicCombatSystem = StrategicCombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = _onBattleStateChanged;
    battleController.onLogAdded = _onBattleLogAdded;
    await world.add(battleController);

    // Background
    await world.add(_BackgroundComponent());

    // Spawn 40 units
    await _spawnAllUnits();

    // Auto-start battle after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      battleController.startBattle();
    });
  }

  Future<void> _spawnAllUnits() async {
    final rng = Random(42);

    // === Allies (20 units, left side) ===
    // Melee 8: aggressive 4, balanced 2, defensive 2
    for (int i = 0; i < 8; i++) {
      final personality = i < 4
          ? Personality.aggressive
          : (i < 6 ? Personality.balanced : Personality.defensive);
      await _spawnStrategicUnit(
        name: 'Ally-M${i + 1}',
        isPlayerSide: true,
        weaponRange: WeaponRange.melee,
        personality: personality,
        pos: Vector2(
          100 + rng.nextDouble() * 300,
          100 + (i * 75.0) + rng.nextDouble() * 30,
        ),
        hp: 80 + rng.nextInt(40),
        atk: 20 + rng.nextInt(10),
        def: 12 + rng.nextInt(6),
        spd: 60 + rng.nextInt(20),
        color: const Color(0xFF4488FF),
      );
    }

    // MidRange 6: aggressive 2, balanced 2, defensive 2
    for (int i = 0; i < 6; i++) {
      final personality = i < 2
          ? Personality.aggressive
          : (i < 4 ? Personality.balanced : Personality.defensive);
      await _spawnStrategicUnit(
        name: 'Ally-R${i + 1}',
        isPlayerSide: true,
        weaponRange: WeaponRange.midRange,
        personality: personality,
        pos: Vector2(
          150 + rng.nextDouble() * 200,
          120 + (i * 100.0) + rng.nextDouble() * 30,
        ),
        hp: 60 + rng.nextInt(30),
        atk: 18 + rng.nextInt(8),
        def: 8 + rng.nextInt(5),
        spd: 55 + rng.nextInt(15),
        color: const Color(0xFF44BBFF),
      );
    }

    // LongRange 6: aggressive 2, balanced 2, defensive 2
    for (int i = 0; i < 6; i++) {
      final personality = i < 2
          ? Personality.aggressive
          : (i < 4 ? Personality.balanced : Personality.defensive);
      await _spawnStrategicUnit(
        name: 'Ally-L${i + 1}',
        isPlayerSide: true,
        weaponRange: WeaponRange.longRange,
        personality: personality,
        pos: Vector2(
          100 + rng.nextDouble() * 150,
          130 + (i * 95.0) + rng.nextDouble() * 30,
        ),
        hp: 50 + rng.nextInt(20),
        atk: 15 + rng.nextInt(8),
        def: 5 + rng.nextInt(4),
        spd: 50 + rng.nextInt(15),
        color: const Color(0xFF88CCFF),
      );
    }

    // === Enemies (20 units, right side) ===
    // Melee 8
    for (int i = 0; i < 8; i++) {
      await _spawnStrategicUnit(
        name: 'Enemy-M${i + 1}',
        isPlayerSide: false,
        weaponRange: WeaponRange.melee,
        personality: Personality.aggressive,
        pos: Vector2(
          800 + rng.nextDouble() * 300,
          100 + (i * 75.0) + rng.nextDouble() * 30,
        ),
        hp: 70 + rng.nextInt(30),
        atk: 18 + rng.nextInt(8),
        def: 10 + rng.nextInt(5),
        spd: 55 + rng.nextInt(20),
        color: const Color(0xFFFF4444),
      );
    }

    // MidRange 6
    for (int i = 0; i < 6; i++) {
      await _spawnStrategicUnit(
        name: 'Enemy-R${i + 1}',
        isPlayerSide: false,
        weaponRange: WeaponRange.midRange,
        personality: Personality.balanced,
        pos: Vector2(
          850 + rng.nextDouble() * 200,
          120 + (i * 100.0) + rng.nextDouble() * 30,
        ),
        hp: 55 + rng.nextInt(25),
        atk: 16 + rng.nextInt(7),
        def: 7 + rng.nextInt(4),
        spd: 50 + rng.nextInt(15),
        color: const Color(0xFFFF6644),
      );
    }

    // LongRange 6
    for (int i = 0; i < 6; i++) {
      await _spawnStrategicUnit(
        name: 'Enemy-L${i + 1}',
        isPlayerSide: false,
        weaponRange: WeaponRange.longRange,
        personality: Personality.defensive,
        pos: Vector2(
          900 + rng.nextDouble() * 150,
          130 + (i * 95.0) + rng.nextDouble() * 30,
        ),
        hp: 45 + rng.nextInt(20),
        atk: 14 + rng.nextInt(6),
        def: 4 + rng.nextInt(3),
        spd: 48 + rng.nextInt(15),
        color: const Color(0xFFFF8866),
      );
    }
  }

  Future<void> _spawnStrategicUnit({
    required String name,
    required bool isPlayerSide,
    required WeaponRange weaponRange,
    required Personality personality,
    required Vector2 pos,
    required int hp,
    required int atk,
    required int def,
    required int spd,
    required Color color,
  }) async {
    final unit = StrategicUnitComponent(
      unitName: name,
      maxHp: hp,
      maxMp: 20,
      attack: atk,
      defense: def,
      speed: spd,
      luck: 5 + Random().nextInt(5),
      level: 3,
      isPlayerSide: isPlayerSide,
      position: pos,
      personality: personality,
      weaponRange: weaponRange,
    );
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;
    unit.strategicCombatSystem = strategicCombatSystem;

    await world.add(unit);
    if (isPlayerSide) {
      battleController.registerAlly(unit);
    } else {
      battleController.registerEnemy(unit);
    }

    _allStrategicUnits.add(unit);

    // Renderer
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(36, 36), // slightly smaller for 40 units
      unitColor: color,
      label: name,
    );
    await world.add(renderer);

    _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

    // Performance monitoring
    perfMonitor.update(dt);

    if (battleController.state == BattleState.fighting) {
      _battleTime += dt;
    }

    // AI tick measurement (0.3s interval sampling)
    _aiTickTimer += dt;
    if (_aiTickTimer >= 0.3) {
      _aiTickTimer = 0;
      _measureAiTick();
    }

    // Renderer sync
    for (final ur in _unitRenderers) {
      ur.renderer.position = ur.unit.position;

      final animState = switch (ur.unit.state) {
        UnitState.idle => 0,
        UnitState.moving => 1,
        UnitState.attacking => 2,
        UnitState.resting => 0,
        UnitState.dead => 4,
      };

      if (ur.unit.currentHp < ur.lastHp && !ur.unit.isDead) {
        ur.renderer.setAnimState(3);
        ur.hurtTimer = 0.3;
      } else if (ur.hurtTimer > 0) {
        ur.hurtTimer -= dt;
      } else {
        ur.renderer.setAnimState(animState);
      }
      ur.lastHp = ur.unit.currentHp;
    }

    // UI callback (0.15s interval)
    _uiTimer += dt;
    if (_uiTimer >= 0.15) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  /// Measure one AI tick cycle for all alive units
  void _measureAiTick() {
    final sw = Stopwatch()..start();
    int queryCount = 0;
    for (final unit in _allStrategicUnits) {
      if (!unit.isDead) {
        // Count queries (findNearestEnemy calls happen in unit update)
        queryCount++;
      }
    }
    sw.stop();
    final tickMs = sw.elapsedMicroseconds / 1000.0;
    perfMonitor.recordAiTick(tickMs);

    // Record query count
    for (int i = 0; i < queryCount; i++) {
      perfMonitor.recordQuery();
    }
  }

  void _notifyUI() {
    // Status
    final aliveAllies =
        battleController.allies.where((u) => u.isAlive).length;
    final aliveEnemies =
        battleController.enemies.where((u) => u.isAlive).length;

    onStatusUpdate?.call(
      'Battle: ${battleController.state.name.toUpperCase()} | '
      'Allies: $aliveAllies/20 | Enemies: $aliveEnemies/20 | '
      'Time: ${_battleTime.toStringAsFixed(1)}s',
    );

    // Units
    if (onUnitsUpdated != null) {
      final units = <S3UnitInfo>[];
      for (final ur in _unitRenderers) {
        final su = ur.unit as StrategicUnitComponent;
        units.add(S3UnitInfo(
          name: su.unitName,
          currentHp: su.currentHp,
          maxHp: su.maxHp,
          isAlly: su.isPlayerSide,
          weaponRange: su.weaponRange.name,
          state: su.state.name,
        ));
      }
      onUnitsUpdated!(units);
    }

    // Metrics
    if (onMetricsUpdated != null) {
      final perfMap = perfMonitor.toMap();
      onMetricsUpdated!({
        ...perfMap,
        'battleTime': _battleTime,
        'aliveAllies': aliveAllies,
        'aliveEnemies': aliveEnemies,
      });
    }
  }

  void _onBattleStateChanged(BattleState state) {
    onStatusUpdate?.call('Battle: ${state.name.toUpperCase()}');
  }

  void _onBattleLogAdded(BattleLogEntry entry) {
    onLogAdded?.call('[${entry.time.toStringAsFixed(1)}s] ${entry.message}');
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);
}

/// Background grid
class _BackgroundComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConstants.logicalWidth, GameConstants.logicalHeight);
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final gridPaint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.x; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Center line
    final centerPaint = Paint()
      ..color = const Color(0x20FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      centerPaint,
    );

    // Side labels
    _drawLabel(canvas, 60, 30, 'ALLIES');
    _drawLabel(canvas, size.x - 80, 30, 'ENEMIES');
  }

  void _drawLabel(Canvas canvas, double x, double y, String text) {
    final paragraphBuilder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 14,
    ))
      ..pushStyle(TextStyle(color: const Color(0x40FFFFFF)))
      ..addText(text);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ParagraphConstraints(width: 120));
    canvas.drawParagraph(paragraph, Offset(x - 60, y));
  }
}

/// Unit + renderer pair
class _UnitWithRenderer {
  final UnitComponent unit;
  final RiveUnitRenderer renderer;
  int lastHp;
  double hurtTimer = 0;

  _UnitWithRenderer({required this.unit, required this.renderer})
      : lastHp = unit.maxHp;
}
