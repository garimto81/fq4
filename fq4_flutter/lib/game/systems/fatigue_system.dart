import 'dart:math';

import '../../core/constants/fatigue_constants.dart';

/// 피로도 시스템 (Godot fatigue_system.gd에서 이식)
class FatigueSystem {
  /// 피로도 증가 (공격)
  double addAttackFatigue(double current) {
    return min(100.0, current + FatigueConstants.fatigueAttack);
  }

  /// 피로도 증가 (스킬/마법)
  double addSkillFatigue(double current) {
    return min(100.0, current + FatigueConstants.fatigueSkill);
  }

  /// 피로도 증가 (이동)
  double addMoveFatigue(double current, double distance) {
    final increase = distance * FatigueConstants.fatigueMovePerUnit;
    return min(100.0, current + increase);
  }

  /// 피로도 회복 (프레임별)
  double recover(double current, double dt, {required bool isResting}) {
    final rate = isResting
        ? FatigueConstants.recoveryRest
        : FatigueConstants.recoveryIdle;
    return max(0.0, current - rate * dt);
  }

  /// 아이템으로 피로도 회복
  double recoverByItem(double current) {
    return max(0.0, current - FatigueConstants.recoveryItem);
  }

  /// 현재 피로도 단계
  FatigueLevel getLevel(double fatigue) {
    return FatigueLevel.fromValue(fatigue);
  }

  /// 이동속도 배율
  double getSpeedMultiplier(double fatigue) {
    return FatigueLevel.fromValue(fatigue).speedMult;
  }

  /// 공격력 배율
  double getAttackMultiplier(double fatigue) {
    return FatigueLevel.fromValue(fatigue).attackMult;
  }

  /// 행동 가능 여부
  bool canAct(double fatigue) {
    return FatigueLevel.fromValue(fatigue).canAct;
  }
}
