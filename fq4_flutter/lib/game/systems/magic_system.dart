// 마법 시스템 (Godot magic_system.gd에서 이식)

import '../../core/constants/spell_constants.dart';

/// 마법 시전 결과
class CastResult {
  final bool success;
  final String reason;
  final List<int> targets;

  const CastResult({
    required this.success,
    required this.reason,
    this.targets = const [],
  });
}

/// 마법 시전 가능 여부 결과
class CanCastResult {
  final bool canCast;
  final String reason;

  const CanCastResult({
    required this.canCast,
    required this.reason,
  });
}

/// 마법 시스템 (순수 Dart 클래스)
class MagicSystem {
  // 쿨다운 상태: unitId -> {spellId -> remainingTime}
  final Map<int, Map<String, double>> _cooldowns = {};

  // 콜백
  Function(int casterId, SpellData spell, List<int> targets)? onSpellCast;
  Function(int casterId, SpellData spell, String reason)? onSpellFailed;
  Function(int unitId, int mpChange)? onMpChanged;

  /// 마법 시전 시도
  CastResult castSpell({
    required int casterId,
    required int casterMp,
    required SpellData spell,
    int? targetId,
    List<int>? areaTargets,
  }) {
    // 시전 가능 여부 확인
    final canCastResult = canCast(
      casterMp: casterMp,
      spell: spell,
      casterId: casterId,
    );

    if (!canCastResult.canCast) {
      onSpellFailed?.call(casterId, spell, canCastResult.reason);
      return CastResult(
        success: false,
        reason: canCastResult.reason,
      );
    }

    // 타겟 결정
    final List<int> targets;
    switch (spell.target) {
      case SpellTarget.self:
        targets = [casterId];
        break;
      case SpellTarget.singleAlly:
      case SpellTarget.singleEnemy:
        if (targetId == null) {
          final reason = 'No target specified';
          onSpellFailed?.call(casterId, spell, reason);
          return CastResult(success: false, reason: reason);
        }
        targets = [targetId];
        break;
      case SpellTarget.area:
      case SpellTarget.allAllies:
      case SpellTarget.allEnemies:
        targets = areaTargets ?? [];
        if (targets.isEmpty) {
          final reason = 'No area targets specified';
          onSpellFailed?.call(casterId, spell, reason);
          return CastResult(success: false, reason: reason);
        }
        break;
    }

    // MP 소모
    onMpChanged?.call(casterId, -spell.mpCost);

    // 쿨다운 시작
    startCooldown(casterId, spell);

    // 시전 성공 콜백
    onSpellCast?.call(casterId, spell, targets);

    return CastResult(
      success: true,
      reason: 'Cast successful',
      targets: targets,
    );
  }

  /// 마법 시전 가능 여부 확인
  CanCastResult canCast({
    required int casterMp,
    required SpellData spell,
    required int casterId,
  }) {
    // MP 체크
    if (casterMp < spell.mpCost) {
      return const CanCastResult(
        canCast: false,
        reason: 'Not enough MP',
      );
    }

    // 쿨다운 체크
    if (isOnCooldown(casterId, spell.id)) {
      final remaining = getCooldownRemaining(casterId, spell.id);
      return CanCastResult(
        canCast: false,
        reason: 'On cooldown (${remaining.toStringAsFixed(1)}s)',
      );
    }

    return const CanCastResult(
      canCast: true,
      reason: 'Can cast',
    );
  }

  /// 쿨다운 업데이트 (매 프레임 호출)
  void updateCooldowns(double dt) {
    final unitsToRemove = <int>[];

    for (final entry in _cooldowns.entries) {
      final unitId = entry.key;
      final spellCooldowns = entry.value;
      final spellsToRemove = <String>[];

      for (final spellEntry in spellCooldowns.entries) {
        final spellId = spellEntry.key;
        final remaining = spellEntry.value;

        final newRemaining = remaining - dt;
        if (newRemaining <= 0) {
          spellsToRemove.add(spellId);
        } else {
          spellCooldowns[spellId] = newRemaining;
        }
      }

      // 만료된 쿨다운 제거
      for (final spellId in spellsToRemove) {
        spellCooldowns.remove(spellId);
      }

      // 모든 쿨다운이 만료된 유닛 제거
      if (spellCooldowns.isEmpty) {
        unitsToRemove.add(unitId);
      }
    }

    // 빈 유닛 엔트리 제거
    for (final unitId in unitsToRemove) {
      _cooldowns.remove(unitId);
    }
  }

  /// 쿨다운 시작
  void startCooldown(int casterId, SpellData spell) {
    if (spell.cooldown <= 0) return;

    _cooldowns.putIfAbsent(casterId, () => {});
    _cooldowns[casterId]![spell.id] = spell.cooldown;
  }

  /// 쿨다운 중인지 확인
  bool isOnCooldown(int casterId, String spellId) {
    return _cooldowns[casterId]?.containsKey(spellId) ?? false;
  }

  /// 남은 쿨다운 시간 조회
  double getCooldownRemaining(int casterId, String spellId) {
    return _cooldowns[casterId]?[spellId] ?? 0.0;
  }

  /// 유닛의 모든 쿨다운 제거 (사망, 리셋 시)
  void clearCooldowns(int unitId) {
    _cooldowns.remove(unitId);
  }

  /// 전체 쿨다운 초기화
  void reset() {
    _cooldowns.clear();
  }
}
