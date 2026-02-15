import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../game/components/units/rive_unit_renderer.dart';

/// POC-1: Rive + Flame 렌더링 통합 테스트
class RiveTestGame extends FlameGame with TapCallbacks {
  static const double viewWidth = 800;
  static const double viewHeight = 1280;

  final List<RiveUnitRenderer> _units = [];
  int _tapCount = 0;
  double _fps = 0;
  double _fpsTimer = 0;
  int _frameCount = 0;
  String statusMessage = 'Tap: cycle states | Long press: spawn 6 units';
  bool _multiSpawned = false;

  // Callback for Flutter UI
  void Function(String status, double fps)? onStatusUpdate;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(viewWidth, viewHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    // Spawn 1 unit at center
    await _spawnUnit(
      Vector2(viewWidth / 2 - 24, viewHeight / 2 - 24),
      const Color(0xFF4488FF),
      'Ares',
    );
  }

  Future<RiveUnitRenderer> _spawnUnit(Vector2 pos, Color color, String label) async {
    final unit = RiveUnitRenderer(
      position: pos,
      size: Vector2(48, 48),
      unitColor: color,
      label: label,
    );
    await world.add(unit);
    _units.add(unit);

    // Try to load Rive (will fail gracefully → fallback)
    await unit.tryLoadRive('assets/rive/characters/warrior_placeholder.riv');

    return unit;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // FPS counter
    _frameCount++;
    _fpsTimer += dt;
    if (_fpsTimer >= 1.0) {
      _fps = _frameCount / _fpsTimer;
      _frameCount = 0;
      _fpsTimer = 0;
      onStatusUpdate?.call(statusMessage, _fps);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _tapCount++;
    final stateIndex = _tapCount % 5;

    for (final unit in _units) {
      unit.setAnimState(stateIndex);
    }

    final stateName = RiveUnitRenderer.stateNames[stateIndex];
    statusMessage = 'State: $stateName (${_units.length} units)';
    onStatusUpdate?.call(statusMessage, _fps);
  }

  /// Spawn 6 units for performance test
  Future<void> spawnMultipleUnits() async {
    if (_multiSpawned) return;
    _multiSpawned = true;

    final colors = [
      const Color(0xFF44FF44), const Color(0xFFFF4444),
      const Color(0xFFFFFF44), const Color(0xFF44FFFF),
      const Color(0xFFFF44FF),
    ];
    final names = ['Taro', 'Goblin1', 'Goblin2', 'Alein', 'Knight'];

    for (int i = 0; i < 5; i++) {
      final x = 150.0 + (i % 3) * 200;
      final y = viewHeight / 2 - 100 + (i ~/ 3) * 150;
      await _spawnUnit(Vector2(x, y), colors[i], names[i]);
    }

    statusMessage = '6 units spawned - tap to cycle states';
    onStatusUpdate?.call(statusMessage, _fps);
  }

  /// Get current FPS
  double get currentFps => _fps;
  int get unitCount => _units.length;
}
