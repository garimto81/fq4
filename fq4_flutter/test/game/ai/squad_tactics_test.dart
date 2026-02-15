import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/ai/squad_tactics.dart';
import 'package:fq4_flutter/core/constants/ai_constants.dart';

void main() {
  group('SquadTactics.getFormationSlots', () {
    test('vShape with 1 unit returns only leader at (0,0)', () {
      final slots = SquadTactics.getFormationSlots(Formation.vShape, 1);

      expect(slots.length, 1);
      expect(slots[0].offsetX, 0);
      expect(slots[0].offsetY, 0);
    });

    test('vShape with 5 units returns leader + 4 spread units', () {
      final slots = SquadTactics.getFormationSlots(Formation.vShape, 5);

      expect(slots.length, 5);
      // Leader at origin
      expect(slots[0].offsetX, 0);
      expect(slots[0].offsetY, 0);
      // Subsequent units spread out in V pattern
      // i=1: row=1, side=-1 -> (-40, -30)
      expect(slots[1].offsetX, closeTo(-40, 0.01));
      expect(slots[1].offsetY, closeTo(-30, 0.01));
      // i=2: row=1, side=+1 -> (40, -30) -- wait, row = (2+1)~/2 = 1
      expect(slots[2].offsetX, closeTo(40, 0.01));
      expect(slots[2].offsetY, closeTo(-30, 0.01));
      // i=3: row=2, side=-1 -> (-80, -60)
      expect(slots[3].offsetX, closeTo(-80, 0.01));
      expect(slots[3].offsetY, closeTo(-60, 0.01));
      // i=4: row=2, side=+1 -> (80, -60) -- row = (4+1)~/2 = 2
      expect(slots[4].offsetX, closeTo(80, 0.01));
      expect(slots[4].offsetY, closeTo(-60, 0.01));
    });

    test('line formation spreads units horizontally', () {
      final slots = SquadTactics.getFormationSlots(Formation.line, 3);

      expect(slots.length, 3);
      // halfWidth = (3-1)/2 = 1.0
      // i=0: (0-1)*45 = -45, y=0
      // i=1: (1-1)*45 = 0, y=0
      // i=2: (2-1)*45 = 45, y=0
      expect(slots[0].offsetX, closeTo(-45, 0.01));
      expect(slots[0].offsetY, 0);
      expect(slots[1].offsetX, closeTo(0, 0.01));
      expect(slots[1].offsetY, 0);
      expect(slots[2].offsetX, closeTo(45, 0.01));
      expect(slots[2].offsetY, 0);
    });

    test('circle with 1 unit returns only center at (0,0)', () {
      final slots = SquadTactics.getFormationSlots(Formation.circle, 1);

      expect(slots.length, 1);
      expect(slots[0].offsetX, 0);
      expect(slots[0].offsetY, 0);
    });

    test('circle with 5 units returns center + 4 in circular pattern', () {
      final slots = SquadTactics.getFormationSlots(Formation.circle, 5);

      expect(slots.length, 5);
      // Center
      expect(slots[0].offsetX, 0);
      expect(slots[0].offsetY, 0);

      // Remaining 4 at radius 50, evenly spaced (each 90 degrees apart)
      const radius = 50.0;
      for (int i = 1; i < 5; i++) {
        final angle = (i - 1) * 2 * pi / 4;
        expect(slots[i].offsetX, closeTo(cos(angle) * radius, 0.01));
        expect(slots[i].offsetY, closeTo(sin(angle) * radius, 0.01));
      }
    });

    test('wedge formation has leader at front (0, 20)', () {
      final slots = SquadTactics.getFormationSlots(Formation.wedge, 3);

      expect(slots.length, 3);
      // Leader at front
      expect(slots[0].offsetX, 0);
      expect(slots[0].offsetY, 20);
      // i=1: row=1, side=-1 -> (-35, -25)
      expect(slots[1].offsetX, closeTo(-35, 0.01));
      expect(slots[1].offsetY, closeTo(-25, 0.01));
      // i=2: row=2, side=+1 -> (70, -50)
      expect(slots[2].offsetX, closeTo(70, 0.01));
      expect(slots[2].offsetY, closeTo(-50, 0.01));
    });

    test('scattered is random but deterministic with seed 42', () {
      final slots1 = SquadTactics.getFormationSlots(Formation.scattered, 3);
      final slots2 = SquadTactics.getFormationSlots(Formation.scattered, 3);

      expect(slots1.length, 3);
      // Same seed produces same results
      for (int i = 0; i < 3; i++) {
        expect(slots1[i].offsetX, slots2[i].offsetX);
        expect(slots1[i].offsetY, slots2[i].offsetY);
      }

      // Values within expected range (-100 to 100)
      for (final slot in slots1) {
        expect(slot.offsetX, greaterThanOrEqualTo(-100));
        expect(slot.offsetX, lessThanOrEqualTo(100));
        expect(slot.offsetY, greaterThanOrEqualTo(-100));
        expect(slot.offsetY, lessThanOrEqualTo(100));
      }
    });
  });

  group('SquadTactics.recommendFormation', () {
    test('squadSurvivalRate < 0.5 returns circle', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.line,
        isSurrounded: false,
        isEnemyRetreating: false,
        hasAlliesNearby: false,
        underAreaAttack: false,
        squadSurvivalRate: 0.3,
      );

      expect(result, Formation.circle);
    });

    test('isSurrounded returns circle', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.vShape,
        isSurrounded: true,
        isEnemyRetreating: false,
        hasAlliesNearby: false,
        underAreaAttack: false,
        squadSurvivalRate: 0.8,
      );

      expect(result, Formation.circle);
    });

    test('underAreaAttack returns scattered', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.line,
        isSurrounded: false,
        isEnemyRetreating: false,
        hasAlliesNearby: false,
        underAreaAttack: true,
        squadSurvivalRate: 0.8,
      );

      expect(result, Formation.scattered);
    });

    test('isEnemyRetreating returns vShape', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.circle,
        isSurrounded: false,
        isEnemyRetreating: true,
        hasAlliesNearby: false,
        underAreaAttack: false,
        squadSurvivalRate: 0.8,
      );

      expect(result, Formation.vShape);
    });

    test('hasAlliesNearby + current scattered returns line', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.scattered,
        isSurrounded: false,
        isEnemyRetreating: false,
        hasAlliesNearby: true,
        underAreaAttack: false,
        squadSurvivalRate: 0.8,
      );

      expect(result, Formation.line);
    });

    test('default returns current formation', () {
      final result = SquadTactics.recommendFormation(
        current: Formation.wedge,
        isSurrounded: false,
        isEnemyRetreating: false,
        hasAlliesNearby: false,
        underAreaAttack: false,
        squadSurvivalRate: 0.8,
      );

      expect(result, Formation.wedge);
    });
  });

  group('SquadTactics.canPincer', () {
    test('two squads on opposite sides of enemy returns true', () {
      // Squad1 to the left, squad2 to the right of enemy at origin
      final result = SquadTactics.canPincer(
        squad1X: -100,
        squad1Y: 0,
        squad2X: 100,
        squad2Y: 0,
        enemyX: 0,
        enemyY: 0,
      );

      expect(result, true);
    });

    test('two squads on same side returns false', () {
      // Both squads to the right of enemy
      final result = SquadTactics.canPincer(
        squad1X: 100,
        squad1Y: 10,
        squad2X: 120,
        squad2Y: -10,
        enemyX: 0,
        enemyY: 0,
      );

      expect(result, false);
    });
  });

  group('SquadTactics.calculateFlankPosition', () {
    test('goLeft true positions to the left of the enemy', () {
      final pos = SquadTactics.calculateFlankPosition(
        anchorX: 0,
        anchorY: 0,
        enemyX: 100,
        enemyY: 0,
        goLeft: true,
      );

      // Anchor to enemy angle = 0 (right)
      // Left flank: angle + pi/2 = pi/2 (up in math coords)
      // Position: enemy + (cos(pi/2)*100, sin(pi/2)*100) = (100, 100)
      expect(pos.x, closeTo(100, 1.0));
      expect(pos.y, closeTo(100, 1.0));
    });

    test('goLeft false positions to the right of the enemy', () {
      final pos = SquadTactics.calculateFlankPosition(
        anchorX: 0,
        anchorY: 0,
        enemyX: 100,
        enemyY: 0,
        goLeft: false,
      );

      // Right flank: angle - pi/2 = -pi/2
      // Position: enemy + (cos(-pi/2)*100, sin(-pi/2)*100) = (100, -100)
      expect(pos.x, closeTo(100, 1.0));
      expect(pos.y, closeTo(-100, 1.0));
    });
  });

  group('SquadTactics.selectFocusFireTarget', () {
    test('empty list returns -1', () {
      final result = SquadTactics.selectFocusFireTarget([]);

      expect(result, -1);
    });

    test('single element returns 0', () {
      final result = SquadTactics.selectFocusFireTarget([42.0]);

      expect(result, 0);
    });

    test('multiple scores returns index of highest', () {
      final result = SquadTactics.selectFocusFireTarget([10.0, 50.0, 30.0, 20.0]);

      expect(result, 1);
    });
  });
}
