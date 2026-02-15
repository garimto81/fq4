// AchievementSystem: Manages achievements and progress tracking
//
// 28 achievements total:
// - 10 chapter clear
// - 4 boss defeats (3 + 1 secret all bosses)
// - 3 level milestones
// - 3 kill count milestones
// - 3 endings
// - 5 special (speed run, no death, NG+, formations, spell master)

enum AchievementType {
  chapterClear,
  bossDefeat,
  unitLevel,
  totalKills,
  endingReached,
  speedRun,
  noDeath,
  newGamePlus,
  formationUse,
  spellCast,
}

class AchievementData {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final AchievementType type;
  final int targetValue;
  final String? targetId;
  final bool secret;

  const AchievementData({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.type,
    required this.targetValue,
    this.targetId,
    this.secret = false,
  });

  bool checkProgress(int currentValue) => currentValue >= targetValue;
}

class AchievementSystem {
  final Map<String, AchievementData> _achievements = {};
  final Map<String, int> _unlocked = {}; // id -> timestamp
  final Map<String, int> _progress = {}; // id -> current value

  // Stats tracking
  int totalKills = 0;
  int spellsCast = 0;
  int goldEarned = 0;
  int deathCount = 0;
  int ngPlusCount = 0;
  List<String> chaptersCleared = [];
  List<String> bossesDefeated = [];
  List<String> endingsReached = [];
  Set<String> formationsUsed = {};
  double totalPlayTime = 0.0;

  Function(AchievementData)? onAchievementUnlocked;
  Function(String id, int current, int target)? onProgressUpdated;

  AchievementSystem() {
    _registerAllAchievements();
  }

  void _registerAllAchievements() {
    // 10 Chapter clear achievements
    for (int i = 1; i <= 10; i++) {
      _registerAchievement(AchievementData(
        id: 'chapter_${i}_clear',
        nameKey: 'ACH_CHAPTER_${i}_NAME',
        descriptionKey: 'ACH_CHAPTER_${i}_DESC',
        type: AchievementType.chapterClear,
        targetValue: i,
        targetId: 'chapter_$i',
      ));
    }

    // 4 Boss achievements
    _registerAchievement(const AchievementData(
      id: 'boss_demon_general',
      nameKey: 'ACH_BOSS_DEMON_GENERAL_NAME',
      descriptionKey: 'ACH_BOSS_DEMON_GENERAL_DESC',
      type: AchievementType.bossDefeat,
      targetValue: 1,
      targetId: 'demon_general',
    ));
    _registerAchievement(const AchievementData(
      id: 'boss_fallen_hero',
      nameKey: 'ACH_BOSS_FALLEN_HERO_NAME',
      descriptionKey: 'ACH_BOSS_FALLEN_HERO_DESC',
      type: AchievementType.bossDefeat,
      targetValue: 1,
      targetId: 'fallen_hero',
    ));
    _registerAchievement(const AchievementData(
      id: 'boss_demon_king',
      nameKey: 'ACH_BOSS_DEMON_KING_NAME',
      descriptionKey: 'ACH_BOSS_DEMON_KING_DESC',
      type: AchievementType.bossDefeat,
      targetValue: 1,
      targetId: 'demon_king',
    ));
    _registerAchievement(const AchievementData(
      id: 'boss_all',
      nameKey: 'ACH_BOSS_ALL_NAME',
      descriptionKey: 'ACH_BOSS_ALL_DESC',
      type: AchievementType.bossDefeat,
      targetValue: 1,
      targetId: 'all_bosses',
      secret: true,
    ));

    // 3 Level achievements
    _registerAchievement(const AchievementData(
      id: 'level_novice',
      nameKey: 'ACH_LEVEL_NOVICE_NAME',
      descriptionKey: 'ACH_LEVEL_NOVICE_DESC',
      type: AchievementType.unitLevel,
      targetValue: 10,
    ));
    _registerAchievement(const AchievementData(
      id: 'level_veteran',
      nameKey: 'ACH_LEVEL_VETERAN_NAME',
      descriptionKey: 'ACH_LEVEL_VETERAN_DESC',
      type: AchievementType.unitLevel,
      targetValue: 30,
    ));
    _registerAchievement(const AchievementData(
      id: 'level_master',
      nameKey: 'ACH_LEVEL_MASTER_NAME',
      descriptionKey: 'ACH_LEVEL_MASTER_DESC',
      type: AchievementType.unitLevel,
      targetValue: 50,
    ));

    // 3 Kill achievements
    _registerAchievement(const AchievementData(
      id: 'kills_hunter',
      nameKey: 'ACH_KILLS_HUNTER_NAME',
      descriptionKey: 'ACH_KILLS_HUNTER_DESC',
      type: AchievementType.totalKills,
      targetValue: 100,
    ));
    _registerAchievement(const AchievementData(
      id: 'kills_slayer',
      nameKey: 'ACH_KILLS_SLAYER_NAME',
      descriptionKey: 'ACH_KILLS_SLAYER_DESC',
      type: AchievementType.totalKills,
      targetValue: 500,
    ));
    _registerAchievement(const AchievementData(
      id: 'kills_legend',
      nameKey: 'ACH_KILLS_LEGEND_NAME',
      descriptionKey: 'ACH_KILLS_LEGEND_DESC',
      type: AchievementType.totalKills,
      targetValue: 1000,
    ));

    // 3 Ending achievements
    _registerAchievement(const AchievementData(
      id: 'ending_good',
      nameKey: 'ACH_ENDING_GOOD_NAME',
      descriptionKey: 'ACH_ENDING_GOOD_DESC',
      type: AchievementType.endingReached,
      targetValue: 1,
      targetId: 'good',
    ));
    _registerAchievement(const AchievementData(
      id: 'ending_normal',
      nameKey: 'ACH_ENDING_NORMAL_NAME',
      descriptionKey: 'ACH_ENDING_NORMAL_DESC',
      type: AchievementType.endingReached,
      targetValue: 1,
      targetId: 'normal',
    ));
    _registerAchievement(const AchievementData(
      id: 'ending_bad',
      nameKey: 'ACH_ENDING_BAD_NAME',
      descriptionKey: 'ACH_ENDING_BAD_DESC',
      type: AchievementType.endingReached,
      targetValue: 1,
      targetId: 'bad',
    ));

    // 5 Special achievements
    _registerAchievement(const AchievementData(
      id: 'speed_run',
      nameKey: 'ACH_SPEED_RUN_NAME',
      descriptionKey: 'ACH_SPEED_RUN_DESC',
      type: AchievementType.speedRun,
      targetValue: 7200, // 2 hours in seconds
      secret: true,
    ));
    _registerAchievement(const AchievementData(
      id: 'no_death',
      nameKey: 'ACH_NO_DEATH_NAME',
      descriptionKey: 'ACH_NO_DEATH_DESC',
      type: AchievementType.noDeath,
      targetValue: 1,
      secret: true,
    ));
    _registerAchievement(const AchievementData(
      id: 'ng_plus',
      nameKey: 'ACH_NG_PLUS_NAME',
      descriptionKey: 'ACH_NG_PLUS_DESC',
      type: AchievementType.newGamePlus,
      targetValue: 1,
    ));
    _registerAchievement(const AchievementData(
      id: 'formation_master',
      nameKey: 'ACH_FORMATION_MASTER_NAME',
      descriptionKey: 'ACH_FORMATION_MASTER_DESC',
      type: AchievementType.formationUse,
      targetValue: 5, // All 5 formations
    ));
    _registerAchievement(const AchievementData(
      id: 'spell_master',
      nameKey: 'ACH_SPELL_MASTER_NAME',
      descriptionKey: 'ACH_SPELL_MASTER_DESC',
      type: AchievementType.spellCast,
      targetValue: 100,
    ));
  }

  void _registerAchievement(AchievementData achievement) {
    _achievements[achievement.id] = achievement;
    _progress[achievement.id] = 0;
  }

  // Unlock achievement
  void unlock(String id) {
    if (_unlocked.containsKey(id)) return;
    if (!_achievements.containsKey(id)) return;

    _unlocked[id] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final achievement = _achievements[id]!;
    onAchievementUnlocked?.call(achievement);
  }

  // Update progress
  void updateProgress(String id, int value) {
    if (_unlocked.containsKey(id)) return;
    if (!_achievements.containsKey(id)) return;

    _progress[id] = value;
    final achievement = _achievements[id]!;
    onProgressUpdated?.call(id, value, achievement.targetValue);

    if (achievement.checkProgress(value)) {
      unlock(id);
    }
  }

  // Stats tracking methods
  void addKill() {
    totalKills++;
    if (totalKills >= 100) unlock('kills_hunter');
    if (totalKills >= 500) unlock('kills_slayer');
    if (totalKills >= 1000) unlock('kills_legend');
  }

  void addSpellCast() {
    spellsCast++;
    updateProgress('spell_master', spellsCast);
  }

  void completeChapter(String chapterId) {
    if (!chaptersCleared.contains(chapterId)) {
      chaptersCleared.add(chapterId);
    }
    unlock('${chapterId}_clear');
  }

  void defeatBoss(String bossId) {
    if (!bossesDefeated.contains(bossId)) {
      bossesDefeated.add(bossId);
    }
    unlock('boss_$bossId');

    // Check for all bosses achievement
    if (bossesDefeated.length >= 3) {
      unlock('boss_all');
    }
  }

  void reachEnding(String endingType) {
    if (!endingsReached.contains(endingType)) {
      endingsReached.add(endingType);
    }
    unlock('ending_$endingType');
  }

  void reachLevel(int level) {
    if (level >= 10) unlock('level_novice');
    if (level >= 30) unlock('level_veteran');
    if (level >= 50) unlock('level_master');
  }

  void useFormation(String formationType) {
    formationsUsed.add(formationType);
    updateProgress('formation_master', formationsUsed.length);
  }

  void addDeath() {
    deathCount++;
  }

  void startNgPlus() {
    ngPlusCount++;
    unlock('ng_plus');
  }

  // Check speed run and no death achievements (called at game end)
  void checkCompletionAchievements(double playTime) {
    totalPlayTime = playTime;

    if (playTime <= 7200.0) {
      unlock('speed_run');
    }

    if (deathCount == 0) {
      unlock('no_death');
    }
  }

  // Query methods
  bool isUnlocked(String id) => _unlocked.containsKey(id);

  int getProgress(String id) => _progress[id] ?? 0;

  double getCompletionPercentage() {
    if (_achievements.isEmpty) return 0.0;
    return (_unlocked.length / _achievements.length) * 100.0;
  }

  List<AchievementData> getAllAchievements() {
    return _achievements.values.toList();
  }

  List<AchievementData> getUnlockedAchievements() {
    return _unlocked.keys
        .where((id) => _achievements.containsKey(id))
        .map((id) => _achievements[id]!)
        .toList();
  }

  // Serialization
  Map<String, dynamic> serialize() {
    return {
      'unlocked': _unlocked,
      'progress': _progress,
      'stats': {
        'total_kills': totalKills,
        'spells_cast': spellsCast,
        'gold_earned': goldEarned,
        'death_count': deathCount,
        'ng_plus_count': ngPlusCount,
        'chapters_cleared': chaptersCleared,
        'bosses_defeated': bossesDefeated,
        'endings_reached': endingsReached,
        'formations_used': formationsUsed.toList(),
        'total_play_time': totalPlayTime,
      },
    };
  }

  void deserialize(Map<String, dynamic> data) {
    if (data.containsKey('unlocked')) {
      _unlocked.clear();
      final unlocked = data['unlocked'] as Map<String, dynamic>;
      unlocked.forEach((key, value) {
        _unlocked[key] = value as int;
      });
    }

    if (data.containsKey('progress')) {
      _progress.clear();
      final progress = data['progress'] as Map<String, dynamic>;
      progress.forEach((key, value) {
        _progress[key] = value as int;
      });
    }

    if (data.containsKey('stats')) {
      final stats = data['stats'] as Map<String, dynamic>;
      totalKills = stats['total_kills'] as int? ?? 0;
      spellsCast = stats['spells_cast'] as int? ?? 0;
      goldEarned = stats['gold_earned'] as int? ?? 0;
      deathCount = stats['death_count'] as int? ?? 0;
      ngPlusCount = stats['ng_plus_count'] as int? ?? 0;
      chaptersCleared = (stats['chapters_cleared'] as List?)?.cast<String>() ?? [];
      bossesDefeated = (stats['bosses_defeated'] as List?)?.cast<String>() ?? [];
      endingsReached = (stats['endings_reached'] as List?)?.cast<String>() ?? [];
      formationsUsed = (stats['formations_used'] as List?)?.cast<String>().toSet() ?? {};
      totalPlayTime = (stats['total_play_time'] as num?)?.toDouble() ?? 0.0;
    }
  }
}
