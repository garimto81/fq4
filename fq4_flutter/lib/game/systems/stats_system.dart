// 스탯 시스템 (Godot stats_system.gd에서 이식)

enum StatType {
  hp,
  mp,
  atk,
  def,
  spd,
  lck,
  attackRange,
  criticalChance,
  evasion,
}

class StatsSystem {
  final Map<StatType, num> baseStats = {};
  final Map<StatType, num> equipmentBonus = {};
  final Map<StatType, ({num value, double remaining})> activeBuff = {};

  StatsSystem();

  /// 기본 스탯 초기화
  void initialize({
    required int hp,
    required int mp,
    required int atk,
    required int def,
    required int spd,
    required int lck,
  }) {
    baseStats[StatType.hp] = hp;
    baseStats[StatType.mp] = mp;
    baseStats[StatType.atk] = atk;
    baseStats[StatType.def] = def;
    baseStats[StatType.spd] = spd;
    baseStats[StatType.lck] = lck;
    baseStats[StatType.attackRange] = 0;
    baseStats[StatType.criticalChance] = 0;
    baseStats[StatType.evasion] = 0;
  }

  /// 최종 스탯 계산 (base + equipment + buff)
  num getStat(StatType type) {
    final base = baseStats[type] ?? 0;
    final equipment = equipmentBonus[type] ?? 0;
    final buff = activeBuff[type]?.value ?? 0;
    return base + equipment + buff;
  }

  /// 기본 스탯 조회
  num getBaseStat(StatType type) {
    return baseStats[type] ?? 0;
  }

  /// 기본 스탯 설정
  void setBaseStat(StatType type, num value) {
    baseStats[type] = value;
  }

  /// 기본 스탯 증가 (레벨업 시 사용)
  void addBaseStat(StatType type, num amount) {
    baseStats[type] = (baseStats[type] ?? 0) + amount;
  }

  /// 장비 보너스 설정
  void setEquipmentBonus(StatType type, num value) {
    equipmentBonus[type] = value;
  }

  /// 장비 보너스 초기화
  void clearEquipmentBonus() {
    equipmentBonus.clear();
  }

  /// 버프 적용
  void applyBuff(StatType type, num value, double duration) {
    activeBuff[type] = (value: value, remaining: duration);
  }

  /// 버프 업데이트 (시간 경과)
  void update(double dt) {
    final expiredBuffs = <StatType>[];

    for (final entry in activeBuff.entries) {
      final newRemaining = entry.value.remaining - dt;
      if (newRemaining <= 0) {
        expiredBuffs.add(entry.key);
      } else {
        activeBuff[entry.key] = (value: entry.value.value, remaining: newRemaining);
      }
    }

    for (final type in expiredBuffs) {
      activeBuff.remove(type);
    }
  }

  /// 편의 메서드: 총 공격력
  num getTotalAttack() => getStat(StatType.atk);

  /// 편의 메서드: 총 방어력
  num getTotalDefense() => getStat(StatType.def);

  /// 편의 메서드: 총 속도
  num getTotalSpeed() => getStat(StatType.spd);
}
