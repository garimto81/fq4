// POC-S2: 사거리 타입 간 상성 유효성 검증 (자동 시뮬레이션)
//
// 목적: 무기 사거리 상성(melee>longRange, midRange>melee, longRange>midRange)이
// 전투 결과에 실제로 영향을 미치는지 자동 시뮬레이션으로 통계 검증.
//
// 3개 매치를 반복:
//   1. melee(3) vs longRange(3) -> melee 유리 (1.3x)
//   2. midRange(3) vs melee(3) -> midRange 유리 (1.2x)
//   3. longRange(3) vs midRange(3) -> longRange 유리 (1.2x)
//
// 검증 기준: 유리한 상성이 60%+ 승률을 가져야 성공
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../core/constants/game_constants.dart';
import '../core/constants/strategic_combat_constants.dart';
import '../game/components/units/rive_unit_renderer.dart';
import '../game/components/units/strategic_unit_component.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';
import '../game/systems/strategic_combat_system.dart';

/// 매치 설정
class _MatchConfig {
  final String name;
  final WeaponRange sideARange;
  final WeaponRange sideBRange;
  final String sideALabel;
  final String sideBLabel;
  final String expectedWinner;
  final double advantageMultiplier;

  const _MatchConfig({
    required this.name,
    required this.sideARange,
    required this.sideBRange,
    required this.sideALabel,
    required this.sideBLabel,
    required this.expectedWinner,
    required this.advantageMultiplier,
  });
}

/// 매치 결과
class MatchResult {
  final String matchName;
  int sideAWins = 0;
  int sideBWins = 0;
  int totalRounds = 0;

  MatchResult(this.matchName);

  double get sideAWinRate =>
      totalRounds > 0 ? sideAWins / totalRounds : 0;
  double get sideBWinRate =>
      totalRounds > 0 ? sideBWins / totalRounds : 0;
}

/// 유닛 정보 (Flutter UI 전달용)
class S2UnitInfo {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isAlly;
  final String weaponRange;
  final String state;

  const S2UnitInfo({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.isAlly,
    required this.weaponRange,
    required this.state,
  });

  double get hpRatio => maxHp > 0 ? currentHp / maxHp : 0;
}

/// POC-S2: 사거리 상성 자동 시뮬레이션 게임
class PocS2Game extends FlameGame {
  late BattleController battleController;
  late CombatSystem combatSystem;
  late StrategicCombatSystem strategicCombatSystem;
  double speedMultiplier = 1.0;

  final List<StrategicUnitComponent> _sideA = [];
  final List<StrategicUnitComponent> _sideB = [];
  final List<_UnitWithRenderer> _unitRenderers = [];

  /// Flutter UI 콜백
  Function(String)? onStatusUpdate;
  Function(List<S2UnitInfo>)? onUnitsUpdated;
  Function(String)? onLogAdded;
  Function(Map<String, dynamic>)? onMetricsUpdated;

  double _uiTimer = 0;

  /// 3 매치 설정
  static const _matchConfigs = [
    _MatchConfig(
      name: 'Match 1: Melee vs LongRange',
      sideARange: WeaponRange.melee,
      sideBRange: WeaponRange.longRange,
      sideALabel: 'Melee',
      sideBLabel: 'LongRange',
      expectedWinner: 'Melee',
      advantageMultiplier: 1.3,
    ),
    _MatchConfig(
      name: 'Match 2: MidRange vs Melee',
      sideARange: WeaponRange.midRange,
      sideBRange: WeaponRange.melee,
      sideALabel: 'MidRange',
      sideBLabel: 'Melee',
      expectedWinner: 'MidRange',
      advantageMultiplier: 1.2,
    ),
    _MatchConfig(
      name: 'Match 3: LongRange vs MidRange',
      sideARange: WeaponRange.longRange,
      sideBRange: WeaponRange.midRange,
      sideALabel: 'LongRange',
      sideBLabel: 'MidRange',
      expectedWinner: 'LongRange',
      advantageMultiplier: 1.2,
    ),
  ];

  /// 현재 매치 인덱스 (0, 1, 2)
  int _currentMatchIndex = 0;

  /// 총 반복 횟수 (각 매치별)
  static const int _maxRoundsPerMatch = 30;

  /// 매치 결과
  final List<MatchResult> matchResults = [
    MatchResult('Melee vs LongRange'),
    MatchResult('MidRange vs Melee'),
    MatchResult('LongRange vs MidRange'),
  ];

  /// 시뮬레이션 완료 여부
  bool _simulationComplete = false;

  /// 라운드 간 대기 타이머
  double _roundDelay = 0;
  bool _waitingForNextRound = false;

  /// 전체 완료된 라운드 수
  int _totalCompletedRounds = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // 배경
    await world.add(_BackgroundComponent());

    // 첫 매치 시작
    await _startNewRound();
  }

  /// 새 라운드 시작
  Future<void> _startNewRound() async {
    // 기존 유닛/렌더러 정리
    await _cleanupCurrentRound();

    // 시스템 초기화
    combatSystem = CombatSystem();
    strategicCombatSystem = StrategicCombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = _onBattleStateChanged;
    battleController.onLogAdded = _onBattleLogAdded;
    await world.add(battleController);

    final config = _matchConfigs[_currentMatchIndex];
    final rng = Random();

    // Side A (아군) - 3체
    final sideAColor = _rangeColor(config.sideARange);
    for (int i = 0; i < 3; i++) {
      final unit = StrategicUnitComponent(
        unitName: '${config.sideALabel} ${i + 1}',
        maxHp: 80,
        maxMp: 20,
        attack: 20,
        defense: 10,
        speed: 60,
        luck: 8,
        level: 4,
        isPlayerSide: true,
        position: Vector2(
          200 + rng.nextDouble() * 60,
          250 + i * 150.0 + rng.nextDouble() * 30,
        ),
        personality: Personality.aggressive,
        weaponRange: config.sideARange,
      );
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerAlly(unit);
      _sideA.add(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(48, 48),
        unitColor: sideAColor,
        label: unit.unitName,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }

    // Side B (적) - 3체
    final sideBColor = _rangeColor(config.sideBRange);
    for (int i = 0; i < 3; i++) {
      final unit = StrategicUnitComponent(
        unitName: '${config.sideBLabel} ${i + 1}',
        maxHp: 80,
        maxMp: 20,
        attack: 20,
        defense: 10,
        speed: 60,
        luck: 8,
        level: 4,
        isPlayerSide: false,
        position: Vector2(
          900 + rng.nextDouble() * 60,
          250 + i * 150.0 + rng.nextDouble() * 30,
        ),
        personality: Personality.aggressive,
        weaponRange: config.sideBRange,
      );
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerEnemy(unit);
      _sideB.add(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(48, 48),
        unitColor: sideBColor,
        label: unit.unitName,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }

    // 전투 시작
    battleController.startBattle();
    _waitingForNextRound = false;
  }

  /// 현재 라운드 정리
  Future<void> _cleanupCurrentRound() async {
    // 렌더러 제거
    for (final ur in _unitRenderers) {
      ur.renderer.removeFromParent();
      ur.unit.removeFromParent();
    }
    _unitRenderers.clear();
    _sideA.clear();
    _sideB.clear();

    // BattleController 제거 (존재하는 경우)
    final existingControllers = world.children.whereType<BattleController>().toList();
    for (final bc in existingControllers) {
      bc.removeFromParent();
    }
  }

  Color _rangeColor(WeaponRange range) {
    return switch (range) {
      WeaponRange.melee => const Color(0xFFFF4444),
      WeaponRange.midRange => const Color(0xFFFFCC44),
      WeaponRange.longRange => const Color(0xFF4488FF),
    };
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

    if (_simulationComplete) return;

    // 렌더러 동기화
    for (final ur in _unitRenderers) {
      ur.renderer.position = ur.unit.position;

      final animState = switch (ur.unit.state) {
        UnitState.idle => 0,
        UnitState.moving => 1,
        UnitState.attacking => 2,
        UnitState.resting => 0,
        UnitState.dead => 4,
      };

      if (ur.unit.currentHp < ur.lastHp && !ur.unit.isDead) {
        ur.renderer.setAnimState(3);
        ur.hurtTimer = 0.3;
      } else if (ur.hurtTimer > 0) {
        ur.hurtTimer -= dt;
      } else {
        ur.renderer.setAnimState(animState);
      }
      ur.lastHp = ur.unit.currentHp;
    }

    // 라운드 종료 감지
    if (!_waitingForNextRound &&
        (battleController.state == BattleState.victory ||
         battleController.state == BattleState.defeat)) {
      _recordRoundResult();
      _waitingForNextRound = true;
      _roundDelay = 0.5; // 0.5초 딜레이 후 다음 라운드
    }

    // 대기 중 → 다음 라운드 시작
    if (_waitingForNextRound) {
      _roundDelay -= dt;
      if (_roundDelay <= 0) {
        _advanceToNextRound();
      }
    }

    // UI 업데이트
    _uiTimer += dt;
    if (_uiTimer >= 0.1) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  void _recordRoundResult() {
    final result = matchResults[_currentMatchIndex];
    result.totalRounds++;
    _totalCompletedRounds++;

    if (battleController.state == BattleState.victory) {
      // Side A (ally) 승리
      result.sideAWins++;
    } else {
      // Side B (enemy) 승리
      result.sideBWins++;
    }

    final config = _matchConfigs[_currentMatchIndex];
    onLogAdded?.call(
      '[Round ${result.totalRounds}] ${config.name}: '
      '${battleController.state == BattleState.victory ? config.sideALabel : config.sideBLabel} wins '
      '(${result.sideAWins}:${result.sideBWins})',
    );
  }

  void _advanceToNextRound() {
    final currentResult = matchResults[_currentMatchIndex];

    if (currentResult.totalRounds >= _maxRoundsPerMatch) {
      // 현재 매치 완료 → 다음 매치로
      _currentMatchIndex++;
      if (_currentMatchIndex >= _matchConfigs.length) {
        // 모든 매치 완료
        _simulationComplete = true;
        _reportFinalResults();
        return;
      }
    }

    // 다음 라운드 시작
    _startNewRound();
  }

  void _reportFinalResults() {
    onLogAdded?.call('');
    onLogAdded?.call('========== SIMULATION COMPLETE ==========');

    bool allPassed = true;
    for (int i = 0; i < matchResults.length; i++) {
      final r = matchResults[i];
      final config = _matchConfigs[i];
      final winRate = r.sideAWinRate * 100;
      final passed = winRate >= 60;
      if (!passed) allPassed = false;

      onLogAdded?.call(
        '${config.name}: ${config.sideALabel} ${winRate.toStringAsFixed(0)}% '
        '(${r.sideAWins}/${r.totalRounds}) '
        '${passed ? "PASS" : "FAIL"} (need 60%+)',
      );
    }

    onLogAdded?.call('');
    onLogAdded?.call(allPassed
        ? 'RESULT: ALL PASS - Range RPS system works as designed'
        : 'RESULT: SOME FAIL - Range RPS needs tuning');

    onStatusUpdate?.call(allPassed ? 'SIMULATION PASS' : 'SIMULATION FAIL');
  }

  void _notifyUI() {
    // Status
    if (onStatusUpdate != null && !_simulationComplete) {
      final config = _currentMatchIndex < _matchConfigs.length
          ? _matchConfigs[_currentMatchIndex]
          : null;
      final result = _currentMatchIndex < matchResults.length
          ? matchResults[_currentMatchIndex]
          : null;

      if (config != null && result != null) {
        onStatusUpdate!(
          '${config.name} | Round ${result.totalRounds + 1}/$_maxRoundsPerMatch '
          '| Total: $_totalCompletedRounds/${_maxRoundsPerMatch * 3}',
        );
      }
    }

    // Units
    if (onUnitsUpdated != null) {
      final units = <S2UnitInfo>[];
      for (final u in _sideA) {
        units.add(S2UnitInfo(
          name: u.unitName,
          currentHp: u.currentHp,
          maxHp: u.maxHp,
          isAlly: true,
          weaponRange: u.weaponRange.name,
          state: u.state.name,
        ));
      }
      for (final u in _sideB) {
        units.add(S2UnitInfo(
          name: u.unitName,
          currentHp: u.currentHp,
          maxHp: u.maxHp,
          isAlly: false,
          weaponRange: u.weaponRange.name,
          state: u.state.name,
        ));
      }
      onUnitsUpdated!(units);
    }

    // Metrics
    if (onMetricsUpdated != null) {
      final metricsMap = <String, dynamic>{
        'currentMatch': _currentMatchIndex + 1,
        'matchCount': _matchConfigs.length,
        'totalRounds': _totalCompletedRounds,
        'maxTotalRounds': _maxRoundsPerMatch * _matchConfigs.length,
        'simulationComplete': _simulationComplete,
      };

      // 각 매치별 결과
      for (int i = 0; i < matchResults.length; i++) {
        final r = matchResults[i];
        final prefix = 'match${i + 1}';
        metricsMap['${prefix}_sideAWins'] = r.sideAWins;
        metricsMap['${prefix}_sideBWins'] = r.sideBWins;
        metricsMap['${prefix}_total'] = r.totalRounds;
        metricsMap['${prefix}_sideARate'] = r.sideAWinRate;
        metricsMap['${prefix}_passed'] = r.sideAWinRate >= 0.6;
      }

      onMetricsUpdated!(metricsMap);
    }
  }

  void _onBattleStateChanged(BattleState state) {
    // 라운드별 승패는 _recordRoundResult에서 처리
  }

  void _onBattleLogAdded(BattleLogEntry entry) {
    // 전투 로그는 너무 많으므로 kill 로그만 전달
    if (entry.type == LogType.death || entry.type == LogType.system) {
      onLogAdded?.call('[${entry.time.toStringAsFixed(1)}s] ${entry.message}');
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);
}

/// 배경 컴포넌트
class _BackgroundComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConstants.logicalWidth, GameConstants.logicalHeight);
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final gridPaint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.x; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    final centerPaint = Paint()
      ..color = const Color(0x20FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      centerPaint,
    );
  }
}

/// 유닛 + 렌더러 매핑
class _UnitWithRenderer {
  final StrategicUnitComponent unit;
  final RiveUnitRenderer renderer;
  int lastHp;
  double hurtTimer = 0;

  _UnitWithRenderer({required this.unit, required this.renderer})
      : lastHp = unit.maxHp;
}
