// Phase 2: 인벤토리/장비 시스템 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/data/item_data.dart';
import 'package:fq4_flutter/game/data/equipment_data.dart';
import 'package:fq4_flutter/game/systems/inventory_system.dart';
import 'package:fq4_flutter/game/systems/equipment_system.dart';

void main() {
  group('ItemData Tests', () {
    test('팩토리 메서드로 아이템 생성', () {
      final potion = ItemData.potionHpSmall();
      expect(potion.id, 'potion_hp_small');
      expect(potion.name, 'HP포션(소)');
      expect(potion.type, ItemType.consumable);
      expect(potion.canUse(), true);
      expect((potion as HealItemData).healHp, 50);
    });

    test('consumable 아이템만 사용 가능', () {
      final potion = ItemData.potionHpSmall();
      final material = ItemData(
        id: 'mat1',
        name: '재료',
        description: '재료',
        type: ItemType.material,
        sellPrice: 10,
      );

      expect(potion.canUse(), true);
      expect(material.canUse(), false);
    });
  });

  group('EquipmentData Tests', () {
    test('팩토리 메서드로 장비 생성', () {
      final sword = EquipmentData.swordIron();
      expect(sword.id, 'sword_iron');
      expect(sword.slot, EquipmentSlot.weapon);
      expect(sword.bonusAtk, 8);
      expect(sword.requiredLevel, 1);
    });

    test('레벨 요구사항 확인', () {
      final steelSword = EquipmentData.swordSteel();
      expect(steelSword.canEquip(1), false);
      expect(steelSword.canEquip(3), true);
      expect(steelSword.canEquip(5), true);
    });

    test('능력치 보너스 합산', () {
      final bow = EquipmentData.bowShort();
      final bonuses = bow.getStatBonuses();
      expect(bonuses['atk'], 6);
      expect(bonuses['attackRange'], 50.0);
    });
  });

  group('InventorySystem Tests', () {
    late InventorySystem inventory;

    setUp(() {
      inventory = InventorySystem(maxSlots: 10, gold: 100);
    });

    test('아이템 추가 성공', () {
      final potion = ItemData.potionHpSmall();
      final result = inventory.addItem(potion, 5);

      expect(result.success, true);
      expect(result.added, 5);
      expect(inventory.getItemCount('potion_hp_small'), 5);
    });

    test('최대 스택 제한', () {
      final potion = ItemData.potionHpSmall();
      final result = inventory.addItem(potion, 150);

      expect(result.success, true);
      expect(result.added, 99); // maxStack
    });

    test('인벤토리 가득 참', () {
      for (int i = 0; i < 10; i++) {
        final item = ItemData(
          id: 'item_$i',
          name: 'Item $i',
          description: 'Test',
          type: ItemType.material,
          sellPrice: 10,
        );
        inventory.addItem(item, 1);
      }

      expect(inventory.isFull(), true);
      expect(inventory.getFreeSlots(), 0);

      final newItem = ItemData.potionHpSmall();
      final result = inventory.addItem(newItem, 1);
      expect(result.success, false);
      expect(result.reason, '인벤토리가 가득 찼습니다');
    });

    test('아이템 제거', () {
      final potion = ItemData.potionHpSmall();
      inventory.addItem(potion, 10);

      final result = inventory.removeItem('potion_hp_small', 3);
      expect(result.success, true);
      expect(result.remaining, 7);
      expect(inventory.getItemCount('potion_hp_small'), 7);
    });

    test('아이템 사용 (소모)', () {
      final potion = ItemData.potionHpSmall();
      inventory.addItem(potion, 3);

      final result = inventory.useItem('potion_hp_small');
      expect(result.success, true);
      expect(inventory.getItemCount('potion_hp_small'), 2);
    });

    test('골드 관리', () {
      expect(inventory.gold, 100);
      expect(inventory.canAfford(50), true);
      expect(inventory.canAfford(150), false);

      inventory.spendGold(30);
      expect(inventory.gold, 70);

      inventory.addGold(50);
      expect(inventory.gold, 120);
    });

    test('콜백 호출 확인', () {
      String? lastAddedId;
      int? lastAddedQuantity;

      inventory.onItemAdded = (id, quantity) {
        lastAddedId = id;
        lastAddedQuantity = quantity;
      };

      final potion = ItemData.potionHpSmall();
      inventory.addItem(potion, 5);

      expect(lastAddedId, 'potion_hp_small');
      expect(lastAddedQuantity, 5);
    });
  });

  group('EquipmentSystem Tests', () {
    late EquipmentSystem equipment;

    setUp(() {
      equipment = EquipmentSystem();
    });

    test('장비 착용 성공', () {
      final sword = EquipmentData.swordIron();
      final result = equipment.equip(sword, 1);

      expect(result.success, true);
      expect(result.oldItem, null);
      expect(equipment.getEquipped(EquipmentSlot.weapon), sword);
    });

    test('레벨 부족으로 착용 실패', () {
      final steelSword = EquipmentData.swordSteel();
      final result = equipment.equip(steelSword, 1);

      expect(result.success, false);
      expect(result.reason.contains('레벨'), true);
    });

    test('장비 교체 시 이전 장비 반환', () {
      final ironSword = EquipmentData.swordIron();
      final steelSword = EquipmentData.swordSteel();

      equipment.equip(ironSword, 1);
      final result = equipment.equip(steelSword, 5);

      expect(result.success, true);
      expect(result.oldItem, ironSword);
      expect(equipment.getEquipped(EquipmentSlot.weapon), steelSword);
    });

    test('장비 해제', () {
      final sword = EquipmentData.swordIron();
      equipment.equip(sword, 1);

      final result = equipment.unequip(EquipmentSlot.weapon);
      expect(result.success, true);
      expect(result.removedItem, sword);
      expect(equipment.getEquipped(EquipmentSlot.weapon), null);
    });

    test('전체 보너스 합산', () {
      final sword = EquipmentData.swordIron(); // ATK +8
      final armor = EquipmentData.armorLeather(); // DEF +5
      final ring = EquipmentData.ringAgility(); // SPD +8, EVA +5%

      equipment.equip(sword, 1);
      equipment.equip(armor, 1);
      equipment.equip(ring, 1);

      final bonuses = equipment.getTotalBonuses();
      expect(bonuses['atk'], 8);
      expect(bonuses['def'], 5);
      expect(bonuses['spd'], 8);
      expect(bonuses['evasion'], 5.0);
    });

    test('음수 보너스 적용 (체인메일)', () {
      final chainmail = EquipmentData.armorChain(); // DEF +10, SPD -5
      equipment.equip(chainmail, 5);

      final bonuses = equipment.getTotalBonuses();
      expect(bonuses['def'], 10);
      expect(bonuses['spd'], -5);
    });
  });

  group('통합 시나리오', () {
    test('아이템 획득 → 사용 → 장비 착용 시나리오', () {
      final inventory = InventorySystem(gold: 100);
      final equipment = EquipmentSystem();

      // 1. 포션 획득
      final potion = ItemData.potionHpSmall();
      inventory.addItem(potion, 3);
      expect(inventory.getItemCount('potion_hp_small'), 3);

      // 2. 포션 사용
      inventory.useItem('potion_hp_small');
      expect(inventory.getItemCount('potion_hp_small'), 2);

      // 3. 무기 획득 및 착용
      final sword = EquipmentData.swordIron();
      final equipResult = equipment.equip(sword, 1);
      expect(equipResult.success, true);

      // 4. 방어구 획득 및 착용
      final armor = EquipmentData.armorLeather();
      equipment.equip(armor, 1);

      // 5. 전체 보너스 확인
      final bonuses = equipment.getTotalBonuses();
      expect(bonuses['atk'], 8);
      expect(bonuses['def'], 5);

      // 6. 골드 소모
      inventory.spendGold(50);
      expect(inventory.gold, 50);
    });
  });
}
