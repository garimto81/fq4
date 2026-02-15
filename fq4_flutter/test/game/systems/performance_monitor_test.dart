import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/systems/performance_monitor.dart';

void main() {
  group('PerformanceMonitor', () {
    test('initial FPS values are 60', () {
      final monitor = PerformanceMonitor();

      expect(monitor.currentFps, 60);
      expect(monitor.minFps, 60);
      expect(monitor.avgFps, 60);
    });

    test('initial AI tick values are 0', () {
      final monitor = PerformanceMonitor();

      expect(monitor.lastAiTickMs, 0);
      expect(monitor.maxAiTickMs, 0);
      expect(monitor.p99AiTickMs, 0);
    });

    test('initial query count is 0', () {
      final monitor = PerformanceMonitor();

      expect(monitor.queriesPerSecond, 0);
    });

    test('update with dt=0 does nothing', () {
      final monitor = PerformanceMonitor();

      monitor.update(0);

      expect(monitor.currentFps, 60);
      expect(monitor.minFps, 60);
      expect(monitor.avgFps, 60);
    });

    test('update calculates FPS after 0.5s timer', () {
      final monitor = PerformanceMonitor();

      // Single update with dt=0.5 triggers the FPS calculation
      monitor.update(0.5);

      // FPS = 1.0 / 0.5 = 2.0
      expect(monitor.currentFps, closeTo(2.0, 0.01));
      // avgFps is also based on the single frame time of 0.5
      expect(monitor.avgFps, closeTo(2.0, 0.01));
    });

    test('update tracks min FPS correctly', () {
      final monitor = PerformanceMonitor();

      // First update: triggers FPS calc (dt=0.5 -> FPS 2.0, below initial 60)
      monitor.update(0.5);
      expect(monitor.minFps, closeTo(2.0, 0.01));

      // Second update: higher FPS frame but need to trigger calc again
      // Accumulate 0.25 + 0.25 = 0.5 to trigger
      monitor.update(0.25);
      monitor.update(0.25);

      // minFps should stay at the lowest seen
      expect(monitor.minFps, closeTo(2.0, 0.01));
    });

    test('recordAiTick updates lastAiTickMs', () {
      final monitor = PerformanceMonitor();

      monitor.recordAiTick(5.0);

      expect(monitor.lastAiTickMs, 5.0);
    });

    test('recordAiTick tracks max AI tick', () {
      final monitor = PerformanceMonitor();

      monitor.recordAiTick(3.0);
      monitor.recordAiTick(7.0);
      monitor.recordAiTick(5.0);

      expect(monitor.maxAiTickMs, 7.0);
    });

    test('recordAiTick calculates P99 after 10+ samples', () {
      final monitor = PerformanceMonitor();

      // Record 9 samples - P99 should still be 0
      for (int i = 1; i <= 9; i++) {
        monitor.recordAiTick(i.toDouble());
      }
      expect(monitor.p99AiTickMs, 0);

      // 10th sample triggers P99 calculation
      monitor.recordAiTick(10.0);

      expect(monitor.p99AiTickMs, greaterThan(0));
      // With values 1..10, sorted = [1,2,...,10], idx = (10*0.99).floor() = 9
      // sorted[9] = 10.0
      expect(monitor.p99AiTickMs, 10.0);
    });

    test('recordQuery increments counter and queriesPerSecond updates', () {
      final monitor = PerformanceMonitor();

      monitor.recordQuery();
      monitor.recordQuery();
      monitor.recordQuery();

      // queriesPerSecond is only updated after 1s timer in update()
      expect(monitor.queriesPerSecond, 0);

      // Trigger the 1s timer
      monitor.update(1.0);

      expect(monitor.queriesPerSecond, 3);
    });

    test('reset clears all values back to initial state', () {
      final monitor = PerformanceMonitor();

      // Modify all values
      monitor.update(0.5);
      monitor.recordAiTick(10.0);
      monitor.recordQuery();
      monitor.allyCount = 5;
      monitor.enemyCount = 10;

      monitor.reset();

      expect(monitor.currentFps, 60);
      expect(monitor.minFps, 60);
      expect(monitor.avgFps, 60);
      expect(monitor.lastAiTickMs, 0);
      expect(monitor.maxAiTickMs, 0);
      expect(monitor.p99AiTickMs, 0);
      expect(monitor.queriesPerSecond, 0);
      expect(monitor.allyCount, 0);
      expect(monitor.enemyCount, 0);
    });

    test('toMap returns correct keys and values', () {
      final monitor = PerformanceMonitor();
      monitor.allyCount = 3;
      monitor.enemyCount = 7;

      final map = monitor.toMap();

      expect(map['fps'], 60.0);
      expect(map['minFps'], 60.0);
      expect(map['avgFps'], 60.0);
      expect(map['aiTickMs'], 0.0);
      expect(map['maxAiTickMs'], 0.0);
      expect(map['p99AiTickMs'], 0.0);
      expect(map['queriesPerSec'], 0);
      expect(map['allyCount'], 3);
      expect(map['enemyCount'], 7);
      expect(map.length, 9);
    });

    test('allyCount and enemyCount can be set and read', () {
      final monitor = PerformanceMonitor();

      monitor.allyCount = 12;
      monitor.enemyCount = 25;

      expect(monitor.allyCount, 12);
      expect(monitor.enemyCount, 25);
    });
  });
}
