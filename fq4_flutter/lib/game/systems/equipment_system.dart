// Phase 2: 장비 시스템

import '../data/equipment_data.dart';

class EquipmentSystem {
  final Map<EquipmentSlot, EquipmentData?> equipped = {
    EquipmentSlot.weapon: null,
    EquipmentSlot.armor: null,
    EquipmentSlot.accessory: null,
  };

  // 콜백
  void Function(EquipmentSlot slot, EquipmentData? newItem, EquipmentData? oldItem)? onEquipmentChanged;

  EquipmentSystem();

  ({bool success, String reason, EquipmentData? oldItem}) equip(EquipmentData item, int unitLevel) {
    if (!item.canEquip(unitLevel)) {
      return (
        success: false,
        reason: '레벨 ${item.requiredLevel} 이상 필요합니다',
        oldItem: null,
      );
    }

    final oldItem = equipped[item.slot];
    equipped[item.slot] = item;
    onEquipmentChanged?.call(item.slot, item, oldItem);

    return (success: true, reason: '', oldItem: oldItem);
  }

  ({bool success, EquipmentData? removedItem}) unequip(EquipmentSlot slot) {
    final removedItem = equipped[slot];
    if (removedItem == null) {
      return (success: false, removedItem: null);
    }

    equipped[slot] = null;
    onEquipmentChanged?.call(slot, null, removedItem);

    return (success: true, removedItem: removedItem);
  }

  EquipmentData? getEquipped(EquipmentSlot slot) {
    return equipped[slot];
  }

  Map<String, num> getTotalBonuses() {
    final bonuses = <String, num>{
      'hp': 0,
      'mp': 0,
      'atk': 0,
      'def': 0,
      'spd': 0,
      'lck': 0,
      'attackRange': 0.0,
      'criticalChance': 0.0,
      'evasion': 0.0,
    };

    for (final item in equipped.values) {
      if (item == null) continue;

      final itemBonuses = item.getStatBonuses();
      for (final entry in itemBonuses.entries) {
        bonuses[entry.key] = (bonuses[entry.key] ?? 0) + entry.value;
      }
    }

    return bonuses;
  }
}
