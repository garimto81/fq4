/// 레벨/경험치 시스템 상수 (Godot experience_system.gd에서 이식)
class LevelConstants {
  LevelConstants._();

  static const int maxLevel = 50;
  static const int baseExpToLevel2 = 100;
  static const double expGrowthRate = 1.2;

  // 레벨업 스탯 성장량
  static const int hpPerLevel = 15;
  static const int mpPerLevel = 5;
  static const int atkPerLevel = 2;
  static const int defPerLevel = 1;
  static const int spdPerLevel = 1;
  static const int lckPerLevel = 1;

  // 적 처치 경험치
  static const int baseExpPerKill = 10;
  static const int expPerEnemyLevel = 5;

  // 적 타입 경험치 배율
  static const double normalExpMult = 1.0;
  static const double eliteExpMult = 2.0;
  static const double bossExpMult = 5.0;

  /// 레벨업에 필요한 경험치 계산
  static int expToNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return (baseExpToLevel2 *
            _pow(expGrowthRate, (currentLevel - 1).toDouble()))
        .round();
  }

  static double _pow(double base, double exp) {
    double result = 1.0;
    for (int i = 0; i < exp.toInt(); i++) {
      result *= base;
    }
    return result;
  }
}
