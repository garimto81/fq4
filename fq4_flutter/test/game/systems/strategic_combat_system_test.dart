import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/core/constants/combat_constants.dart';
import 'package:fq4_flutter/core/constants/strategic_combat_constants.dart';
import 'package:fq4_flutter/game/systems/combat_system.dart';
import 'package:fq4_flutter/game/systems/strategic_combat_system.dart';

/// Run N attacks and collect results
List<StrategicAttackResult> runAttacks(
  StrategicCombatSystem scs,
  StrategicUnitStats attacker,
  StrategicUnitStats target,
  int n,
  double ax,
  double ay,
  double tx,
  double ty,
) {
  final results = <StrategicAttackResult>[];
  for (int i = 0; i < n; i++) {
    final r = scs.executeStrategicAttack(
      attacker: attacker,
      target: target,
      attackerX: ax,
      attackerY: ay,
      targetX: tx,
      targetY: ty,
    );
    results.add(r);
  }
  return results;
}

void main() {
  group('StrategicUnitStats', () {
    test('constructor creates stats with weaponRange, facingAngle, optimalRange', () {
      final stats = StrategicUnitStats(
        attack: 20,
        defense: 10,
        speed: 15,
        luck: 5,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );

      expect(stats.weaponRange, WeaponRange.melee);
      expect(stats.facingAngle, 0.0);
      expect(stats.optimalRange, 30.0);
    });

    test('inherits UnitStats fields (attack, defense, speed, luck, fatigue)', () {
      final stats = StrategicUnitStats(
        attack: 25,
        defense: 12,
        speed: 18,
        luck: 7,
        fatigue: 0.3,
        weaponRange: WeaponRange.midRange,
        facingAngle: 1.57,
        optimalRange: 100.0,
      );

      expect(stats.attack, 25);
      expect(stats.defense, 12);
      expect(stats.speed, 18);
      expect(stats.luck, 7);
      expect(stats.fatigue, 0.3);
    });
  });

  group('StrategicCombatSystem', () {
    late StrategicCombatSystem scs;

    setUp(() {
      scs = StrategicCombatSystem();
    });

    test('back attack deals more average damage than front attack', () {
      // High attack, low defense to minimize miss/evade impact
      final attacker = StrategicUnitStats(
        attack: 50,
        defense: 10,
        speed: 10,
        luck: 50, // high luck for high hit chance
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      // Target facing right (angle 0)
      final target = StrategicUnitStats(
        attack: 10,
        defense: 5,
        speed: 0,
        luck: 0,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );

      // Front attack: attacker in front (positive x)
      final frontResults = runAttacks(scs, attacker, target, 200, 100, 0, 0, 0);
      final frontHits = frontResults.where((r) => r.damage > 0).toList();

      // Back attack: attacker behind (negative x)
      final backResults = runAttacks(scs, attacker, target, 200, -100, 0, 0, 0);
      final backHits = backResults.where((r) => r.damage > 0).toList();

      // Both should have hits
      expect(frontHits, isNotEmpty);
      expect(backHits, isNotEmpty);

      final frontAvg = frontHits.fold<double>(0, (sum, r) => sum + r.damage) /
          frontHits.length;
      final backAvg = backHits.fold<double>(0, (sum, r) => sum + r.damage) /
          backHits.length;

      // Back attack (1.5x) should average higher than front (1.0x)
      expect(backAvg, greaterThan(frontAvg));
    });

    test('melee vs longRange applies range advantage producing higher damage', () {
      // Melee attacker vs longRange defender: 1.3x advantage
      final meleeAttacker = StrategicUnitStats(
        attack: 50,
        defense: 10,
        speed: 10,
        luck: 50,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      // Same stats but longRange attacker vs melee defender: 0.8x disadvantage
      final longRangeAttacker = StrategicUnitStats(
        attack: 50,
        defense: 10,
        speed: 10,
        luck: 50,
        weaponRange: WeaponRange.longRange,
        facingAngle: 0.0,
        optimalRange: 240.0,
      );
      final meleeTarget = StrategicUnitStats(
        attack: 10,
        defense: 5,
        speed: 0,
        luck: 0,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      final longRangeTarget = StrategicUnitStats(
        attack: 10,
        defense: 5,
        speed: 0,
        luck: 0,
        weaponRange: WeaponRange.longRange,
        facingAngle: 0.0,
        optimalRange: 240.0,
      );

      // All front attacks to isolate range advantage
      final advantageResults = runAttacks(
          scs, meleeAttacker, longRangeTarget, 200, 100, 0, 0, 0);
      final advantageHits =
          advantageResults.where((r) => r.damage > 0).toList();

      final disadvantageResults = runAttacks(
          scs, longRangeAttacker, meleeTarget, 200, 100, 0, 0, 0);
      final disadvantageHits =
          disadvantageResults.where((r) => r.damage > 0).toList();

      expect(advantageHits, isNotEmpty);
      expect(disadvantageHits, isNotEmpty);

      final advantageAvg =
          advantageHits.fold<double>(0, (sum, r) => sum + r.damage) /
              advantageHits.length;
      final disadvantageAvg =
          disadvantageHits.fold<double>(0, (sum, r) => sum + r.damage) /
              disadvantageHits.length;

      // 1.3x advantage should produce higher avg than 0.8x disadvantage
      expect(advantageAvg, greaterThan(disadvantageAvg));
    });

    test('miss result returns 0 damage with front direction', () {
      // Use very low luck to increase miss chance, run many attacks
      final attacker = StrategicUnitStats(
        attack: 50,
        defense: 10,
        speed: 10,
        luck: 0,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      final target = StrategicUnitStats(
        attack: 10,
        defense: 5,
        speed: 100, // high speed for evasion
        luck: 100,  // high luck for evasion
        equipmentEvasion: 0.5, // boost evasion significantly
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );

      final results = runAttacks(scs, attacker, target, 500, 100, 0, 0, 0);
      final missOrEvade = results.where(
        (r) => r.hitResult == HitResult.miss || r.hitResult == HitResult.evade,
      ).toList();

      // With high evasion, we should get some misses/evades
      expect(missOrEvade, isNotEmpty);

      // All miss/evade results should have 0 damage and front direction
      for (final r in missOrEvade) {
        expect(r.damage, 0);
        expect(r.direction, AttackDirection.front);
        expect(r.directionMultiplier, 1.0);
        expect(r.rangeAdvantage, 1.0);
      }
    });

    test('damage is always >= minDamage (1) for hits', () {
      // Low attack, high defense to test minimum damage clamping
      final attacker = StrategicUnitStats(
        attack: 1,
        defense: 0,
        speed: 10,
        luck: 50,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      final target = StrategicUnitStats(
        attack: 10,
        defense: 100, // very high defense
        speed: 0,
        luck: 0,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );

      final results = runAttacks(scs, attacker, target, 200, 100, 0, 0, 0);
      final hits = results.where((r) =>
          r.hitResult == HitResult.hit || r.hitResult == HitResult.critical);

      for (final r in hits) {
        expect(r.damage, greaterThanOrEqualTo(CombatConstants.minDamage));
      }
    });

    test('StrategicAttackResult contains direction and rangeAdvantage fields', () {
      final attacker = StrategicUnitStats(
        attack: 30,
        defense: 10,
        speed: 10,
        luck: 50,
        weaponRange: WeaponRange.melee,
        facingAngle: 0.0,
        optimalRange: 30.0,
      );
      final target = StrategicUnitStats(
        attack: 10,
        defense: 5,
        speed: 0,
        luck: 0,
        weaponRange: WeaponRange.longRange,
        facingAngle: 0.0,
        optimalRange: 240.0,
      );

      // Run one attack from behind to get back direction
      final results = runAttacks(scs, attacker, target, 1, -100, 0, 0, 0);
      final result = results.first;

      // Verify the result has the strategic fields
      expect(result.direction, isA<AttackDirection>());
      expect(result.directionMultiplier, isA<double>());
      expect(result.rangeAdvantage, isA<double>());

      // If it was a hit, direction should be back and range should be 1.3
      if (result.hitResult != HitResult.miss &&
          result.hitResult != HitResult.evade) {
        expect(result.direction, AttackDirection.back);
        expect(result.directionMultiplier, 1.5);
        expect(result.rangeAdvantage, 1.3);
      }
    });
  });
}
