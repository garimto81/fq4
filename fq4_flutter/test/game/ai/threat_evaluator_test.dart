import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/ai/threat_evaluator.dart';
import 'package:fq4_flutter/core/constants/strategic_combat_constants.dart';

void main() {
  group('ThreatEvaluator.evaluateThreat', () {
    late ThreatEvaluator evaluator;

    setUp(() {
      evaluator = ThreatEvaluator();
    });

    test('close enemy has higher threat than far enemy', () {
      // Close enemy at distance 50 from self at origin
      final closeEnemyThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 50,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      // Far enemy at distance 250
      final farEnemyThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 250,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      expect(closeEnemyThreat, greaterThan(farEnemyThreat));
      // Distance factor contributes up to 30
      expect(closeEnemyThreat - farEnemyThreat, greaterThan(0));
    });

    test('enemy behind me has higher threat than enemy in front', () {
      // Self faces right (angle=0), enemy behind = to the left at (-100, 0)
      final behindThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0, // facing right
        selfWeaponRange: WeaponRange.melee,
        enemyX: -100,
        enemyY: 0, // directly behind
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      // Enemy in front = to the right at (100, 0)
      final frontThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0, // facing right
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0, // directly in front
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      // Behind adds +40, front adds +0
      expect(behindThreat, greaterThan(frontThreat));
      expect(behindThreat - frontThreat, closeTo(40, 1.0));
    });

    test('enemy at my side gives +20 threat', () {
      // Self faces right (angle=0), enemy at 90 degrees = above at (0, -100)
      final sideThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 0,
        enemyY: -100, // perpendicular = side
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      // Enemy in front at same distance
      final frontThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      // Side adds +20, front adds +0
      expect(sideThreat, greaterThan(frontThreat));
    });

    test('more enemies targeting me increases threat', () {
      final zeroTargeting = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      final threeTargeting = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee,
        maxDetectionRange: 300,
        targetingMeCount: 3,
      );

      // +15 per targeting count
      expect(threeTargeting - zeroTargeting, closeTo(45, 0.01));
    });

    test('enemy with range advantage adds +25 threat', () {
      // melee vs longRange: longRange attacking melee defender = advantage 0.8
      // But enemy has longRange attacking self melee: getAdvantage(longRange, melee) = 0.8
      // We need enemy to have advantage: getAdvantage(enemyWeapon, selfWeapon) > 1.0
      // midRange vs melee → 1.2 (advantage)
      final advantageThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.midRange, // midRange vs melee = 1.2
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      final noAdvantageThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0,
        selfWeaponRange: WeaponRange.melee,
        enemyX: 100,
        enemyY: 0,
        enemyWeaponRange: WeaponRange.melee, // same = 1.0 (no advantage)
        maxDetectionRange: 300,
        targetingMeCount: 0,
      );

      expect(advantageThreat - noAdvantageThreat, closeTo(25, 0.01));
    });

    test('combined: close + behind + targeting = very high threat', () {
      final combinedThreat = evaluator.evaluateThreat(
        selfX: 0,
        selfY: 0,
        selfFacingAngle: 0, // facing right
        selfWeaponRange: WeaponRange.melee,
        enemyX: -30,
        enemyY: 0, // close + behind
        enemyWeaponRange: WeaponRange.midRange, // range advantage
        maxDetectionRange: 300,
        targetingMeCount: 2,
      );

      // Distance ~30/300 = 0.1, so distance factor ~ (1-0.1)*30 = 27
      // Behind: +40
      // Targeting: 2*15 = 30
      // Range advantage (midRange vs melee = 1.2 > 1.0): +25
      // Total ~ 27 + 40 + 30 + 25 = 122
      expect(combinedThreat, greaterThan(100));
    });
  });

  group('ThreatEvaluator.evaluateTargetPriority', () {
    late ThreatEvaluator evaluator;

    setUp(() {
      evaluator = ThreatEvaluator();
    });

    test('low HP target (<=30%) gets +50 priority', () {
      final lowHpPriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 0.2,
        maxDetectionRange: 300,
      );

      final fullHpPriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      expect(lowHpPriority - fullHpPriority, closeTo(50, 0.01));
    });

    test('medium HP target (<=50%) gets +25 priority', () {
      final medHpPriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 0.4,
        maxDetectionRange: 300,
      );

      final fullHpPriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      expect(medHpPriority - fullHpPriority, closeTo(25, 0.01));
    });

    test('full HP target gets no HP bonus', () {
      // Attacker in front of target so no directional bonus
      // Target faces left (pi), attacker at (-100, 0) = in front
      final fullHpPriority = evaluator.evaluateTargetPriority(
        selfX: -100,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: pi, // facing left
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // Only proximity bonus applies: (1 - 100/300) * 10 = 6.67
      // No HP bonus, no direction bonus, no type bonus, no advantage bonus
      expect(fullHpPriority, closeTo(6.67, 0.1));
    });

    test('LongRange target gets +35 priority', () {
      final longRangePriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.longRange,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      final meleePriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // longRange target gives +35 for weapon type
      // melee vs longRange advantage = 1.3 > 1.0 → +20 range advantage too
      // So total diff = 35 + 20 = 55
      expect(longRangePriority - meleePriority, closeTo(55, 0.1));
    });

    test('target with exposed back gets +30 priority', () {
      // Target faces right (angle=0), attacker behind at (-100, 0)
      final backPriority = evaluator.evaluateTargetPriority(
        selfX: -100,
        selfY: 0, // behind the target
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: 0, // facing right
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // Target faces right, attacker in front at (100, 0)
      final frontPriority = evaluator.evaluateTargetPriority(
        selfX: 100,
        selfY: 0, // in front of the target
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      expect(backPriority - frontPriority, closeTo(30, 1.0));
    });

    test('target with exposed side gets +15 priority', () {
      // Target faces right (angle=0), attacker at (0, -100) = side
      final sidePriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: -100, // side of the target
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // attacker in front
      final frontPriority = evaluator.evaluateTargetPriority(
        selfX: 100,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      expect(sidePriority, greaterThan(frontPriority));
    });

    test('range advantage against target gives +20 priority', () {
      // melee vs longRange = 1.3 > 1.0 → +20
      final _ = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.longRange,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // melee vs melee = 1.0, no advantage
      final noAdvantagePriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // longRange target also adds +35 for weapon type, but the advantage portion is +20
      // Isolate by comparing: midRange vs melee (advantage 0.8, no bonus) vs midRange vs longRange (1.2, +20)
      final midVsMelee = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.midRange,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.midRange,
        targetX: 100,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.longRange,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      // midRange vs melee: advantage = 1.2 (> 1.0, +20), melee target = no type bonus
      expect(midVsMelee, greaterThan(noAdvantagePriority)); // has advantage bonus
    });

    test('closer target gets higher proximity bonus (up to +10)', () {
      final closePriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 30,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      final farPriority = evaluator.evaluateTargetPriority(
        selfX: 0,
        selfY: 0,
        selfWeaponRange: WeaponRange.melee,
        targetX: 270,
        targetY: 0,
        targetFacingAngle: 0,
        targetWeaponRange: WeaponRange.melee,
        targetHpRatio: 1.0,
        maxDetectionRange: 300,
      );

      expect(closePriority, greaterThan(farPriority));
      // Max proximity bonus is 10
      expect(closePriority - farPriority, lessThanOrEqualTo(10));
    });

    test('combined: low HP + exposed back + range advantage = very high priority', () {
      final combinedPriority = evaluator.evaluateTargetPriority(
        selfX: -100,
        selfY: 0, // behind target
        selfWeaponRange: WeaponRange.melee,
        targetX: 0,
        targetY: 0,
        targetFacingAngle: 0, // facing right
        targetWeaponRange: WeaponRange.longRange,
        targetHpRatio: 0.2,
        maxDetectionRange: 300,
      );

      // Low HP (<=30%): +50
      // LongRange target: +35
      // Exposed back: +30
      // Range advantage (melee vs longRange = 1.3): +20
      // Proximity: (1 - 100/300) * 10 ~ 6.67
      // Total ~ 141.67
      expect(combinedPriority, greaterThan(130));
    });
  });
}
