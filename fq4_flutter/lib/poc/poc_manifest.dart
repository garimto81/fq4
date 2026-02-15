// POC Manifest - 전체 POC 레지스트리
// 10개 POC 정의: ID, 이름, 카테고리, 검증 기준, auto-run 여부

import 'infrastructure/poc_definition.dart';

class PocManifest {
  PocManifest._();

  static const _coreSystems = 'Core Systems';
  static const _integration = 'Integration';
  static const _gochaKyara = 'Gocha-Kyara';
  static const _strategicCombat = 'Strategic Combat';

  static final List<PocDefinition> all = [
    // --- Core Systems ---
    PocDefinition(
      id: 'poc-1',
      name: 'POC-01: Rive + Flame Rendering',
      category: _coreSystems,
      description: 'Rive 애니메이션과 Flame 엔진 통합 렌더링 검증',
      route: '/poc1',
      requiresInput: true,
      tags: ['rive', 'rendering'],
      timeout: const Duration(seconds: 30),
      criteria: [
        PocCriterion(
          id: 'fps-30',
          description: 'FPS >= 30',
          evaluate: (m) => (m['fps'] as double? ?? 0) >= 30,
        ),
        PocCriterion(
          id: 'fallback-render',
          description: 'Fallback 렌더러 동작',
          evaluate: (m) => m['rendererActive'] == true,
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-2',
      name: 'POC-02: AI Auto-Battle Pipeline',
      category: _coreSystems,
      description: 'AI 자동전투 파이프라인: 전투 시작~종료 검증',
      route: '/poc2',
      requiresInput: false,
      tags: ['ai', 'combat'],
      timeout: const Duration(seconds: 60),
      criteria: [
        PocCriterion(
          id: 'battle-complete',
          description: '전투 완료 (victory/defeat)',
          evaluate: (m) {
            final state = m['battleState'] as String? ?? '';
            return state == 'victory' || state == 'defeat';
          },
        ),
        PocCriterion(
          id: 'within-60s',
          description: '60초 이내 완료',
          evaluate: (m) => (m['battleTime'] as double? ?? 999) <= 60,
        ),
        PocCriterion(
          id: 'damage-dealt',
          description: '데미지 발생',
          evaluate: (m) => (m['totalDamage'] as int? ?? 0) > 0,
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-3',
      name: 'POC-03: Portrait Layout',
      category: _coreSystems,
      description: '유닛 초상화 레이아웃 렌더링 검증',
      route: '/poc3',
      requiresInput: true,
      tags: ['ui', 'layout'],
      timeout: const Duration(seconds: 30),
      criteria: [
        PocCriterion(
          id: 'units-rendered',
          description: '3개+ 유닛 렌더링',
          evaluate: (m) => (m['unitCount'] as int? ?? 0) >= 3,
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-4',
      name: 'POC-04: Battle Speed Multiplier',
      category: _coreSystems,
      description: '배속 시스템: 2x 속도에서 이동거리 2배 검증',
      route: '/poc4',
      requiresInput: false,
      tags: ['speed', 'physics'],
      timeout: const Duration(seconds: 30),
      criteria: [
        PocCriterion(
          id: 'speed-2x-distance',
          description: '2x 속도 = 2배 이동거리 (±15%)',
          evaluate: (m) {
            final dist1x = m['distance1x'] as double? ?? 0;
            final dist2x = m['distance2x'] as double? ?? 0;
            if (dist1x <= 0) return false;
            final ratio = dist2x / dist1x;
            return ratio >= 1.7 && ratio <= 2.3; // ±15%
          },
        ),
      ],
    ),

    // --- Integration ---
    PocDefinition(
      id: 'poc-5',
      name: 'POC-05: Integrated Battle',
      category: _integration,
      description: 'POC 1-4 통합: 렌더링+AI+레이아웃+배속',
      route: '/battle',
      requiresInput: false,
      tags: ['integration'],
      timeout: const Duration(seconds: 60),
      criteria: [
        PocCriterion(
          id: 'battle-complete',
          description: '전투 완료',
          evaluate: (m) {
            final state = m['battleState'] as String? ?? '';
            return state == 'victory' || state == 'defeat';
          },
        ),
      ],
    ),

    // --- Gocha-Kyara ---
    PocDefinition(
      id: 'poc-t0',
      name: 'POC-06: Gocha-Kyara AI/Manual Toggle',
      category: _gochaKyara,
      description: 'AI/수동 전환 시스템: WASD 입력→수동, 3초 방치→자동',
      route: '/phase0',
      requiresInput: true,
      tags: ['gocha-kyara', 'input'],
      timeout: const Duration(seconds: 60),
      criteria: [
        PocCriterion(
          id: 'battle-3s',
          description: '전투 3초+ 진행',
          evaluate: (m) => (m['battleTime'] as double? ?? 0) >= 3,
        ),
        PocCriterion(
          id: 'input-latency',
          description: '입력 지연 < 50ms',
          evaluate: (m) => (m['inputLatency'] as double? ?? 999) < 50,
        ),
      ],
    ),

    // --- Strategic Combat ---
    PocDefinition(
      id: 'poc-s1',
      name: 'POC-07: Direction-Based Damage',
      category: _strategicCombat,
      description: '방향별 데미지 배율: front 1.0x / side 1.3x / back 1.5x',
      route: '/poc-s1',
      requiresInput: false,
      tags: ['strategic', 'damage'],
      timeout: const Duration(seconds: 60),
      criteria: [
        PocCriterion(
          id: 'back-gt-front',
          description: 'back 평균 데미지 > front 평균 데미지',
          evaluate: (m) {
            final avgBack = double.tryParse(m['avgBackDmg']?.toString() ?? '') ?? 0;
            final avgFront = double.tryParse(m['avgFrontDmg']?.toString() ?? '') ?? 0;
            return avgBack > avgFront && avgFront > 0;
          },
        ),
        PocCriterion(
          id: 'side-back-attacks',
          description: 'side/back 공격 각 1회 이상',
          evaluate: (m) =>
              (m['sideAttacks'] as int? ?? 0) >= 1 &&
              (m['backAttacks'] as int? ?? 0) >= 1,
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-s2',
      name: 'POC-08: Weapon Range RPS',
      category: _strategicCombat,
      description: '무기 사거리 가위바위보: 3매치 각 우세측 55%+ 승률',
      route: '/poc-s2',
      requiresInput: false,
      tags: ['strategic', 'weapon'],
      timeout: const Duration(seconds: 90),
      criteria: [
        PocCriterion(
          id: 'match1-winrate',
          description: 'Match 1 우세측 55%+ 승률',
          evaluate: (m) => (m['match1_winRate'] as double? ?? 0) >= 0.55,
        ),
        PocCriterion(
          id: 'match2-winrate',
          description: 'Match 2 우세측 55%+ 승률',
          evaluate: (m) => (m['match2_winRate'] as double? ?? 0) >= 0.55,
        ),
        PocCriterion(
          id: 'match3-winrate',
          description: 'Match 3 우세측 55%+ 승률',
          evaluate: (m) => (m['match3_winRate'] as double? ?? 0) >= 0.55,
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-s3',
      name: 'POC-09: 40-Unit Mass Battle',
      category: _strategicCombat,
      description: '40유닛 대규모 전투: 성능 목표 60 FPS',
      route: '/poc-s3',
      requiresInput: false,
      tags: ['strategic', 'performance'],
      timeout: const Duration(seconds: 120),
      criteria: [
        PocCriterion(
          id: 'avg-fps-55',
          description: 'avgFPS >= 55',
          evaluate: (m) => (m['avgFps'] as double? ?? 0) >= 55,
        ),
        PocCriterion(
          id: 'min-fps-30',
          description: 'minFPS >= 30',
          evaluate: (m) => (m['minFps'] as double? ?? 0) >= 30,
        ),
        PocCriterion(
          id: 'p99-ai-5ms',
          description: 'P99 AI tick < 5ms',
          evaluate: (m) => (m['p99AiTickMs'] as double? ?? 999) < 5,
        ),
        PocCriterion(
          id: 'battle-complete',
          description: '전투 완료',
          evaluate: (m) {
            final state = m['battleState'] as String? ?? '';
            return state == 'victory' || state == 'defeat';
          },
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-s4',
      name: 'POC-10: Player Strategic Intervention',
      category: _strategicCombat,
      description: '수동 개입 효과 비교: auto 2회+ 실행, 승률/back-attack 데이터 수집',
      route: '/poc-s4',
      requiresInput: true,
      tags: ['strategic', 'intervention'],
      timeout: const Duration(seconds: 120),
      criteria: [
        PocCriterion(
          id: 'auto-runs-2',
          description: 'auto 실행 2회 이상',
          evaluate: (m) => (m['autoRuns'] as int? ?? 0) >= 2,
        ),
        PocCriterion(
          id: 'data-collected',
          description: '승률/back-attack 데이터 수집',
          evaluate: (m) =>
              m.containsKey('autoWinRate') && m.containsKey('autoBackAttacks'),
        ),
      ],
    ),
    PocDefinition(
      id: 'poc-s5',
      name: 'POC-11: AI Flanking Behavior',
      category: _strategicCombat,
      description: 'AI 측면/후방 기동 검증: 동적 적 상대로 flanking 비율 25%+',
      route: '/poc-s5',
      requiresInput: false,
      tags: ['strategic', 'flanking'],
      timeout: const Duration(seconds: 90),
      criteria: [
        PocCriterion(
          id: 'side-back-ratio-25',
          description: 'side+back 공격 비율 >= 25%',
          evaluate: (m) => (m['sideBackRatio'] as double? ?? 0) >= 0.25,
        ),
        PocCriterion(
          id: 'back-attacks-3',
          description: 'back 공격 3회 이상',
          evaluate: (m) => (m['backAttacks'] as int? ?? 0) >= 3,
        ),
        PocCriterion(
          id: 'flanking-attempts-5',
          description: 'flanking 기동 시도 5회 이상',
          evaluate: (m) => (m['flankingAttempts'] as int? ?? 0) >= 5,
        ),
        PocCriterion(
          id: 'battle-complete',
          description: '전투 완료',
          evaluate: (m) {
            final state = m['battleState'] as String? ?? '';
            return state == 'victory' || state == 'defeat';
          },
        ),
      ],
    ),
  ];

  /// ID로 POC 정의 검색
  static PocDefinition? byId(String id) {
    for (final def in all) {
      if (def.id == id) return def;
    }
    return null;
  }

  /// 카테고리 목록 (순서 유지)
  static List<String> get categories {
    final seen = <String>{};
    final result = <String>[];
    for (final def in all) {
      if (seen.add(def.category)) {
        result.add(def.category);
      }
    }
    return result;
  }

  /// 카테고리별 POC 목록
  static List<PocDefinition> byCategory(String category) =>
      all.where((d) => d.category == category).toList();

  /// auto-runnable POC 목록
  static List<PocDefinition> get autoRunnable =>
      all.where((d) => d.isAutoRunnable).toList();
}
