import 'dart:math';
import '../../core/constants/strategic_combat_constants.dart';

/// 위협 평가 결과
class ThreatScore {
  final double score;
  final String reason;

  const ThreatScore(this.score, this.reason);
}

/// 타겟 평가 결과
class TargetScore {
  final double score;
  final ({double x, double y}) position;
  final WeaponRange weaponRange;
  final double hpRatio;
  final double facingAngle;

  const TargetScore({
    required this.score,
    required this.position,
    required this.weaponRange,
    required this.hpRatio,
    required this.facingAngle,
  });
}

/// 위협 평가기: 적의 위험도와 타겟 우선순위를 수치화
class ThreatEvaluator {
  /// 적의 위협도 평가 (0~100+)
  double evaluateThreat({
    required double selfX,
    required double selfY,
    required double selfFacingAngle,
    required WeaponRange selfWeaponRange,
    required double enemyX,
    required double enemyY,
    required WeaponRange enemyWeaponRange,
    required double maxDetectionRange,
    required int targetingMeCount,
  }) {
    double threat = 0;

    // 거리 위협 (가까울수록 높음, 최대 30)
    final dx = enemyX - selfX;
    final dy = enemyY - selfY;
    final distance = sqrt(dx * dx + dy * dy);
    threat += (1.0 - (distance / maxDetectionRange).clamp(0.0, 1.0)) * 30;

    // 방향 위협 (내 후면에 있으면 높음)
    final attackDir = DirectionalCombatConstants.getAttackDirection(
      attackerX: enemyX,
      attackerY: enemyY,
      targetX: selfX,
      targetY: selfY,
      targetFacingAngle: selfFacingAngle,
    );
    if (attackDir == AttackDirection.back) threat += 40;
    if (attackDir == AttackDirection.side) threat += 20;

    // 수적 위협 (나를 타겟하는 적 수)
    threat += targetingMeCount * 15;

    // 상성 위협 (불리한 상성이면 높음)
    final advantage =
        RangeAdvantageConstants.getAdvantage(enemyWeaponRange, selfWeaponRange);
    if (advantage > 1.0) threat += 25;

    return threat;
  }

  /// 타겟 우선순위 평가 (높을수록 우선 공격)
  double evaluateTargetPriority({
    required double selfX,
    required double selfY,
    required WeaponRange selfWeaponRange,
    required double targetX,
    required double targetY,
    required double targetFacingAngle,
    required WeaponRange targetWeaponRange,
    required double targetHpRatio,
    required double maxDetectionRange,
  }) {
    double priority = 0;

    // 체력 낮은 적 (HP 30% 이하): +50
    if (targetHpRatio <= 0.3) {
      priority += 50;
    } else if (targetHpRatio <= 0.5) {
      priority += 25;
    }

    // 위험한 적 (원거리 딜러): +35
    if (targetWeaponRange == WeaponRange.longRange) priority += 35;

    // 후면이 노출된 적: +30
    final attackDir = DirectionalCombatConstants.getAttackDirection(
      attackerX: selfX,
      attackerY: selfY,
      targetX: targetX,
      targetY: targetY,
      targetFacingAngle: targetFacingAngle,
    );
    if (attackDir == AttackDirection.back) priority += 30;
    if (attackDir == AttackDirection.side) priority += 15;

    // 상성 유리한 적: +20
    final advantage = RangeAdvantageConstants.getAdvantage(
        selfWeaponRange, targetWeaponRange);
    if (advantage > 1.0) priority += 20;

    // 가장 가까운 적: +10 (거리 반비례)
    final dx = targetX - selfX;
    final dy = targetY - selfY;
    final distance = sqrt(dx * dx + dy * dy);
    priority += (1.0 - (distance / maxDetectionRange).clamp(0.0, 1.0)) * 10;

    return priority;
  }
}
