import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../../systems/fatigue_system.dart';
import 'ai_unit_component.dart';
import 'unit_component.dart';

/// 플레이어 직접 조작 유닛 (Godot player_unit.gd 이식)
class PlayerUnitComponent extends AIUnitComponent with KeyboardHandler {
  PlayerUnitComponent({
    required super.unitName,
    required super.maxHp,
    required super.maxMp,
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.level,
    super.position,
    super.personality,
    super.formation,
  }) : super(isPlayerSide: true) {
    isPlayerControlled = true;
  }

  // 입력 상태
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return false; // 다른 핸들러도 처리
  }

  @override
  void update(double dt) {
    if (isDead) {
      super.update(dt);
      return;
    }

    // 키보드 이동 처리
    final direction = Vector2.zero();
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }

    if (direction.length > 0) {
      direction.normalize();
      final speedMult = FatigueSystem().getSpeedMultiplier(fatigue);
      velocity = direction * speed.toDouble() * speedMult;
      position += velocity * dt;
      state = UnitState.moving;
      fatigue = FatigueSystem().addMoveFatigue(fatigue, (velocity * dt).length);
    } else if (state == UnitState.moving) {
      velocity = Vector2.zero();
      state = UnitState.idle;
    }

    // 공격 키 (Space)
    if (_pressedKeys.contains(LogicalKeyboardKey.space)) {
      tryAttack();
    }

    super.update(dt);
  }
}
