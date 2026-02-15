import 'package:flame/components.dart';

import '../systems/spatial_hash.dart';

/// Gocha-Kyara 핵심 매니저: 부대/유닛 관리, 조작 전환
class GameManager extends Component {
  // 게임 상태
  GameState state = GameState.playing;

  // 부대 관리: {squad_id: [unit_components]}
  final Map<int, List<Component>> squads = {};
  int currentSquadId = 0;
  int currentUnitIndex = 0;

  // 유닛 목록
  final List<Component> playerUnits = [];
  final List<Component> enemyUnits = [];

  // Spatial Hash (100 유닛 최적화)
  late final SpatialHash spatialHash;

  // 통계
  int totalKills = 0;
  int totalGold = 0;
  double playTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spatialHash = SpatialHash(cellSize: 100);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;
    playTime += dt;
  }

  /// 유닛 등록
  void registerUnit(Component unit, {required bool isPlayer, int squadId = 0}) {
    if (isPlayer) {
      playerUnits.add(unit);
      squads.putIfAbsent(squadId, () => []).add(unit);
    } else {
      enemyUnits.add(unit);
    }
  }

  /// 유닛 해제
  void unregisterUnit(Component unit, {required bool isPlayer}) {
    if (isPlayer) {
      playerUnits.remove(unit);
      for (final squad in squads.values) {
        squad.remove(unit);
      }
    } else {
      enemyUnits.remove(unit);
    }
    _checkGameOver();
  }

  /// 같은 부대 내 유닛 전환 (좌/우)
  void switchUnitInSquad(int direction) {
    final squad = squads[currentSquadId];
    if (squad == null || squad.isEmpty) return;
    currentUnitIndex = (currentUnitIndex + direction) % squad.length;
  }

  /// 부대 전환 (상/하)
  void switchSquad(int direction) {
    final squadIds = squads.keys.toList()..sort();
    if (squadIds.isEmpty) return;
    final idx = squadIds.indexOf(currentSquadId);
    final newIdx = (idx + direction) % squadIds.length;
    currentSquadId = squadIds[newIdx];
    currentUnitIndex = 0;
  }

  /// 현재 조작 유닛
  Component? get controlledUnit {
    final squad = squads[currentSquadId];
    if (squad == null || squad.isEmpty) return null;
    if (currentUnitIndex >= squad.length) currentUnitIndex = 0;
    return squad[currentUnitIndex];
  }

  /// 게임 오버 체크
  void _checkGameOver() {
    if (playerUnits.isEmpty) {
      state = GameState.gameOver;
    } else if (enemyUnits.isEmpty) {
      state = GameState.victory;
    }
  }

  /// 적 처치 기록
  void recordKill({int gold = 0}) {
    totalKills++;
    totalGold += gold;
  }

  /// 가장 가까운 적 검색 (POC-2)
  Component? findNearestEnemy(Vector2 position, bool isPlayerSide) {
    final targets = isPlayerSide ? enemyUnits : playerUnits;
    Component? nearest;
    double minDist = double.infinity;

    for (final target in targets) {
      if (target is PositionComponent) {
        final d = position.distanceTo(target.position);
        if (d < minDist) {
          minDist = d;
          nearest = target;
        }
      }
    }
    return nearest;
  }
}

/// 게임 상태
enum GameState {
  playing,
  paused,
  victory,
  gameOver,
  cutscene,
}
