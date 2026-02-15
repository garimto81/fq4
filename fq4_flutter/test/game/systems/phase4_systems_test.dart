// Phase 4 systems tests
// Coverage: ObjectPool, ShopSystem, LocalizationManager, AccessibilitySystem, AudioManager

import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/systems/object_pool.dart';
import 'package:fq4_flutter/game/systems/shop_system.dart';
import 'package:fq4_flutter/game/managers/localization_manager.dart';
import 'package:fq4_flutter/game/systems/accessibility_system.dart';
import 'package:fq4_flutter/game/managers/audio_manager.dart';

void main() {
  group('ObjectPool', () {
    test('warmUp creates initial objects', () {
      final pool = ObjectPool<int>(
        factory: () => 42,
        initialSize: 5,
      );

      expect(pool.poolSize, 5);
      expect(pool.activeCount, 0);
      expect(pool.totalSize, 5);
    });

    test('acquire returns object from pool', () {
      final pool = ObjectPool<int>(
        factory: () => 42,
        initialSize: 3,
      );

      final obj = pool.acquire();
      expect(obj, 42);
      expect(pool.poolSize, 2);
      expect(pool.activeCount, 1);
    });

    test('acquire creates new when pool empty', () {
      int counter = 0;
      final pool = ObjectPool<int>(
        factory: () => ++counter,
        initialSize: 0,
      );

      final obj = pool.acquire();
      expect(obj, 1);
      expect(pool.poolSize, 0);
      expect(pool.activeCount, 1);
      expect(pool.totalSize, 1);
    });

    test('release returns object to pool', () {
      final pool = ObjectPool<int>(
        factory: () => 1,
        initialSize: 2,
      );

      final obj = pool.acquire();
      expect(pool.activeCount, 1);

      pool.release(obj);
      expect(pool.activeCount, 0);
      expect(pool.poolSize, 2);
    });

    test('releaseAll returns all active objects', () {
      final pool = ObjectPool<int>(
        factory: () => 1,
        initialSize: 5,
      );

      pool.acquire();
      pool.acquire();
      pool.acquire();
      expect(pool.activeCount, 3);

      pool.releaseAll();
      expect(pool.activeCount, 0);
      expect(pool.poolSize, 5);
    });

    test('activeCount, poolSize, totalSize are correct', () {
      final pool = ObjectPool<int>(
        factory: () => 1,
        initialSize: 10,
      );

      expect(pool.totalSize, 10);
      expect(pool.poolSize, 10);
      expect(pool.activeCount, 0);

      final obj1 = pool.acquire();
      expect(pool.totalSize, 10);
      expect(pool.poolSize, 9);
      expect(pool.activeCount, 1);

      pool.acquire();
      expect(pool.totalSize, 10);
      expect(pool.poolSize, 8);
      expect(pool.activeCount, 2);

      pool.release(obj1);
      expect(pool.totalSize, 10);
      expect(pool.poolSize, 9);
      expect(pool.activeCount, 1);
    });

    test('onAcquire and onRelease callbacks called', () {
      int acquireCount = 0;
      int releaseCount = 0;

      final pool = ObjectPool<int>(
        factory: () => 1,
        initialSize: 2,
        onAcquire: (_) => acquireCount++,
        onRelease: (_) => releaseCount++,
      );

      final obj = pool.acquire();
      expect(acquireCount, 1);
      expect(releaseCount, 0);

      pool.release(obj);
      expect(acquireCount, 1);
      expect(releaseCount, 1);
    });

    test('multiple acquire/release cycles work correctly', () {
      final pool = ObjectPool<int>(
        factory: () => 1,
        initialSize: 3,
      );

      // Cycle 1
      final obj1 = pool.acquire();
      expect(pool.activeCount, 1);
      pool.release(obj1);
      expect(pool.activeCount, 0);

      // Cycle 2
      final obj2 = pool.acquire();
      final obj3 = pool.acquire();
      expect(pool.activeCount, 2);
      pool.release(obj2);
      pool.release(obj3);
      expect(pool.activeCount, 0);
      expect(pool.poolSize, 3);
    });
  });

  group('ShopSystem', () {
    late ShopSystem shopSystem;

    setUp(() {
      shopSystem = ShopSystem();
    });

    test('openShop sets currentShop and initializes stock', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small', 'potion_mp_small'],
      );

      shopSystem.openShop(shop);
      expect(shopSystem.currentShop, shop);
      expect(shopSystem.getStock('potion_hp_small'), -1);
    });

    test('closeShop clears state', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      shopSystem.openShop(shop);
      shopSystem.closeShop();
      expect(shopSystem.currentShop, null);
    });

    test('buyItem succeeds with canAfford callback', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      int gold = 1000;
      shopSystem.canAfford = (amount) => gold >= amount;
      shopSystem.spendGold = (amount) { gold -= amount; return true; };

      shopSystem.openShop(shop);
      final result = shopSystem.buyItem('potion_hp_small', 100);

      expect(result.success, true);
      expect(result.reason, null);
      expect(gold, 900);
    });

    test('buyItem fails with insufficient gold', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      shopSystem.canAfford = (amount) => false;
      shopSystem.openShop(shop);
      final result = shopSystem.buyItem('potion_hp_small', 100);

      expect(result.success, false);
      expect(result.reason, 'Not enough gold');
    });

    test('buyItem fails when out of stock', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      int gold = 10000;
      shopSystem.canAfford = (amount) => gold >= amount;
      shopSystem.spendGold = (amount) { gold -= amount; return true; };

      shopSystem.openShop(shop);
      shopSystem.setStockLimit('potion_hp_small', 1);

      final result1 = shopSystem.buyItem('potion_hp_small', 100);
      expect(result1.success, true);

      final result2 = shopSystem.buyItem('potion_hp_small', 100);
      expect(result2.success, false);
      expect(result2.reason, 'Out of stock');
    });

    test('buyItem fails when no shop opened', () {
      final result = shopSystem.buyItem('potion_hp_small', 100);
      expect(result.success, false);
      expect(result.reason, 'No shop opened');
    });

    test('sellItem succeeds and adds gold', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      int gold = 0;
      shopSystem.addGold = (amount) => gold += amount;

      shopSystem.openShop(shop);
      final result = shopSystem.sellItem('potion_hp_small', 50);

      expect(result.success, true);
      expect(gold, 50);
    });

    test('getBuyPrice and getSellPrice with multipliers', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
        buyPriceMultiplier: 1.2,
        sellPriceMultiplier: 0.6,
      );

      shopSystem.openShop(shop);

      expect(shopSystem.getBuyPrice(100), 120);
      expect(shopSystem.getSellPrice(100), 60);
    });

    test('setStockLimit and stock depletion', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small'],
      );

      int gold = 10000;
      shopSystem.canAfford = (amount) => gold >= amount;
      shopSystem.spendGold = (amount) { gold -= amount; return true; };

      shopSystem.openShop(shop);
      shopSystem.setStockLimit('potion_hp_small', 3);

      expect(shopSystem.getStock('potion_hp_small'), 3);

      shopSystem.buyItem('potion_hp_small', 10);
      expect(shopSystem.getStock('potion_hp_small'), 2);
    });

    test('hasStock returns correctly for infinite, limited, and empty', () {
      final shop = ShopData(
        shopId: 'shop_1',
        shopName: 'Test Shop',
        itemsForSale: ['potion_hp_small', 'potion_mp_small'],
      );

      int gold = 10000;
      shopSystem.canAfford = (amount) => gold >= amount;
      shopSystem.spendGold = (amount) { gold -= amount; return true; };

      shopSystem.openShop(shop);

      // Infinite stock
      expect(shopSystem.hasStock('potion_hp_small'), true);

      // Limited stock
      shopSystem.setStockLimit('potion_mp_small', 1);
      expect(shopSystem.hasStock('potion_mp_small'), true);

      // Deplete stock
      shopSystem.buyItem('potion_mp_small', 10);
      expect(shopSystem.hasStock('potion_mp_small'), false);
    });
  });

  group('LocalizationManager', () {
    late LocalizationManager locManager;

    setUp(() {
      locManager = LocalizationManager();
    });

    test('default locale is ja', () {
      expect(locManager.currentLocale, 'ja');
    });

    test('setLocale changes locale', () {
      locManager.setLocale('en');
      expect(locManager.currentLocale, 'en');

      locManager.setLocale('ko');
      expect(locManager.currentLocale, 'ko');
    });

    test('setLocale ignores unsupported locale', () {
      locManager.setLocale('ja');
      locManager.setLocale('fr');
      expect(locManager.currentLocale, 'ja');
    });

    test('tr returns key when not found', () {
      final result = locManager.tr('nonexistent.key');
      expect(result, 'nonexistent.key');
    });

    test('tr returns translated text after loadFlatTranslations', () {
      locManager.loadFlatTranslations({
        'test.key': 'Test Value',
        'game.start': 'Start Game',
      });

      expect(locManager.tr('test.key'), 'Test Value');
      expect(locManager.tr('game.start'), 'Start Game');
    });

    test('tr substitutes parameters', () {
      locManager.loadFlatTranslations({
        'greeting': 'Hello, {name}!',
        'stats': 'HP: {hp}/{maxHp}',
      });

      expect(
        locManager.tr('greeting', {'name': 'Player'}),
        'Hello, Player!',
      );
      expect(
        locManager.tr('stats', {'hp': '50', 'maxHp': '100'}),
        'HP: 50/100',
      );
    });

    test('loadTranslations loads for current locale', () {
      locManager.setLocale('en');
      locManager.loadTranslations({
        'UI_START': {'ja': 'はじめる', 'ko': '시작', 'en': 'Start'},
        'UI_EXIT': {'ja': '終了', 'ko': '종료', 'en': 'Exit'},
      });

      expect(locManager.tr('UI_START'), 'Start');
      expect(locManager.tr('UI_EXIT'), 'Exit');
    });

    test('getLocaleName returns correct names', () {
      expect(locManager.getLocaleName('ja'), '日本語');
      expect(locManager.getLocaleName('en'), 'English');
      expect(locManager.getLocaleName('ko'), '한국어');
      expect(locManager.getLocaleName('unknown'), 'unknown');
    });
  });

  group('AccessibilitySystem', () {
    late AccessibilitySystem accessSystem;

    setUp(() {
      accessSystem = AccessibilitySystem();
    });

    test('default values correct', () {
      expect(accessSystem.colorBlindMode, ColorBlindMode.none);
      expect(accessSystem.fontScale, 1.0);
      expect(accessSystem.highContrast, false);
      expect(accessSystem.screenShakeEnabled, true);
      expect(accessSystem.flashEffectsEnabled, true);
    });

    test('setColorBlindMode changes mode and calls callback', () {
      int callCount = 0;
      accessSystem.onSettingsChanged = () => callCount++;

      accessSystem.setColorBlindMode(ColorBlindMode.protanopia);

      expect(accessSystem.colorBlindMode, ColorBlindMode.protanopia);
      expect(callCount, 1);
    });

    test('setFontScale clamps to 0.8-1.5', () {
      accessSystem.setFontScale(0.5);
      expect(accessSystem.fontScale, 0.8);

      accessSystem.setFontScale(2.0);
      expect(accessSystem.fontScale, 1.5);

      accessSystem.setFontScale(1.2);
      expect(accessSystem.fontScale, 1.2);
    });

    test('setHighContrast changes value and calls callback', () {
      int callCount = 0;
      accessSystem.onSettingsChanged = () => callCount++;

      accessSystem.setHighContrast(true);

      expect(accessSystem.highContrast, true);
      expect(callCount, 1);
    });

    test('serialize and deserialize round-trip', () {
      accessSystem.setColorBlindMode(ColorBlindMode.deuteranopia);
      accessSystem.setFontScale(1.3);
      accessSystem.setHighContrast(true);
      accessSystem.setScreenShake(false);
      accessSystem.setFlashEffects(false);

      final data = accessSystem.serialize();
      final newSystem = AccessibilitySystem();
      newSystem.deserialize(data);

      expect(newSystem.colorBlindMode, ColorBlindMode.deuteranopia);
      expect(newSystem.fontScale, 1.3);
      expect(newSystem.highContrast, true);
      expect(newSystem.screenShakeEnabled, false);
      expect(newSystem.flashEffectsEnabled, false);
    });

    test('canShakeScreen and canFlash return settings', () {
      expect(accessSystem.canShakeScreen(), true);
      expect(accessSystem.canFlash(), true);

      accessSystem.setScreenShake(false);
      accessSystem.setFlashEffects(false);

      expect(accessSystem.canShakeScreen(), false);
      expect(accessSystem.canFlash(), false);
    });
  });

  group('AudioManager', () {
    late AudioManager audioManager;

    setUp(() {
      audioManager = AudioManager();
    });

    test('playBgm sets current and calls callback', () {
      String? calledTrack;
      audioManager.onBgmChanged = (track) => calledTrack = track;

      audioManager.playBgm('battle_theme');

      expect(audioManager.currentBgm, 'battle_theme');
      expect(audioManager.isBgmPlaying, true);
      expect(calledTrack, 'battle_theme');
    });

    test('playBgm skips if same track already playing', () {
      int callCount = 0;
      audioManager.onBgmChanged = (track) => callCount++;

      audioManager.playBgm('battle_theme');
      expect(callCount, 1);

      audioManager.playBgm('battle_theme');
      expect(callCount, 1);
    });

    test('stopBgm clears state', () {
      audioManager.playBgm('battle_theme');
      audioManager.stopBgm();

      expect(audioManager.isBgmPlaying, false);
      expect(audioManager.currentBgm, '');
    });

    test('playSfx uses available channel', () {
      final playedSfx = <String>[];
      audioManager.onSfxPlayed = (sfx) => playedSfx.add(sfx);

      audioManager.playSfx('sword_hit');
      audioManager.playSfx('magic_cast');

      expect(playedSfx.length, 2);
      expect(playedSfx[0], 'sword_hit');
      expect(playedSfx[1], 'magic_cast');
    });

    test('stopAllSfx clears all channels', () {
      audioManager.playSfx('sfx1');
      audioManager.playSfx('sfx2');
      audioManager.playSfx('sfx3');

      audioManager.stopAllSfx();
      expect(audioManager.isBgmPlaying, false);
    });

    test('setMasterVolume clamps to 0.0-1.0', () {
      audioManager.setMasterVolume(-0.5);
      expect(audioManager.masterVolume, 0.0);

      audioManager.setMasterVolume(2.0);
      expect(audioManager.masterVolume, 1.0);

      audioManager.setMasterVolume(0.7);
      expect(audioManager.masterVolume, 0.7);
    });

    test('getEffectiveBgmVolume multiplies master and bgm', () {
      audioManager.setMasterVolume(0.8);
      audioManager.setBgmVolume(0.5);

      expect(audioManager.getEffectiveBgmVolume(), 0.4);

      audioManager.setMasterVolume(1.0);
      expect(audioManager.getEffectiveBgmVolume(), 0.5);
    });

    test('serialize and deserialize round-trip', () {
      audioManager.setMasterVolume(0.9);
      audioManager.setBgmVolume(0.7);
      audioManager.setSfxVolume(0.6);

      final data = audioManager.serialize();
      final newManager = AudioManager();
      newManager.deserialize(data);

      expect(newManager.masterVolume, 0.9);
      expect(newManager.bgmVolume, 0.7);
      expect(newManager.sfxVolume, 0.6);
    });
  });
}
