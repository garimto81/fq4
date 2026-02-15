// EndingSystem: Determines and triggers game endings based on player performance
//
// Ending types:
// - GOOD: All chapters cleared, low deaths, all bosses defeated
// - NORMAL: Game completed with moderate performance
// - BAD: High death count or many chapters skipped

enum EndingType {
  good,
  normal,
  bad,
}

class EndingCriteria {
  final int minChaptersForGood;
  final int maxDeathsForGood;
  final int minBossesForGood;
  final int maxDeathsForNormal;

  const EndingCriteria({
    this.minChaptersForGood = 10,
    this.maxDeathsForGood = 3,
    this.minBossesForGood = 3,
    this.maxDeathsForNormal = 10,
  });
}

class EndingSystem {
  final EndingCriteria criteria;

  Function(EndingType)? onEndingTriggered;

  EndingSystem({
    this.criteria = const EndingCriteria(),
  });

  // Determine ending based on game stats
  EndingType determineEnding({
    required int chaptersCleared,
    required int deathCount,
    required int bossesDefeated,
  }) {
    // Good ending: Complete all chapters, low deaths, all bosses
    if (chaptersCleared >= criteria.minChaptersForGood &&
        deathCount <= criteria.maxDeathsForGood &&
        bossesDefeated >= criteria.minBossesForGood) {
      return EndingType.good;
    }

    // Bad ending: Too many deaths
    if (deathCount > criteria.maxDeathsForNormal) {
      return EndingType.bad;
    }

    // Normal ending: Everything else
    return EndingType.normal;
  }

  // Get ending description key for localization
  String getEndingDescriptionKey(EndingType ending) {
    switch (ending) {
      case EndingType.good:
        return 'ENDING_GOOD_DESC';
      case EndingType.normal:
        return 'ENDING_NORMAL_DESC';
      case EndingType.bad:
        return 'ENDING_BAD_DESC';
    }
  }

  // Get ending title key for localization
  String getEndingTitleKey(EndingType ending) {
    switch (ending) {
      case EndingType.good:
        return 'ENDING_GOOD_TITLE';
      case EndingType.normal:
        return 'ENDING_NORMAL_TITLE';
      case EndingType.bad:
        return 'ENDING_BAD_TITLE';
    }
  }

  // Trigger ending with callback
  void triggerEnding(EndingType ending) {
    onEndingTriggered?.call(ending);
  }

  // Serialize ending state
  Map<String, dynamic> serialize(EndingType? reachedEnding) {
    return {
      'reached_ending': reachedEnding?.name,
    };
  }

  // Deserialize ending state
  EndingType? deserialize(Map<String, dynamic> data) {
    final endingName = data['reached_ending'] as String?;
    if (endingName == null) return null;

    try {
      return EndingType.values.firstWhere((e) => e.name == endingName);
    } catch (_) {
      return null;
    }
  }
}
