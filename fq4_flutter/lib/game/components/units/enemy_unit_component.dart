import '../../../core/constants/ai_constants.dart';
import '../../managers/game_manager.dart';
import '../../systems/battle_controller.dart';
import '../../systems/combat_system.dart';
import 'unit_component.dart';

/// 적 유닛 (Godot enemy_unit.gd 이식)
class EnemyUnitComponent extends UnitComponent {
  EnemyUnitComponent({
    required super.unitName,
    required super.maxHp,
    required super.maxMp,
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.level,
    super.position,
    this.expReward = 10,
    this.goldReward = 5,
  }) : super(isPlayerSide: false);

  final int expReward;
  final int goldReward;

  // POC-2: BattleController/CombatSystem 연결
  BattleController? battleController;
  CombatSystem? combatSystem;

  double _aiTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    _aiTimer += dt;
    if (_aiTimer < AIConstants.enemyTickInterval) return;
    _aiTimer = 0;

    _executeEnemyAI();
  }

  void _executeEnemyAI() {
    final bc = battleController;
    final cs = combatSystem;

    UnitComponent? nearest;
    double minDist = AIConstants.enemyDetectionRange;

    if (bc != null) {
      // BattleController 경유
      nearest = bc.findNearestEnemy(position, isPlayerSide);
      if (nearest != null) {
        minDist = position.distanceTo(nearest.position);
      }
    } else {
      // 기존 GameManager fallback
      final gm = findParent<GameManager>();
      if (gm == null) return;

      for (final p in gm.playerUnits) {
        if (p is UnitComponent && p.isAlive) {
          final d = position.distanceTo(p.position);
          if (d < minDist) {
            minDist = d;
            nearest = p;
          }
        }
      }
    }

    if (nearest == null || nearest.isDead) return;

    if (minDist <= AIConstants.defaultAttackRange) {
      // 공격 범위 내 → CombatSystem 경유 공격
      if (bc != null && cs != null) {
        if (!tryAttack()) return;

        final result = cs.executeAttack(
          attacker: toUnitStats(),
          target: nearest.toUnitStats(),
        );

        final isMiss = result.hitResult == HitResult.miss ||
            result.hitResult == HitResult.evade;

        if (!isMiss) {
          nearest.takeDamage(result.damage);
        }

        bc.logAttack(unitName, nearest.unitName, result.damage, result.isCritical, isMiss);

        if (nearest.isDead) {
          bc.logDeath(nearest.unitName, true);
        }
      } else {
        tryAttack();
      }
    } else {
      moveTo(nearest.position);
    }
  }
}
