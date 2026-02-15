class ChapterData {
  final int chapterId;
  final String chapterName;
  final String chapterSubtitle;
  final String description;
  final List<String> maps;
  final String introDialogue;
  final String outroDialogue;
  final List<String> clearFlags;
  final String bossMapId;
  final String bossEnemyId;
  final String bgmPath;

  ChapterData({
    required this.chapterId,
    required this.chapterName,
    required this.chapterSubtitle,
    required this.description,
    required this.maps,
    required this.introDialogue,
    required this.outroDialogue,
    required this.clearFlags,
    required this.bossMapId,
    required this.bossEnemyId,
    required this.bgmPath,
  });

  String getFirstMap() {
    return maps.isNotEmpty ? maps.first : '';
  }

  bool hasBoss() {
    return bossMapId.isNotEmpty && bossEnemyId.isNotEmpty;
  }

  int getMapIndex(String mapId) {
    return maps.indexOf(mapId);
  }

  String? getNextMap(String currentMapId) {
    final index = getMapIndex(currentMapId);
    if (index == -1 || index >= maps.length - 1) {
      return null;
    }
    return maps[index + 1];
  }

  static ChapterData chapter1() {
    return ChapterData(
      chapterId: 1,
      chapterName: '아레스의 각성',
      chapterSubtitle: 'The Awakening of Ares',
      description: '아레스가 고블린의 침략에 맞서 첫 번째 전투를 치릅니다.',
      maps: ['forest_path', 'goblin_camp', 'castle_entrance'],
      introDialogue: 'chapter1_intro',
      outroDialogue: 'chapter1_outro',
      clearFlags: ['chapter1_cleared'],
      bossMapId: 'castle_entrance',
      bossEnemyId: 'goblin_chief',
      bgmPath: 'audio/bgm/chapter1.ogg',
    );
  }

  static ChapterData chapter2() {
    return ChapterData(
      chapterId: 2,
      chapterName: '사막의 시련',
      chapterSubtitle: 'Desert Trials',
      description: '사막에서 도적떼를 격파하고 용병 길드와 협력합니다.',
      maps: ['desert_arrival', 'oasis_rest', 'mercenary_guild'],
      introDialogue: 'chapter2_intro',
      outroDialogue: 'chapter2_outro',
      clearFlags: ['chapter2_cleared'],
      bossMapId: 'mercenary_guild',
      bossEnemyId: 'bandit_leader',
      bgmPath: 'audio/bgm/chapter2.ogg',
    );
  }

  static ChapterData chapter3() {
    return ChapterData(
      chapterId: 3,
      chapterName: '어둠의 숲',
      chapterSubtitle: 'Dark Forest',
      description: '타락한 기사와의 결전을 준비합니다.',
      maps: ['dark_forest_entrance', 'corrupted_shrine', 'dark_knight_arena'],
      introDialogue: 'chapter3_intro',
      outroDialogue: 'chapter3_outro',
      clearFlags: ['chapter3_cleared'],
      bossMapId: 'dark_knight_arena',
      bossEnemyId: 'dark_knight',
      bgmPath: 'audio/bgm/chapter3.ogg',
    );
  }

  static ChapterData chapter4() {
    return ChapterData(
      chapterId: 4,
      chapterName: '얼어붙은 성채',
      chapterSubtitle: 'Frozen Fortress',
      description: '얼음의 땅을 지배하는 리치를 쓰러뜨립니다.',
      maps: ['frozen_entrance', 'ice_cavern', 'lich_throne'],
      introDialogue: 'chapter4_intro',
      outroDialogue: 'chapter4_outro',
      clearFlags: ['chapter4_cleared'],
      bossMapId: 'lich_throne',
      bossEnemyId: 'lich',
      bgmPath: 'audio/bgm/chapter4.ogg',
    );
  }

  static ChapterData chapter5() {
    return ChapterData(
      chapterId: 5,
      chapterName: '독의 늪',
      chapterSubtitle: 'Poison Swamp',
      description: '타락한 귀족이 지배하는 독의 늪을 정화합니다.',
      maps: ['swamp_entrance', 'poison_marsh', 'noble_manor'],
      introDialogue: 'chapter5_intro',
      outroDialogue: 'chapter5_outro',
      clearFlags: ['chapter5_cleared'],
      bossMapId: 'noble_manor',
      bossEnemyId: 'corrupted_noble',
      bgmPath: 'audio/bgm/chapter5.ogg',
    );
  }

  static ChapterData chapter6() {
    return ChapterData(
      chapterId: 6,
      chapterName: '불의 산',
      chapterSubtitle: 'Mountain of Fire',
      description: '화산에 숨은 데몬 제너럴을 격퇴합니다.',
      maps: ['volcano_base', 'lava_path', 'demon_lair'],
      introDialogue: 'chapter6_intro',
      outroDialogue: 'chapter6_outro',
      clearFlags: ['chapter6_cleared'],
      bossMapId: 'demon_lair',
      bossEnemyId: 'demon_general',
      bgmPath: 'audio/bgm/chapter6.ogg',
    );
  }

  static ChapterData chapter7() {
    return ChapterData(
      chapterId: 7,
      chapterName: '어둠의 탑',
      chapterSubtitle: 'Tower of Darkness',
      description: '타락한 영웅과의 최종 결전을 준비합니다.',
      maps: ['tower_entrance', 'shadow_hall', 'fallen_chamber'],
      introDialogue: 'chapter7_intro',
      outroDialogue: 'chapter7_outro',
      clearFlags: ['chapter7_cleared'],
      bossMapId: 'fallen_chamber',
      bossEnemyId: 'fallen_hero',
      bgmPath: 'audio/bgm/chapter7.ogg',
    );
  }

  static ChapterData chapter8() {
    return ChapterData(
      chapterId: 8,
      chapterName: '마왕의 영역',
      chapterSubtitle: 'Demon Lord Territory',
      description: '마왕의 영역으로 깊숙이 침투합니다.',
      maps: ['demon_realm_entrance', 'dark_corridor', 'throne_approach'],
      introDialogue: 'chapter8_intro',
      outroDialogue: 'chapter8_outro',
      clearFlags: ['chapter8_cleared'],
      bossMapId: '',
      bossEnemyId: '',
      bgmPath: 'audio/bgm/chapter8.ogg',
    );
  }

  static ChapterData chapter9() {
    return ChapterData(
      chapterId: 9,
      chapterName: '최후의 결전',
      chapterSubtitle: 'Final Battle',
      description: '마왕군 최강의 장군과 맞서 싸웁니다.',
      maps: ['demon_generals_hall', 'blood_throne'],
      introDialogue: 'chapter9_intro',
      outroDialogue: 'chapter9_outro',
      clearFlags: ['chapter9_cleared'],
      bossMapId: 'blood_throne',
      bossEnemyId: 'demon_general',
      bgmPath: 'audio/bgm/chapter9.ogg',
    );
  }

  static ChapterData chapter10() {
    return ChapterData(
      chapterId: 10,
      chapterName: '마왕과의 대결',
      chapterSubtitle: 'Showdown with the Demon King',
      description: '마침내 마왕과의 최종 결전이 시작됩니다.',
      maps: ['demon_kings_throne'],
      introDialogue: 'chapter10_intro',
      outroDialogue: 'chapter10_outro',
      clearFlags: ['chapter10_cleared', 'demon_king_defeated'],
      bossMapId: 'demon_kings_throne',
      bossEnemyId: 'demon_king',
      bgmPath: 'audio/bgm/chapter10.ogg',
    );
  }
}
