// POC-S4: Player Strategic Intervention Effect Verification
//
// Purpose: Verify that when a player directly controls 1 unit using
// WASD + Space for back attacks and weapon-type exploitation, the
// battle outcome changes significantly compared to pure AI auto-battle.
// (Auto-battle vs Manual intervention comparison)
//
// Metrics tracked:
// - Auto wins / Manual wins
// - Average battle time per mode
// - Back attack ratio comparison (manual should be higher)

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../core/constants/ai_constants.dart';
import '../core/constants/game_constants.dart';
import '../core/constants/strategic_combat_constants.dart';
import '../game/components/units/ai_unit_component.dart';
import '../game/components/units/hybrid_unit_component.dart';
import '../game/components/units/rive_unit_renderer.dart';
import '../game/components/units/strategic_unit_component.dart';
import '../game/components/units/unit_component.dart';
import '../game/systems/battle_controller.dart';
import '../game/systems/combat_system.dart';
import '../game/systems/strategic_combat_system.dart';

/// Unit info for Flutter UI communication
class S4UnitInfo {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isAlly;
  final String weaponRange;
  final String state;
  final bool isManualMode;

  const S4UnitInfo({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.isAlly,
    required this.weaponRange,
    required this.state,
    required this.isManualMode,
  });

  double get hpRatio => maxHp > 0 ? currentHp / maxHp : 0;
}

/// POC-S4: Player strategic intervention effect verification game
class PocS4InterventionGame extends FlameGame with HasKeyboardHandlerComponents {
  late BattleController battleController;
  late CombatSystem combatSystem;
  late StrategicCombatSystem strategicCombatSystem;

  /// Current mode: true = manual (WASD), false = auto (AI only)
  bool isManualMode = false;
  double speedMultiplier = 1.0;

  /// The player-controllable leader unit
  HybridUnitComponent? _leader;

  /// All unit + renderer pairs (rebuild on reset)
  final List<_UnitWithRenderer> _unitRenderers = [];

  /// All strategic units (AI-only allies)
  final List<StrategicUnitComponent> _aiAllies = [];

  /// All ally units for Q/E switching (leader + AI allies)
  final List<AIUnitComponent> _allAllies = [];

  /// Currently controlled unit index in _allAllies
  int _controlledIndex = 0;

  /// Battle statistics
  int autoWins = 0;
  int manualWins = 0;
  final List<double> _autoBattleTimes = [];
  final List<double> _manualBattleTimes = [];
  int _autoBackAttacks = 0;
  int _autoTotalAttacks = 0;
  int _manualBackAttacks = 0;
  int _manualTotalAttacks = 0;

  /// Reset timer
  double _resetTimer = -1;
  bool _battleEnded = false;

  /// Flutter UI callbacks
  Function(String)? onStatusUpdate;
  Function(List<S4UnitInfo>)? onUnitsUpdated;
  Function(String)? onLogAdded;
  Function(Map<String, dynamic>)? onMetricsUpdated;

  double _uiTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // Background
    await world.add(_BackgroundComponent());

    // Initial battle setup
    await _setupBattle();
  }

  Future<void> _setupBattle() async {
    // Systems
    combatSystem = CombatSystem();
    strategicCombatSystem = StrategicCombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = _onBattleStateChanged;
    battleController.onLogAdded = _onBattleLogAdded;
    await world.add(battleController);

    _battleEnded = false;
    _resetTimer = -1;

    await _spawnUnits();

    // Q/E 유닛 전환 콜백 (모드 무관하게 항상 바인딩)
    final leader = _leader;
    if (leader != null) {
      leader.onSwitchPrev = () => _switchUnit(-1);
      leader.onSwitchNext = () => _switchUnit(1);
    }

    // Auto-start
    Future.delayed(const Duration(milliseconds: 500), () {
      battleController.startBattle();
    });
  }

  Future<void> _spawnUnits() async {
    final rng = Random();

    // === Leader (HybridUnitComponent, melee, aggressive) ===
    final leader = HybridUnitComponent(
      unitName: 'Leader',
      maxHp: 120,
      maxMp: 30,
      attack: 28,
      defense: 15,
      speed: 80,
      luck: 10,
      level: 5,
      isPlayerSide: true,
      position: Vector2(200, 400),
      personality: Personality.aggressive,
    );
    leader.battleController = battleController;
    leader.combatSystem = combatSystem;
    // In auto mode, leader is AI-controlled
    if (!isManualMode) {
      leader.isPlayerControlled = false;
    }

    await world.add(leader);
    battleController.registerAlly(leader);
    _leader = leader;
    _allAllies.add(leader);

    final leaderRenderer = RiveUnitRenderer(
      position: leader.position.clone(),
      size: Vector2(48, 48),
      unitColor: const Color(0xFFFFCC44),
      label: 'Leader',
    );
    await world.add(leaderRenderer);
    _unitRenderers.add(_UnitWithRenderer(unit: leader, renderer: leaderRenderer));

    // === 4 AI Allies ===
    final allyConfigs = [
      (name: 'Guard-A', weapon: WeaponRange.melee, personality: Personality.defensive,
       hp: 90, atk: 22, def: 16, spd: 65, y: 280.0, color: const Color(0xFF4488FF)),
      (name: 'Scout-B', weapon: WeaponRange.midRange, personality: Personality.aggressive,
       hp: 70, atk: 20, def: 10, spd: 75, y: 350.0, color: const Color(0xFF44BBFF)),
      (name: 'Mage-C', weapon: WeaponRange.midRange, personality: Personality.balanced,
       hp: 60, atk: 24, def: 8, spd: 60, y: 450.0, color: const Color(0xFF88CCFF)),
      (name: 'Archer-D', weapon: WeaponRange.longRange, personality: Personality.defensive,
       hp: 55, atk: 18, def: 6, spd: 55, y: 520.0, color: const Color(0xFFAADDFF)),
    ];

    for (final cfg in allyConfigs) {
      final unit = StrategicUnitComponent(
        unitName: cfg.name,
        maxHp: cfg.hp,
        maxMp: 20,
        attack: cfg.atk,
        defense: cfg.def,
        speed: cfg.spd,
        luck: 7,
        level: 4,
        isPlayerSide: true,
        position: Vector2(180 + rng.nextDouble() * 60, cfg.y + rng.nextDouble() * 20),
        personality: cfg.personality,
        weaponRange: cfg.weapon,
      );
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerAlly(unit);
      _aiAllies.add(unit);
      _allAllies.add(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(42, 42),
        unitColor: cfg.color,
        label: cfg.name,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }

    // === 5 Enemies ===
    final enemyConfigs = [
      (name: 'Orc-1', weapon: WeaponRange.melee, hp: 80, atk: 20, def: 12, spd: 60, y: 250.0),
      (name: 'Orc-2', weapon: WeaponRange.melee, hp: 75, atk: 22, def: 10, spd: 65, y: 340.0),
      (name: 'Archer-3', weapon: WeaponRange.midRange, hp: 55, atk: 18, def: 7, spd: 55, y: 420.0),
      (name: 'Mage-4', weapon: WeaponRange.midRange, hp: 50, atk: 24, def: 6, spd: 50, y: 500.0),
      (name: 'Sniper-5', weapon: WeaponRange.longRange, hp: 45, atk: 16, def: 5, spd: 48, y: 580.0),
    ];

    for (final cfg in enemyConfigs) {
      final unit = StrategicUnitComponent(
        unitName: cfg.name,
        maxHp: cfg.hp,
        maxMp: 10,
        attack: cfg.atk,
        defense: cfg.def,
        speed: cfg.spd,
        luck: 5,
        level: 4,
        isPlayerSide: false,
        position: Vector2(900 + rng.nextDouble() * 100, cfg.y + rng.nextDouble() * 20),
        personality: Personality.aggressive,
        weaponRange: cfg.weapon,
      );
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerEnemy(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(42, 42),
        unitColor: const Color(0xFFFF4444),
        label: cfg.name,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  /// Switch between AUTO and MANUAL mode
  void switchMode(bool manual) {
    isManualMode = manual;
    final leader = _leader;
    if (leader == null) return;

    if (manual) {
      // 첫 번째 살아있는 아군에게 제어 부여
      _controlledIndex = 0;
      _applyControlToUnit(_controlledIndex);

      // Q/E 유닛 전환 콜백
      leader.onSwitchPrev = () => _switchUnit(-1);
      leader.onSwitchNext = () => _switchUnit(1);
    } else {
      // 모든 제어 해제 → 전원 AI
      leader.controlProxy = null;
      leader.releaseManualControl();
      for (final ally in _aiAllies) {
        ally.isPlayerControlled = false;
      }
    }
  }

  /// Q/E로 유닛 전환 (direction: -1=Q, +1=E)
  void _switchUnit(int direction) {
    if (_allAllies.isEmpty) return;

    // 현재 제어 유닛 해제
    _releaseCurrentUnit();

    // 다음 살아있는 유닛 찾기
    for (int i = 0; i < _allAllies.length; i++) {
      _controlledIndex = (_controlledIndex + direction) % _allAllies.length;
      if (_controlledIndex < 0) _controlledIndex += _allAllies.length;
      if (!_allAllies[_controlledIndex].isDead) break;
    }

    _applyControlToUnit(_controlledIndex);

    final unit = _allAllies[_controlledIndex];
    onLogAdded?.call('[Switch] Now controlling: ${unit.unitName}');
  }

  /// 현재 제어 유닛 해제
  void _releaseCurrentUnit() {
    final leader = _leader;
    if (leader == null) return;

    leader.controlProxy = null;

    for (final ally in _allAllies) {
      if (ally is HybridUnitComponent) {
        ally.releaseManualControl();
      } else {
        ally.isPlayerControlled = false;
        if (ally.state == UnitState.moving) {
          ally.velocity = Vector2.zero();
          ally.state = UnitState.idle;
        }
      }
    }
  }

  /// 지정 인덱스의 유닛에 제어 부여
  void _applyControlToUnit(int index) {
    final leader = _leader;
    if (leader == null || _allAllies.isEmpty) return;

    final target = _allAllies[index];

    if (target == leader) {
      // Leader 직접 제어
      leader.controlProxy = null;
      leader.activateManualControl();
    } else {
      // 다른 유닛 제어: leader가 proxy로 전달
      leader.controlProxy = target;
      leader.isPlayerControlled = false; // leader 자신은 AI
      target.isPlayerControlled = true;  // 타겟만 수동
    }
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

    // Track back attacks from strategic units
    _trackBackAttacks();

    // Renderer sync
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

    // Auto-reset timer
    if (_resetTimer > 0) {
      _resetTimer -= dt;
      if (_resetTimer <= 0) {
        _resetTimer = -1;
        _performReset();
      }
    }

    // UI callback
    _uiTimer += dt;
    if (_uiTimer >= 0.1) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  /// Track cumulative back attack stats from strategic units
  void _trackBackAttacks() {
    // Stats are collected in _onBattleStateChanged when battle ends.
    // This method is called every frame for future real-time tracking.
  }

  void _onBattleStateChanged(BattleState state) {
    if (_battleEnded) return;

    if (state == BattleState.victory || state == BattleState.defeat) {
      _battleEnded = true;
      final time = battleController.battleTime;

      // Collect back attack stats from all strategic units
      int backAttacks = 0;
      int totalAttacks = 0;
      for (final unit in _aiAllies) {
        backAttacks += unit.backAttacks;
        totalAttacks += unit.backAttacks + unit.flankedAttacks;
      }
      // Add leader stats if it has strategic combat
      for (final ur in _unitRenderers) {
        if (ur.unit is StrategicUnitComponent) {
          // Already counted in _aiAllies
        }
      }

      if (isManualMode) {
        if (state == BattleState.victory) manualWins++;
        _manualBattleTimes.add(time);
        _manualBackAttacks += backAttacks;
        _manualTotalAttacks += max(1, totalAttacks);
      } else {
        if (state == BattleState.victory) autoWins++;
        _autoBattleTimes.add(time);
        _autoBackAttacks += backAttacks;
        _autoTotalAttacks += max(1, totalAttacks);
      }

      onLogAdded?.call(
        '=== ${state == BattleState.victory ? "VICTORY" : "DEFEAT"} '
        '(${isManualMode ? "MANUAL" : "AUTO"}, ${time.toStringAsFixed(1)}s) ===',
      );

      // Auto-reset after 3 seconds
      _resetTimer = 3.0;
    }
  }

  void _onBattleLogAdded(BattleLogEntry entry) {
    onLogAdded?.call('[${entry.time.toStringAsFixed(1)}s] ${entry.message}');
  }

  void _performReset() {
    // Remove all units and renderers
    for (final ur in _unitRenderers) {
      ur.unit.removeFromParent();
      ur.renderer.removeFromParent();
    }
    _unitRenderers.clear();
    _aiAllies.clear();
    _allAllies.clear();
    _controlledIndex = 0;

    // Remove old battle controller
    battleController.removeFromParent();

    // Re-setup
    _setupBattle();
  }

  void _notifyUI() {
    // Status
    final mode = isManualMode ? 'MANUAL' : 'AUTO';
    String unitStatus = '';
    if (isManualMode && _allAllies.isNotEmpty && _controlledIndex < _allAllies.length) {
      final controlled = _allAllies[_controlledIndex];
      unitStatus = ' | ${controlled.unitName} HP:${controlled.currentHp}/${controlled.maxHp}';
      unitStatus += ' | Q/E: Switch';
    } else {
      final leader = _leader;
      if (leader != null && !leader.isDead) {
        unitStatus = ' | HP: ${leader.currentHp}/${leader.maxHp}';
      }
    }
    final resetInfo = _resetTimer > 0
        ? ' | Reset in ${_resetTimer.toStringAsFixed(0)}s'
        : '';

    onStatusUpdate?.call('$mode$unitStatus$resetInfo');

    // Units
    if (onUnitsUpdated != null) {
      final units = <S4UnitInfo>[];
      // 현재 제어 중인 유닛 판별
      final controlledUnit = isManualMode &&
              _allAllies.isNotEmpty &&
              _controlledIndex < _allAllies.length
          ? _allAllies[_controlledIndex]
          : null;

      for (final ur in _unitRenderers) {
        final isControlled = isManualMode && ur.unit == controlledUnit;
        String weapon = 'melee';
        if (ur.unit is StrategicUnitComponent) {
          weapon = (ur.unit as StrategicUnitComponent).weaponRange.name;
        }
        units.add(S4UnitInfo(
          name: ur.unit.unitName,
          currentHp: ur.unit.currentHp,
          maxHp: ur.unit.maxHp,
          isAlly: ur.unit.isPlayerSide,
          weaponRange: weapon,
          state: ur.unit.state.name,
          isManualMode: isControlled,
        ));
      }
      onUnitsUpdated!(units);
    }

    // Metrics
    if (onMetricsUpdated != null) {
      final avgAutoTime = _autoBattleTimes.isEmpty
          ? 0.0
          : _autoBattleTimes.reduce((a, b) => a + b) / _autoBattleTimes.length;
      final avgManualTime = _manualBattleTimes.isEmpty
          ? 0.0
          : _manualBattleTimes.reduce((a, b) => a + b) / _manualBattleTimes.length;

      final autoBackPct = _autoTotalAttacks > 0
          ? (_autoBackAttacks / _autoTotalAttacks * 100)
          : 0.0;
      final manualBackPct = _manualTotalAttacks > 0
          ? (_manualBackAttacks / _manualTotalAttacks * 100)
          : 0.0;

      onMetricsUpdated!({
        'mode': isManualMode ? 'manual' : 'auto',
        'autoWins': autoWins,
        'manualWins': manualWins,
        'avgAutoTime': avgAutoTime,
        'avgManualTime': avgManualTime,
        'autoBackAttackPct': autoBackPct,
        'manualBackAttackPct': manualBackPct,
        'autoBattles': _autoBattleTimes.length,
        'manualBattles': _manualBattleTimes.length,
        'battleTime': battleController.battleTime,
      });
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);
}

/// Background with grid and zone labels
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

    _drawLabel(canvas, 60, 30, 'PLAYER TEAM');
    _drawLabel(canvas, size.x - 100, 30, 'ENEMY TEAM');
  }

  void _drawLabel(Canvas canvas, double x, double y, String text) {
    final paragraphBuilder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 12,
    ))
      ..pushStyle(TextStyle(color: const Color(0x40FFFFFF)))
      ..addText(text);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ParagraphConstraints(width: 140));
    canvas.drawParagraph(paragraph, Offset(x - 70, y));
  }
}

/// Unit + renderer pair
class _UnitWithRenderer {
  final UnitComponent unit;
  final RiveUnitRenderer renderer;
  int lastHp;
  double hurtTimer = 0;

  _UnitWithRenderer({required this.unit, required this.renderer})
      : lastHp = unit.maxHp;
}
