// NewGamePlusSystem: Manages New Game Plus scaling and bonuses
//
// NG+ Scaling:
// - Enemy stats: 1.5x
// - Experience gain: 0.8x
// - Gold gain: 1.2x

class NewGamePlusData {
  final int ngPlusCount;
  final int previousPlayTime;
  final int previousDeathCount;
  final List<String> unlockedAchievements;

  const NewGamePlusData({
    required this.ngPlusCount,
    required this.previousPlayTime,
    required this.previousDeathCount,
    required this.unlockedAchievements,
  });

  Map<String, dynamic> toJson() {
    return {
      'ng_plus_count': ngPlusCount,
      'previous_play_time': previousPlayTime,
      'previous_death_count': previousDeathCount,
      'unlocked_achievements': unlockedAchievements,
    };
  }

  factory NewGamePlusData.fromJson(Map<String, dynamic> json) {
    return NewGamePlusData(
      ngPlusCount: json['ng_plus_count'] as int? ?? 0,
      previousPlayTime: json['previous_play_time'] as int? ?? 0,
      previousDeathCount: json['previous_death_count'] as int? ?? 0,
      unlockedAchievements: (json['unlocked_achievements'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class NewGamePlusSystem {
  static const double enemyStatMultiplier = 1.5;
  static const double expMultiplier = 0.8;
  static const double goldMultiplier = 1.2;

  NewGamePlusData? _ngPlusData;
  bool _isActive = false;

  Function(NewGamePlusData)? onNgPlusStarted;

  // Check if NG+ is active
  bool get isActive => _isActive;

  // Get current NG+ count
  int get ngPlusCount => _ngPlusData?.ngPlusCount ?? 0;

  // Check if player has NG+ data available
  bool get hasNgPlusData => _ngPlusData != null;

  // Start New Game Plus
  void startNgPlus(NewGamePlusData data) {
    _ngPlusData = data;
    _isActive = true;
    onNgPlusStarted?.call(data);
  }

  // Prepare NG+ data from current game
  NewGamePlusData prepareNgPlusData({
    required int playTime,
    required int deathCount,
    required List<String> achievements,
  }) {
    final currentCount = _ngPlusData?.ngPlusCount ?? 0;
    return NewGamePlusData(
      ngPlusCount: currentCount + 1,
      previousPlayTime: playTime,
      previousDeathCount: deathCount,
      unlockedAchievements: achievements,
    );
  }

  // Get scaled enemy stats
  int getScaledEnemyStat(int baseStat) {
    if (!_isActive) return baseStat;
    return (baseStat * enemyStatMultiplier).round();
  }

  // Get scaled experience
  int getScaledExperience(int baseExp) {
    if (!_isActive) return baseExp;
    return (baseExp * expMultiplier).round();
  }

  // Get scaled gold
  int getScaledGold(int baseGold) {
    if (!_isActive) return baseGold;
    return (baseGold * goldMultiplier).round();
  }

  // Deactivate NG+ (for new regular game)
  void deactivate() {
    _isActive = false;
  }

  // Serialize NG+ state
  Map<String, dynamic> serialize() {
    return {
      'is_active': _isActive,
      'ng_plus_data': _ngPlusData?.toJson(),
    };
  }

  // Deserialize NG+ state
  void deserialize(Map<String, dynamic> data) {
    _isActive = data['is_active'] as bool? ?? false;
    final ngDataJson = data['ng_plus_data'] as Map<String, dynamic>?;
    if (ngDataJson != null) {
      _ngPlusData = NewGamePlusData.fromJson(ngDataJson);
    }
  }
}
