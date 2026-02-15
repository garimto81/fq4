import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/systems/ending_system.dart';
import 'package:fq4_flutter/game/systems/newgame_plus_system.dart';
import 'package:fq4_flutter/game/systems/achievement_system.dart';
import 'package:fq4_flutter/game/systems/save_system.dart';

void main() {
  group('EndingSystem', () {
    late EndingSystem endingSystem;

    setUp(() {
      endingSystem = EndingSystem();
    });

    test('determineEnding returns GOOD for perfect playthrough', () {
      final ending = endingSystem.determineEnding(
        chaptersCleared: 10,
        deathCount: 2,
        bossesDefeated: 3,
      );
      expect(ending, EndingType.good);
    });

    test('determineEnding returns NORMAL for moderate playthrough', () {
      final ending = endingSystem.determineEnding(
        chaptersCleared: 10,
        deathCount: 8,
        bossesDefeated: 2,
      );
      expect(ending, EndingType.normal);
    });

    test('determineEnding returns BAD for high death count', () {
      final ending = endingSystem.determineEnding(
        chaptersCleared: 10,
        deathCount: 15,
        bossesDefeated: 3,
      );
      expect(ending, EndingType.bad);
    });

    test('determineEnding returns NORMAL when missing chapters', () {
      final ending = endingSystem.determineEnding(
        chaptersCleared: 8,
        deathCount: 2,
        bossesDefeated: 3,
      );
      expect(ending, EndingType.normal);
    });

    test('getEndingDescriptionKey returns correct keys', () {
      expect(
        endingSystem.getEndingDescriptionKey(EndingType.good),
        'ENDING_GOOD_DESC',
      );
      expect(
        endingSystem.getEndingDescriptionKey(EndingType.normal),
        'ENDING_NORMAL_DESC',
      );
      expect(
        endingSystem.getEndingDescriptionKey(EndingType.bad),
        'ENDING_BAD_DESC',
      );
    });

    test('getEndingTitleKey returns correct keys', () {
      expect(
        endingSystem.getEndingTitleKey(EndingType.good),
        'ENDING_GOOD_TITLE',
      );
      expect(
        endingSystem.getEndingTitleKey(EndingType.normal),
        'ENDING_NORMAL_TITLE',
      );
      expect(
        endingSystem.getEndingTitleKey(EndingType.bad),
        'ENDING_BAD_TITLE',
      );
    });

    test('triggerEnding calls callback', () {
      EndingType? triggeredEnding;
      endingSystem.onEndingTriggered = (ending) {
        triggeredEnding = ending;
      };

      endingSystem.triggerEnding(EndingType.good);
      expect(triggeredEnding, EndingType.good);
    });

    test('serialize and deserialize ending state', () {
      final serialized = endingSystem.serialize(EndingType.good);
      expect(serialized['reached_ending'], 'good');

      final deserialized = endingSystem.deserialize(serialized);
      expect(deserialized, EndingType.good);
    });

    test('deserialize returns null for invalid data', () {
      final deserialized = endingSystem.deserialize({'reached_ending': null});
      expect(deserialized, isNull);
    });
  });

  group('NewGamePlusSystem', () {
    late NewGamePlusSystem ngPlusSystem;

    setUp(() {
      ngPlusSystem = NewGamePlusSystem();
    });

    test('isActive returns false initially', () {
      expect(ngPlusSystem.isActive, false);
    });

    test('hasNgPlusData returns false initially', () {
      expect(ngPlusSystem.hasNgPlusData, false);
    });

    test('ngPlusCount returns 0 initially', () {
      expect(ngPlusSystem.ngPlusCount, 0);
    });

    test('getScaledEnemyStat returns base stat when inactive', () {
      expect(ngPlusSystem.getScaledEnemyStat(100), 100);
    });

    test('getScaledEnemyStat applies 1.5x multiplier when active', () {
      final data = NewGamePlusData(
        ngPlusCount: 1,
        previousPlayTime: 3600,
        previousDeathCount: 5,
        unlockedAchievements: [],
      );
      ngPlusSystem.startNgPlus(data);

      expect(ngPlusSystem.getScaledEnemyStat(100), 150);
      expect(ngPlusSystem.getScaledEnemyStat(50), 75);
    });

    test('getScaledExperience returns base exp when inactive', () {
      expect(ngPlusSystem.getScaledExperience(100), 100);
    });

    test('getScaledExperience applies 0.8x multiplier when active', () {
      final data = NewGamePlusData(
        ngPlusCount: 1,
        previousPlayTime: 3600,
        previousDeathCount: 5,
        unlockedAchievements: [],
      );
      ngPlusSystem.startNgPlus(data);

      expect(ngPlusSystem.getScaledExperience(100), 80);
      expect(ngPlusSystem.getScaledExperience(50), 40);
    });

    test('getScaledGold returns base gold when inactive', () {
      expect(ngPlusSystem.getScaledGold(100), 100);
    });

    test('getScaledGold applies 1.2x multiplier when active', () {
      final data = NewGamePlusData(
        ngPlusCount: 1,
        previousPlayTime: 3600,
        previousDeathCount: 5,
        unlockedAchievements: [],
      );
      ngPlusSystem.startNgPlus(data);

      expect(ngPlusSystem.getScaledGold(100), 120);
      expect(ngPlusSystem.getScaledGold(50), 60);
    });

    test('prepareNgPlusData increments count', () {
      final data1 = ngPlusSystem.prepareNgPlusData(
        playTime: 7200,
        deathCount: 3,
        achievements: ['achievement1'],
      );
      expect(data1.ngPlusCount, 1);

      ngPlusSystem.startNgPlus(data1);

      final data2 = ngPlusSystem.prepareNgPlusData(
        playTime: 9000,
        deathCount: 5,
        achievements: ['achievement1', 'achievement2'],
      );
      expect(data2.ngPlusCount, 2);
    });

    test('startNgPlus activates system and calls callback', () {
      NewGamePlusData? startedData;
      ngPlusSystem.onNgPlusStarted = (data) {
        startedData = data;
      };

      final data = NewGamePlusData(
        ngPlusCount: 1,
        previousPlayTime: 3600,
        previousDeathCount: 5,
        unlockedAchievements: ['test'],
      );
      ngPlusSystem.startNgPlus(data);

      expect(ngPlusSystem.isActive, true);
      expect(ngPlusSystem.hasNgPlusData, true);
      expect(startedData, isNotNull);
      expect(startedData?.ngPlusCount, 1);
    });

    test('deactivate sets isActive to false', () {
      final data = NewGamePlusData(
        ngPlusCount: 1,
        previousPlayTime: 3600,
        previousDeathCount: 5,
        unlockedAchievements: [],
      );
      ngPlusSystem.startNgPlus(data);
      expect(ngPlusSystem.isActive, true);

      ngPlusSystem.deactivate();
      expect(ngPlusSystem.isActive, false);
    });

    test('serialize and deserialize NG+ state', () {
      final data = NewGamePlusData(
        ngPlusCount: 2,
        previousPlayTime: 7200,
        previousDeathCount: 10,
        unlockedAchievements: ['ach1', 'ach2'],
      );
      ngPlusSystem.startNgPlus(data);

      final serialized = ngPlusSystem.serialize();
      expect(serialized['is_active'], true);
      expect(serialized['ng_plus_data'], isNotNull);

      final newSystem = NewGamePlusSystem();
      newSystem.deserialize(serialized);
      expect(newSystem.isActive, true);
      expect(newSystem.ngPlusCount, 2);
    });
  });

  group('AchievementSystem', () {
    late AchievementSystem achievementSystem;

    setUp(() {
      achievementSystem = AchievementSystem();
    });

    test('initializes with 28 achievements', () {
      final all = achievementSystem.getAllAchievements();
      expect(all.length, 28);
    });

    test('unlock marks achievement as unlocked', () {
      expect(achievementSystem.isUnlocked('chapter_1_clear'), false);
      achievementSystem.unlock('chapter_1_clear');
      expect(achievementSystem.isUnlocked('chapter_1_clear'), true);
    });

    test('unlock calls callback', () {
      AchievementData? unlockedAchievement;
      achievementSystem.onAchievementUnlocked = (ach) {
        unlockedAchievement = ach;
      };

      achievementSystem.unlock('chapter_1_clear');
      expect(unlockedAchievement, isNotNull);
      expect(unlockedAchievement?.id, 'chapter_1_clear');
    });

    test('unlock ignores already unlocked achievements', () {
      int callCount = 0;
      achievementSystem.onAchievementUnlocked = (_) {
        callCount++;
      };

      achievementSystem.unlock('chapter_1_clear');
      achievementSystem.unlock('chapter_1_clear');
      expect(callCount, 1);
    });

    test('updateProgress tracks progress and unlocks when reached', () {
      expect(achievementSystem.isUnlocked('spell_master'), false);

      achievementSystem.updateProgress('spell_master', 50);
      expect(achievementSystem.getProgress('spell_master'), 50);
      expect(achievementSystem.isUnlocked('spell_master'), false);

      achievementSystem.updateProgress('spell_master', 100);
      expect(achievementSystem.isUnlocked('spell_master'), true);
    });

    test('addKill unlocks achievements at thresholds', () {
      for (int i = 0; i < 99; i++) {
        achievementSystem.addKill();
      }
      expect(achievementSystem.isUnlocked('kills_hunter'), false);

      achievementSystem.addKill(); // 100th kill
      expect(achievementSystem.isUnlocked('kills_hunter'), true);
      expect(achievementSystem.totalKills, 100);
    });

    test('addKill unlocks all kill achievements at 1000', () {
      for (int i = 0; i < 1000; i++) {
        achievementSystem.addKill();
      }
      expect(achievementSystem.isUnlocked('kills_hunter'), true);
      expect(achievementSystem.isUnlocked('kills_slayer'), true);
      expect(achievementSystem.isUnlocked('kills_legend'), true);
    });

    test('completeChapter unlocks chapter achievement', () {
      achievementSystem.completeChapter('chapter_1');
      expect(achievementSystem.isUnlocked('chapter_1_clear'), true);
      expect(achievementSystem.chaptersCleared, contains('chapter_1'));
    });

    test('defeatBoss unlocks boss achievement', () {
      achievementSystem.defeatBoss('demon_general');
      expect(achievementSystem.isUnlocked('boss_demon_general'), true);
      expect(achievementSystem.bossesDefeated, contains('demon_general'));
    });

    test('defeatBoss unlocks all bosses achievement when 3 defeated', () {
      achievementSystem.defeatBoss('demon_general');
      achievementSystem.defeatBoss('fallen_hero');
      expect(achievementSystem.isUnlocked('boss_all'), false);

      achievementSystem.defeatBoss('demon_king');
      expect(achievementSystem.isUnlocked('boss_all'), true);
    });

    test('reachLevel unlocks level achievements', () {
      achievementSystem.reachLevel(9);
      expect(achievementSystem.isUnlocked('level_novice'), false);

      achievementSystem.reachLevel(10);
      expect(achievementSystem.isUnlocked('level_novice'), true);

      achievementSystem.reachLevel(30);
      expect(achievementSystem.isUnlocked('level_veteran'), true);

      achievementSystem.reachLevel(50);
      expect(achievementSystem.isUnlocked('level_master'), true);
    });

    test('reachEnding unlocks ending achievement', () {
      achievementSystem.reachEnding('good');
      expect(achievementSystem.isUnlocked('ending_good'), true);
      expect(achievementSystem.endingsReached, contains('good'));
    });

    test('useFormation tracks unique formations', () {
      achievementSystem.useFormation('V_SHAPE');
      achievementSystem.useFormation('V_SHAPE'); // duplicate
      achievementSystem.useFormation('LINE');

      expect(achievementSystem.formationsUsed.length, 2);
      expect(achievementSystem.getProgress('formation_master'), 2);
    });

    test('useFormation unlocks achievement with 5 formations', () {
      achievementSystem.useFormation('V_SHAPE');
      achievementSystem.useFormation('LINE');
      achievementSystem.useFormation('CIRCLE');
      achievementSystem.useFormation('WEDGE');
      expect(achievementSystem.isUnlocked('formation_master'), false);

      achievementSystem.useFormation('SCATTERED');
      expect(achievementSystem.isUnlocked('formation_master'), true);
    });

    test('addSpellCast updates spell_master progress', () {
      for (int i = 0; i < 100; i++) {
        achievementSystem.addSpellCast();
      }
      expect(achievementSystem.spellsCast, 100);
      expect(achievementSystem.isUnlocked('spell_master'), true);
    });

    test('addDeath increments death count', () {
      achievementSystem.addDeath();
      achievementSystem.addDeath();
      expect(achievementSystem.deathCount, 2);
    });

    test('startNgPlus unlocks NG+ achievement', () {
      achievementSystem.startNgPlus();
      expect(achievementSystem.isUnlocked('ng_plus'), true);
      expect(achievementSystem.ngPlusCount, 1);
    });

    test('checkCompletionAchievements unlocks speed_run under 2 hours', () {
      achievementSystem.checkCompletionAchievements(7200.0);
      expect(achievementSystem.isUnlocked('speed_run'), true);

      final system2 = AchievementSystem();
      system2.checkCompletionAchievements(7201.0);
      expect(system2.isUnlocked('speed_run'), false);
    });

    test('checkCompletionAchievements unlocks no_death with 0 deaths', () {
      achievementSystem.checkCompletionAchievements(5000.0);
      expect(achievementSystem.isUnlocked('no_death'), true);

      achievementSystem.addDeath();
      final system2 = AchievementSystem();
      system2.addDeath();
      system2.checkCompletionAchievements(5000.0);
      expect(system2.isUnlocked('no_death'), false);
    });

    test('getCompletionPercentage calculates correctly', () {
      expect(achievementSystem.getCompletionPercentage(), 0.0);

      achievementSystem.unlock('chapter_1_clear');
      achievementSystem.unlock('chapter_2_clear');

      final percentage = achievementSystem.getCompletionPercentage();
      expect(percentage, closeTo(7.14, 0.01)); // 2/28 * 100
    });

    test('getUnlockedAchievements returns only unlocked', () {
      achievementSystem.unlock('chapter_1_clear');
      achievementSystem.unlock('boss_demon_general');

      final unlocked = achievementSystem.getUnlockedAchievements();
      expect(unlocked.length, 2);
      expect(unlocked.any((a) => a.id == 'chapter_1_clear'), true);
      expect(unlocked.any((a) => a.id == 'boss_demon_general'), true);
    });

    test('serialize and deserialize preserves state', () {
      achievementSystem.unlock('chapter_1_clear');
      achievementSystem.addKill();
      achievementSystem.addKill();
      achievementSystem.addSpellCast();
      achievementSystem.useFormation('V_SHAPE');

      final serialized = achievementSystem.serialize();

      final newSystem = AchievementSystem();
      newSystem.deserialize(serialized);

      expect(newSystem.isUnlocked('chapter_1_clear'), true);
      expect(newSystem.totalKills, 2);
      expect(newSystem.spellsCast, 1);
      expect(newSystem.formationsUsed.contains('V_SHAPE'), true);
    });
  });

  group('SaveSystem', () {
    late SaveSystem saveSystem;

    setUp(() {
      saveSystem = SaveSystem();
    });

    test('saveGame and loadGame round-trip', () {
      final gameState = {'chapter': 3, 'play_time': 1800};
      final playerUnits = [
        {'name': 'Hero', 'hp': 100}
      ];
      final inventory = {'gold': 500};

      final saved = saveSystem.saveGame(
        1,
        gameState: gameState,
        playerUnits: playerUnits,
        inventory: inventory,
      );
      expect(saved, true);

      final loaded = saveSystem.loadGame(1);
      expect(loaded, isNotNull);
      expect(loaded!['game_state']['chapter'], 3);
      expect(loaded['player_units'][0]['name'], 'Hero');
      expect(loaded['inventory']['gold'], 500);
    });

    test('saveGame calls onSaveCompleted callback', () {
      int? savedSlot;
      bool? savedSuccess;
      saveSystem.onSaveCompleted = (slot, success) {
        savedSlot = slot;
        savedSuccess = success;
      };

      saveSystem.saveGame(
        2,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );

      expect(savedSlot, 2);
      expect(savedSuccess, true);
    });

    test('loadGame calls onLoadCompleted callback', () {
      int? loadedSlot;
      bool? loadedSuccess;
      saveSystem.onLoadCompleted = (slot, success) {
        loadedSlot = slot;
        loadedSuccess = success;
      };

      saveSystem.saveGame(
        1,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );
      saveSystem.loadGame(1);

      expect(loadedSlot, 1);
      expect(loadedSuccess, true);
    });

    test('autoSave uses slot 0 and calls callback', () {
      bool autoSaveCalled = false;
      saveSystem.onAutoSaveTriggered = () {
        autoSaveCalled = true;
      };

      final saved = saveSystem.autoSave(
        gameState: {'chapter': 1},
        playerUnits: [],
        inventory: {},
      );

      expect(saved, true);
      expect(autoSaveCalled, true);
      expect(saveSystem.hasSaveData(SaveSystem.autoSaveSlot), true);
    });

    test('getSlotInfo returns correct info for existing save', () {
      saveSystem.saveGame(
        1,
        gameState: {'chapter': 5, 'play_time': 3600},
        playerUnits: [
          {
            'name': 'Hero',
            'experience': {'current_level': 15}
          }
        ],
        inventory: {},
      );

      final info = saveSystem.getSlotInfo(1);
      expect(info.exists, true);
      expect(info.slot, 1);
      expect(info.version, SaveSystem.saveVersion);
      expect(info.chapter, 5);
      expect(info.playTime, 3600);
      expect(info.playerLevel, 15);
      expect(info.corrupted, false);
    });

    test('getSlotInfo returns non-existent info for empty slot', () {
      final info = saveSystem.getSlotInfo(2);
      expect(info.exists, false);
      expect(info.slot, 2);
      expect(info.corrupted, false);
    });

    test('getAllSlotsInfo returns all 4 slots', () {
      saveSystem.saveGame(
        0,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );
      saveSystem.saveGame(
        2,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );

      final allInfo = saveSystem.getAllSlotsInfo();
      expect(allInfo.length, 4); // 0, 1, 2, 3
      expect(allInfo[0].exists, true); // slot 0
      expect(allInfo[1].exists, false); // slot 1
      expect(allInfo[2].exists, true); // slot 2
      expect(allInfo[3].exists, false); // slot 3
    });

    test('deleteSave removes save from slot', () {
      saveSystem.saveGame(
        2,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );
      expect(saveSystem.hasSaveData(2), true);

      final deleted = saveSystem.deleteSave(2);
      expect(deleted, true);
      expect(saveSystem.hasSaveData(2), false);
    });

    test('deleteSave prevents deleting slot 0 (auto-save)', () {
      saveSystem.autoSave(
        gameState: {},
        playerUnits: [],
        inventory: {},
      );

      final deleted = saveSystem.deleteSave(0);
      expect(deleted, false);
      expect(saveSystem.hasSaveData(0), true);
    });

    test('deleteSave returns false for invalid slots', () {
      expect(saveSystem.deleteSave(-1), false);
      expect(saveSystem.deleteSave(4), false);
    });

    test('saveGame rejects invalid slot numbers', () {
      bool? success;
      saveSystem.onSaveCompleted = (slot, result) {
        success = result;
      };

      saveSystem.saveGame(
        -1,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );
      expect(success, false);

      saveSystem.saveGame(
        4,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );
      expect(success, false);
    });

    test('loadGame rejects invalid slot numbers', () {
      bool? success;
      saveSystem.onLoadCompleted = (slot, result) {
        success = result;
      };

      final loaded1 = saveSystem.loadGame(-1);
      expect(loaded1, isNull);
      expect(success, false);

      final loaded2 = saveSystem.loadGame(4);
      expect(loaded2, isNull);
      expect(success, false);
    });

    test('hasSaveData returns correct status', () {
      expect(saveSystem.hasSaveData(1), false);

      saveSystem.saveGame(
        1,
        gameState: {},
        playerUnits: [],
        inventory: {},
      );

      expect(saveSystem.hasSaveData(1), true);
    });
  });
}
