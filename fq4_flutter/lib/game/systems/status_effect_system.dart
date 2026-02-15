// 상태이상 시스템 (Godot status_effect_system.gd에서 이식)

import '../../core/constants/status_effect_constants.dart';

/// 활성 상태이상 데이터
class ActiveEffect {
  final StatusEffectType effectType;
  double remainingTime;
  double tickTimer;

  ActiveEffect({
    required this.effectType,
    required this.remainingTime,
    this.tickTimer = 0.0,
  });
}

/// 상태이상 시스템 (순수 Dart 클래스)
class StatusEffectSystem {
  // 활성 상태이상: unitId -> List<ActiveEffect>
  final Map<int, List<ActiveEffect>> _activeEffects = {};

  // 콜백
  Function(int unitId, StatusEffectType effectType)? onEffectApplied;
  Function(int unitId, StatusEffectType effectType)? onEffectRemoved;
  Function(int unitId, StatusEffectType effectType, int damage)? onEffectTick;

  /// 상태이상 적용
  bool applyEffect(int unitId, StatusEffectType effectType) {
    _activeEffects.putIfAbsent(unitId, () => []);

    // 기존 효과 확인 (중복 시 시간 갱신)
    final existingIndex = _activeEffects[unitId]!
        .indexWhere((e) => e.effectType == effectType);

    if (existingIndex != -1) {
      // 시간 갱신
      _activeEffects[unitId]![existingIndex].remainingTime =
          effectType.duration;
      _activeEffects[unitId]![existingIndex].tickTimer = 0.0;
      return false; // 중복 적용
    }

    // 새 효과 추가
    _activeEffects[unitId]!.add(ActiveEffect(
      effectType: effectType,
      remainingTime: effectType.duration,
      tickTimer: 0.0,
    ));

    onEffectApplied?.call(unitId, effectType);
    return true;
  }

  /// 상태이상 제거
  void removeEffect(int unitId, StatusEffectType effectType) {
    final effects = _activeEffects[unitId];
    if (effects == null) return;

    final hadEffect = effects.any((e) => e.effectType == effectType);
    effects.removeWhere((e) => e.effectType == effectType);
    if (hadEffect) {
      onEffectRemoved?.call(unitId, effectType);
    }

    // 빈 리스트 제거
    if (effects.isEmpty) {
      _activeEffects.remove(unitId);
    }
  }

  /// 유닛의 모든 상태이상 제거
  void removeAllEffects(int unitId) {
    final effects = _activeEffects[unitId];
    if (effects == null) return;

    for (final effect in effects) {
      onEffectRemoved?.call(unitId, effect.effectType);
    }

    _activeEffects.remove(unitId);
  }

  /// 특정 상태이상 보유 여부
  bool hasEffect(int unitId, StatusEffectType effectType) {
    final effects = _activeEffects[unitId];
    if (effects == null) return false;
    return effects.any((e) => e.effectType == effectType);
  }

  /// 활성 상태이상 목록 조회
  List<StatusEffectType> getActiveEffects(int unitId) {
    final effects = _activeEffects[unitId];
    if (effects == null) return [];
    return effects.map((e) => e.effectType).toList();
  }

  /// 상태이상 업데이트 (매 프레임 호출)
  void update(double dt) {
    final unitsToRemove = <int>[];

    for (final entry in _activeEffects.entries) {
      final unitId = entry.key;
      final effects = entry.value;
      final effectsToRemove = <ActiveEffect>[];

      for (final effect in effects) {
        // 시간 감소
        effect.remainingTime -= dt;

        // Tick 데미지 처리 (POISON, BURN)
        if (effect.effectType.tickDamage > 0) {
          effect.tickTimer += dt;
          if (effect.tickTimer >= effect.effectType.tickInterval) {
            effect.tickTimer -= effect.effectType.tickInterval;
            onEffectTick?.call(
              unitId,
              effect.effectType,
              effect.effectType.tickDamage,
            );
          }
        }

        // 만료 확인
        if (effect.remainingTime <= 0) {
          effectsToRemove.add(effect);
        }
      }

      // 만료된 효과 제거
      for (final effect in effectsToRemove) {
        effects.remove(effect);
        onEffectRemoved?.call(unitId, effect.effectType);
      }

      // 빈 리스트 제거
      if (effects.isEmpty) {
        unitsToRemove.add(unitId);
      }
    }

    // 빈 유닛 엔트리 제거
    for (final unitId in unitsToRemove) {
      _activeEffects.remove(unitId);
    }
  }

  /// 속도 배율 계산 (모든 활성 효과의 speedMult 곱)
  double getSpeedModifier(int unitId) {
    final effects = _activeEffects[unitId];
    if (effects == null || effects.isEmpty) return 1.0;

    double modifier = 1.0;
    for (final effect in effects) {
      modifier *= effect.effectType.speedMult;
    }
    return modifier;
  }

  /// 행동 가능 여부 (STUN, FREEZE 체크)
  bool canAct(int unitId) {
    final effects = _activeEffects[unitId];
    if (effects == null || effects.isEmpty) return true;

    for (final effect in effects) {
      if (!effect.effectType.canAct) return false;
    }
    return true;
  }

  /// 탐지 범위 배율 (BLIND 체크)
  double getDetectionModifier(int unitId) {
    final effects = _activeEffects[unitId];
    if (effects == null || effects.isEmpty) return 1.0;

    double modifier = 1.0;
    for (final effect in effects) {
      modifier *= effect.effectType.detectionMult;
    }
    return modifier;
  }

  /// 전체 초기화
  void reset() {
    _activeEffects.clear();
  }
}
