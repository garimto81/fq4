import 'dart:math';

import '../../core/constants/combat_constants.dart';
import '../../core/constants/fatigue_constants.dart';

/// 전투 시스템 (Godot combat_system.gd에서 이식)
class CombatSystem {
  final Random _random = Random();

  /// 공격 실행
  AttackResult executeAttack({
    required UnitStats attacker,
    required UnitStats target,
  }) {
    // 명중 판정
    final hitResult = _calculateHit(attacker, target);
    if (hitResult == HitResult.miss) {
      return AttackResult(hitResult: HitResult.miss, damage: 0);
    }
    if (hitResult == HitResult.evade) {
      return AttackResult(hitResult: HitResult.evade, damage: 0);
    }

    // 데미지 계산
    final damageResult = calculateDamage(attacker, target);

    return AttackResult(
      hitResult: damageResult.isCritical ? HitResult.critical : HitResult.hit,
      damage: damageResult.finalDamage,
      isCritical: damageResult.isCritical,
    );
  }

  /// 명중/회피 판정
  HitResult _calculateHit(UnitStats attacker, UnitStats target) {
    // 명중 판정
    final hitChance = CombatConstants.baseHitChance +
        (attacker.luck * 0.01);
    if (_random.nextDouble() > hitChance) return HitResult.miss;

    // 회피 판정
    final evasionChance = CombatConstants.baseEvasion +
        (target.speed * 0.001) +
        (target.luck * 0.005) +
        target.equipmentEvasion;
    if (_random.nextDouble() < evasionChance) return HitResult.evade;

    return HitResult.hit;
  }

  /// 데미지 계산
  DamageResult calculateDamage(UnitStats attacker, UnitStats target) {
    double baseDamage = attacker.attack.toDouble();

    // 크리티컬 판정
    final critChance = CombatConstants.criticalHitChance +
        (attacker.luck * 0.005) +
        attacker.equipmentCritBonus;
    final isCritical = _random.nextDouble() < critChance;
    if (isCritical) {
      baseDamage *= CombatConstants.criticalHitMultiplier;
    }

    // 데미지 분산 +-10%
    final variance = 1.0 +
        (_random.nextDouble() * 2 - 1) * CombatConstants.baseDamageVariance;
    baseDamage *= variance;

    // 방어력 적용
    int finalDamage = max(CombatConstants.minDamage,
        (baseDamage - target.defense).round());

    // 피로도 배율 적용
    final fatigueLevel = FatigueLevel.fromValue(attacker.fatigue);
    finalDamage = (finalDamage * fatigueLevel.attackMult).round();
    finalDamage = max(CombatConstants.minDamage, finalDamage);

    return DamageResult(
      baseDamage: baseDamage.round(),
      finalDamage: finalDamage,
      isCritical: isCritical,
    );
  }

  /// 적 처치 경험치 계산
  int calculateKillExp({
    required int enemyLevel,
    required int killerLevel,
    required EnemyType enemyType,
  }) {
    int baseExp = 10 + (enemyLevel * 5);

    // 타입 배율
    final typeMult = switch (enemyType) {
      EnemyType.normal => 1.0,
      EnemyType.elite => 2.0,
      EnemyType.boss => 5.0,
    };
    baseExp = (baseExp * typeMult).round();

    // 레벨 차이 보정
    final diff = enemyLevel - killerLevel;
    double levelMult = 1.0;
    if (diff < -5) {
      levelMult = max(0.1, 1.0 + diff * 0.1);
    } else if (diff > 5) {
      levelMult = min(2.0, 1.0 + diff * 0.05);
    }

    return (baseExp * levelMult).round();
  }

  /// 골드 보상 계산
  int calculateGoldReward(int enemyMaxHp) {
    return CombatConstants.baseGoldReward +
        (enemyMaxHp ~/ CombatConstants.goldPerHpDivisor);
  }
}

/// 유닛 전투 스탯 인터페이스
class UnitStats {
  final int attack;
  final int defense;
  final int speed;
  final int luck;
  final double fatigue;
  final double equipmentEvasion;
  final double equipmentCritBonus;

  const UnitStats({
    required this.attack,
    required this.defense,
    required this.speed,
    required this.luck,
    this.fatigue = 0,
    this.equipmentEvasion = 0,
    this.equipmentCritBonus = 0,
  });
}

enum HitResult { hit, miss, evade, critical }
enum EnemyType { normal, elite, boss }

class AttackResult {
  final HitResult hitResult;
  final int damage;
  final bool isCritical;

  const AttackResult({
    required this.hitResult,
    required this.damage,
    this.isCritical = false,
  });
}

class DamageResult {
  final int baseDamage;
  final int finalDamage;
  final bool isCritical;

  const DamageResult({
    required this.baseDamage,
    required this.finalDamage,
    required this.isCritical,
  });
}
