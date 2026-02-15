import 'dart:math';

/// 무기 사거리 타입
enum WeaponRange {
  melee,     // 0-60px
  midRange,  // 60-150px
  longRange, // 150-300px
}

/// 공격 방향
enum AttackDirection {
  front,  // 정면: 0~45도
  side,   // 측면: 45~135도
  back,   // 후면: 135~180도
}

/// 방향별 데미지 배율
class DirectionalCombatConstants {
  DirectionalCombatConstants._();

  static const Map<AttackDirection, double> directionMultiplier = {
    AttackDirection.front: 1.0,
    AttackDirection.side: 1.3,
    AttackDirection.back: 1.5,
  };

  /// 공격 방향 판정: 공격자 위치에서 대상 facing 벡터와의 각도
  static AttackDirection getAttackDirection({
    required double attackerX,
    required double attackerY,
    required double targetX,
    required double targetY,
    required double targetFacingAngle, // radian
  }) {
    // 대상 → 공격자 벡터
    final dx = attackerX - targetX;
    final dy = attackerY - targetY;

    // 대상의 facing 벡터
    final facingX = cos(targetFacingAngle);
    final facingY = sin(targetFacingAngle);

    // 정규화
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) return AttackDirection.front;
    final ndx = dx / len;
    final ndy = dy / len;

    // dot product → angle
    final dot = ndx * facingX + ndy * facingY;
    final angle = acos(dot.clamp(-1.0, 1.0)); // radian

    // 45도 = pi/4, 135도 = 3*pi/4
    if (angle <= pi / 4) return AttackDirection.front;
    if (angle <= 3 * pi / 4) return AttackDirection.side;
    return AttackDirection.back;
  }
}

/// 상성 배율
class RangeAdvantageConstants {
  RangeAdvantageConstants._();

  static double getAdvantage(WeaponRange attacker, WeaponRange defender) {
    if (attacker == WeaponRange.melee && defender == WeaponRange.longRange) return 1.3;
    if (attacker == WeaponRange.midRange && defender == WeaponRange.melee) return 1.2;
    if (attacker == WeaponRange.longRange && defender == WeaponRange.midRange) return 1.2;
    if (attacker == WeaponRange.longRange && defender == WeaponRange.melee) return 0.8;
    if (attacker == WeaponRange.melee && defender == WeaponRange.midRange) return 0.8;
    if (attacker == WeaponRange.midRange && defender == WeaponRange.longRange) return 0.8;
    return 1.0;
  }
}

/// 사거리별 유닛 프로파일
class WeaponRangeProfile {
  final WeaponRange range;
  final double attackRange;
  final double optimalRange;
  final double dpsMultiplier;
  final double defenseBonus;
  final double speedBonus;

  const WeaponRangeProfile._({
    required this.range,
    required this.attackRange,
    required this.optimalRange,
    required this.dpsMultiplier,
    required this.defenseBonus,
    required this.speedBonus,
  });

  static const melee = WeaponRangeProfile._(
    range: WeaponRange.melee,
    attackRange: 60,
    optimalRange: 30,
    dpsMultiplier: 1.4,
    defenseBonus: 1.3,
    speedBonus: 1.0,
  );

  static const midRange = WeaponRangeProfile._(
    range: WeaponRange.midRange,
    attackRange: 150,
    optimalRange: 100,
    dpsMultiplier: 1.0,
    defenseBonus: 1.0,
    speedBonus: 1.0,
  );

  static const longRange = WeaponRangeProfile._(
    range: WeaponRange.longRange,
    attackRange: 300,
    optimalRange: 240,
    dpsMultiplier: 0.7,
    defenseBonus: 0.7,
    speedBonus: 1.2,
  );

  static WeaponRangeProfile fromRange(WeaponRange range) {
    return switch (range) {
      WeaponRange.melee => melee,
      WeaponRange.midRange => midRange,
      WeaponRange.longRange => longRange,
    };
  }
}
