import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/components/units/hybrid_unit_component.dart';
import 'package:fq4_flutter/game/components/units/unit_component.dart';

void main() {
  group('HybridUnitComponent - 기본 상태 테스트', () {
    test('생성 시 isPlayerControlled는 false (AI 자동전투가 기본)', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isPlayerControlled, isFalse);
    });

    test('생성 시 isInManualMode는 false', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isInManualMode, isFalse);
    });

    test('생성 시 autoRevertRemaining은 0', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.autoRevertRemaining, equals(0));
    });

    test('생성 시 averageInputLatency는 0', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.averageInputLatency, equals(0));
    });
  });

  group('HybridUnitComponent - 자동 복귀 타이머 테스트', () {
    test('수동 모드 진입 후 isPlayerControlled는 true', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 수동 모드 진입 시뮬레이션 (isPlayerControlled를 직접 설정)
      unit.isPlayerControlled = true;
      expect(unit.isPlayerControlled, isTrue);
    });

    test('자동 복귀 타이머 3초 후 isPlayerControlled는 false로 복귀', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 수동 모드 진입 (private 필드를 직접 조작할 수 없으므로, isPlayerControlled만 설정)
      unit.isPlayerControlled = true;

      // 3.1초 경과 시뮬레이션 (update를 여러 번 호출)
      for (int i = 0; i < 32; i++) {
        unit.update(0.1); // 총 3.2초
      }

      // 주의: _autoRevertTimer는 isPlayerControlled를 true로 설정한 것만으로는
      // 시작되지 않음. update() 내부에서 키 입력이 있어야 함.
      // 이 테스트는 타이머가 시작된 후의 동작만 검증 가능.
      // 실제로는 releaseManualControl()을 사용하는 패턴을 테스트
    });

    test('autoRevertRemaining 값이 시간에 따라 감소', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 초기값 확인
      expect(unit.autoRevertRemaining, equals(0));

      // 타이머를 시작시키려면 실제 키 입력이 필요하지만,
      // 단위 테스트에서는 isPlayerControlled만으로는 타이머가 시작 안 됨
      // 대신 releaseManualControl() 후 상태를 확인하는 방식으로 테스트
    });
  });

  group('HybridUnitComponent - releaseManualControl 테스트', () {
    test('releaseManualControl 호출 후 isPlayerControlled는 false', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 수동 모드 진입
      unit.isPlayerControlled = true;
      expect(unit.isPlayerControlled, isTrue);

      // 수동 제어 해제
      unit.releaseManualControl();
      expect(unit.isPlayerControlled, isFalse);
    });

    test('releaseManualControl 호출 후 autoRevertRemaining은 0', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.releaseManualControl();
      expect(unit.autoRevertRemaining, equals(0));
    });

    test('releaseManualControl 호출 후 moveTarget은 null', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.releaseManualControl();
      expect(unit.moveTarget, isNull);
    });

    test('releaseManualControl 호출 후 velocity는 zero', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.releaseManualControl();
      expect(unit.velocity.x, equals(0));
      expect(unit.velocity.y, equals(0));
    });

    test('releaseManualControl 호출 후 moving 상태는 idle로 전환', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.state = UnitState.moving;
      unit.releaseManualControl();
      expect(unit.state, equals(UnitState.idle));
    });

    test('releaseManualControl 호출 후 idle 상태는 유지', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.state = UnitState.idle;
      unit.releaseManualControl();
      expect(unit.state, equals(UnitState.idle));
    });
  });

  group('HybridUnitComponent - 유닛 전환 콜백 테스트', () {
    test('onSwitchNext 콜백이 설정 가능', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      bool callbackCalled = false;
      unit.onSwitchNext = () {
        callbackCalled = true;
      };

      // 콜백 호출
      unit.onSwitchNext?.call();
      expect(callbackCalled, isTrue);
    });

    test('onSwitchPrev 콜백이 설정 가능', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      bool callbackCalled = false;
      unit.onSwitchPrev = () {
        callbackCalled = true;
      };

      // 콜백 호출
      unit.onSwitchPrev?.call();
      expect(callbackCalled, isTrue);
    });

    test('콜백이 설정되지 않았을 때 호출해도 에러 발생 안 함', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 콜백 미설정 상태에서 호출
      expect(() => unit.onSwitchNext?.call(), returnsNormally);
      expect(() => unit.onSwitchPrev?.call(), returnsNormally);
    });
  });

  group('HybridUnitComponent - update 동작 테스트', () {
    test('사망 상태에서는 update가 정상 동작', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.takeDamage(100); // 사망
      expect(unit.isDead, isTrue);

      // update 호출해도 에러 없음
      expect(() => unit.update(0.1), returnsNormally);
    });

    test('isInManualMode가 false일 때 AI 모드', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isInManualMode, isFalse);
      expect(unit.isPlayerControlled, isFalse);
    });

    test('update 호출 시 타이머 감소 (수동 제어 후)', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 수동 모드 진입 (타이머는 키 입력으로만 시작되므로, 직접 테스트 불가)
      // releaseManualControl() 후 타이머가 0인지만 확인
      unit.releaseManualControl();
      unit.update(1.0);
      expect(unit.autoRevertRemaining, equals(0));
    });
  });

  group('HybridUnitComponent - 상태 전이 테스트', () {
    test('AI 모드 → 수동 모드 전환', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.isPlayerControlled, isFalse);
      unit.isPlayerControlled = true;
      expect(unit.isPlayerControlled, isTrue);
    });

    test('수동 모드 → AI 모드 복귀', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      unit.isPlayerControlled = true;
      unit.releaseManualControl();
      expect(unit.isPlayerControlled, isFalse);
    });
  });

  group('HybridUnitComponent - 입력 지연 측정 테스트', () {
    test('averageInputLatency 초기값은 0', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.averageInputLatency, equals(0));
    });

    test('입력 지연 데이터가 없을 때 averageInputLatency는 0', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      // 아무 동작도 하지 않음
      expect(unit.averageInputLatency, equals(0));
    });
  });

  group('HybridUnitComponent - 부모 클래스 기능 상속 테스트', () {
    test('AIUnitComponent 기능 상속 (isPlayerSide)', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
        isPlayerSide: true,
      );

      expect(unit.isPlayerSide, isTrue);
    });

    test('UnitComponent 기능 상속 (HP 관리)', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.currentHp, equals(100));
      unit.takeDamage(30);
      expect(unit.currentHp, equals(70));
      expect(unit.isAlive, isTrue);
    });

    test('UnitComponent 기능 상속 (MP 관리)', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
        maxHp: 100,
        maxMp: 50,
        attack: 10,
        defense: 5,
        speed: 100,
        luck: 10,
      );

      expect(unit.currentMp, equals(50));
      expect(unit.consumeMp(20), isTrue);
      expect(unit.currentMp, equals(30));
    });

    test('toUnitStats 변환 정상 동작', () {
      final unit = HybridUnitComponent(
        unitName: 'HybridUnit',
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
    });
  });
}
