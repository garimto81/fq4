/// Gocha-Kyara AI 시스템 상수 (Godot ai_unit.gd에서 이식)
class AIConstants {
  AIConstants._();

  // AI 업데이트 간격
  static const double allyTickInterval = 0.15;
  static const double enemyTickInterval = 0.2;

  // 감지/거리 (논리 좌표 기준, 전장 폭 ~1200px 기준)
  static const double allyDetectionRange = 800.0;
  static const double enemyDetectionRange = 600.0;
  static const double followDistance = 80.0;
  static const double spreadDistance = 40.0;
  static const double attackEngageRange = 150.0;
  static const double defaultAttackRange = 60.0;
  static const double retreatDistance = 200.0;

  // 임계값
  static const double retreatHpThreshold = 0.3;
  static const double fatigueRetreatThreshold = 70.0;
  static const double fatigueForceRestThreshold = 90.0;
  static const double supportHealThreshold = 0.5;
}

/// AI 상태
enum AIState {
  idle,
  follow,
  patrol,
  chase,
  attack,
  retreat,
  defend,
  support,
  rest,
}

/// AI 성격
enum Personality {
  aggressive(chaseRangeMult: 1.5, retreatHpMult: 0.7, attackPriority: 1.0, followPriority: 0.5),
  defensive(chaseRangeMult: 0.7, retreatHpMult: 1.3, attackPriority: 0.5, followPriority: 1.0),
  balanced(chaseRangeMult: 1.0, retreatHpMult: 1.0, attackPriority: 0.8, followPriority: 0.8);

  const Personality({
    required this.chaseRangeMult,
    required this.retreatHpMult,
    required this.attackPriority,
    required this.followPriority,
  });

  final double chaseRangeMult;
  final double retreatHpMult;
  final double attackPriority;
  final double followPriority;
}

/// 대형
enum Formation {
  vShape,
  line,
  circle,
  wedge,
  scattered,
}

/// 부대 명령
enum SquadCommand {
  none,
  gather,
  scatter,
  attackAll,
  defendAll,
  retreatAll,
}
