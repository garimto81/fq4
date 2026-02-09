/// 상태이상 상수 (Godot status_effect_system.gd에서 이식)
class StatusEffectConstants {
  StatusEffectConstants._();
}

/// 상태이상 유형 (6종)
enum StatusEffectType {
  poison(duration: 10.0, tickInterval: 1.0, tickDamage: 5, speedMult: 1.0, canAct: true, detectionMult: 1.0),
  burn(duration: 8.0, tickInterval: 1.0, tickDamage: 8, speedMult: 1.0, canAct: true, detectionMult: 1.0),
  stun(duration: 3.0, tickInterval: 0, tickDamage: 0, speedMult: 1.0, canAct: false, detectionMult: 1.0),
  slow(duration: 5.0, tickInterval: 0, tickDamage: 0, speedMult: 0.5, canAct: true, detectionMult: 1.0),
  freeze(duration: 4.0, tickInterval: 0, tickDamage: 0, speedMult: 0.0, canAct: false, detectionMult: 1.0),
  blind(duration: 6.0, tickInterval: 0, tickDamage: 0, speedMult: 1.0, canAct: true, detectionMult: 0.2);

  const StatusEffectType({
    required this.duration,
    required this.tickInterval,
    required this.tickDamage,
    required this.speedMult,
    required this.canAct,
    required this.detectionMult,
  });

  final double duration;
  final double tickInterval;
  final int tickDamage;
  final double speedMult;
  final bool canAct;
  final double detectionMult;
}

/// 지형 유형 (6종)
enum TerrainType {
  normal(speedMult: 1.0, fatigueMult: 1.0, detectionMult: 1.0, statusEffect: null),
  water(speedMult: 0.7, fatigueMult: 1.0, detectionMult: 1.0, statusEffect: null),
  cold(speedMult: 1.0, fatigueMult: 1.5, detectionMult: 1.0, statusEffect: null),
  dark(speedMult: 1.0, fatigueMult: 1.0, detectionMult: 0.5, statusEffect: null),
  poison(speedMult: 1.0, fatigueMult: 1.0, detectionMult: 1.0, statusEffect: StatusEffectType.poison),
  fire(speedMult: 1.0, fatigueMult: 1.0, detectionMult: 1.0, statusEffect: StatusEffectType.burn);

  const TerrainType({
    required this.speedMult,
    required this.fatigueMult,
    required this.detectionMult,
    required this.statusEffect,
  });

  final double speedMult;
  final double fatigueMult;
  final double detectionMult;
  final StatusEffectType? statusEffect;
}
