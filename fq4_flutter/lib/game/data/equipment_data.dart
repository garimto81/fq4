// Phase 2: 장비 데이터 모델

enum EquipmentSlot {
  weapon,
  armor,
  accessory,
}

class EquipmentData {
  final String id;
  final String name;
  final String description;
  final EquipmentSlot slot;
  final int requiredLevel;
  final int sellPrice;

  // 능력치 보너스
  final int bonusHp;
  final int bonusMp;
  final int bonusAtk;
  final int bonusDef;
  final int bonusSpd;
  final int bonusLck;

  final double bonusAttackRange;
  final double bonusCriticalChance;
  final double bonusEvasion;

  const EquipmentData({
    required this.id,
    required this.name,
    required this.description,
    required this.slot,
    this.requiredLevel = 1,
    required this.sellPrice,
    this.bonusHp = 0,
    this.bonusMp = 0,
    this.bonusAtk = 0,
    this.bonusDef = 0,
    this.bonusSpd = 0,
    this.bonusLck = 0,
    this.bonusAttackRange = 0.0,
    this.bonusCriticalChance = 0.0,
    this.bonusEvasion = 0.0,
  });

  bool canEquip(int level) {
    return level >= requiredLevel;
  }

  Map<String, num> getStatBonuses() {
    return {
      'hp': bonusHp,
      'mp': bonusMp,
      'atk': bonusAtk,
      'def': bonusDef,
      'spd': bonusSpd,
      'lck': bonusLck,
      'attackRange': bonusAttackRange,
      'criticalChance': bonusCriticalChance,
      'evasion': bonusEvasion,
    };
  }

  // 무기 팩토리
  static EquipmentData swordIron() {
    return const EquipmentData(
      id: 'sword_iron',
      name: '철검',
      description: '기본적인 철제 검',
      slot: EquipmentSlot.weapon,
      bonusAtk: 8,
      sellPrice: 50,
    );
  }

  static EquipmentData swordSteel() {
    return const EquipmentData(
      id: 'sword_steel',
      name: '강철검',
      description: '단단한 강철 검',
      slot: EquipmentSlot.weapon,
      requiredLevel: 3,
      bonusAtk: 14,
      sellPrice: 120,
    );
  }

  static EquipmentData staffOak() {
    return const EquipmentData(
      id: 'staff_oak',
      name: '참나무 지팡이',
      description: '마법사용에 적합한 지팡이',
      slot: EquipmentSlot.weapon,
      bonusAtk: 4,
      bonusMp: 20,
      sellPrice: 60,
    );
  }

  static EquipmentData bowShort() {
    return const EquipmentData(
      id: 'bow_short',
      name: '단궁',
      description: '사거리가 긴 활',
      slot: EquipmentSlot.weapon,
      bonusAtk: 6,
      bonusAttackRange: 50.0,
      sellPrice: 70,
    );
  }

  // 방어구 팩토리
  static EquipmentData armorLeather() {
    return const EquipmentData(
      id: 'armor_leather',
      name: '가죽 갑옷',
      description: '기본적인 가죽 방어구',
      slot: EquipmentSlot.armor,
      bonusDef: 5,
      sellPrice: 40,
    );
  }

  static EquipmentData armorChain() {
    return const EquipmentData(
      id: 'armor_chain',
      name: '체인 메일',
      description: '방어력이 높지만 무거운 갑옷',
      slot: EquipmentSlot.armor,
      requiredLevel: 3,
      bonusDef: 10,
      bonusSpd: -5,
      sellPrice: 100,
    );
  }

  static EquipmentData helmetIron() {
    return const EquipmentData(
      id: 'helmet_iron',
      name: '철 투구',
      description: '머리를 보호하는 투구',
      slot: EquipmentSlot.armor,
      bonusDef: 3,
      sellPrice: 35,
    );
  }

  // 액세서리 팩토리
  static EquipmentData ringAgility() {
    return const EquipmentData(
      id: 'ring_agility',
      name: '민첩의 반지',
      description: '속도와 회피력 증가',
      slot: EquipmentSlot.accessory,
      bonusSpd: 8,
      bonusEvasion: 5.0,
      sellPrice: 80,
    );
  }
}
