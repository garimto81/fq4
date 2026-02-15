import '../../core/constants/combat_constants.dart';
import '../../core/constants/strategic_combat_constants.dart';
import 'combat_system.dart';

/// 전략 전투용 확장 스탯
class StrategicUnitStats extends UnitStats {
  final WeaponRange weaponRange;
  final double facingAngle;
  final double optimalRange;

  const StrategicUnitStats({
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.fatigue,
    super.equipmentEvasion,
    super.equipmentCritBonus,
    required this.weaponRange,
    required this.facingAngle,
    required this.optimalRange,
  });
}

/// 전략 전투 시스템: 방향 + 상성 배율 적용
class StrategicCombatSystem extends CombatSystem {
  /// 방향 + 상성 적용 공격
  StrategicAttackResult executeStrategicAttack({
    required StrategicUnitStats attacker,
    required StrategicUnitStats target,
    required double attackerX,
    required double attackerY,
    required double targetX,
    required double targetY,
  }) {
    // 기본 공격 실행
    final baseResult = executeAttack(attacker: attacker, target: target);
    if (baseResult.hitResult == HitResult.miss || baseResult.hitResult == HitResult.evade) {
      return StrategicAttackResult(
        hitResult: baseResult.hitResult,
        damage: 0,
        isCritical: false,
        direction: AttackDirection.front,
        directionMultiplier: 1.0,
        rangeAdvantage: 1.0,
      );
    }

    // 방향 판정
    final direction = DirectionalCombatConstants.getAttackDirection(
      attackerX: attackerX,
      attackerY: attackerY,
      targetX: targetX,
      targetY: targetY,
      targetFacingAngle: target.facingAngle,
    );
    final dirMult = DirectionalCombatConstants.directionMultiplier[direction]!;

    // 상성 판정
    final rangeMult = RangeAdvantageConstants.getAdvantage(
      attacker.weaponRange,
      target.weaponRange,
    );

    // 최종 데미지 = 기본 데미지 * 방향배율 * 상성배율
    final finalDamage = (baseResult.damage * dirMult * rangeMult).round();
    final clampedDamage = finalDamage < CombatConstants.minDamage
        ? CombatConstants.minDamage
        : finalDamage;

    return StrategicAttackResult(
      hitResult: baseResult.hitResult,
      damage: clampedDamage,
      isCritical: baseResult.isCritical,
      direction: direction,
      directionMultiplier: dirMult,
      rangeAdvantage: rangeMult,
    );
  }
}

/// 전략 전투 결과
class StrategicAttackResult extends AttackResult {
  final AttackDirection direction;
  final double directionMultiplier;
  final double rangeAdvantage;

  const StrategicAttackResult({
    required super.hitResult,
    required super.damage,
    super.isCritical,
    required this.direction,
    required this.directionMultiplier,
    required this.rangeAdvantage,
  });
}
