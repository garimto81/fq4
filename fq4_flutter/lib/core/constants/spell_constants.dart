/// 마법 시스템 상수 (Godot spell_database.gd에서 이식)
class SpellConstants {
  SpellConstants._();

  static const double castFatigueCost = 20;
}

/// 마법 유형
enum SpellType { damage, heal, buff, debuff }

/// 마법 속성
enum SpellElement { fire, ice, lightning, holy, none }

/// 마법 타겟 유형
enum SpellTarget { self, singleAlly, singleEnemy, area, allAllies, allEnemies }

/// 마법 데이터 정의
class SpellData {
  const SpellData({
    required this.id,
    required this.name,
    required this.type,
    required this.element,
    required this.mpCost,
    required this.basePower,
    required this.range,
    required this.aoeRadius,
    required this.cooldown,
    required this.castTime,
    required this.target,
  });

  final String id;
  final String name;
  final SpellType type;
  final SpellElement element;
  final int mpCost;
  final int basePower;
  final double range;
  final double aoeRadius;
  final double cooldown;
  final double castTime;
  final SpellTarget target;

  static const List<SpellData> allSpells = [
    SpellData(id: 'fire_ball', name: 'Fire Ball', type: SpellType.damage, element: SpellElement.fire, mpCost: 15, basePower: 30, range: 250, aoeRadius: 60, cooldown: 4.0, castTime: 0.8, target: SpellTarget.area),
    SpellData(id: 'ice_bolt', name: 'Ice Bolt', type: SpellType.damage, element: SpellElement.ice, mpCost: 10, basePower: 25, range: 200, aoeRadius: 50, cooldown: 2.0, castTime: 0.5, target: SpellTarget.singleEnemy),
    SpellData(id: 'thunder', name: 'Thunder', type: SpellType.damage, element: SpellElement.lightning, mpCost: 20, basePower: 45, range: 300, aoeRadius: 50, cooldown: 5.0, castTime: 1.0, target: SpellTarget.singleEnemy),
    SpellData(id: 'heal', name: 'Heal', type: SpellType.heal, element: SpellElement.holy, mpCost: 12, basePower: 40, range: 150, aoeRadius: 0, cooldown: 3.0, castTime: 0.6, target: SpellTarget.singleAlly),
    SpellData(id: 'mass_heal', name: 'Mass Heal', type: SpellType.heal, element: SpellElement.holy, mpCost: 30, basePower: 25, range: 100, aoeRadius: 120, cooldown: 8.0, castTime: 1.2, target: SpellTarget.area),
    SpellData(id: 'shield', name: 'Shield', type: SpellType.buff, element: SpellElement.none, mpCost: 8, basePower: 0, range: 150, aoeRadius: 0, cooldown: 5.0, castTime: 0.5, target: SpellTarget.singleAlly),
    SpellData(id: 'haste', name: 'Haste', type: SpellType.buff, element: SpellElement.none, mpCost: 10, basePower: 0, range: 150, aoeRadius: 0, cooldown: 6.0, castTime: 0.5, target: SpellTarget.singleAlly),
    SpellData(id: 'slow', name: 'Slow', type: SpellType.debuff, element: SpellElement.ice, mpCost: 8, basePower: 0, range: 180, aoeRadius: 0, cooldown: 4.0, castTime: 0.5, target: SpellTarget.singleEnemy),
  ];
}
