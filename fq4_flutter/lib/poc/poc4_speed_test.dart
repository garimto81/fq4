import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../game/components/units/ai_unit_component.dart';
import '../game/components/units/enemy_unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';

/// POC-4: 배속 시스템 테스트
class SpeedTestGame extends FlameGame {
  static const double viewWidth = 800;
  static const double viewHeight = 768;

  double speedMultiplier = 1.0;
  static const List<double> speedOptions = [1.0, 2.0, 4.0, 8.0, 16.0];

  // Movement test
  late _MovingUnit _testUnit;
  double _distanceTraveled = 0;
  double _measureTimer = 0;
  double _lastMeasuredDistance = 0;

  // Battle test
  late BattleController battleController;
  late CombatSystem combatSystem;
  bool _battleStarted = false;

  // Callbacks
  void Function(double speed, double distance, double battleTime, String battleState)?
      onStatusUpdate;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(viewWidth, viewHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    combatSystem = CombatSystem();
    battleController = BattleController();
    await world.add(battleController);

    // Moving unit for speed measurement
    _testUnit = _MovingUnit(
      startPos: Vector2(100, 200),
      endPos: Vector2(700, 200),
      speed: 150,
    );
    world.add(_testUnit);

    // Battle units
    _spawnBattleUnits();
  }

  void _spawnBattleUnits() {
    final ally = AIUnitComponent(
      unitName: 'Fighter',
      maxHp: 100,
      maxMp: 20,
      attack: 22,
      defense: 12,
      speed: 75,
      luck: 8,
      level: 4,
      isPlayerSide: true,
      position: Vector2(200, 500),
      personality: Personality.aggressive,
    );
    ally.isPlayerControlled = false;
    ally.battleController = battleController;
    ally.combatSystem = combatSystem;

    final enemy = EnemyUnitComponent(
      unitName: 'Slime',
      maxHp: 80,
      maxMp: 0,
      attack: 12,
      defense: 4,
      speed: 40,
      luck: 2,
      level: 2,
      position: Vector2(600, 500),
    );
    enemy.battleController = battleController;
    enemy.combatSystem = combatSystem;

    world.add(ally);
    world.add(enemy);

    battleController.registerAlly(ally);
    battleController.registerEnemy(enemy);

    // Visuals
    world.add(_SimpleVisual(unit: ally, color: const Color(0xFF4488FF)));
    world.add(_SimpleVisual(unit: enemy, color: const Color(0xFFFF4444)));
  }

  void setSpeed(double mult) {
    speedMultiplier = mult;
    _distanceTraveled = 0;
    _measureTimer = 0;
  }

  void startBattle() {
    if (!_battleStarted) {
      _battleStarted = true;
      battleController.startBattle();
    }
  }

  @override
  void update(double dt) {
    final scaledDt = dt * speedMultiplier;
    super.update(scaledDt);

    // Measure distance per second
    _distanceTraveled += _testUnit.lastFrameDistance;
    _measureTimer += dt; // real time
    if (_measureTimer >= 1.0) {
      _lastMeasuredDistance = _distanceTraveled;
      _distanceTraveled = 0;
      _measureTimer = 0;
    }

    // Status update
    onStatusUpdate?.call(
      speedMultiplier,
      _lastMeasuredDistance,
      battleController.battleTime,
      battleController.state.name.toUpperCase(),
    );
  }
}

/// 왕복 이동 유닛 (속도 측정용)
class _MovingUnit extends PositionComponent {
  final Vector2 startPos;
  final Vector2 endPos;
  final double speed;
  bool _goingRight = true;
  double lastFrameDistance = 0;

  _MovingUnit({
    required this.startPos,
    required this.endPos,
    required this.speed,
  }) {
    position = startPos.clone();
    size = Vector2(24, 24);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _goingRight ? endPos : startPos;
    final dir = target - position;

    if (dir.length < 5) {
      _goingRight = !_goingRight;
      lastFrameDistance = 0;
      return;
    }

    final move = dir.normalized() * speed * dt;
    lastFrameDistance = move.length;
    position += move;
  }

  @override
  void render(Canvas canvas) {
    // Moving dot
    final paint = Paint()..color = const Color(0xFF00FF88);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    // Trail line
    final linePaint = Paint()
      ..color = const Color(0x4400FF88)
      ..strokeWidth = 2;
    final leftX = startPos.x - position.x + size.x / 2;
    final rightX = endPos.x - position.x + size.x / 2;
    canvas.drawLine(
      Offset(leftX, size.y / 2),
      Offset(rightX, size.y / 2),
      linePaint,
    );

    super.render(canvas);
  }
}

class _SimpleVisual extends PositionComponent {
  final dynamic unit; // UnitComponent
  final Color color;

  _SimpleVisual({required this.unit, required this.color});

  @override
  void update(double dt) {
    super.update(dt);
    if (unit is PositionComponent) {
      position = (unit as PositionComponent).position;
    }
    size = Vector2(28, 28);
  }

  @override
  void render(Canvas canvas) {
    final isDead = (unit as dynamic).isDead as bool;
    if (isDead) {
      final paint = Paint()
        ..color = const Color(0xFF666666)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(4, 4), Offset(size.x - 4, size.y - 4), paint);
      canvas.drawLine(Offset(size.x - 4, 4), Offset(4, size.y - 4), paint);
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
    super.render(canvas);
  }
}
