import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// POC-3: 세로 모드 레이아웃 테스트 게임
class LayoutTestGame extends FlameGame {
  static const double viewWidth = 800;
  static const double viewHeight = 768; // 상단 60% of 1280

  final List<_TestUnit> _units = [];
  int allyCount = 0;
  int enemyCount = 0;

  // Callbacks for Flutter UI
  void Function(List<UnitInfo> allies, List<UnitInfo> enemies)? onUnitsUpdated;

  double _uiTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(viewWidth, viewHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    // Initial units
    _spawnAlly('Ares', Vector2(200, 300));
    _spawnAlly('Taro', Vector2(200, 450));
    _spawnEnemy('Goblin', Vector2(600, 375));
  }

  void _spawnAlly(String name, Vector2 pos) {
    allyCount++;
    final unit = _TestUnit(
      name: name,
      pos: pos,
      color: const Color(0xFF4488FF),
      isAlly: true,
      hp: 100,
    );
    world.add(unit);
    _units.add(unit);
  }

  void _spawnEnemy(String name, Vector2 pos) {
    enemyCount++;
    final unit = _TestUnit(
      name: name,
      pos: pos,
      color: const Color(0xFFFF4444),
      isAlly: false,
      hp: 60,
    );
    world.add(unit);
    _units.add(unit);
  }

  /// Flutter UI에서 호출: 테스트 유닛 스폰
  void spawnTestUnit() {
    final rng = Random();
    final x = 100.0 + rng.nextDouble() * 600;
    final y = 100.0 + rng.nextDouble() * 500;
    if (rng.nextBool()) {
      _spawnAlly('Ally${allyCount + 1}', Vector2(x, y));
    } else {
      _spawnEnemy('Enemy${enemyCount + 1}', Vector2(x, y));
    }
  }

  /// Flutter UI에서 호출: 유닛 HP 변경 테스트
  void damageRandomUnit() {
    if (_units.isEmpty) return;
    final rng = Random();
    final unit = _units[rng.nextInt(_units.length)];
    unit.hp = max(0, unit.hp - 20);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _uiTimer += dt;
    if (_uiTimer >= 0.2) {
      _uiTimer = 0;
      _notifyUnits();
    }
  }

  void _notifyUnits() {
    if (onUnitsUpdated == null) return;

    final allies = _units
        .where((u) => u.isAlly)
        .map((u) => UnitInfo(name: u.name, hp: u.hp, maxHp: u.maxHp))
        .toList();
    final enemies = _units
        .where((u) => !u.isAlly)
        .map((u) => UnitInfo(name: u.name, hp: u.hp, maxHp: u.maxHp))
        .toList();

    onUnitsUpdated?.call(allies, enemies);
  }
}

class UnitInfo {
  final String name;
  final int hp;
  final int maxHp;
  double get hpRatio => maxHp > 0 ? hp / maxHp : 0;

  const UnitInfo({required this.name, required this.hp, required this.maxHp});
}

class _TestUnit extends PositionComponent {
  final String name;
  final Color color;
  final bool isAlly;
  int hp;
  int maxHp;

  // Simple wandering
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderTimer = 0;
  final _rng = Random();

  _TestUnit({
    required this.name,
    required Vector2 pos,
    required this.color,
    required this.isAlly,
    this.hp = 100,
  }) : maxHp = hp {
    position = pos;
    size = Vector2(32, 32);
    anchor = Anchor.center;
    _wanderTarget = pos.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Random wandering
    _wanderTimer += dt;
    if (_wanderTimer > 2.0) {
      _wanderTimer = 0;
      _wanderTarget = Vector2(
        position.x + (_rng.nextDouble() - 0.5) * 100,
        position.y + (_rng.nextDouble() - 0.5) * 100,
      );
      _wanderTarget.x = _wanderTarget.x.clamp(50, 750);
      _wanderTarget.y = _wanderTarget.y.clamp(50, 718);
    }

    final dir = _wanderTarget - position;
    if (dir.length > 3) {
      position += dir.normalized() * 30 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Body
    final bodyPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // HP bar
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x, 4),
      Paint()..color = const Color(0xFF333333),
    );
    final hpRatio = maxHp > 0 ? hp / maxHp : 0.0;
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF00CC00)
        : const Color(0xFFCC0000);
    canvas.drawRect(
      Rect.fromLTWH(0, -8, size.x * hpRatio, 4),
      Paint()..color = hpColor,
    );

    // Name
    final pb = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 9,
    ))
      ..pushStyle(TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(name);
    final p = pb.build();
    p.layout(ParagraphConstraints(width: size.x + 20));
    canvas.drawParagraph(p, Offset(-10, -18));

    super.render(canvas);
  }
}
