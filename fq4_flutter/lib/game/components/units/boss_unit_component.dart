import 'enemy_unit_component.dart';

/// 보스 페이즈
enum BossPhase { phase1, phase2, phase3 }

/// 보스 유닛 (Godot boss_unit.gd 이식)
class BossUnitComponent extends EnemyUnitComponent {
  BossUnitComponent({
    required super.unitName,
    required super.maxHp,
    required super.maxMp,
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.level,
    super.position,
    super.expReward = 100,
    super.goldReward = 50,
  });

  BossPhase phase = BossPhase.phase1;
  bool isEnraged = false;

  // 페이즈 전환 HP 임계값
  static const double phase2Threshold = 0.66;
  static const double phase3Threshold = 0.33;
  static const double enrageThreshold = 0.20;

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _checkPhaseTransition();
  }

  void _checkPhaseTransition() {
    final ratio = hpRatio;

    if (!isEnraged && ratio <= enrageThreshold) {
      isEnraged = true;
      // 광폭화: 공격력 1.5배, 속도 1.3배
      attack = (attack * 1.5).round();
      speed = (speed * 1.3).round();
    }

    final newPhase = ratio > phase2Threshold
        ? BossPhase.phase1
        : ratio > phase3Threshold
            ? BossPhase.phase2
            : BossPhase.phase3;

    if (newPhase != phase) {
      phase = newPhase;
      _onPhaseChange();
    }
  }

  void _onPhaseChange() {
    // 페이즈 전환 효과 (추후 이펙트 연동)
    switch (phase) {
      case BossPhase.phase2:
        defense = (defense * 1.2).round();
      case BossPhase.phase3:
        attack = (attack * 1.3).round();
      default:
        break;
    }
  }
}
