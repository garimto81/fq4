import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/components/units/units.dart';

void main() {
  group('UnitComponent', () {
    test('초기화 시 maxHp와 currentHp가 동일', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.currentHp, equals(100));
      expect(unit.maxMp, equals(50));
      expect(unit.isAlive, isTrue);
      expect(unit.isDead, isFalse);
    });

    test('takeDamage 호출 시 currentHp 감소', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.takeDamage(30);
      expect(unit.currentHp, equals(70));
      expect(unit.hpRatio, equals(0.7));
      expect(unit.isAlive, isTrue);
    });

    test('HP가 0 이하로 떨어지면 사망 처리', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.takeDamage(150);
      expect(unit.currentHp, equals(0));
      expect(unit.isDead, isTrue);
      expect(unit.state, equals(UnitState.dead));
    });

    test('heal 호출 시 maxHp를 초과하지 않음', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.takeDamage(30);
      expect(unit.currentHp, equals(70));

      unit.heal(50);
      expect(unit.currentHp, equals(100)); // maxHp 이상 회복 안 됨
    });

    test('consumeMp 호출 시 MP 체크', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.consumeMp(30), isTrue);
      expect(unit.currentMp, equals(20));

      expect(unit.consumeMp(30), isFalse); // MP 부족
      expect(unit.currentMp, equals(20)); // 변화 없음
    });

    test('toUnitStats 변환', () {
      final unit = UnitComponent(
        unitName: 'TestUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      final stats = unit.toUnitStats();
      expect(stats.attack, equals(10));
      expect(stats.defense, equals(5));
      expect(stats.speed, equals(100));
      expect(stats.luck, equals(10));
      expect(stats.fatigue, equals(0));
    });
  });

  group('AIUnitComponent', () {
    test('초기화 시 isPlayerControlled는 false', () {
      final unit = AIUnitComponent(
        unitName: 'TestAI',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isPlayerControlled, isFalse);
      expect(unit.squadId, equals(0));
    });

    test('플레이어 제어 시 AI 비활성화', () {
      final unit = AIUnitComponent(
        unitName: 'TestAI',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.isPlayerControlled = true;
      expect(unit.isPlayerControlled, isTrue);
    });
  });

  group('PlayerUnitComponent', () {
    test('초기화 시 isPlayerSide는 true, isPlayerControlled는 true', () {
      final unit = PlayerUnitComponent(
        unitName: 'Player',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isPlayerSide, isTrue);
      expect(unit.isPlayerControlled, isTrue);
    });
  });

  group('EnemyUnitComponent', () {
    test('초기화 시 isPlayerSide는 false', () {
      final unit = EnemyUnitComponent(
        unitName: 'Enemy',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isPlayerSide, isFalse);
      expect(unit.expReward, equals(10));
      expect(unit.goldReward, equals(5));
    });
  });

  group('BossUnitComponent', () {
    test('초기 페이즈는 phase1', () {
      final boss = BossUnitComponent(
        unitName: 'Boss',
        maxHp: 1000,
        maxMp: 100,
        attack: 50,
        defense: 30,
        speed: 80,
        luck: 20,
      );

      expect(boss.phase, equals(BossPhase.phase1));
      expect(boss.isEnraged, isFalse);
    });

    test('HP 66% 이하에서 phase2 전환', () {
      final boss = BossUnitComponent(
        unitName: 'Boss',
        maxHp: 1000,
        maxMp: 100,
        attack: 50,
        defense: 30,
        speed: 80,
        luck: 20,
      );

      boss.takeDamage(350); // 65% HP
      boss.update(0.1); // 페이즈 체크 트리거

      expect(boss.phase, equals(BossPhase.phase2));
    });

    test('HP 33% 이하에서 phase3 전환', () {
      final boss = BossUnitComponent(
        unitName: 'Boss',
        maxHp: 1000,
        maxMp: 100,
        attack: 50,
        defense: 30,
        speed: 80,
        luck: 20,
      );

      boss.takeDamage(700); // 30% HP
      boss.update(0.1); // 페이즈 체크 트리거

      expect(boss.phase, equals(BossPhase.phase3));
    });

    test('HP 20% 이하에서 광폭화', () {
      final boss = BossUnitComponent(
        unitName: 'Boss',
        maxHp: 1000,
        maxMp: 100,
        attack: 50,
        defense: 30,
        speed: 80,
        luck: 20,
      );

      final initialAttack = boss.attack;
      final initialSpeed = boss.speed;

      boss.takeDamage(850); // 15% HP
      boss.update(0.1); // 광폭화 트리거

      expect(boss.isEnraged, isTrue);
      expect(boss.attack, greaterThan(initialAttack));
      expect(boss.speed, greaterThan(initialSpeed));
    });
  });
}
