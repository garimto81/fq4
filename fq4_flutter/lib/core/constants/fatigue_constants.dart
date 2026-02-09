/// 피로도 시스템 상수 (Godot fatigue_system.gd에서 이식)
class FatigueConstants {
  FatigueConstants._();

  // 피로도 증가량
  static const double fatigueAttack = 10;
  static const double fatigueSkill = 20;
  static const double fatigueMovePerUnit = 0.1; // 10px당 1

  // 피로도 회복량 (/초)
  static const double recoveryIdle = 1;
  static const double recoveryRest = 5;
  static const double recoveryItem = 30;

  // 피로도 단계 임계값
  static const double normalMax = 30;
  static const double tiredMax = 60;
  static const double exhaustedMax = 90;
  static const double collapsedMin = 91;
}

/// 피로도 단계
enum FatigueLevel {
  normal(speedMult: 1.0, attackMult: 1.0, canAct: true),
  tired(speedMult: 0.8, attackMult: 0.9, canAct: true),
  exhausted(speedMult: 0.5, attackMult: 0.7, canAct: true),
  collapsed(speedMult: 0.0, attackMult: 0.0, canAct: false);

  const FatigueLevel({
    required this.speedMult,
    required this.attackMult,
    required this.canAct,
  });

  final double speedMult;
  final double attackMult;
  final bool canAct;

  static FatigueLevel fromValue(double fatigue) {
    if (fatigue >= FatigueConstants.collapsedMin) return collapsed;
    if (fatigue > FatigueConstants.exhaustedMax) return collapsed;
    if (fatigue > FatigueConstants.tiredMax) return exhausted;
    if (fatigue > FatigueConstants.normalMax) return tired;
    return normal;
  }
}
