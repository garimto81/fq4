import 'dart:math';
import '../../core/constants/ai_constants.dart';
import '../../core/constants/strategic_combat_constants.dart';
import 'ai_brain.dart';
import 'threat_evaluator.dart';

/// 전략 AI 컨텍스트: 기본 AIContext + 전략 정보
class StrategicAIContext extends AIContext {
  final double selfFacingAngle;
  final WeaponRange selfWeaponRange;
  final double selfX;
  final double selfY;
  final List<EnemyInfo> visibleEnemies;
  final List<AllyInfo> nearbyAllies;

  const StrategicAIContext({
    required super.hpRatio,
    required super.fatigue,
    required super.hasLeader,
    required super.leaderPosition,
    super.nearestEnemy,
    super.distanceToNearestEnemy,
    required super.distanceToLeader,
    required super.attackRange,
    super.woundedAlly,
    required this.selfFacingAngle,
    required this.selfWeaponRange,
    required this.selfX,
    required this.selfY,
    this.visibleEnemies = const [],
    this.nearbyAllies = const [],
  });
}

/// 적 정보
class EnemyInfo {
  final double x;
  final double y;
  final double facingAngle;
  final WeaponRange weaponRange;
  final double hpRatio;
  final int targetingMeCount;

  const EnemyInfo({
    required this.x,
    required this.y,
    required this.facingAngle,
    required this.weaponRange,
    required this.hpRatio,
    this.targetingMeCount = 0,
  });
}

/// 아군 정보
class AllyInfo {
  final double x;
  final double y;
  final double hpRatio;
  final WeaponRange weaponRange;

  const AllyInfo({
    required this.x,
    required this.y,
    required this.hpRatio,
    required this.weaponRange,
  });
}

/// 전략 AI 두뇌: AIBrain 상속, 전술 판단 레이어 추가
class StrategicAIBrain extends AIBrain {
  StrategicAIBrain({
    super.personality,
    super.formation,
  });

  final ThreatEvaluator _threatEvaluator = ThreatEvaluator();
  final Random _random = Random();
  int flankingAttempts = 0;

  /// 전략 AI 업데이트 (기본 AI 로직 + 전술 레이어)
  AIDecision? updateStrategic(double dt, StrategicAIContext context) {
    // 기본 AI 체크 (후퇴/휴식 등)는 부모 로직 호출
    // 하지만 전략 컨텍스트에서 최적 타겟을 선택

    final baseDecision = update(dt, context);
    if (baseDecision == null) return null;

    // 전략적 판단이 필요한 상태에서만 오버라이드
    if (baseDecision.type == AIDecisionType.attack ||
        baseDecision.type == AIDecisionType.chase) {
      return _strategicTargetSelection(context, baseDecision);
    }

    // 위험 회피 판단
    if (state == AIState.attack || state == AIState.chase) {
      final evasion = _checkEvasion(context);
      if (evasion != null) return evasion;
    }

    return baseDecision;
  }

  /// 전략적 타겟 선택
  AIDecision? _strategicTargetSelection(
      StrategicAIContext context, AIDecision baseDecision) {
    if (context.visibleEnemies.isEmpty) return baseDecision;

    // 모든 적에 대해 타겟 우선순위 평가
    double bestPriority = -1;
    EnemyInfo? bestTarget;

    final profile = WeaponRangeProfile.fromRange(context.selfWeaponRange);

    for (final enemy in context.visibleEnemies) {
      final priority = _threatEvaluator.evaluateTargetPriority(
        selfX: context.selfX,
        selfY: context.selfY,
        selfWeaponRange: context.selfWeaponRange,
        targetX: enemy.x,
        targetY: enemy.y,
        targetFacingAngle: enemy.facingAngle,
        targetWeaponRange: enemy.weaponRange,
        targetHpRatio: enemy.hpRatio,
        maxDetectionRange: effectiveDetectionRange,
      );

      if (priority > bestPriority) {
        bestPriority = priority;
        bestTarget = enemy;
      }
    }

    if (bestTarget == null) return baseDecision;

    // 거리 관리: 무기 타입에 따른 최적 교전 거리
    final dx = bestTarget.x - context.selfX;
    final dy = bestTarget.y - context.selfY;
    final dist = sqrt(dx * dx + dy * dy);

    // 측면/후면 기동 시도 (성격별 확률)
    final flankChance = switch (personality) {
      Personality.aggressive => 0.5,
      Personality.balanced => 0.3,
      Personality.defensive => 0.15,
    };
    // 공격 범위 1.5배 이내일 때 기동 시도 (접근 중에도 활성화)
    if (dist < profile.attackRange * 1.5 &&
        _random.nextDouble() < flankChance) {
      final flankPos = _calculateFlankPosition(
        context.selfX,
        context.selfY,
        bestTarget.x,
        bestTarget.y,
        bestTarget.facingAngle,
      );
      if (flankPos != null) {
        flankingAttempts++;
        return AIDecision.chase(flankPos);
      }
    }

    // 원거리 유닛: 최적 거리 유지
    if (context.selfWeaponRange == WeaponRange.longRange) {
      if (dist < profile.optimalRange * 0.7) {
        // 너무 가까우면 후퇴
        final retreatDir = -(dx / dist);
        final retreatDirY = -(dy / dist);
        return AIDecision.chase((
          x: context.selfX + retreatDir * 50,
          y: context.selfY + retreatDirY * 50,
        ));
      }
    }

    // 중거리 유닛: 적정 거리 유지
    if (context.selfWeaponRange == WeaponRange.midRange) {
      if (dist < profile.optimalRange * 0.5) {
        final retreatDir = -(dx / dist);
        final retreatDirY = -(dy / dist);
        return AIDecision.chase((
          x: context.selfX + retreatDir * 30,
          y: context.selfY + retreatDirY * 30,
        ));
      }
    }

    // 공격 범위 내이면 공격
    if (dist <= profile.attackRange) {
      return AIDecision.attack((x: bestTarget.x, y: bestTarget.y));
    }

    return AIDecision.chase((x: bestTarget.x, y: bestTarget.y));
  }

  /// 측면/후면 우회 기동 위치 계산
  ({double x, double y})? _calculateFlankPosition(
    double selfX,
    double selfY,
    double targetX,
    double targetY,
    double targetFacingAngle,
  ) {
    // 대상의 후면 방향 계산
    final backAngle = targetFacingAngle + pi;
    final flankDistance = 60.0;

    // 좌우 중 가까운 측면 선택
    final leftFlank = (
      x: targetX + cos(backAngle + pi / 2) * flankDistance,
      y: targetY + sin(backAngle + pi / 2) * flankDistance,
    );
    final rightFlank = (
      x: targetX + cos(backAngle - pi / 2) * flankDistance,
      y: targetY + sin(backAngle - pi / 2) * flankDistance,
    );

    final leftDist = (leftFlank.x - selfX) * (leftFlank.x - selfX) +
        (leftFlank.y - selfY) * (leftFlank.y - selfY);
    final rightDist = (rightFlank.x - selfX) * (rightFlank.x - selfX) +
        (rightFlank.y - selfY) * (rightFlank.y - selfY);

    return leftDist < rightDist ? leftFlank : rightFlank;
  }

  /// 위험 회피 판단
  AIDecision? _checkEvasion(StrategicAIContext context) {
    // 후면에 적 1명 이상 -> 회전 (null 반환, facing 변경은 컴포넌트에서)
    int backEnemies = 0;
    int surroundingEnemies = 0;

    for (final enemy in context.visibleEnemies) {
      final dx = enemy.x - context.selfX;
      final dy = enemy.y - context.selfY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 150) continue;

      surroundingEnemies++;

      final dir = DirectionalCombatConstants.getAttackDirection(
        attackerX: enemy.x,
        attackerY: enemy.y,
        targetX: context.selfX,
        targetY: context.selfY,
        targetFacingAngle: context.selfFacingAngle,
      );
      if (dir == AttackDirection.back) backEnemies++;
    }

    // 후면 노출 + HP 위험 -> 즉시 후퇴
    if (backEnemies >= 1 && context.hpRatio < 0.4) {
      return AIDecision.retreat(context.leaderPosition);
    }

    // 3명 이상에게 포위 -> 아군 방향으로 탈출
    if (surroundingEnemies >= 3 && context.hpRatio < 0.5) {
      return AIDecision.retreat(context.leaderPosition);
    }

    // HP 30% 이하 + 적 접근 -> 즉시 후퇴
    if (context.hpRatio < 0.3 && surroundingEnemies > 0) {
      state = AIState.retreat;
      return AIDecision.retreat(context.leaderPosition);
    }

    return null;
  }
}
