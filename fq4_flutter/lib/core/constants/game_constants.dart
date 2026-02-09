/// 게임 전역 상수
class GameConstants {
  GameConstants._();

  // 논리 해상도 (원본 320x200의 4배)
  static const double logicalWidth = 1280;
  static const double logicalHeight = 800;

  // 인벤토리
  static const int maxInventorySlots = 50;

  // 장비 슬롯
  static const int equipSlotWeapon = 0;
  static const int equipSlotArmor = 1;
  static const int equipSlotAccessory = 2;

  // 충돌 레이어
  static const int collisionWorld = 1;
  static const int collisionPlayer = 2;
  static const int collisionEnemy = 4;
  static const int collisionTrigger = 8;
  static const int collisionProjectile = 16;

  // NG+ 스케일링
  static const double ngPlusEnemyStatScale = 1.5;
  static const double ngPlusEnemySpdScale = 1.2;
  static const double ngPlusExpScale = 0.8;
  static const double ngPlusGoldScale = 1.2;
}
