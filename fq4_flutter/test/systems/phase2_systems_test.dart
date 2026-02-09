import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/core/constants/spell_constants.dart';
import 'package:fq4_flutter/core/constants/status_effect_constants.dart';
import 'package:fq4_flutter/game/systems/magic_system.dart';
import 'package:fq4_flutter/game/systems/status_effect_system.dart';
import 'package:fq4_flutter/game/systems/environment_system.dart';

void main() {
  group('MagicSystem', () {
    late MagicSystem magicSystem;

    setUp(() {
      magicSystem = MagicSystem();
    });

    test('castSpell succeeds with sufficient MP and no cooldown', () {
      final spell = SpellData.allSpells[0]; // fire_ball
      final result = magicSystem.castSpell(
        casterId: 1,
        casterMp: 100,
        spell: spell,
        areaTargets: [2, 3],
      );

      expect(result.success, isTrue);
      expect(result.targets, equals([2, 3]));
    });

    test('castSpell fails with insufficient MP', () {
      final spell = SpellData.allSpells[0]; // fire_ball (mpCost: 15)
      final result = magicSystem.castSpell(
        casterId: 1,
        casterMp: 10,
        spell: spell,
        areaTargets: [2],
      );

      expect(result.success, isFalse);
      expect(result.reason, contains('Not enough MP'));
    });

    test('cooldown prevents immediate recast', () {
      final spell = SpellData.allSpells[0];

      // First cast
      magicSystem.castSpell(
        casterId: 1,
        casterMp: 100,
        spell: spell,
        areaTargets: [2],
      );

      // Immediate recast should fail
      final result = magicSystem.castSpell(
        casterId: 1,
        casterMp: 100,
        spell: spell,
        areaTargets: [2],
      );

      expect(result.success, isFalse);
      expect(result.reason, contains('On cooldown'));
      expect(magicSystem.isOnCooldown(1, spell.id), isTrue);
    });

    test('updateCooldowns reduces remaining time', () {
      final spell = SpellData.allSpells[0]; // cooldown: 4.0

      magicSystem.castSpell(
        casterId: 1,
        casterMp: 100,
        spell: spell,
        areaTargets: [2],
      );

      final initialRemaining = magicSystem.getCooldownRemaining(1, spell.id);
      expect(initialRemaining, equals(4.0));

      // Update by 1 second
      magicSystem.updateCooldowns(1.0);

      final afterUpdate = magicSystem.getCooldownRemaining(1, spell.id);
      expect(afterUpdate, equals(3.0));
    });

    test('cooldown expires after full duration', () {
      final spell = SpellData.allSpells[0]; // cooldown: 4.0

      magicSystem.castSpell(
        casterId: 1,
        casterMp: 100,
        spell: spell,
        areaTargets: [2],
      );

      // Update by full cooldown duration
      magicSystem.updateCooldowns(4.5);

      expect(magicSystem.isOnCooldown(1, spell.id), isFalse);
    });
  });

  group('StatusEffectSystem', () {
    late StatusEffectSystem statusSystem;

    setUp(() {
      statusSystem = StatusEffectSystem();
    });

    test('applyEffect adds new effect', () {
      final applied = statusSystem.applyEffect(1, StatusEffectType.poison);

      expect(applied, isTrue);
      expect(statusSystem.hasEffect(1, StatusEffectType.poison), isTrue);
    });

    test('applyEffect renews existing effect', () {
      statusSystem.applyEffect(1, StatusEffectType.poison);

      // Apply again - should renew
      final renewed = statusSystem.applyEffect(1, StatusEffectType.poison);

      expect(renewed, isFalse); // Returns false for renewal
      expect(statusSystem.hasEffect(1, StatusEffectType.poison), isTrue);
    });

    test('removeEffect removes specific effect', () {
      statusSystem.applyEffect(1, StatusEffectType.poison);
      statusSystem.applyEffect(1, StatusEffectType.slow);

      statusSystem.removeEffect(1, StatusEffectType.poison);

      expect(statusSystem.hasEffect(1, StatusEffectType.poison), isFalse);
      expect(statusSystem.hasEffect(1, StatusEffectType.slow), isTrue);
    });

    test('getSpeedModifier multiplies all speed effects', () {
      statusSystem.applyEffect(1, StatusEffectType.slow); // 0.5x

      final modifier = statusSystem.getSpeedModifier(1);
      expect(modifier, equals(0.5));
    });

    test('canAct returns false for STUN and FREEZE', () {
      statusSystem.applyEffect(1, StatusEffectType.stun);
      expect(statusSystem.canAct(1), isFalse);

      statusSystem.removeAllEffects(1);
      statusSystem.applyEffect(1, StatusEffectType.freeze);
      expect(statusSystem.canAct(1), isFalse);
    });

    test('canAct returns true for other effects', () {
      statusSystem.applyEffect(1, StatusEffectType.poison);
      expect(statusSystem.canAct(1), isTrue);
    });

    test('update processes tick damage', () {
      var tickCount = 0;
      statusSystem.onEffectTick = (unitId, effectType, damage) {
        tickCount++;
        expect(damage, equals(5)); // poison tick damage
      };

      statusSystem.applyEffect(1, StatusEffectType.poison);

      // Poison ticks every 1.0s
      statusSystem.update(1.1);
      expect(tickCount, equals(1));
    });

    test('update expires effects after duration', () {
      statusSystem.applyEffect(1, StatusEffectType.stun); // duration: 3.0

      statusSystem.update(3.5);

      expect(statusSystem.hasEffect(1, StatusEffectType.stun), isFalse);
    });
  });

  group('EnvironmentSystem', () {
    late EnvironmentSystem envSystem;
    late StatusEffectSystem statusSystem;

    setUp(() {
      envSystem = EnvironmentSystem();
      statusSystem = StatusEffectSystem();
      envSystem.statusEffectSystem = statusSystem;
    });

    test('registerTerrainZone adds zone', () {
      final zone = TerrainZone(
        id: 'water1',
        terrainType: TerrainType.water,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );

      envSystem.registerTerrainZone(zone);
      expect(envSystem.terrainZoneCount, equals(1));
    });

    test('checkUnitTerrain detects zone', () {
      final zone = TerrainZone(
        id: 'water1',
        terrainType: TerrainType.water,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      envSystem.registerTerrainZone(zone);

      final terrain = envSystem.checkUnitTerrain(1, 50, 50);
      expect(terrain, equals(TerrainType.water));
    });

    test('checkUnitTerrain returns normal outside zones', () {
      final terrain = envSystem.checkUnitTerrain(1, 1000, 1000);
      expect(terrain, equals(TerrainType.normal));
    });

    test('checkUnitTerrain applies status effects', () {
      final zone = TerrainZone(
        id: 'poison1',
        terrainType: TerrainType.poison,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      envSystem.registerTerrainZone(zone);

      envSystem.checkUnitTerrain(1, 50, 50);

      expect(statusSystem.hasEffect(1, StatusEffectType.poison), isTrue);
    });

    test('getSpeedModifier returns terrain speed multiplier', () {
      final zone = TerrainZone(
        id: 'water1',
        terrainType: TerrainType.water,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      envSystem.registerTerrainZone(zone);

      envSystem.checkUnitTerrain(1, 50, 50);

      final modifier = envSystem.getSpeedModifier(1);
      expect(modifier, equals(0.7)); // water speedMult
    });

    test('getFatigueMultiplier returns terrain fatigue multiplier', () {
      final zone = TerrainZone(
        id: 'cold1',
        terrainType: TerrainType.cold,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      envSystem.registerTerrainZone(zone);

      envSystem.checkUnitTerrain(1, 50, 50);

      final modifier = envSystem.getFatigueMultiplier(1);
      expect(modifier, equals(1.5)); // cold fatigueMult
    });

    test('getDetectionModifier returns terrain detection multiplier', () {
      final zone = TerrainZone(
        id: 'dark1',
        terrainType: TerrainType.dark,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      envSystem.registerTerrainZone(zone);

      envSystem.checkUnitTerrain(1, 50, 50);

      final modifier = envSystem.getDetectionModifier(1);
      expect(modifier, equals(0.5)); // dark detectionMult
    });
  });
}
