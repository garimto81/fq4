import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'units/unit_component.dart';

/// 투사체 컴포넌트: 원거리 유닛의 화살/마법 투사체
/// ObjectPool과 함께 사용하여 생성/파괴 비용 제거
class ProjectileComponent extends PositionComponent with CollisionCallbacks {
  ProjectileComponent({
    required this.damage,
    required this.targetPosition,
    required this.speed,
    required this.ownerIsPlayerSide,
    this.color = const Color(0xFFFFFF00),
    this.maxLifetime = 3.0,
  });

  final int damage;
  final Vector2 targetPosition;
  final double speed;
  final bool ownerIsPlayerSide;
  final Color color;
  final double maxLifetime;

  Vector2 _direction = Vector2.zero();
  double _lifetime = 0;
  bool _active = true;

  /// 풀 반환 콜백
  Function(ProjectileComponent)? onRelease;

  /// 피격 유닛 콜백
  Function(UnitComponent target, int damage)? onHit;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(8, 4);
    anchor = Anchor.center;

    // 방향 계산
    _direction = (targetPosition - position);
    if (_direction.length > 0) {
      _direction.normalize();
    }

    // 회전 (이동 방향)
    angle = atan2(_direction.y, _direction.x);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    _lifetime += dt;
    if (_lifetime >= maxLifetime) {
      deactivate();
      return;
    }

    // 이동
    position += _direction * speed * dt;

    // 목표 도달 판정
    if (position.distanceTo(targetPosition) < 10) {
      deactivate();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _active ? color : const Color(0x00000000);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      paint,
    );
  }

  /// 비활성화 (풀 반환)
  void deactivate() {
    _active = false;
    onRelease?.call(this);
  }

  /// 재활성화 (풀에서 꺼낼 때)
  void activate({
    required Vector2 startPosition,
    required Vector2 target,
    required int newDamage,
  }) {
    position = startPosition.clone();
    _direction = (target - startPosition);
    if (_direction.length > 0) {
      _direction.normalize();
    }
    angle = atan2(_direction.y, _direction.x);
    _lifetime = 0;
    _active = true;
  }

  bool get isActive => _active;
}
