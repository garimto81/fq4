import '../../core/constants/level_constants.dart';

// 경험치 시스템 (Godot experience_system.gd에서 이식)
class ExperienceSystem {
  int currentLevel;
  int currentExp;
  int totalExp;

  Function(int amount)? onExpGained;
  Function(LevelUpResult result)? onLevelUp;

  ExperienceSystem({
    this.currentLevel = 1,
    this.currentExp = 0,
    this.totalExp = 0,
    this.onExpGained,
    this.onLevelUp,
  });

  /// 경험치 획득 및 레벨업 처리
  LevelUpResult gainExp(int amount) {
    if (currentLevel >= LevelConstants.maxLevel) {
      return LevelUpResult(
        levelUps: 0,
        oldLevel: currentLevel,
        newLevel: currentLevel,
        statGains: {},
      );
    }

    currentExp += amount;
    totalExp += amount;
    onExpGained?.call(amount);

    final oldLevel = currentLevel;
    int levelUps = 0;
    final statGains = <String, int>{};

    // 레벨업 루프
    while (currentLevel < LevelConstants.maxLevel &&
        currentExp >= getExpToNextLevel()) {
      currentExp -= getExpToNextLevel();
      currentLevel++;
      levelUps++;

      // 스탯 증가 누적
      statGains['hp'] = (statGains['hp'] ?? 0) + LevelConstants.hpPerLevel;
      statGains['mp'] = (statGains['mp'] ?? 0) + LevelConstants.mpPerLevel;
      statGains['atk'] = (statGains['atk'] ?? 0) + LevelConstants.atkPerLevel;
      statGains['def'] = (statGains['def'] ?? 0) + LevelConstants.defPerLevel;
      statGains['spd'] = (statGains['spd'] ?? 0) + LevelConstants.spdPerLevel;
      statGains['lck'] = (statGains['lck'] ?? 0) + LevelConstants.lckPerLevel;
    }

    final result = LevelUpResult(
      levelUps: levelUps,
      oldLevel: oldLevel,
      newLevel: currentLevel,
      statGains: statGains,
    );

    if (levelUps > 0) {
      onLevelUp?.call(result);
    }

    return result;
  }

  /// 다음 레벨까지 필요한 경험치
  int getExpToNextLevel() {
    return LevelConstants.expToNextLevel(currentLevel);
  }

  /// 레벨 진행도 (0.0~1.0)
  double getLevelProgress() {
    if (currentLevel >= LevelConstants.maxLevel) return 1.0;
    final expNeeded = getExpToNextLevel();
    if (expNeeded == 0) return 1.0;
    return (currentExp / expNeeded).clamp(0.0, 1.0);
  }

  /// 경험치 정보
  Map<String, dynamic> getExpInfo() {
    return {
      'level': currentLevel,
      'currentExp': currentExp,
      'expToNext': getExpToNextLevel(),
      'progress': getLevelProgress(),
      'isMaxLevel': currentLevel >= LevelConstants.maxLevel,
    };
  }

  /// 적 처치 경험치 계산 (정적 메서드)
  static int calculateEnemyExp(int enemyLevel, String enemyType, int playerLevel) {
    int baseExp = LevelConstants.baseExpPerKill + (enemyLevel * LevelConstants.expPerEnemyLevel);

    // 타입 배율
    final typeMult = switch (enemyType.toLowerCase()) {
      'elite' => LevelConstants.eliteExpMult,
      'boss' => LevelConstants.bossExpMult,
      _ => LevelConstants.normalExpMult,
    };
    baseExp = (baseExp * typeMult).round();

    // 레벨 차이 보정
    final diff = enemyLevel - playerLevel;
    double levelMult = 1.0;
    if (diff < -5) {
      levelMult = (1.0 + diff * 0.1).clamp(0.1, 1.0);
    } else if (diff > 5) {
      levelMult = (1.0 + diff * 0.05).clamp(1.0, 2.0);
    }

    return (baseExp * levelMult).round();
  }
}

/// 레벨업 결과
class LevelUpResult {
  final int levelUps;
  final int oldLevel;
  final int newLevel;
  final Map<String, int> statGains;

  const LevelUpResult({
    required this.levelUps,
    required this.oldLevel,
    required this.newLevel,
    required this.statGains,
  });
}
