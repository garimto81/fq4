import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../../core/constants/ai_constants.dart';
import '../../ai/ai_brain.dart';
import '../../managers/game_manager.dart';
import '../../systems/battle_controller.dart';
import '../../systems/combat_system.dart';
import 'unit_component.dart';

/// AI 자동 제어 유닛 (Godot ai_unit.gd 이식)
class AIUnitComponent extends UnitComponent {
  AIUnitComponent({
    required super.unitName,
    required super.maxHp,
    required super.maxMp,
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.level,
    super.isPlayerSide,
    super.position,
    Personality personality = Personality.balanced,
    Formation formation = Formation.vShape,
  }) : aiBrain = AIBrain(personality: personality, formation: formation);

  final AIBrain aiBrain;
  bool isPlayerControlled = false;
  int squadId = 0;

  // POC-2: BattleController/CombatSystem 연결
  BattleController? battleController;
  CombatSystem? combatSystem;

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || isPlayerControlled) return;

    final decision = aiBrain.update(dt, _buildContext());
    if (decision != null) {
      _executeDecision(decision);
    }
  }

  AIContext _buildContext() {
    // BattleController 우선, 없으면 GameManager fallback
    final bc = battleController;

    ({double x, double y})? nearestEnemy;
    double? distToEnemy;
    ({double x, double y}) leaderPosition = (x: position.x, y: position.y);
    bool hasLeader = false;
    double distToLeader = 0;
    ({double x, double y})? woundedAlly;

    if (bc != null) {
      // BattleController 경유: 직접 UnitComponent 참조
      final target = bc.findNearestEnemy(position, isPlayerSide);
      if (target != null) {
        final d = position.distanceTo(target.position);
        if (d < aiBrain.effectiveDetectionRange) {
          nearestEnemy = (x: target.position.x, y: target.position.y);
          distToEnemy = d;
        }
      }

      // 부상 아군 검색
      final wounded = bc.findWoundedAlly(position, isPlayerSide);
      if (wounded != null) {
        woundedAlly = (x: wounded.position.x, y: wounded.position.y);
      }
    } else {
      // 기존 GameManager fallback
      final gm = findParent<GameManager>();
      final leaderPos = gm?.controlledUnit;
      if (leaderPos is PositionComponent) {
        leaderPosition = (x: leaderPos.position.x, y: leaderPos.position.y);
        hasLeader = true;
        distToLeader = position.distanceTo(leaderPos.position);
      }

      if (gm != null) {
        final enemies = isPlayerSide ? gm.enemyUnits : gm.playerUnits;
        double minDist = double.infinity;
        for (final e in enemies) {
          if (e is PositionComponent) {
            final d = position.distanceTo(e.position);
            if (d < minDist && d < aiBrain.effectiveDetectionRange) {
              minDist = d;
              nearestEnemy = (x: e.position.x, y: e.position.y);
              distToEnemy = d;
            }
          }
        }
      }
    }

    return AIContext(
      hpRatio: hpRatio,
      fatigue: fatigue,
      hasLeader: hasLeader,
      leaderPosition: leaderPosition,
      nearestEnemy: nearestEnemy,
      distanceToNearestEnemy: distToEnemy,
      distanceToLeader: distToLeader,
      attackRange: AIConstants.defaultAttackRange,
      woundedAlly: woundedAlly,
    );
  }

  void _executeDecision(AIDecision decision) {
    switch (decision.type) {
      case AIDecisionType.follow:
      case AIDecisionType.chase:
      case AIDecisionType.retreat:
      case AIDecisionType.defend:
        if (decision.targetPosition != null) {
          moveTo(Vector2(decision.targetPosition!.x, decision.targetPosition!.y));
        }
      case AIDecisionType.attack:
        _attackNearestTarget();
      case AIDecisionType.rest:
        state = UnitState.resting;
      case AIDecisionType.heal:
        break;
      case AIDecisionType.scatter:
        final angle = (position.x * 7 + position.y * 13) % (2 * math.pi);
        moveTo(position + Vector2(100 * math.cos(angle), 100 * math.sin(angle)));
    }
  }

  /// POC-2: 가장 가까운 적에게 CombatSystem 경유 공격
  void _attackNearestTarget() {
    final bc = battleController;
    final cs = combatSystem;

    if (bc != null && cs != null) {
      final target = bc.findNearestEnemy(position, isPlayerSide);
      if (target != null && !target.isDead && !isDead && attackCooldown <= 0) {
        // tryAttack()로 쿨다운/피로도 처리만 수행
        if (!tryAttack()) return;

        // CombatSystem 경유 데미지 계산
        final result = cs.executeAttack(
          attacker: toUnitStats(),
          target: target.toUnitStats(),
        );

        final isMiss = result.hitResult == HitResult.miss ||
            result.hitResult == HitResult.evade;

        if (!isMiss) {
          target.takeDamage(result.damage);
        }

        bc.logAttack(unitName, target.unitName, result.damage, result.isCritical, isMiss);

        if (target.isDead) {
          bc.logDeath(target.unitName, !isPlayerSide);
        }
      }
    } else {
      // Fallback: 기존 tryAttack() (데미지 미적용)
      tryAttack();
    }
  }
}
