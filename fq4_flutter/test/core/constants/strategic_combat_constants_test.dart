import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/core/constants/strategic_combat_constants.dart';

void main() {
  group('DirectionalCombatConstants', () {
    group('getAttackDirection', () {
      test('attacker directly in front of target returns front', () {
        // Target facing right (angle 0), attacker at positive x (in front)
        final direction = DirectionalCombatConstants.getAttackDirection(
          attackerX: 100,
          attackerY: 0,
          targetX: 0,
          targetY: 0,
          targetFacingAngle: 0,
        );

        expect(direction, AttackDirection.front);
      });

      test('attacker directly behind target returns back', () {
        // Target facing right (angle 0), attacker at negative x (behind)
        final direction = DirectionalCombatConstants.getAttackDirection(
          attackerX: -100,
          attackerY: 0,
          targetX: 0,
          targetY: 0,
          targetFacingAngle: 0,
        );

        expect(direction, AttackDirection.back);
      });

      test('attacker to the right side returns side', () {
        // Target facing right (angle 0), attacker at positive y (right side)
        final direction = DirectionalCombatConstants.getAttackDirection(
          attackerX: 0,
          attackerY: 100,
          targetX: 0,
          targetY: 0,
          targetFacingAngle: 0,
        );

        expect(direction, AttackDirection.side);
      });

      test('attacker to the left side returns side', () {
        // Target facing right (angle 0), attacker at negative y (left side)
        final direction = DirectionalCombatConstants.getAttackDirection(
          attackerX: 0,
          attackerY: -100,
          targetX: 0,
          targetY: 0,
          targetFacingAngle: 0,
        );

        expect(direction, AttackDirection.side);
      });

      test('attacker at same position as target returns front (edge case)', () {
        // Distance < 0.001 triggers early return of front
        final direction = DirectionalCombatConstants.getAttackDirection(
          attackerX: 50,
          attackerY: 50,
          targetX: 50,
          targetY: 50,
          targetFacingAngle: 0,
        );

        expect(direction, AttackDirection.front);
      });
    });

    test('directionMultiplier has correct values', () {
      expect(
        DirectionalCombatConstants.directionMultiplier[AttackDirection.front],
        1.0,
      );
      expect(
        DirectionalCombatConstants.directionMultiplier[AttackDirection.side],
        1.3,
      );
      expect(
        DirectionalCombatConstants.directionMultiplier[AttackDirection.back],
        1.5,
      );
    });
  });

  group('RangeAdvantageConstants', () {
    test('melee vs longRange returns 1.3 (advantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.melee,
          WeaponRange.longRange,
        ),
        1.3,
      );
    });

    test('midRange vs melee returns 1.2 (advantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.midRange,
          WeaponRange.melee,
        ),
        1.2,
      );
    });

    test('longRange vs midRange returns 1.2 (advantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.longRange,
          WeaponRange.midRange,
        ),
        1.2,
      );
    });

    test('longRange vs melee returns 0.8 (disadvantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.longRange,
          WeaponRange.melee,
        ),
        0.8,
      );
    });

    test('melee vs midRange returns 0.8 (disadvantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.melee,
          WeaponRange.midRange,
        ),
        0.8,
      );
    });

    test('midRange vs longRange returns 0.8 (disadvantage)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.midRange,
          WeaponRange.longRange,
        ),
        0.8,
      );
    });

    test('same type vs same type returns 1.0 (neutral)', () {
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.melee,
          WeaponRange.melee,
        ),
        1.0,
      );
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.midRange,
          WeaponRange.midRange,
        ),
        1.0,
      );
      expect(
        RangeAdvantageConstants.getAdvantage(
          WeaponRange.longRange,
          WeaponRange.longRange,
        ),
        1.0,
      );
    });
  });

  group('WeaponRangeProfile', () {
    test('melee profile has correct values', () {
      expect(WeaponRangeProfile.melee.range, WeaponRange.melee);
      expect(WeaponRangeProfile.melee.attackRange, 60);
      expect(WeaponRangeProfile.melee.optimalRange, 30);
      expect(WeaponRangeProfile.melee.dpsMultiplier, 1.4);
      expect(WeaponRangeProfile.melee.defenseBonus, 1.3);
      expect(WeaponRangeProfile.melee.speedBonus, 1.0);
    });

    test('midRange profile has correct values', () {
      expect(WeaponRangeProfile.midRange.range, WeaponRange.midRange);
      expect(WeaponRangeProfile.midRange.attackRange, 150);
      expect(WeaponRangeProfile.midRange.optimalRange, 100);
      expect(WeaponRangeProfile.midRange.dpsMultiplier, 1.0);
      expect(WeaponRangeProfile.midRange.defenseBonus, 1.0);
      expect(WeaponRangeProfile.midRange.speedBonus, 1.0);
    });

    test('longRange profile has correct values', () {
      expect(WeaponRangeProfile.longRange.range, WeaponRange.longRange);
      expect(WeaponRangeProfile.longRange.attackRange, 300);
      expect(WeaponRangeProfile.longRange.optimalRange, 240);
      expect(WeaponRangeProfile.longRange.dpsMultiplier, 0.7);
      expect(WeaponRangeProfile.longRange.defenseBonus, 0.7);
      expect(WeaponRangeProfile.longRange.speedBonus, 1.2);
    });

    test('fromRange returns correct profile for each WeaponRange', () {
      expect(WeaponRangeProfile.fromRange(WeaponRange.melee),
          WeaponRangeProfile.melee);
      expect(WeaponRangeProfile.fromRange(WeaponRange.midRange),
          WeaponRangeProfile.midRange);
      expect(WeaponRangeProfile.fromRange(WeaponRange.longRange),
          WeaponRangeProfile.longRange);
    });
  });
}
