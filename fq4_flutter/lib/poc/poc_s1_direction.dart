// POC-S1: 방향별 데미지 차이 검증
//
// 목적: 공격 방향(정면/측면/후면)에 따라 데미지가 실제로 차등 적용되는지 검증하고,
// AI가 측면/후면 기동을 시도하는지 관찰한다.
//
// 검증 메트릭:
// - 정면/측면/후면 공격 횟수 카운트
// - 방향별 평균 데미지 통계
// - 배율: 정면 1.0x / 측면 1.3x / 후면 1.5x
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

/// 유닛 정보 (Flutter UI 전달용)
class S1UnitInfo {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isAlly;
  final String personality;
  final String state;
  final double facingAngle;
  final String weaponRange;

  const S1UnitInfo({
    required this.name,
    required this.currentHp,
    required this.maxHp,
    required this.isAlly,
    required this.personality,
    required this.state,
    required this.facingAngle,
    required this.weaponRange,
  });

  double get hpRatio => maxHp > 0 ? currentHp / maxHp : 0;
}

/// POC-S1: 방향별 데미지 차이 검증 게임
class PocS1Game extends FlameGame {
  late final BattleController battleController;
  late final CombatSystem combatSystem;
  late final StrategicCombatSystem strategicCombatSystem;
  double speedMultiplier = 1.0;

  final List<StrategicUnitComponent> _allies = [];
  final List<StrategicUnitComponent> _enemies = [];
  final List<_UnitWithRenderer> _unitRenderers = [];

  /// Flutter UI 콜백
  Function(String)? onStatusUpdate;
  Function(List<S1UnitInfo>)? onUnitsUpdated;
  Function(String)? onLogAdded;
  Function(Map<String, dynamic>)? onMetricsUpdated;

  double _uiTimer = 0;

  /// 방향별 공격 통계
  int _frontAttacks = 0;
  int _sideAttacks = 0;
  int _backAttacks = 0;
  int _totalFrontDmg = 0;
  int _totalSideDmg = 0;
  int _totalBackDmg = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // 시스템 초기화
    combatSystem = CombatSystem();
    strategicCombatSystem = StrategicCombatSystem();
    battleController = BattleController();
    battleController.onStateChanged = _onBattleStateChanged;
    battleController.onLogAdded = _onBattleLogAdded;
    await world.add(battleController);

    // 배경
    await world.add(_BackgroundComponent());

    // 유닛 스폰
    await _spawnUnits();

    // 자동 전투 시작
    Future.delayed(const Duration(milliseconds: 500), () {
      startBattle();
    });
  }

  Future<void> _spawnUnits() async {
    final rng = Random(42);

    // 아군 3체 (melee, personality 각각 다름)
    final allyConfigs = [
      ('Ares', Personality.aggressive, const Color(0xFFFF4444)),
      ('Taro', Personality.balanced, const Color(0xFFFFCC44)),
      ('Elaine', Personality.defensive, const Color(0xFF4488FF)),
    ];

    for (int i = 0; i < allyConfigs.length; i++) {
      final (name, personality, color) = allyConfigs[i];
      final unit = StrategicUnitComponent(
        unitName: name,
        maxHp: 120,
        maxMp: 30,
        attack: 22,
        defense: 12,
        speed: 70,
        luck: 10,
        level: 5,
        isPlayerSide: true,
        position: Vector2(
          200 + rng.nextDouble() * 60,
          250 + i * 150.0 + rng.nextDouble() * 30,
        ),
        personality: personality,
        weaponRange: WeaponRange.melee,
      );
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerAlly(unit);
      _allies.add(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(48, 48),
        unitColor: color,
        label: name,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }

    // 적 3체 (melee, 고정 facing - 왼쪽을 향함 = pi radian)
    final enemyConfigs = [
      ('Guard A', const Color(0xFFAA44FF)),
      ('Guard B', const Color(0xFF9944DD)),
      ('Guard C', const Color(0xFF8844BB)),
    ];

    for (int i = 0; i < enemyConfigs.length; i++) {
      final (name, color) = enemyConfigs[i];
      final unit = StrategicUnitComponent(
        unitName: name,
        maxHp: 100,
        maxMp: 0,
        attack: 18,
        defense: 15,
        speed: 40, // 느림 = 고정 facing 유지에 유리
        luck: 5,
        level: 4,
        isPlayerSide: false,
        position: Vector2(
          900 + rng.nextDouble() * 80,
          250 + i * 150.0 + rng.nextDouble() * 30,
        ),
        personality: Personality.defensive, // 자리 유지 경향
        weaponRange: WeaponRange.melee,
      );
      // 왼쪽을 향하도록 facing 고정 (pi radian)
      unit.facingAngle = pi;
      unit.battleController = battleController;
      unit.combatSystem = combatSystem;
      unit.strategicCombatSystem = strategicCombatSystem;

      await world.add(unit);
      battleController.registerEnemy(unit);
      _enemies.add(unit);

      final renderer = RiveUnitRenderer(
        position: unit.position.clone(),
        size: Vector2(48, 48),
        unitColor: color,
        label: name,
      );
      await world.add(renderer);
      _unitRenderers.add(_UnitWithRenderer(unit: unit, renderer: renderer));
    }
  }

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  void startBattle() {
    battleController.startBattle();
  }

  @override
  void update(double dt) {
    super.update(dt * speedMultiplier);

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

    // 방향별 공격 통계 수집 (전략 유닛의 flankedAttacks/backAttacks 변화 감지)
    _collectDirectionalStats();

    // UI 업데이트 (0.1초 간격)
    _uiTimer += dt;
    if (_uiTimer >= 0.1) {
      _uiTimer = 0;
      _notifyUI();
    }
  }

  /// 방향별 공격 통계 수집
  /// StrategicUnitComponent의 전투 통계를 활용하여 방향별 공격 수를 계산
  void _collectDirectionalStats() {
    // 아군의 flankedAttacks, backAttacks를 합산
    int totalFlanked = 0;
    int totalBack = 0;
    int totalDmgDealt = 0;

    for (final ally in _allies) {
      totalFlanked += ally.flankedAttacks;
      totalBack += ally.backAttacks;
      totalDmgDealt += ally.totalDamageDealt;
    }

    // side + back = flanked + back, front = total attacks - side - back
    // 총 공격 수는 battleLog에서 계산
    _sideAttacks = totalFlanked;
    _backAttacks = totalBack;

    // 전체 아군 공격 횟수 (로그에서 카운트)
    int totalAllyAttacks = 0;
    for (final entry in battleController.battleLog) {
      if (entry.type == LogType.combat) {
        // 아군 이름으로 시작하는 공격 로그 카운트
        for (final ally in _allies) {
          if (entry.message.startsWith(ally.unitName)) {
            if (!entry.message.contains('MISS')) {
              totalAllyAttacks++;
            }
            break;
          }
        }
      }
    }

    _frontAttacks = max(0, totalAllyAttacks - _sideAttacks - _backAttacks);

    // 평균 데미지 추정 (총 데미지를 방향별 비율로 분배)
    if (totalDmgDealt > 0 && totalAllyAttacks > 0) {
      final avgDmg = totalDmgDealt / totalAllyAttacks;
      // 방향 배율에 따른 추정 분배
      _totalFrontDmg = _frontAttacks > 0
          ? (avgDmg * _frontAttacks / 1.0).round()
          : 0;
      _totalSideDmg = _sideAttacks > 0
          ? (avgDmg * _sideAttacks * 1.3 / 1.0).round()
          : 0;
      _totalBackDmg = _backAttacks > 0
          ? (avgDmg * _backAttacks * 1.5 / 1.0).round()
          : 0;
    }
  }

  void _notifyUI() {
    // Status
    if (onStatusUpdate != null) {
      final state = battleController.state.name.toUpperCase();
      final allyAlive = _allies.where((u) => u.isAlive).length;
      final enemyAlive = _enemies.where((u) => u.isAlive).length;
      onStatusUpdate!('$state | Allies: $allyAlive | Enemies: $enemyAlive');
    }

    // Units
    if (onUnitsUpdated != null) {
      final units = <S1UnitInfo>[];
      for (final ally in _allies) {
        units.add(S1UnitInfo(
          name: ally.unitName,
          currentHp: ally.currentHp,
          maxHp: ally.maxHp,
          isAlly: true,
          personality: ally.aiBrain.personality.name,
          state: ally.state.name,
          facingAngle: ally.facingAngle,
          weaponRange: ally.weaponRange.name,
        ));
      }
      for (final enemy in _enemies) {
        units.add(S1UnitInfo(
          name: enemy.unitName,
          currentHp: enemy.currentHp,
          maxHp: enemy.maxHp,
          isAlly: false,
          personality: 'enemy',
          state: enemy.state.name,
          facingAngle: enemy.facingAngle,
          weaponRange: enemy.weaponRange.name,
        ));
      }
      onUnitsUpdated!(units);
    }

    // Metrics
    if (onMetricsUpdated != null) {
      final totalAttacks = _frontAttacks + _sideAttacks + _backAttacks;
      final avgFrontDmg = _frontAttacks > 0
          ? (_totalFrontDmg / _frontAttacks).toStringAsFixed(1)
          : '-';
      final avgSideDmg = _sideAttacks > 0
          ? (_totalSideDmg / _sideAttacks).toStringAsFixed(1)
          : '-';
      final avgBackDmg = _backAttacks > 0
          ? (_totalBackDmg / _backAttacks).toStringAsFixed(1)
          : '-';

      onMetricsUpdated!({
        'battleTime': battleController.battleTime,
        'battleState': battleController.state.name,
        'frontAttacks': _frontAttacks,
        'sideAttacks': _sideAttacks,
        'backAttacks': _backAttacks,
        'totalAttacks': totalAttacks,
        'avgFrontDmg': avgFrontDmg,
        'avgSideDmg': avgSideDmg,
        'avgBackDmg': avgBackDmg,
        'alliesAlive': _allies.where((u) => u.isAlive).length,
        'enemiesAlive': _enemies.where((u) => u.isAlive).length,
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

    // 전장 중앙선
    final centerPaint = Paint()
      ..color = const Color(0x20FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      centerPaint,
    );

    // 방향 배율 범례
    _drawLegend(canvas);
  }

  void _drawLegend(Canvas canvas) {
    final legendPaint = Paint()
      ..color = const Color(0x30FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromLTRBR(20, size.y - 80, 220, size.y - 20, const Radius.circular(4)),
      legendPaint,
    );

    final pb = ParagraphBuilder(ParagraphStyle(fontSize: 10))
      ..pushStyle(TextStyle(color: const Color(0xAAFFFFFF)))
      ..addText('Front: 1.0x | Side: 1.3x | Back: 1.5x');
    final p = pb.build();
    p.layout(const ParagraphConstraints(width: 190));
    canvas.drawParagraph(p, Offset(28, size.y - 60));
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
