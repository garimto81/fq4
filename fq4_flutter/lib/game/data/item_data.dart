// Phase 2: 아이템 데이터 모델

enum ItemType {
  consumable,
  material,
  keyItem,
}

class ItemData {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final int maxStack;
  final int sellPrice;

  const ItemData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.maxStack = 99,
    required this.sellPrice,
  });

  bool canUse() {
    return type == ItemType.consumable;
  }

  // 기본 소모품 팩토리
  static ItemData potionHpSmall() {
    return HealItemData(
      id: 'potion_hp_small',
      name: 'HP포션(소)',
      description: 'HP를 50 회복합니다',
      healHp: 50,
      sellPrice: 20,
    );
  }

  static ItemData potionHpMedium() {
    return HealItemData(
      id: 'potion_hp_medium',
      name: 'HP포션(중)',
      description: 'HP를 120 회복합니다',
      healHp: 120,
      sellPrice: 50,
    );
  }

  static ItemData potionMpSmall() {
    return HealItemData(
      id: 'potion_mp_small',
      name: 'MP포션(소)',
      description: 'MP를 30 회복합니다',
      healMp: 30,
      sellPrice: 25,
    );
  }

  static ItemData antidote() {
    return const ItemData(
      id: 'antidote',
      name: '해독제',
      description: '독 상태이상을 해제합니다',
      type: ItemType.consumable,
      sellPrice: 15,
    );
  }

  static ItemData revivalPotion() {
    return HealItemData(
      id: 'revival_potion',
      name: '부활의 물약',
      description: '전투불능 상태를 해제하고 HP 30% 회복',
      healHp: 0, // 부활 시 최대HP의 30% 회복 (실제 회복량은 사용 시 계산)
      sellPrice: 100,
    );
  }

  static ItemData strengthPotion() {
    return const ItemData(
      id: 'strength_potion',
      name: '힘의 물약',
      description: '일시적으로 ATK +10',
      type: ItemType.consumable,
      sellPrice: 40,
    );
  }

  static ItemData bomb() {
    return const ItemData(
      id: 'bomb',
      name: '폭탄',
      description: '적에게 80 데미지',
      type: ItemType.consumable,
      sellPrice: 30,
    );
  }
}

class HealItemData extends ItemData {
  final int healHp;
  final int healMp;

  const HealItemData({
    required super.id,
    required super.name,
    required super.description,
    this.healHp = 0,
    this.healMp = 0,
    super.maxStack,
    required super.sellPrice,
  }) : super(type: ItemType.consumable);
}
