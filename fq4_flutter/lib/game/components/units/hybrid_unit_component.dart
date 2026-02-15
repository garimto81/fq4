import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../../systems/combat_system.dart';
import '../../systems/fatigue_system.dart';
import 'ai_unit_component.dart';
import 'unit_component.dart';

/// Gocha-Kyara 하이브리드 유닛: AI 자동전투 + 수동 조작 전환
///
/// 기본 상태: AI 자동전투 (isPlayerControlled = false)
/// WASD/방향키 입력 시: 수동 모드 전환 (3초 타이머 시작)
/// 3초간 입력 없으면: AI 자동전투로 자동 복귀
class HybridUnitComponent extends AIUnitComponent with KeyboardHandler {
  HybridUnitComponent({
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
    super.isPlayerSide,
  }) {
    isPlayerControlled = false;
  }

  /// 수동 모드 자동 복귀 타이머 (3초)
  double _autoRevertTimer = 0;
  static const double _revertDuration = 3.0;

  /// 수동 모드 이동 속도 (PlayerUnitComponent와 동일)
  static const double _manualMoveSpeed = 150.0;

  /// 현재 수동 모드 여부
  bool get isInManualMode => _autoRevertTimer > 0;

  /// 자동 복귀까지 남은 시간
  double get autoRevertRemaining => _autoRevertTimer;

  /// 입력 상태 추적
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  /// 유닛 전환 콜백 (외부에서 바인딩)
  Function()? onSwitchPrev; // Q키
  Function()? onSwitchNext; // E키

  /// Control proxy: WASD 이동/자동공격을 다른 유닛에 적용
  /// null이면 자기 자신을 제어
  UnitComponent? controlProxy;

  /// 자동 공격 쿨다운 (Space 없이 적 감지 시 자동 공격)
  double _autoAttackTimer = 0;
  static const double _autoAttackInterval = 0.15;

  /// 입력 지연 측정
  final List<double> _inputLatencies = [];
  Stopwatch? _inputStopwatch;
  Vector2? _lastPositionForLatency;

  /// 평균 입력 지연 (ms)
  double get averageInputLatency => _inputLatencies.isEmpty
      ? 0
      : _inputLatencies.reduce((a, b) => a + b) / _inputLatencies.length;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return false; // 다른 핸들러도 처리 가능
  }

  @override
  void update(double dt) {
    if (isDead) {
      super.update(dt);
      return;
    }

    // Proxy가 설정된 경우: 이 유닛은 AI로 동작하고, 입력은 proxy에 적용
    final proxy = controlProxy;
    final hasProxy = proxy != null && !proxy.isDead;

    // 자동 복귀 타이머 감소 (proxy 없을 때만)
    if (!hasProxy && _autoRevertTimer > 0) {
      _autoRevertTimer -= dt;
      if (_autoRevertTimer <= 0) {
        _autoRevertTimer = 0;
        isPlayerControlled = false;
        moveTarget = null;
        velocity = Vector2.zero();
        state = UnitState.idle;
      }
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

    bool hasMovementInput = direction.length > 0;

    if (hasProxy) {
      // === Proxy 모드: 입력을 proxy 유닛에 적용 ===
      if (hasMovementInput) {
        direction.normalize();
        final speedMult = FatigueSystem().getSpeedMultiplier(proxy.fatigue);
        proxy.velocity = direction * _manualMoveSpeed * speedMult;
        proxy.position += proxy.velocity * dt;
        proxy.state = UnitState.moving;
      } else if (proxy.state == UnitState.moving) {
        proxy.velocity = Vector2.zero();
        proxy.state = UnitState.idle;
      }

      // Proxy 자동 공격
      _autoAttackTimer += dt;
      if (_autoAttackTimer >= _autoAttackInterval) {
        _autoAttackTimer = 0;
        _autoAttackForUnit(proxy);
      }

      // 이 유닛 자신은 AI로 동작 (isPlayerControlled = false)
    } else {
      // === 직접 제어 모드 ===
      if (hasMovementInput) {
        if (!isPlayerControlled) {
          _inputStopwatch = Stopwatch()..start();
          _lastPositionForLatency = position.clone();
        }
        isPlayerControlled = true;
        _autoRevertTimer = _revertDuration;

        direction.normalize();
        final speedMult = FatigueSystem().getSpeedMultiplier(fatigue);
        velocity = direction * _manualMoveSpeed * speedMult;
        position += velocity * dt;
        state = UnitState.moving;
        fatigue = FatigueSystem().addMoveFatigue(fatigue, (velocity * dt).length);
        _measureInputLatency();
      } else if (isPlayerControlled && _autoRevertTimer > 0) {
        if (state == UnitState.moving) {
          velocity = Vector2.zero();
          state = UnitState.idle;
        }
      }

      // 자동 공격 (Space 없이도 범위 내 적 자동 공격)
      if (isPlayerControlled) {
        _autoAttackTimer += dt;
        if (_autoAttackTimer >= _autoAttackInterval) {
          _autoAttackTimer = 0;
          _autoAttackForUnit(this);
        }
      }
    }

    // Q/E 키: 유닛 전환
    if (_pressedKeys.contains(LogicalKeyboardKey.keyQ)) {
      onSwitchPrev?.call();
      _pressedKeys.remove(LogicalKeyboardKey.keyQ);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyE)) {
      onSwitchNext?.call();
      _pressedKeys.remove(LogicalKeyboardKey.keyE);
    }

    // super.update(dt) → UnitComponent 상태머신 + AI 로직
    // Proxy 모드에서는 이 유닛의 AI가 정상 동작
    super.update(dt);
  }

  /// 유닛의 위치 기준 가장 가까운 적 자동 공격 (Space 불필요)
  void _autoAttackForUnit(UnitComponent target) {
    final bc = battleController;
    final cs = combatSystem;
    if (bc == null || cs == null) return;
    if (target.isDead || target.attackCooldown > 0) return;

    final enemy = bc.findNearestEnemy(target.position, target.isPlayerSide);
    if (enemy == null || enemy.isDead) return;

    final dist = target.position.distanceTo(enemy.position);
    if (dist > 60) return; // 공격 사거리

    if (!target.tryAttack()) return;

    final result = cs.executeAttack(
      attacker: target.toUnitStats(),
      target: enemy.toUnitStats(),
    );

    final isMiss = result.hitResult == HitResult.miss ||
        result.hitResult == HitResult.evade;

    if (!isMiss) {
      enemy.takeDamage(result.damage);
    }

    bc.logAttack(
        target.unitName, enemy.unitName, result.damage, result.isCritical, isMiss);

    if (enemy.isDead) {
      bc.logDeath(enemy.unitName, !target.isPlayerSide);
    }
  }

  /// 입력 지연 측정
  void _measureInputLatency() {
    final sw = _inputStopwatch;
    final lastPos = _lastPositionForLatency;
    if (sw != null && lastPos != null) {
      if (position.distanceTo(lastPos) > 0.1) {
        final latencyMs = sw.elapsedMicroseconds / 1000.0;
        _inputLatencies.add(latencyMs);
        // 최근 100개만 유지
        if (_inputLatencies.length > 100) {
          _inputLatencies.removeAt(0);
        }
        _inputStopwatch = null;
        _lastPositionForLatency = null;
      }
    }
  }

  /// 수동 모드 강제 활성화 (외부에서 제어 부여 시 호출)
  void activateManualControl() {
    isPlayerControlled = true;
    _autoRevertTimer = _revertDuration;
  }

  /// 수동 모드 강제 해제 (유닛 전환 시 호출)
  void releaseManualControl() {
    isPlayerControlled = false;
    _autoRevertTimer = 0;
    moveTarget = null;
    velocity = Vector2.zero();
    if (state == UnitState.moving) {
      state = UnitState.idle;
    }
    _pressedKeys.clear();
  }
}
