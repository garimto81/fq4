import 'package:flame/components.dart';
import '../components/units/unit_component.dart';

/// 전투 오케스트레이터: 스폰, 승패 판정, 전투 로그
/// POC-2: AI 자동전투 파이프라인 검증
enum BattleState { preparing, fighting, victory, defeat }

class BattleController extends Component {
  final List<UnitComponent> allies = [];
  final List<UnitComponent> enemies = [];
  final List<BattleLogEntry> battleLog = [];
  BattleState state = BattleState.preparing;
  double battleTime = 0;

  // Callbacks for Flutter UI
  void Function(BattleState state)? onStateChanged;
  void Function(BattleLogEntry entry)? onLogAdded;

  void registerAlly(UnitComponent unit) {
    allies.add(unit);
  }

  void registerEnemy(UnitComponent unit) {
    enemies.add(unit);
  }

  void startBattle() {
    if (state != BattleState.preparing) return;
    state = BattleState.fighting;
    battleTime = 0;
    onStateChanged?.call(state);
    addLog('=== Battle Start ===', LogType.system);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != BattleState.fighting) return;

    battleTime += dt;
    _checkBattleEnd();
  }

  void _checkBattleEnd() {
    final alliesAlive = allies.where((u) => u.isAlive).toList();
    final enemiesAlive = enemies.where((u) => u.isAlive).toList();

    if (alliesAlive.isEmpty) {
      state = BattleState.defeat;
      addLog('=== DEFEAT (${battleTime.toStringAsFixed(1)}s) ===', LogType.system);
      onStateChanged?.call(state);
    } else if (enemiesAlive.isEmpty) {
      state = BattleState.victory;
      addLog('=== VICTORY (${battleTime.toStringAsFixed(1)}s) ===', LogType.system);
      onStateChanged?.call(state);
    }
  }

  void logAttack(String attacker, String target, int damage, bool crit, bool miss) {
    final String msg;
    if (miss) {
      msg = '$attacker -> $target: MISS';
    } else {
      msg = '$attacker -> $target: ${damage}dmg${crit ? " CRIT!" : ""}';
    }
    addLog(msg, LogType.combat);
  }

  void logDeath(String unitName, bool isAlly) {
    addLog('${isAlly ? "[Ally]" : "[Enemy]"} $unitName defeated!', LogType.death);
  }

  void logStateChange(String unitName, String fromState, String toState) {
    addLog('$unitName: $fromState -> $toState', LogType.ai);
  }

  void addLog(String message, LogType type) {
    final entry = BattleLogEntry(
      message: message,
      type: type,
      time: battleTime,
    );
    battleLog.add(entry);
    onLogAdded?.call(entry);
  }

  /// Find nearest enemy for a given unit
  UnitComponent? findNearestEnemy(Vector2 position, bool isPlayerSide) {
    final targets = isPlayerSide ? enemies : allies;
    UnitComponent? nearest;
    double minDist = double.infinity;

    for (final target in targets) {
      if (target.isDead) continue;
      final d = position.distanceTo(target.position);
      if (d < minDist) {
        minDist = d;
        nearest = target;
      }
    }
    return nearest;
  }

  /// Find nearest ally for support
  UnitComponent? findWoundedAlly(Vector2 position, bool isPlayerSide) {
    final targets = isPlayerSide ? allies : enemies;
    UnitComponent? nearest;
    double minDist = double.infinity;

    for (final target in targets) {
      if (target.isDead || target.hpRatio > 0.5) continue;
      final d = position.distanceTo(target.position);
      if (d < minDist) {
        minDist = d;
        nearest = target;
      }
    }
    return nearest;
  }
}

enum LogType { combat, death, ai, system }

class BattleLogEntry {
  final String message;
  final LogType type;
  final double time;

  const BattleLogEntry({
    required this.message,
    required this.type,
    required this.time,
  });
}
