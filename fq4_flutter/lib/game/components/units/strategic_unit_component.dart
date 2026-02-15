import 'dart:math';
import 'package:flame/components.dart';
import '../../../core/constants/fatigue_constants.dart';
import '../../../core/constants/strategic_combat_constants.dart';
import '../../ai/ai_brain.dart';
import '../../ai/strategic_ai_brain.dart';
import '../../systems/combat_system.dart';
import '../../systems/strategic_combat_system.dart';
import 'ai_unit_component.dart';
import 'unit_component.dart';

/// 전략 전투용 AI 유닛 컴포넌트
/// AIUnitComponent를 상속하여 StrategicAIBrain, WeaponRange 기반 동적 attackRange,
/// facingAngle 관리를 추가한다.
class StrategicUnitComponent extends AIUnitComponent {
  StrategicUnitComponent({
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
    super.personality,
    super.formation,
    required this.weaponRange,
  }) {
    _profile = WeaponRangeProfile.fromRange(weaponRange);
    _strategicBrain = StrategicAIBrain(
      personality: aiBrain.personality,
      formation: aiBrain.formation,
    );
  }

  final WeaponRange weaponRange;
  late final WeaponRangeProfile _profile;
  late final StrategicAIBrain _strategicBrain;

  /// 유닛이 바라보는 방향 (radian)
  double facingAngle = 0;

  /// 전략 전투 시스템 참조
  StrategicCombatSystem? strategicCombatSystem;

  /// 이 유닛을 타겟하고 있는 적 수
  int targetingMeCount = 0;

  /// 전투 통계
  int totalDamageDealt = 0;
  int totalDamageTaken = 0;
  int flankedAttacks = 0;
  int backAttacks = 0;

  /// 측면/후방 기동 시도 횟수 (AI brain에서 추적)
  int get flankingAttempts => _strategicBrain.flankingAttempts;

  @override
  void update(double dt) {
    if (isDead) {
      // UnitComponent.update(dt) 호출 (상태머신)
      // super.super는 불가하므로 직접 처리
      attackCooldown = max(0, attackCooldown - dt);
      return;
    }

    // facing angle 업데이트
    _updateFacing(dt);

    if (isPlayerControlled) {
      // 수동 제어 시 UnitComponent 상태머신만 실행
      attackCooldown = max(0, attackCooldown - dt);
      switch (state) {
        case UnitState.idle:
          fatigue = max(0, fatigue - FatigueConstants.recoveryIdle * dt);
        case UnitState.moving:
          _processMovingBase(dt);
        case UnitState.attacking:
          if (attackCooldown <= 0) state = UnitState.idle;
        case UnitState.resting:
          fatigue = max(0, fatigue - FatigueConstants.recoveryRest * dt);
          if (fatigue <= FatigueConstants.normalMax) {
            state = UnitState.idle;
          }
        case UnitState.dead:
          break;
      }
      return;
    }

    // 전략 AI 실행
    final context = _buildStrategicContext();
    final sw = Stopwatch()..start();
    final decision = _strategicBrain.updateStrategic(dt, context);
    sw.stop();
    // performanceMonitor?.recordAiTick(sw.elapsedMicroseconds / 1000.0);

    if (decision != null) {
      _executeDecisionStrategic(decision);
    }

    // UnitComponent 상태머신 (피로도 회복 포함)
    attackCooldown = max(0, attackCooldown - dt);
    switch (state) {
      case UnitState.idle:
        fatigue = max(0, fatigue - FatigueConstants.recoveryIdle * dt);
      case UnitState.moving:
        _processMovingBase(dt);
      case UnitState.attacking:
        if (attackCooldown <= 0) state = UnitState.idle;
      case UnitState.resting:
        fatigue = max(0, fatigue - FatigueConstants.recoveryRest * dt);
        if (fatigue <= FatigueConstants.normalMax) {
          state = UnitState.idle;
        }
      case UnitState.dead:
        break;
    }
  }

  void _processMovingBase(double dt) {
    if (moveTarget == null) {
      state = UnitState.idle;
      return;
    }
    final dir = moveTarget! - position;
    if (dir.length < 5) {
      moveTarget = null;
      state = UnitState.idle;
      return;
    }
    final fatigueLevel = fatigue;
    // 간단한 피로도 속도 배율 (기존 FatigueSystem 참조)
    double speedMult = 1.0;
    if (fatigueLevel > 90) {
      speedMult = 0;
    } else if (fatigueLevel > 60) {
      speedMult = 0.5;
    } else if (fatigueLevel > 30) {
      speedMult = 0.8;
    }
    final moveSpeed = speed * speedMult * _profile.speedBonus;
    velocity = dir.normalized() * moveSpeed;
    position += velocity * dt;
    // 이동 피로도 누적
    final distance = (velocity * dt).length;
    fatigue = min(100, fatigue + distance * FatigueConstants.fatigueMovePerUnit);
  }

  /// facing angle 업데이트
  void _updateFacing(double dt) {
    if (velocity.length > 1) {
      // 이동 중: 이동 방향
      facingAngle = atan2(velocity.y, velocity.x);
    }
    // 공격 대상이 있으면 대상 방향 (attack 상태)
    // 이는 _executeDecisionStrategic에서 처리
  }

  /// 전략 AI 컨텍스트 빌드
  StrategicAIContext _buildStrategicContext() {
    final bc = battleController;

    ({double x, double y})? nearestEnemy;
    double? distToEnemy;
    ({double x, double y}) leaderPosition = (x: position.x, y: position.y);
    bool hasLeader = false;
    double distToLeader = 0;
    ({double x, double y})? woundedAlly;
    List<EnemyInfo> visibleEnemies = [];
    List<AllyInfo> nearbyAllies = [];

    if (bc != null) {
      // 리더 찾기: 플레이어 컨트롤 유닛만 리더로 인정
      // (리더 없으면 hasLeader=false → AI가 idle에서 직접 chase로 전환)
      final sameTeam = isPlayerSide ? bc.allies : bc.enemies;
      for (final ally in sameTeam) {
        if (ally.isDead || ally == this) continue;
        if (ally is AIUnitComponent && ally.isPlayerControlled) {
          hasLeader = true;
          leaderPosition = (x: ally.position.x, y: ally.position.y);
          distToLeader = position.distanceTo(ally.position);
          break;
        }
      }

      // 적 목록 수집
      final targets = isPlayerSide ? bc.enemies : bc.allies;
      double minDist = double.infinity;

      for (final target in targets) {
        if (target.isDead) continue;
        final d = position.distanceTo(target.position);
        if (d < _strategicBrain.effectiveDetectionRange) {
          // WeaponRange 결정
          WeaponRange enemyWeapon = WeaponRange.melee;
          double enemyFacing = 0;
          if (target is StrategicUnitComponent) {
            enemyWeapon = target.weaponRange;
            enemyFacing = target.facingAngle;
          }

          visibleEnemies.add(EnemyInfo(
            x: target.position.x,
            y: target.position.y,
            facingAngle: enemyFacing,
            weaponRange: enemyWeapon,
            hpRatio: target.hpRatio,
            targetingMeCount: 0,
          ));

          if (d < minDist) {
            minDist = d;
            nearestEnemy = (x: target.position.x, y: target.position.y);
            distToEnemy = d;
          }
        }
      }

      // 아군 목록 수집
      final allies = isPlayerSide ? bc.allies : bc.enemies;
      for (final ally in allies) {
        if (ally.isDead || ally == this) continue;
        final d = position.distanceTo(ally.position);
        if (d < 200) {
          WeaponRange allyWeapon = WeaponRange.melee;
          if (ally is StrategicUnitComponent) {
            allyWeapon = ally.weaponRange;
          }
          nearbyAllies.add(AllyInfo(
            x: ally.position.x,
            y: ally.position.y,
            hpRatio: ally.hpRatio,
            weaponRange: allyWeapon,
          ));
        }
      }

      // 부상 아군
      final wounded = bc.findWoundedAlly(position, isPlayerSide);
      if (wounded != null) {
        woundedAlly = (x: wounded.position.x, y: wounded.position.y);
      }
    }

    return StrategicAIContext(
      hpRatio: hpRatio,
      fatigue: fatigue,
      hasLeader: hasLeader,
      leaderPosition: leaderPosition,
      nearestEnemy: nearestEnemy,
      distanceToNearestEnemy: distToEnemy,
      distanceToLeader: distToLeader,
      attackRange: _profile.attackRange,
      woundedAlly: woundedAlly,
      selfFacingAngle: facingAngle,
      selfWeaponRange: weaponRange,
      selfX: position.x,
      selfY: position.y,
      visibleEnemies: visibleEnemies,
      nearbyAllies: nearbyAllies,
    );
  }

  void _executeDecisionStrategic(AIDecision decision) {
    switch (decision.type) {
      case AIDecisionType.follow:
      case AIDecisionType.chase:
      case AIDecisionType.retreat:
      case AIDecisionType.defend:
        if (decision.targetPosition != null) {
          moveTo(Vector2(decision.targetPosition!.x, decision.targetPosition!.y));
        }
      case AIDecisionType.attack:
        if (decision.targetPosition != null) {
          // 타겟 방향으로 facing 업데이트
          final dx = decision.targetPosition!.x - position.x;
          final dy = decision.targetPosition!.y - position.y;
          facingAngle = atan2(dy, dx);
        }
        _strategicAttackNearest();
      case AIDecisionType.rest:
        state = UnitState.resting;
      case AIDecisionType.heal:
        break;
      case AIDecisionType.scatter:
        final angle = (position.x * 7 + position.y * 13) % (2 * pi);
        moveTo(position + Vector2(100 * cos(angle), 100 * sin(angle)));
    }
  }

  /// 전략 전투 시스템 경유 공격
  void _strategicAttackNearest() {
    final bc = battleController;
    final scs = strategicCombatSystem;

    if (bc != null && scs != null) {
      final target = bc.findNearestEnemy(position, isPlayerSide);
      if (target != null && !target.isDead && !isDead && attackCooldown <= 0) {
        final dist = position.distanceTo(target.position);
        if (dist > _profile.attackRange) return;

        if (!tryAttack()) return;

        // 전략 스탯 생성
        final attackerStats = toStrategicUnitStats();
        double targetFacing = 0;
        WeaponRange targetWeapon = WeaponRange.melee;
        double targetOptimal = 30;
        if (target is StrategicUnitComponent) {
          targetFacing = target.facingAngle;
          targetWeapon = target.weaponRange;
          targetOptimal = target._profile.optimalRange;
        }

        final targetStats = StrategicUnitStats(
          attack: target.attack,
          defense: target.defense,
          speed: target.speed,
          luck: target.luck,
          fatigue: target.fatigue,
          weaponRange: targetWeapon,
          facingAngle: targetFacing,
          optimalRange: targetOptimal,
        );

        final result = scs.executeStrategicAttack(
          attacker: attackerStats,
          target: targetStats,
          attackerX: position.x,
          attackerY: position.y,
          targetX: target.position.x,
          targetY: target.position.y,
        );

        final isMiss = result.hitResult == HitResult.miss ||
            result.hitResult == HitResult.evade;

        if (!isMiss) {
          target.takeDamage(result.damage);
          totalDamageDealt += result.damage;
          if (result.direction == AttackDirection.side) flankedAttacks++;
          if (result.direction == AttackDirection.back) backAttacks++;
        }

        bc.logAttack(unitName, target.unitName, result.damage, result.isCritical, isMiss);

        if (target.isDead) {
          bc.logDeath(target.unitName, !isPlayerSide);
        }
      }
    } else {
      // Fallback to basic combat
      final bc2 = battleController;
      final cs = combatSystem;
      if (bc2 != null && cs != null) {
        final target = bc2.findNearestEnemy(position, isPlayerSide);
        if (target != null && !target.isDead && !isDead && attackCooldown <= 0) {
          if (!tryAttack()) return;
          final result = cs.executeAttack(
            attacker: toUnitStats(),
            target: target.toUnitStats(),
          );
          final isMiss = result.hitResult == HitResult.miss ||
              result.hitResult == HitResult.evade;
          if (!isMiss) {
            target.takeDamage(result.damage);
          }
          bc2.logAttack(unitName, target.unitName, result.damage, result.isCritical, isMiss);
          if (target.isDead) {
            bc2.logDeath(target.unitName, !isPlayerSide);
          }
        }
      }
    }
  }

  @override
  void takeDamage(int damage) {
    totalDamageTaken += damage;
    super.takeDamage(damage);
  }

  /// StrategicUnitStats 변환
  StrategicUnitStats toStrategicUnitStats() {
    return StrategicUnitStats(
      attack: (attack * _profile.dpsMultiplier).round(),
      defense: (defense * _profile.defenseBonus).round(),
      speed: speed,
      luck: luck,
      fatigue: fatigue,
      weaponRange: weaponRange,
      facingAngle: facingAngle,
      optimalRange: _profile.optimalRange,
    );
  }
}
