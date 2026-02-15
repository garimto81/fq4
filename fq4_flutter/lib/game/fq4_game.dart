import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/camera/game_camera.dart';
import 'components/ui/battle_hud.dart';
import 'components/ui/minimap.dart';
import 'components/units/player_unit_component.dart';
import 'components/units/ai_unit_component.dart';
import 'components/units/enemy_unit_component.dart';
import 'components/units/unit_component.dart';
import 'input/game_input_handler.dart';
import 'managers/game_manager.dart';
import '../core/constants/ai_constants.dart';

/// First Queen 4 메인 게임 클래스
class FQ4Game extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  static const double logicalWidth = 1280;
  static const double logicalHeight = 800;

  // POC-4: 배속 시스템
  double speedMultiplier = 1.0;
  static const List<double> speedOptions = [1.0, 2.0, 4.0, 8.0, 16.0];

  void setSpeed(double mult) {
    speedMultiplier = mult.clamp(0.25, 16.0);
  }

  late final GameManager gameManager;
  late final GameCameraController cameraController;
  late final BattleHud battleHud;
  late final Minimap minimap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 카메라 설정: 논리 좌표계 1280x800
    camera.viewfinder.visibleGameSize = Vector2(logicalWidth, logicalHeight);
    camera.viewfinder.anchor = Anchor.topLeft;

    // GameManager 초기화
    gameManager = GameManager();
    await world.add(gameManager);

    // 카메라 컨트롤러
    cameraController = GameCameraController();
    await world.add(cameraController);

    // 입력 핸들러
    await world.add(GameInputHandler());

    // HUD (카메라 viewport에 추가 - 화면 고정)
    battleHud = BattleHud();
    camera.viewport.add(battleHud);

    // 미니맵 (우상단)
    minimap = Minimap();
    minimap.position = Vector2(logicalWidth - 160, 10);
    camera.viewport.add(minimap);

    // 데모 유닛 스폰
    _spawnDemoUnits();
  }

  @override
  void update(double dt) {
    // speedMultiplier는 POC 전용 게임에서만 사용
    // FQ4Game에서는 기본 속도 유지 (카메라/HUD 동기화 문제 방지)
    super.update(dt);
    _updateHud();
    _updateMinimap();
  }

  /// 데모 유닛 스폰
  void _spawnDemoUnits() {
    // 플레이어 유닛 (아레스)
    final player = PlayerUnitComponent(
      unitName: 'Ares',
      maxHp: 100,
      maxMp: 30,
      attack: 25,
      defense: 15,
      speed: 80,
      luck: 10,
      level: 1,
      position: Vector2(640, 400),
      personality: Personality.balanced,
    );
    world.add(player);
    gameManager.registerUnit(player, isPlayer: true, squadId: 0);

    // AI 아군 (타로)
    final ally1 = AIUnitComponent(
      unitName: 'Taro',
      maxHp: 80,
      maxMp: 50,
      attack: 20,
      defense: 10,
      speed: 70,
      luck: 8,
      level: 1,
      isPlayerSide: true,
      position: Vector2(600, 420),
      personality: Personality.balanced,
    );
    world.add(ally1);
    gameManager.registerUnit(ally1, isPlayer: true, squadId: 0);

    // AI 아군 (알레인)
    final ally2 = AIUnitComponent(
      unitName: 'Alein',
      maxHp: 60,
      maxMp: 80,
      attack: 15,
      defense: 8,
      speed: 65,
      luck: 12,
      level: 1,
      isPlayerSide: true,
      position: Vector2(680, 420),
      personality: Personality.defensive,
    );
    world.add(ally2);
    gameManager.registerUnit(ally2, isPlayer: true, squadId: 0);

    // 적 유닛 3체
    for (int i = 0; i < 3; i++) {
      final enemy = EnemyUnitComponent(
        unitName: 'Goblin ${i + 1}',
        maxHp: 40,
        maxMp: 0,
        attack: 12,
        defense: 5,
        speed: 50,
        luck: 3,
        level: 1,
        position: Vector2(900 + i * 60.0, 350 + i * 40.0),
        expReward: 15,
        goldReward: 8,
      );
      world.add(enemy);
      gameManager.registerUnit(enemy, isPlayer: false);
    }

    // 카메라를 플레이어에 추적
    cameraController.setFollowTarget(player);
  }

  /// HUD 갱신
  void _updateHud() {
    final unit = gameManager.controlledUnit;
    if (unit is! UnitComponent) return;

    final squad = gameManager.squads[gameManager.currentSquadId];
    battleHud.updateData(
      name: unit.unitName,
      hp: unit.currentHp,
      hpMax: unit.maxHp,
      mp: unit.currentMp,
      mpMax: unit.maxMp,
      fatigueValue: unit.fatigue,
      squad: gameManager.currentSquadId,
      index: gameManager.currentUnitIndex,
      total: squad?.length ?? 0,
      state: gameManager.state.name.toUpperCase(),
    );
  }

  /// 미니맵 갱신
  void _updateMinimap() {
    final positions = <({double x, double y, bool isPlayer, bool isControlled})>[];
    final controlled = gameManager.controlledUnit;

    for (final u in gameManager.playerUnits) {
      if (u is PositionComponent) {
        positions.add((
          x: u.position.x,
          y: u.position.y,
          isPlayer: true,
          isControlled: u == controlled,
        ));
      }
    }
    for (final u in gameManager.enemyUnits) {
      if (u is PositionComponent) {
        positions.add((
          x: u.position.x,
          y: u.position.y,
          isPlayer: false,
          isControlled: false,
        ));
      }
    }

    minimap.updatePositions(positions);
  }

  /// 게임 일시정지
  void togglePause() {
    if (paused) {
      resumeEngine();
      overlays.remove('pause');
    } else {
      pauseEngine();
      overlays.add('pause');
    }
  }
}
