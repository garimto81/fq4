import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../core/constants/game_constants.dart';
import '../game/components/units/ai_unit_component.dart';
import '../game/components/units/enemy_unit_component.dart';
import '../game/components/units/hybrid_unit_component.dart';
import '../game/components/units/rive_unit_renderer.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';

/// 유닛 정보 (Flutter UI 전달용)
class UnitInfo {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isAlly;
  final String personality;
  final String state;
  final bool isManualMode;

  const UnitInfo({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.isAlly,
    required this.personality,
    required this.state,
    required this.isManualMode,
  });

  double get hpRatio => maxHp > 0 ? currentHp / maxHp : 0;
}

/// Phase 0 POC: Gocha-Kyara AI/수동 전환 검증 게임
class PocT0Game extends FlameGame with HasKeyboardHandlerComponents {
  late final BattleController battleController;
  late final CombatSystem combatSystem;
  double speedMultiplier = 1.0;

  /// 아군 유닛 목록 (전환 대상)
  final List<_AllyEntry> _allyEntries = [];

  /// 전체 유닛+렌더러 매핑
  final List<_UnitWithRenderer> _unitRenderers = [];

  /// 현재 제어 대상 index (아군 중)
  int _currentControlIndex = 0;

  /// Flutter UI 콜백
  Function(String)? onStatusUpdate;
  Function(List<UnitInfo>)? onUnitsUpdated;
  Function(String)? onLogAdded;
  Function(Map<String, dynamic>)? onMetricsUpdated;

  double _uiTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 가로 1280x800 viewport
    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // 시스템 초기화
    combatSystem = CombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = _onBattleStateChanged;
    battleController.onLogAdded = _onBattleLogAdded;
    await world.add(battleController);

    // 배경색 (어두운 회색)
    await world.add(_BackgroundComponent());

    // 유닛 스폰
    await _spawnUnits();

    // 자동 전투 시작 (약간의 딜레이)
    Future.delayed(const Duration(milliseconds: 500), () {
      startBattle();
    });
  }

  Future<void> _spawnUnits() async {
    final rng = Random(42);

    // 아군 3체 스폰
    // 아레스 (주인공) - HybridUnitComponent
    final ares = await _spawnHybridAlly(
      name: 'Ares',
      level: 5,
      hp: 100,
      mp: 30,
      atk: 25,
      def: 15,
      spd: 80,
      luck: 10,
      personality: Personality.aggressive,
      pos: Vector2(200 + rng.nextDouble() * 40, 300 + rng.nextDouble() * 40),
      color: const Color(0xFFFF4444), // aggressive = red
    );

    // 타로 - AIUnitComponent
    await _spawnAIAlly(
      name: 'Taro',
      level: 3,
      hp: 80,
      mp: 40,
      atk: 20,
      def: 12,
      spd: 70,
      luck: 8,
      personality: Personality.balanced,
      pos: Vector2(180 + rng.nextDouble() * 40, 420 + rng.nextDouble() * 40),
      color: const Color(0xFFFFCC44), // balanced = yellow
    );

    // 엘레인 - AIUnitComponent
    await _spawnAIAlly(
      name: 'Elaine',
      level: 3,
      hp: 60,
      mp: 50,
      atk: 15,
      def: 10,
      spd: 65,
      luck: 12,
      personality: Personality.defensive,
      pos: Vector2(160 + rng.nextDouble() * 40, 540 + rng.nextDouble() * 40),
      color: const Color(0xFF4488FF), // defensive = blue
    );

    // 적 5체 스폰
    for (int i = 0; i < 5; i++) {
      await _spawnEnemy(
        name: 'Goblin ${String.fromCharCode(65 + i)}', // A~E
        level: 3,
        hp: 40,
        mp: 0,
        atk: 12,
        def: 5,
        spd: 50,
        luck: 3,
        pos: Vector2(
          900 + rng.nextDouble() * 200,
          200 + i * 120.0 + rng.nextDouble() * 40,
        ),
        color: const Color(0xFFAA44FF), // enemy = purple
      );
    }

    // 주인공 전환 콜백 설정
    ares.onSwitchPrev = _switchToPrevAlly;
    ares.onSwitchNext = _switchToNextAlly;
  }

  /// HybridUnitComponent 스폰 (직접 제어 가능 유닛)
  Future<HybridUnitComponent> _spawnHybridAlly({
    required String name,
    required int level,
    required int hp,
    required int mp,
    required int atk,
    required int def,
    required int spd,
    required int luck,
    required Personality personality,
    required Vector2 pos,
    required Color color,
  }) async {
    final unit = HybridUnitComponent(
      unitName: name,
      maxHp: hp,
      maxMp: mp,
      attack: atk,
      defense: def,
      speed: spd,
      luck: luck,
      level: level,
      isPlayerSide: true,
      position: pos,
      personality: personality,
    );
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;

    await world.add(unit);
    battleController.registerAlly(unit);

    // Renderer
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(48, 48),
      unitColor: color,
      label: name,
    );
    await world.add(renderer);

    final entry = _UnitWithRenderer(unit: unit, renderer: renderer);
    _unitRenderers.add(entry);
    _allyEntries.add(_AllyEntry(unit: unit, renderer: renderer, personality: personality));

    return unit;
  }

  /// AIUnitComponent 스폰 (AI 전용 아군)
  Future<AIUnitComponent> _spawnAIAlly({
    required String name,
    required int level,
    required int hp,
    required int mp,
    required int atk,
    required int def,
    required int spd,
    required int luck,
    required Personality personality,
    required Vector2 pos,
    required Color color,
  }) async {
    final unit = AIUnitComponent(
      unitName: name,
      maxHp: hp,
      maxMp: mp,
      attack: atk,
      defense: def,
      speed: spd,
      luck: luck,
      level: level,
      isPlayerSide: true,
      position: pos,
      personality: personality,
    );
    unit.isPlayerControlled = false;
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;

    await world.add(unit);
    battleController.registerAlly(unit);

    // Renderer
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(48, 48),
      unitColor: color,
      label: name,
    );
    await world.add(renderer);

    final entry = _UnitWithRenderer(unit: unit, renderer: renderer);
    _unitRenderers.add(entry);
    _allyEntries.add(_AllyEntry(unit: unit, renderer: renderer, personality: personality));

    return unit;
  }

  /// EnemyUnitComponent 스폰
  Future<EnemyUnitComponent> _spawnEnemy({
    required String name,
    required int level,
    required int hp,
    required int mp,
    required int atk,
    required int def,
    required int spd,
    required int luck,
    required Vector2 pos,
    required Color color,
  }) async {
    final unit = EnemyUnitComponent(
      unitName: name,
      maxHp: hp,
      maxMp: mp,
      attack: atk,
      defense: def,
      speed: spd,
      luck: luck,
      level: level,
      position: pos,
    );
    unit.battleController = battleController;
    unit.combatSystem = combatSystem;

    await world.add(unit);
    battleController.registerEnemy(unit);

    // Renderer
    final renderer = RiveUnitRenderer(
      position: pos.clone(),
      size: Vector2(48, 48),
      unitColor: color,
      label: name,
    );
    await world.add(renderer);

    _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));

    return unit;
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  /// 전투 시작
  void startBattle() {
    battleController.startBattle();
  }

  /// 이전 아군으로 전환
  void _switchToPrevAlly() {
    _switchAlly(-1);
  }

  /// 다음 아군으로 전환
  void _switchToNextAlly() {
    _switchAlly(1);
  }

  /// 아군 유닛 전환
  void _switchAlly(int direction) {
    if (_allyEntries.isEmpty) return;

    // 현재 유닛 수동 해제
    final currentEntry = _allyEntries[_currentControlIndex];
    if (currentEntry.unit is HybridUnitComponent) {
      (currentEntry.unit as HybridUnitComponent).releaseManualControl();
    } else {
      currentEntry.unit.isPlayerControlled = false;
    }

    // 다음 유닛 선택 (살아있는 아군만)
    int attempts = _allyEntries.length;
    do {
      _currentControlIndex =
          (_currentControlIndex + direction) % _allyEntries.length;
      if (_currentControlIndex < 0) {
        _currentControlIndex += _allyEntries.length;
      }
      attempts--;
    } while (_allyEntries[_currentControlIndex].unit.isDead && attempts > 0);

    // 새 유닛에 전환 콜백 재설정
    final newEntry = _allyEntries[_currentControlIndex];
    if (newEntry.unit is HybridUnitComponent) {
      final hybrid = newEntry.unit as HybridUnitComponent;
      hybrid.onSwitchPrev = _switchToPrevAlly;
      hybrid.onSwitchNext = _switchToNextAlly;
    }
    // AIUnitComponent인 경우 관전만 가능 (키보드 미수신)
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

    // 렌더러 동기화 (위치, 애니메이션)
    for (final ur in _unitRenderers) {
      ur.renderer.position = ur.unit.position;

      // 애니메이션 상태 동기화
      final animState = switch (ur.unit.state) {
        UnitState.idle => 0,
        UnitState.moving => 1,
        UnitState.attacking => 2,
        UnitState.resting => 0,
        UnitState.dead => 4,
      };

      // Hurt 감지 (HP 감소)
      if (ur.unit.currentHp < ur.lastHp && !ur.unit.isDead) {
        ur.renderer.setAnimState(3); // hurt
        ur.hurtTimer = 0.3;
      } else if (ur.hurtTimer > 0) {
        ur.hurtTimer -= dt;
      } else {
        ur.renderer.setAnimState(animState);
      }
      ur.lastHp = ur.unit.currentHp;
    }

    // 0.2초 간격 UI 콜백
    _uiTimer += dt;
    if (_uiTimer >= 0.2) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  void _notifyUI() {
    // Status 콜백
    if (onStatusUpdate != null) {
      final currentAlly = _allyEntries.isNotEmpty
          ? _allyEntries[_currentControlIndex]
          : null;
      final isManual = currentAlly?.unit is HybridUnitComponent &&
          (currentAlly!.unit as HybridUnitComponent).isInManualMode;
      final timer = currentAlly?.unit is HybridUnitComponent
          ? (currentAlly!.unit as HybridUnitComponent).isInManualMode
              ? '${(currentAlly.unit as HybridUnitComponent).autoRevertRemaining.toStringAsFixed(1)}s'
              : ''
          : '';
      final mode = isManual ? 'MANUAL' : 'AUTO';
      final controlledName = currentAlly?.unit.unitName ?? 'N/A';
      onStatusUpdate!('$mode | $controlledName${timer.isNotEmpty ? " ($timer)" : ""}');
    }

    // Units 콜백
    if (onUnitsUpdated != null) {
      final units = <UnitInfo>[];

      // 아군
      for (final entry in _allyEntries) {
        final unit = entry.unit;
        final isManual = unit is HybridUnitComponent && unit.isInManualMode;
        units.add(UnitInfo(
          name: unit.unitName,
          currentHp: unit.currentHp,
          maxHp: unit.maxHp,
          isAlly: true,
          personality: entry.personality.name,
          state: unit.state.name,
          isManualMode: isManual,
        ));
      }

      // 적
      for (final enemy in battleController.enemies) {
        units.add(UnitInfo(
          name: enemy.unitName,
          currentHp: enemy.currentHp,
          maxHp: enemy.maxHp,
          isAlly: false,
          personality: 'enemy',
          state: enemy.state.name,
          isManualMode: false,
        ));
      }

      onUnitsUpdated!(units);
    }

    // Metrics 콜백
    if (onMetricsUpdated != null) {
      final currentAlly = _allyEntries.isNotEmpty
          ? _allyEntries[_currentControlIndex]
          : null;
      double inputLatency = 0;
      if (currentAlly?.unit is HybridUnitComponent) {
        inputLatency =
            (currentAlly!.unit as HybridUnitComponent).averageInputLatency;
      }

      onMetricsUpdated!({
        'inputLatency': inputLatency,
        'battleTime': battleController.battleTime,
        'battleState': battleController.state.name,
        'alliesAlive': battleController.allies.where((u) => u.isAlive).length,
        'enemiesAlive': battleController.enemies.where((u) => u.isAlive).length,
        'totalLogs': battleController.battleLog.length,
      });
    }
  }

  void _onBattleStateChanged(BattleState state) {
    onStatusUpdate?.call('Battle: ${state.name.toUpperCase()}');
  }

  void _onBattleLogAdded(BattleLogEntry entry) {
    onLogAdded?.call('[${entry.time.toStringAsFixed(1)}s] ${entry.message}');
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);
}

/// 배경 컴포넌트 (어두운 회색 격자)
class _BackgroundComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(GameConstants.logicalWidth, GameConstants.logicalHeight);
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    // 격자 그리기 (시각적 참조)
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

    // 중앙선
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

/// 아군 엔트리 (유닛 + 렌더러 + 성격)
class _AllyEntry {
  final AIUnitComponent unit;
  final RiveUnitRenderer renderer;
  final Personality personality;

  _AllyEntry({
    required this.unit,
    required this.renderer,
    required this.personality,
  });
}

/// 유닛 + 렌더러 매핑 (POC-5 패턴)
class _UnitWithRenderer {
  final UnitComponent unit;
  final RiveUnitRenderer renderer;
  int lastHp;
  double hurtTimer = 0;

  _UnitWithRenderer({required this.unit, required this.renderer})
      : lastHp = unit.maxHp;
}
