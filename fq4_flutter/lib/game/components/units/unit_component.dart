import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../../core/constants/fatigue_constants.dart';
import '../../systems/fatigue_system.dart';
import '../../systems/combat_system.dart';

/// 유닛 상태
enum UnitState {
  idle,
  moving,
  attacking,
  resting,
  dead,
}

/// 유닛 기본 컴포넌트 (Godot unit.gd 이식)
class UnitComponent extends PositionComponent with HasGameReference, CollisionCallbacks {
  UnitComponent({
    required this.unitName,
    required this.maxHp,
    required this.maxMp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.luck,
    this.level = 1,
    this.isPlayerSide = true,
    super.position,
  });

  // 기본 정보
  final String unitName;
  int level;
  final bool isPlayerSide;

  // 스탯
  int maxHp;
  int maxMp;
  int attack;
  int defense;
  int speed;
  int luck;

  // 현재 상태
  late int currentHp = maxHp;
  late int currentMp = maxMp;
  double fatigue = 0;
  UnitState state = UnitState.idle;

  // 이동
  Vector2 velocity = Vector2.zero();
  Vector2? moveTarget;

  // 전투
  double attackCooldown = 0;
  static const double attackCooldownTime = 0.6;
  static const double moveSpeedMultiplier = 1.5;

  // 시스템
  final FatigueSystem _fatigueSystem = FatigueSystem();

  bool get isDead => state == UnitState.dead;
  bool get isAlive => !isDead;
  double get hpRatio => currentHp / maxHp;
  double get mpRatio => maxMp > 0 ? currentMp / maxMp : 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(32, 32); // 기본 32x32
    anchor = Anchor.center;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    attackCooldown = max(0, attackCooldown - dt);

    switch (state) {
      case UnitState.idle:
        _processIdle(dt);
      case UnitState.moving:
        _processMoving(dt);
      case UnitState.attacking:
        _processAttacking(dt);
      case UnitState.resting:
        _processResting(dt);
      case UnitState.dead:
        break;
    }
  }

  void _processIdle(double dt) {
    fatigue = _fatigueSystem.recover(fatigue, dt, isResting: false);
  }

  void _processMoving(double dt) {
    if (moveTarget == null) {
      state = UnitState.idle;
      return;
    }
    final dir = moveTarget! - position;
    if (dir.length < 5) {
      moveTarget = null;
      state = UnitState.idle;
      return;
    }
    final speedMult = _fatigueSystem.getSpeedMultiplier(fatigue);
    final moveSpeed = speed * speedMult * moveSpeedMultiplier;
    velocity = dir.normalized() * moveSpeed;
    position += velocity * dt;
    fatigue = _fatigueSystem.addMoveFatigue(fatigue, (velocity * dt).length);
  }

  void _processAttacking(double dt) {
    // 공격 후 idle 전환은 외부에서 처리
    if (attackCooldown <= 0) {
      state = UnitState.idle;
    }
  }

  void _processResting(double dt) {
    fatigue = _fatigueSystem.recover(fatigue, dt, isResting: true);
    if (fatigue <= FatigueConstants.normalMax) {
      state = UnitState.idle;
    }
  }

  /// 데미지 받기
  void takeDamage(int damage) {
    if (isDead) return;
    currentHp = max(0, currentHp - damage);
    if (currentHp <= 0) {
      die();
    }
  }

  /// HP 회복
  void heal(int amount) {
    if (isDead) return;
    currentHp = min(maxHp, currentHp + amount);
  }

  /// MP 소비
  bool consumeMp(int cost) {
    if (currentMp < cost) return false;
    currentMp -= cost;
    return true;
  }

  /// 사망 처리
  void die() {
    state = UnitState.dead;
    velocity = Vector2.zero();
    moveTarget = null;
  }

  /// 이동 지시
  void moveTo(Vector2 target) {
    if (isDead) return;
    if (!_fatigueSystem.canAct(fatigue)) return;
    moveTarget = target.clone();
    state = UnitState.moving;
  }

  /// 공격 시도 (타겟 없이 - 하위 호환)
  bool tryAttack() {
    if (isDead || attackCooldown > 0) return false;
    if (!_fatigueSystem.canAct(fatigue)) return false;
    state = UnitState.attacking;
    attackCooldown = attackCooldownTime;
    fatigue = _fatigueSystem.addAttackFatigue(fatigue);
    return true;
  }

  /// 타겟 지정 공격 (CombatSystem 경유)
  bool tryAttackTarget(UnitComponent target, CombatSystem combatSystem) {
    if (isDead || attackCooldown > 0) return false;
    if (!_fatigueSystem.canAct(fatigue)) return false;
    if (target.isDead) return false;

    state = UnitState.attacking;
    attackCooldown = attackCooldownTime;
    fatigue = _fatigueSystem.addAttackFatigue(fatigue);

    final result = combatSystem.executeAttack(
      attacker: toUnitStats(),
      target: target.toUnitStats(),
    );

    if (result.hitResult != HitResult.miss && result.hitResult != HitResult.evade) {
      target.takeDamage(result.damage);
    }

    return true;
  }

  /// UnitStats로 변환 (CombatSystem용)
  UnitStats toUnitStats() {
    return UnitStats(
      attack: attack,
      defense: defense,
      speed: speed,
      luck: luck,
      fatigue: fatigue,
    );
  }
}
