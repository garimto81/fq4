import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/systems/experience_system.dart';
import 'package:fq4_flutter/game/systems/stats_system.dart';
import 'package:fq4_flutter/game/systems/inventory_system.dart';
import 'package:fq4_flutter/game/systems/equipment_system.dart';
import 'package:fq4_flutter/game/data/item_data.dart';
import 'package:fq4_flutter/game/data/equipment_data.dart';
import 'package:fq4_flutter/core/constants/level_constants.dart';

void main() {
  group('ExperienceSystem', () {
    test('gainExp increases experience', () {
      final exp = ExperienceSystem();

      final result = exp.gainExp(50);

      expect(exp.currentExp, 50);
      expect(exp.totalExp, 50);
      expect(result.levelUps, 0);
    });

    test('gainExp triggers level up when exp is sufficient', () {
      final exp = ExperienceSystem();
      final expNeeded = LevelConstants.expToNextLevel(1);

      final result = exp.gainExp(expNeeded);

      expect(exp.currentLevel, 2);
      expect(result.levelUps, 1);
      expect(result.oldLevel, 1);
      expect(result.newLevel, 2);
    });

    test('level up grants correct stat gains', () {
      final exp = ExperienceSystem();
      final expNeeded = LevelConstants.expToNextLevel(1);

      final result = exp.gainExp(expNeeded);

      expect(result.statGains['hp'], LevelConstants.hpPerLevel);
      expect(result.statGains['mp'], LevelConstants.mpPerLevel);
      expect(result.statGains['atk'], LevelConstants.atkPerLevel);
      expect(result.statGains['def'], LevelConstants.defPerLevel);
      expect(result.statGains['spd'], LevelConstants.spdPerLevel);
      expect(result.statGains['lck'], LevelConstants.lckPerLevel);
    });

    test('getExpToNextLevel returns correct value', () {
      final exp = ExperienceSystem();

      final expNeeded = exp.getExpToNextLevel();

      expect(expNeeded, LevelConstants.expToNextLevel(1));
    });

    test('getLevelProgress returns correct percentage', () {
      final exp = ExperienceSystem();
      exp.gainExp(50);

      final progress = exp.getLevelProgress();

      expect(progress, closeTo(0.5, 0.01));
    });

    test('getExpInfo returns correct information', () {
      final exp = ExperienceSystem();
      exp.gainExp(50);

      final info = exp.getExpInfo();

      expect(info['level'], 1);
      expect(info['currentExp'], 50);
      expect(info['expToNext'], LevelConstants.expToNextLevel(1));
      expect(info['progress'], closeTo(0.5, 0.01));
      expect(info['isMaxLevel'], false);
    });

    test('calculateEnemyExp returns base exp for normal enemy', () {
      final exp = ExperienceSystem.calculateEnemyExp(5, 'normal', 5);

      expect(exp, LevelConstants.baseExpPerKill + (5 * LevelConstants.expPerEnemyLevel));
    });

    test('calculateEnemyExp applies elite multiplier', () {
      final baseExp = LevelConstants.baseExpPerKill + (5 * LevelConstants.expPerEnemyLevel);
      final expected = (baseExp * LevelConstants.eliteExpMult).round();

      final exp = ExperienceSystem.calculateEnemyExp(5, 'elite', 5);

      expect(exp, expected);
    });

    test('calculateEnemyExp applies boss multiplier', () {
      final baseExp = LevelConstants.baseExpPerKill + (5 * LevelConstants.expPerEnemyLevel);
      final expected = (baseExp * LevelConstants.bossExpMult).round();

      final exp = ExperienceSystem.calculateEnemyExp(5, 'boss', 5);

      expect(exp, expected);
    });

    test('onLevelUp callback is triggered', () {
      LevelUpResult? callbackResult;
      final exp = ExperienceSystem(
        onLevelUp: (result) => callbackResult = result,
      );

      exp.gainExp(LevelConstants.expToNextLevel(1));

      expect(callbackResult, isNotNull);
      expect(callbackResult?.levelUps, 1);
    });
  });

  group('StatsSystem', () {
    test('initialize sets base stats', () {
      final stats = StatsSystem();

      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      expect(stats.getStat(StatType.hp), 100);
      expect(stats.getStat(StatType.mp), 50);
      expect(stats.getStat(StatType.atk), 20);
      expect(stats.getStat(StatType.def), 10);
      expect(stats.getStat(StatType.spd), 15);
      expect(stats.getStat(StatType.lck), 5);
    });

    test('getStat returns sum of base, equipment, and buff', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      stats.setEquipmentBonus(StatType.atk, 10);
      stats.applyBuff(StatType.atk, 5, 10.0);

      expect(stats.getStat(StatType.atk), 35);
    });

    test('setBaseStat changes base stat value', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      stats.setBaseStat(StatType.hp, 150);

      expect(stats.getBaseStat(StatType.hp), 150);
      expect(stats.getStat(StatType.hp), 150);
    });

    test('addBaseStat increases base stat', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      stats.addBaseStat(StatType.hp, 15);

      expect(stats.getBaseStat(StatType.hp), 115);
    });

    test('setEquipmentBonus applies bonus to final stat', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      stats.setEquipmentBonus(StatType.atk, 10);

      expect(stats.getStat(StatType.atk), 30);
    });

    test('clearEquipmentBonus removes all equipment bonuses', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);
      stats.setEquipmentBonus(StatType.atk, 10);
      stats.setEquipmentBonus(StatType.def, 5);

      stats.clearEquipmentBonus();

      expect(stats.getStat(StatType.atk), 20);
      expect(stats.getStat(StatType.def), 10);
    });

    test('applyBuff adds temporary stat bonus', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      stats.applyBuff(StatType.atk, 15, 5.0);

      expect(stats.getStat(StatType.atk), 35);
    });

    test('update reduces buff duration and removes expired buffs', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);
      stats.applyBuff(StatType.atk, 15, 2.0);

      stats.update(1.0);
      expect(stats.getStat(StatType.atk), 35);

      stats.update(1.5);
      expect(stats.getStat(StatType.atk), 20);
    });

    test('getTotalAttack returns attack stat', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      expect(stats.getTotalAttack(), 20);
    });

    test('getTotalDefense returns defense stat', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      expect(stats.getTotalDefense(), 10);
    });

    test('getTotalSpeed returns speed stat', () {
      final stats = StatsSystem();
      stats.initialize(hp: 100, mp: 50, atk: 20, def: 10, spd: 15, lck: 5);

      expect(stats.getTotalSpeed(), 15);
    });
  });

  group('InventorySystem', () {
    test('addItem increases item count', () {
      final inventory = InventorySystem();
      final item = ItemData(
        id: 'potion',
        name: 'Potion',
        description: 'Restores HP',
        type: ItemType.consumable,
        maxStack: 99,
        sellPrice: 20,
      );

      final result = inventory.addItem(item, 5);

      expect(result.success, true);
      expect(result.added, 5);
      expect(inventory.getItemCount('potion'), 5);
    });

    test('removeItem decreases item count', () {
      final inventory = InventorySystem();
      final item = ItemData(
        id: 'potion',
        name: 'Potion',
        description: 'Restores HP',
        type: ItemType.consumable,
        maxStack: 99,
        sellPrice: 20,
      );
      inventory.addItem(item, 10);

      final result = inventory.removeItem('potion', 3);

      expect(result.success, true);
      expect(result.remaining, 7);
      expect(inventory.getItemCount('potion'), 7);
    });

    test('removeItem removes item when quantity reaches zero', () {
      final inventory = InventorySystem();
      final item = ItemData(
        id: 'potion',
        name: 'Potion',
        description: 'Restores HP',
        type: ItemType.consumable,
        maxStack: 99,
        sellPrice: 20,
      );
      inventory.addItem(item, 5);

      final result = inventory.removeItem('potion', 5);

      expect(result.success, true);
      expect(result.remaining, 0);
      expect(inventory.getItemCount('potion'), 0);
    });

    test('addGold increases gold', () {
      final inventory = InventorySystem();

      inventory.addGold(100);

      expect(inventory.gold, 100);
    });

    test('spendGold decreases gold', () {
      final inventory = InventorySystem();
      inventory.addGold(100);

      final success = inventory.spendGold(50);

      expect(success, true);
      expect(inventory.gold, 50);
    });

    test('spendGold fails when insufficient gold', () {
      final inventory = InventorySystem();
      inventory.addGold(30);

      final success = inventory.spendGold(50);

      expect(success, false);
      expect(inventory.gold, 30);
    });

    test('canAfford returns true when sufficient gold', () {
      final inventory = InventorySystem();
      inventory.addGold(100);

      expect(inventory.canAfford(50), true);
    });

    test('canAfford returns false when insufficient gold', () {
      final inventory = InventorySystem();
      inventory.addGold(30);

      expect(inventory.canAfford(50), false);
    });
  });

  group('EquipmentSystem', () {
    test('equip adds equipment to slot', () {
      final equipment = EquipmentSystem();
      final weapon = EquipmentData(
        id: 'sword',
        name: 'Iron Sword',
        description: 'A basic sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        bonusAtk: 10,
        sellPrice: 50,
      );

      final result = equipment.equip(weapon, 5);

      expect(result.success, true);
      expect(equipment.getEquipped(EquipmentSlot.weapon), weapon);
    });

    test('equip fails when level requirement not met', () {
      final equipment = EquipmentSystem();
      final weapon = EquipmentData(
        id: 'sword',
        name: 'Steel Sword',
        description: 'A strong sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 10,
        bonusAtk: 25,
        sellPrice: 120,
      );

      final result = equipment.equip(weapon, 5);

      expect(result.success, false);
      expect(result.reason, contains('레벨'));
    });

    test('equip returns old item when replacing equipment', () {
      final equipment = EquipmentSystem();
      final oldWeapon = EquipmentData(
        id: 'sword',
        name: 'Iron Sword',
        description: 'A basic sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        bonusAtk: 10,
        sellPrice: 50,
      );
      final newWeapon = EquipmentData(
        id: 'steel_sword',
        name: 'Steel Sword',
        description: 'A strong sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        bonusAtk: 20,
        sellPrice: 120,
      );

      equipment.equip(oldWeapon, 5);
      final result = equipment.equip(newWeapon, 5);

      expect(result.success, true);
      expect(result.oldItem, oldWeapon);
    });

    test('unequip removes equipment from slot', () {
      final equipment = EquipmentSystem();
      final weapon = EquipmentData(
        id: 'sword',
        name: 'Iron Sword',
        description: 'A basic sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        bonusAtk: 10,
        sellPrice: 50,
      );
      equipment.equip(weapon, 5);

      final result = equipment.unequip(EquipmentSlot.weapon);

      expect(result.success, true);
      expect(result.removedItem, weapon);
      expect(equipment.getEquipped(EquipmentSlot.weapon), null);
    });

    test('getTotalBonuses sums all equipment bonuses', () {
      final equipment = EquipmentSystem();
      final weapon = EquipmentData(
        id: 'sword',
        name: 'Iron Sword',
        description: 'A basic sword',
        slot: EquipmentSlot.weapon,
        requiredLevel: 1,
        bonusAtk: 10,
        bonusSpd: 2,
        sellPrice: 50,
      );
      final armor = EquipmentData(
        id: 'armor',
        name: 'Leather Armor',
        description: 'Basic armor',
        slot: EquipmentSlot.armor,
        requiredLevel: 1,
        bonusDef: 15,
        bonusHp: 20,
        sellPrice: 40,
      );

      equipment.equip(weapon, 5);
      equipment.equip(armor, 5);

      final bonuses = equipment.getTotalBonuses();

      expect(bonuses['atk'], 10);
      expect(bonuses['def'], 15);
      expect(bonuses['spd'], 2);
      expect(bonuses['hp'], 20);
    });
  });
}
