import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/ai/strategic_ai_brain.dart';
import 'package:fq4_flutter/game/ai/ai_brain.dart';
import 'package:fq4_flutter/core/constants/ai_constants.dart';
import 'package:fq4_flutter/core/constants/strategic_combat_constants.dart';

/// Helper: StrategicAIContext builder with sensible defaults
StrategicAIContext makeContext({
  double hpRatio = 1.0,
  double fatigue = 0,
  bool hasLeader = true,
  ({double x, double y}) leaderPosition = (x: 0.0, y: 0.0),
  ({double x, double y})? nearestEnemy,
  double? distanceToNearestEnemy,
  double distanceToLeader = 50,
  double attackRange = 60,
  double selfFacingAngle = 0,
  WeaponRange selfWeaponRange = WeaponRange.melee,
  double selfX = 0,
  double selfY = 0,
  List<EnemyInfo> visibleEnemies = const [],
  List<AllyInfo> nearbyAllies = const [],
}) {
  return StrategicAIContext(
    hpRatio: hpRatio,
    fatigue: fatigue,
    hasLeader: hasLeader,
    leaderPosition: leaderPosition,
    nearestEnemy: nearestEnemy,
    distanceToNearestEnemy: distanceToNearestEnemy,
    distanceToLeader: distanceToLeader,
    attackRange: attackRange,
    selfFacingAngle: selfFacingAngle,
    selfWeaponRange: selfWeaponRange,
    selfX: selfX,
    selfY: selfY,
    visibleEnemies: visibleEnemies,
    nearbyAllies: nearbyAllies,
  );
}

/// Fires one tick to transition brain from idle to follow state.
/// Returns the follow decision from the first tick.
AIDecision? _warmUpToFollow(StrategicAIBrain brain) {
  return brain.updateStrategic(0.31, makeContext());
}

void main() {
  group('StrategicAIContext', () {
    test('constructor stores all required fields', () {
      final ctx = StrategicAIContext(
        hpRatio: 0.8,
        fatigue: 25,
        hasLeader: true,
        leaderPosition: (x: 10.0, y: 20.0),
        distanceToLeader: 30,
        attackRange: 60,
        selfFacingAngle: 1.5,
        selfWeaponRange: WeaponRange.midRange,
        selfX: 100,
        selfY: 200,
      );

      expect(ctx.hpRatio, 0.8);
      expect(ctx.fatigue, 25);
      expect(ctx.hasLeader, true);
      expect(ctx.leaderPosition, (x: 10.0, y: 20.0));
      expect(ctx.distanceToLeader, 30);
      expect(ctx.attackRange, 60);
      expect(ctx.selfFacingAngle, 1.5);
      expect(ctx.selfWeaponRange, WeaponRange.midRange);
      expect(ctx.selfX, 100);
      expect(ctx.selfY, 200);
    });

    test('visibleEnemies defaults to empty list', () {
      final ctx = makeContext();

      expect(ctx.visibleEnemies, isEmpty);
    });

    test('nearbyAllies defaults to empty list', () {
      final ctx = makeContext();

      expect(ctx.nearbyAllies, isEmpty);
    });
  });

  group('EnemyInfo', () {
    test('constructor stores all fields correctly', () {
      final enemy = EnemyInfo(
        x: 50,
        y: 60,
        facingAngle: 1.2,
        weaponRange: WeaponRange.longRange,
        hpRatio: 0.4,
        targetingMeCount: 2,
      );

      expect(enemy.x, 50);
      expect(enemy.y, 60);
      expect(enemy.facingAngle, 1.2);
      expect(enemy.weaponRange, WeaponRange.longRange);
      expect(enemy.hpRatio, 0.4);
      expect(enemy.targetingMeCount, 2);
    });

    test('targetingMeCount defaults to 0', () {
      final enemy = EnemyInfo(
        x: 0,
        y: 0,
        facingAngle: 0,
        weaponRange: WeaponRange.melee,
        hpRatio: 1.0,
      );

      expect(enemy.targetingMeCount, 0);
    });
  });

  group('AllyInfo', () {
    test('constructor stores all fields correctly', () {
      final ally = AllyInfo(
        x: 30,
        y: 40,
        hpRatio: 0.7,
        weaponRange: WeaponRange.midRange,
      );

      expect(ally.x, 30);
      expect(ally.y, 40);
      expect(ally.hpRatio, 0.7);
      expect(ally.weaponRange, WeaponRange.midRange);
    });
  });

  group('StrategicAIBrain.updateStrategic', () {
    test('returns null when tick interval not reached', () {
      final brain = StrategicAIBrain();
      final ctx = makeContext();

      // dt=0.1 is less than AIConstants.allyTickInterval (0.3)
      final result = brain.updateStrategic(0.1, ctx);

      expect(result, isNull);
    });

    test('with no enemies and leader present returns follow', () {
      final brain = StrategicAIBrain();
      final ctx = makeContext(
        hasLeader: true,
        leaderPosition: (x: 100.0, y: 200.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.follow);
      expect(result.targetPosition, (x: 100.0, y: 200.0));
    });

    test('low HP triggers retreat', () {
      final brain = StrategicAIBrain();
      final ctx = makeContext(
        hpRatio: 0.1,
        leaderPosition: (x: 0.0, y: 0.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.retreat);
    });

    test('high fatigue triggers forced rest', () {
      final brain = StrategicAIBrain();
      final ctx = makeContext(
        fatigue: 90,
        leaderPosition: (x: 0.0, y: 0.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.rest);
    });

    test('with visible enemies in range returns attack or chase', () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      // First tick: transition from idle to follow state
      _warmUpToFollow(brain);

      // Second tick: balanced personality engages when dist < attackEngageRange * 1.5
      final enemy = EnemyInfo(
        x: 100,
        y: 0,
        facingAngle: pi,
        weaponRange: WeaponRange.melee,
        hpRatio: 0.5,
      );
      final ctx = makeContext(
        nearestEnemy: (x: 100.0, y: 0.0),
        distanceToNearestEnemy: 100,
        attackRange: 150,
        selfWeaponRange: WeaponRange.melee,
        visibleEnemies: [enemy],
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(
        result!.type,
        anyOf(AIDecisionType.attack, AIDecisionType.chase),
      );
    });

    test('aggressive personality with enemy in range attempts flanking', () {
      // Flanking has 50% random chance for aggressive. Run multiple iterations.
      int flankCount = 0;
      int attackCount = 0;
      const runs = 100;

      for (int i = 0; i < runs; i++) {
        final brain = StrategicAIBrain(personality: Personality.aggressive);
        _warmUpToFollow(brain);

        final enemy = EnemyInfo(
          x: 40,
          y: 0,
          facingAngle: 0,
          weaponRange: WeaponRange.melee,
          hpRatio: 1.0,
        );

        // Aggressive: dist 40 < attackRange * 1.5 (90), aggressive -> 50% flank
        final ctx = makeContext(
          nearestEnemy: (x: 40.0, y: 0.0),
          distanceToNearestEnemy: 40,
          attackRange: 150,
          selfWeaponRange: WeaponRange.melee,
          visibleEnemies: [enemy],
        );

        final result = brain.updateStrategic(0.31, ctx);
        if (result != null) {
          if (result.type == AIDecisionType.chase) {
            flankCount++;
          } else if (result.type == AIDecisionType.attack) {
            attackCount++;
          }
        }
      }

      // With 50% chance, expect some flanks and some attacks
      expect(flankCount, greaterThan(0));
      expect(attackCount, greaterThan(0));
    });

    test('balanced personality also attempts flanking with 30% chance', () {
      int flankCount = 0;
      const runs = 100;

      for (int i = 0; i < runs; i++) {
        final brain = StrategicAIBrain(personality: Personality.balanced);
        _warmUpToFollow(brain);

        final enemy = EnemyInfo(
          x: 40,
          y: 0,
          facingAngle: 0,
          weaponRange: WeaponRange.melee,
          hpRatio: 1.0,
        );

        final ctx = makeContext(
          nearestEnemy: (x: 40.0, y: 0.0),
          distanceToNearestEnemy: 40,
          attackRange: 150,
          selfWeaponRange: WeaponRange.melee,
          visibleEnemies: [enemy],
        );

        final result = brain.updateStrategic(0.31, ctx);
        if (result != null && result.type == AIDecisionType.chase) {
          flankCount++;
        }
      }

      // Balanced has 30% flank chance
      expect(flankCount, greaterThan(0));
    });

    test('defensive personality attempts flanking with 15% chance', () {
      int flankCount = 0;
      const runs = 200;

      for (int i = 0; i < runs; i++) {
        final brain = StrategicAIBrain(personality: Personality.defensive);
        // hasLeader: false -> idle에서 직접 chase로 전환
        // (defensive는 follow 상태에서 적 감지해도 engage하지 않으므로)
        brain.updateStrategic(0.31, makeContext(hasLeader: false));

        final enemy = EnemyInfo(
          x: 40,
          y: 0,
          facingAngle: 0,
          weaponRange: WeaponRange.melee,
          hpRatio: 1.0,
        );

        final ctx = makeContext(
          hasLeader: false,
          nearestEnemy: (x: 40.0, y: 0.0),
          distanceToNearestEnemy: 40,
          attackRange: 150,
          selfWeaponRange: WeaponRange.melee,
          visibleEnemies: [enemy],
        );

        final result = brain.updateStrategic(0.31, ctx);
        if (result != null && result.type == AIDecisionType.chase) {
          flankCount++;
        }
      }

      // Defensive has 15% flank chance - should still see some
      expect(flankCount, greaterThan(0));
    });

    test('flankingAttempts counter increments on flanking decisions', () {
      int totalFlankAttempts = 0;
      const runs = 100;

      for (int i = 0; i < runs; i++) {
        final brain = StrategicAIBrain(personality: Personality.aggressive);
        _warmUpToFollow(brain);

        final enemy = EnemyInfo(
          x: 40,
          y: 0,
          facingAngle: 0,
          weaponRange: WeaponRange.melee,
          hpRatio: 1.0,
        );

        final ctx = makeContext(
          nearestEnemy: (x: 40.0, y: 0.0),
          distanceToNearestEnemy: 40,
          attackRange: 150,
          selfWeaponRange: WeaponRange.melee,
          visibleEnemies: [enemy],
        );

        brain.updateStrategic(0.31, ctx);
        totalFlankAttempts += brain.flankingAttempts;
      }

      // With 50% aggressive chance over 100 runs, should have many
      expect(totalFlankAttempts, greaterThan(0));
    });

    test('longRange weapon too close to enemy retreats to maintain distance',
        () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      // Warm up: idle -> follow
      _warmUpToFollow(brain);

      // longRange optimalRange = 240, threshold = 0.7 * 240 = 168
      // Enemy at distance 50, well below threshold
      final enemy = EnemyInfo(
        x: 50,
        y: 0,
        facingAngle: 0,
        weaponRange: WeaponRange.melee,
        hpRatio: 1.0,
      );

      // balanced + dist 50 < attackEngageRange*1.5=225 -> base returns attack
      // strategic selection: longRange, dist 50 < 168 -> retreat chase away
      final ctx = makeContext(
        nearestEnemy: (x: 50.0, y: 0.0),
        distanceToNearestEnemy: 50,
        attackRange: 150,
        selfWeaponRange: WeaponRange.longRange,
        visibleEnemies: [enemy],
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.chase);
      // Should move away from enemy (negative x)
      expect(result.targetPosition!.x, lessThan(0));
    });

    test('midRange weapon too close to enemy retreats to optimal distance',
        () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      _warmUpToFollow(brain);

      // midRange optimalRange = 100, threshold = 0.5 * 100 = 50
      // Enemy at distance 30, below threshold
      final enemy = EnemyInfo(
        x: 30,
        y: 0,
        facingAngle: 0,
        weaponRange: WeaponRange.melee,
        hpRatio: 1.0,
      );

      final ctx = makeContext(
        nearestEnemy: (x: 30.0, y: 0.0),
        distanceToNearestEnemy: 30,
        attackRange: 150,
        selfWeaponRange: WeaponRange.midRange,
        visibleEnemies: [enemy],
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.chase);
      // Should move away from enemy
      expect(result.targetPosition!.x, lessThan(0));
    });
  });

  group('Evasion via updateStrategic', () {
    test('back enemy + low HP triggers retreat via evasion', () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      // Set state to attack directly and use squad command to get a
      // non-attack base decision while keeping state as attack.
      // This exercises the _checkEvasion code path.
      brain.state = AIState.attack;
      brain.currentCommand = SquadCommand.gather;

      // Enemy behind us (back direction): self faces right (angle 0),
      // enemy at (-30, 0) is behind.
      final backEnemy = EnemyInfo(
        x: -30,
        y: 0,
        facingAngle: 0,
        weaponRange: WeaponRange.melee,
        hpRatio: 1.0,
      );
      final ctx = makeContext(
        hpRatio: 0.35, // < 0.4
        selfFacingAngle: 0,
        visibleEnemies: [backEnemy],
        leaderPosition: (x: -100.0, y: 0.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.retreat);
    });

    test('surrounded by 3+ enemies with HP < 50% triggers retreat', () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      brain.state = AIState.chase;
      brain.currentCommand = SquadCommand.gather;

      // 3 enemies within 150px distance
      final enemies = [
        EnemyInfo(x: 50, y: 0, facingAngle: 0, weaponRange: WeaponRange.melee, hpRatio: 1.0),
        EnemyInfo(x: -50, y: 0, facingAngle: 0, weaponRange: WeaponRange.melee, hpRatio: 1.0),
        EnemyInfo(x: 0, y: 50, facingAngle: 0, weaponRange: WeaponRange.melee, hpRatio: 1.0),
      ];
      final ctx = makeContext(
        hpRatio: 0.45, // < 0.5
        visibleEnemies: enemies,
        leaderPosition: (x: -200.0, y: 0.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.retreat);
    });

    test('HP below 30% with enemies nearby triggers immediate retreat', () {
      final brain = StrategicAIBrain(personality: Personality.balanced);
      // HP < 0.3 triggers base AIBrain retreat directly (effectiveRetreatHp)
      final enemy = EnemyInfo(
        x: 80,
        y: 0,
        facingAngle: pi,
        weaponRange: WeaponRange.melee,
        hpRatio: 1.0,
      );
      final ctx = makeContext(
        hpRatio: 0.25,
        nearestEnemy: (x: 80.0, y: 0.0),
        distanceToNearestEnemy: 80,
        attackRange: 60,
        visibleEnemies: [enemy],
        leaderPosition: (x: -100.0, y: 0.0),
      );

      final result = brain.updateStrategic(0.31, ctx);

      expect(result, isNotNull);
      expect(result!.type, AIDecisionType.retreat);
    });
  });
}
