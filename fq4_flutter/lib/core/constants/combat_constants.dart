/// 전투 시스템 상수 (Godot combat_system.gd에서 이식)
class CombatConstants {
  CombatConstants._();

  /// 데미지 편차 +-10%
  static const double baseDamageVariance = 0.1;

  /// 기본 크리티컬 확률 5%
  static const double criticalHitChance = 0.05;

  /// 크리티컬 데미지 배율 2배
  static const double criticalHitMultiplier = 2.0;

  /// 기본 명중률 95%
  static const double baseHitChance = 0.95;

  /// 기본 회피율 5%
  static const double baseEvasion = 0.05;

  /// 최소 데미지 1
  static const int minDamage = 1;

  /// 적 처치 골드 계산: 5 + (enemy_max_hp / 20)
  static const int baseGoldReward = 5;
  static const int goldPerHpDivisor = 20;
}
