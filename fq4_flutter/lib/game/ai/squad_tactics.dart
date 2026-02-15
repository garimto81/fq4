import 'dart:math';
import '../../core/constants/ai_constants.dart';

/// 진형별 슬롯 오프셋 (리더 기준 상대 위치)
class FormationSlot {
  final double offsetX;
  final double offsetY;

  const FormationSlot(this.offsetX, this.offsetY);
}

/// 부대 전술 관리자
class SquadTactics {
  /// 진형 이탈 허용 거리
  static const double formationBreakDistance = 30.0;

  /// 진형별 슬롯 오프셋 계산 (최대 10 유닛)
  static List<FormationSlot> getFormationSlots(
      Formation formation, int unitCount) {
    return switch (formation) {
      Formation.vShape => _vShapeSlots(unitCount),
      Formation.line => _lineSlots(unitCount),
      Formation.circle => _circleSlots(unitCount),
      Formation.wedge => _wedgeSlots(unitCount),
      Formation.scattered => _scatteredSlots(unitCount),
    };
  }

  static List<FormationSlot> _vShapeSlots(int count) {
    final slots = <FormationSlot>[const FormationSlot(0, 0)]; // leader
    for (int i = 1; i < count; i++) {
      final row = (i + 1) ~/ 2;
      final side = i.isOdd ? -1.0 : 1.0;
      slots.add(FormationSlot(side * row * 40, -row * 30.0));
    }
    return slots;
  }

  static List<FormationSlot> _lineSlots(int count) {
    final slots = <FormationSlot>[];
    final halfWidth = (count - 1) / 2.0;
    for (int i = 0; i < count; i++) {
      slots.add(FormationSlot((i - halfWidth) * 45, 0));
    }
    return slots;
  }

  static List<FormationSlot> _circleSlots(int count) {
    if (count <= 1) return [const FormationSlot(0, 0)];
    final slots = <FormationSlot>[const FormationSlot(0, 0)]; // center
    final radius = 50.0;
    for (int i = 1; i < count; i++) {
      final angle = (i - 1) * 2 * pi / (count - 1);
      slots.add(FormationSlot(
        cos(angle) * radius,
        sin(angle) * radius,
      ));
    }
    return slots;
  }

  static List<FormationSlot> _wedgeSlots(int count) {
    final slots = <FormationSlot>[const FormationSlot(0, 20)]; // 선두
    for (int i = 1; i < count; i++) {
      final row = i;
      final side = i.isOdd ? -1.0 : 1.0;
      slots.add(FormationSlot(side * row * 35, -row * 25.0));
    }
    return slots;
  }

  static List<FormationSlot> _scatteredSlots(int count) {
    final rng = Random(42); // 고정 시드로 일관성
    final slots = <FormationSlot>[];
    for (int i = 0; i < count; i++) {
      slots.add(FormationSlot(
        (rng.nextDouble() - 0.5) * 200,
        (rng.nextDouble() - 0.5) * 200,
      ));
    }
    return slots;
  }

  /// 전투 상황별 진형 자동 전환 추천
  static Formation recommendFormation({
    required Formation current,
    required bool isSurrounded,
    required bool isEnemyRetreating,
    required bool hasAlliesNearby,
    required bool underAreaAttack,
    required double squadSurvivalRate,
  }) {
    // 부대 생존율 50% 이하 -> CIRCLE (전방위 방어)
    if (squadSurvivalRate < 0.5) return Formation.circle;

    // 포위당함 -> CIRCLE
    if (isSurrounded) return Formation.circle;

    // 범위 공격 감지 -> SCATTERED
    if (underAreaAttack) return Formation.scattered;

    // 적 퇴각 -> V_SHAPE (추격)
    if (isEnemyRetreating) return Formation.vShape;

    // 아군 합류 -> LINE (전력 집중)
    if (hasAlliesNearby && current == Formation.scattered) return Formation.line;

    return current;
  }

  /// 핀서 공격 가능 여부 판정
  static bool canPincer({
    required double squad1X,
    required double squad1Y,
    required double squad2X,
    required double squad2Y,
    required double enemyX,
    required double enemyY,
  }) {
    // 두 부대가 적의 양면에 있는지 확인
    final angle1 = atan2(squad1Y - enemyY, squad1X - enemyX);
    final angle2 = atan2(squad2Y - enemyY, squad2X - enemyX);
    final angleDiff = (angle1 - angle2).abs();
    // 90도 이상 차이나면 핀서 가능
    return angleDiff > pi / 2 && angleDiff < 3 * pi / 2;
  }

  /// 앵커 & 플랭크 위치 계산
  static ({double x, double y}) calculateFlankPosition({
    required double anchorX,
    required double anchorY,
    required double enemyX,
    required double enemyY,
    bool goLeft = true,
  }) {
    final angle = atan2(enemyY - anchorY, enemyX - anchorX);
    final flankAngle = goLeft ? angle + pi / 2 : angle - pi / 2;
    final flankDist = 100.0;
    return (
      x: enemyX + cos(flankAngle) * flankDist,
      y: enemyY + sin(flankAngle) * flankDist,
    );
  }

  /// 집중 사격 타겟 선정 (위협 최고점)
  static int selectFocusFireTarget(List<double> threatScores) {
    if (threatScores.isEmpty) return -1;
    int bestIdx = 0;
    double bestScore = threatScores[0];
    for (int i = 1; i < threatScores.length; i++) {
      if (threatScores[i] > bestScore) {
        bestScore = threatScores[i];
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}
