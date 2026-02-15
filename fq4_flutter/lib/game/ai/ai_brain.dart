import '../../core/constants/ai_constants.dart';
import '../../core/constants/fatigue_constants.dart';

/// Gocha-Kyara AI 두뇌 (Godot ai_unit.gd에서 이식)
class AIBrain {
  AIBrain({
    this.personality = Personality.balanced,
    this.formation = Formation.vShape,
  });

  Personality personality;
  Formation formation;
  AIState state = AIState.idle;
  SquadCommand currentCommand = SquadCommand.none;

  double _aiTimer = 0;

  /// 유효 감지 범위
  double get effectiveDetectionRange =>
      AIConstants.allyDetectionRange * personality.chaseRangeMult;

  /// 유효 후퇴 HP 임계값
  double get effectiveRetreatHp =>
      AIConstants.retreatHpThreshold * personality.retreatHpMult;

  /// AI tick 업데이트
  AIDecision? update(double dt, AIContext context) {
    _aiTimer += dt;
    if (_aiTimer < AIConstants.allyTickInterval) return null;
    _aiTimer = 0;

    // 강제 휴식 (피로도 90%+)
    if (context.fatigue >= AIConstants.fatigueForceRestThreshold) {
      state = AIState.rest;
      return AIDecision.rest();
    }

    // 후퇴 판정 (HP)
    if (context.hpRatio < effectiveRetreatHp) {
      state = AIState.retreat;
      return AIDecision.retreat(context.leaderPosition);
    }

    // 후퇴 판정 (피로도)
    if (context.fatigue >= AIConstants.fatigueRetreatThreshold) {
      state = AIState.retreat;
      return AIDecision.retreat(context.leaderPosition);
    }

    // 부대 명령 처리
    if (currentCommand != SquadCommand.none) {
      return _processCommand(context);
    }

    // 상태별 행동
    return switch (state) {
      AIState.idle => _processIdle(context),
      AIState.follow => _processFollow(context),
      AIState.patrol => _processPatrol(context),
      AIState.chase => _processChase(context),
      AIState.attack => _processAttack(context),
      AIState.retreat => _processRetreat(context),
      AIState.defend => _processDefend(context),
      AIState.support => _processSupport(context),
      AIState.rest => _processRest(context),
    };
  }

  AIDecision? _processIdle(AIContext context) {
    if (context.hasLeader) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    if (context.nearestEnemy != null) {
      state = AIState.chase;
      return AIDecision.chase(context.nearestEnemy!);
    }
    return null;
  }

  AIDecision? _processFollow(AIContext context) {
    if (context.nearestEnemy != null) {
      final dist = context.distanceToNearestEnemy ?? double.infinity;
      if (personality == Personality.aggressive && dist < AIConstants.attackEngageRange) {
        state = AIState.chase;
        return AIDecision.chase(context.nearestEnemy!);
      }
      if (personality == Personality.balanced && dist < AIConstants.attackEngageRange * 1.5) {
        state = AIState.attack;
        return AIDecision.attack(context.nearestEnemy!);
      }
    }
    return AIDecision.follow(context.leaderPosition);
  }

  AIDecision? _processChase(AIContext context) {
    if (context.nearestEnemy == null) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    final dist = context.distanceToNearestEnemy!;
    if (dist <= context.attackRange) {
      state = AIState.attack;
      return AIDecision.attack(context.nearestEnemy!);
    }
    // 리더와 너무 멀면 FOLLOW
    if (context.distanceToLeader > effectiveDetectionRange * 1.5) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    return AIDecision.chase(context.nearestEnemy!);
  }

  AIDecision? _processAttack(AIContext context) {
    if (context.nearestEnemy == null) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    final dist = context.distanceToNearestEnemy!;
    if (dist > context.attackRange) {
      state = AIState.chase;
      return AIDecision.chase(context.nearestEnemy!);
    }
    return AIDecision.attack(context.nearestEnemy!);
  }

  AIDecision? _processRetreat(AIContext context) {
    if (context.hpRatio > effectiveRetreatHp + 0.1 &&
        context.fatigue < AIConstants.fatigueRetreatThreshold - 10) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    return AIDecision.retreat(context.leaderPosition);
  }

  AIDecision? _processDefend(AIContext context) {
    return AIDecision.defend(context.leaderPosition);
  }

  AIDecision? _processSupport(AIContext context) {
    // 부상 아군 검색 (HP < 50%)
    if (context.woundedAlly != null) {
      return AIDecision.heal(context.woundedAlly!);
    }
    if (context.nearestEnemy != null) {
      return AIDecision.attack(context.nearestEnemy!);
    }
    return AIDecision.follow(context.leaderPosition);
  }

  AIDecision? _processRest(AIContext context) {
    if (context.fatigue < FatigueConstants.normalMax) {
      state = AIState.follow;
      return AIDecision.follow(context.leaderPosition);
    }
    return AIDecision.rest();
  }

  AIDecision? _processPatrol(AIContext context) {
    if (context.nearestEnemy != null) {
      state = AIState.chase;
      return AIDecision.chase(context.nearestEnemy!);
    }
    return null;
  }

  AIDecision? _processCommand(AIContext context) {
    return switch (currentCommand) {
      SquadCommand.gather => AIDecision.follow(context.leaderPosition),
      SquadCommand.scatter => AIDecision.scatter(),
      SquadCommand.attackAll => () {
        state = AIState.attack;
        return context.nearestEnemy != null
            ? AIDecision.attack(context.nearestEnemy!)
            : null;
      }(),
      SquadCommand.defendAll => AIDecision.defend(context.leaderPosition),
      SquadCommand.retreatAll => AIDecision.retreat(context.leaderPosition),
      SquadCommand.none => null,
    };
  }
}

/// AI 판단 컨텍스트
class AIContext {
  final double hpRatio;
  final double fatigue;
  final bool hasLeader;
  final ({double x, double y}) leaderPosition;
  final ({double x, double y})? nearestEnemy;
  final double? distanceToNearestEnemy;
  final double distanceToLeader;
  final double attackRange;
  final ({double x, double y})? woundedAlly;

  const AIContext({
    required this.hpRatio,
    required this.fatigue,
    required this.hasLeader,
    required this.leaderPosition,
    this.nearestEnemy,
    this.distanceToNearestEnemy,
    required this.distanceToLeader,
    required this.attackRange,
    this.woundedAlly,
  });
}

/// AI 판단 결과
class AIDecision {
  final AIDecisionType type;
  final ({double x, double y})? targetPosition;

  const AIDecision._({required this.type, this.targetPosition});

  factory AIDecision.follow(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.follow, targetPosition: pos);
  factory AIDecision.chase(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.chase, targetPosition: pos);
  factory AIDecision.attack(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.attack, targetPosition: pos);
  factory AIDecision.retreat(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.retreat, targetPosition: pos);
  factory AIDecision.defend(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.defend, targetPosition: pos);
  factory AIDecision.heal(({double x, double y}) pos) =>
      AIDecision._(type: AIDecisionType.heal, targetPosition: pos);
  factory AIDecision.rest() =>
      const AIDecision._(type: AIDecisionType.rest);
  factory AIDecision.scatter() =>
      const AIDecision._(type: AIDecisionType.scatter);
}

enum AIDecisionType {
  follow,
  chase,
  attack,
  retreat,
  defend,
  heal,
  rest,
  scatter,
}
