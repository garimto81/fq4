class_name StatusEffectDatabase

## 상태이상 데이터베이스
## 사전 정의된 상태이상 효과를 생성하는 정적 메서드 모음
## 모든 메서드가 static이므로 Node를 상속하지 않음

## 상태이상 효과 생성
static func create_effect(effect_id: String):
	var effect = null

	# StatusEffectData를 직접 참조하지 않고 로드
	const StatusEffectData = preload("res://scripts/resources/status_effect_data.gd")

	match effect_id:
		"poison":
			effect = StatusEffectData.new("poison", "독", 0, 10.0)  # EffectType.POISON = 0
			effect.description = "1초마다 5 독 피해"
			effect.tick_interval = 1.0
			effect.tick_damage = 5

		"burn":
			effect = StatusEffectData.new("burn", "화상", 3, 8.0)  # EffectType.BURN = 3
			effect.description = "1초마다 8 화염 피해"
			effect.tick_interval = 1.0
			effect.tick_damage = 8

		"stun":
			effect = StatusEffectData.new("stun", "기절", 2, 3.0)  # EffectType.STUN = 2
			effect.description = "이동 및 공격 불가"
			effect.can_act = false

		"slow":
			effect = StatusEffectData.new("slow", "둔화", 1, 5.0)  # EffectType.SLOW = 1
			effect.description = "이동속도 50% 감소"
			effect.speed_modifier = 0.5

		"freeze":
			effect = StatusEffectData.new("freeze", "빙결", 4, 4.0)  # EffectType.FREEZE = 4
			effect.description = "이동 및 행동 불가"
			effect.speed_modifier = 0.0
			effect.can_act = false

		"blind":
			effect = StatusEffectData.new("blind", "실명", 5, 6.0)  # EffectType.BLIND = 5
			effect.description = "감지 범위 80% 감소"
			effect.detection_modifier = 0.2

		_:
			push_error("[StatusEffectDatabase] Unknown effect ID: ", effect_id)
			return null

	return effect

## 사전 정의된 효과 목록 가져오기
static func get_all_effect_ids() -> Array[String]:
	return [
		"poison", "burn", "stun", "slow", "freeze", "blind"
	]

## 효과가 존재하는지 확인
static func has_effect(effect_id: String) -> bool:
	return effect_id in get_all_effect_ids()

## 효과 설명 가져오기 (미리보기용)
static func get_effect_description(effect_id: String) -> Dictionary:
	var effect = create_effect(effect_id)
	if not effect:
		return {}

	const StatusEffectData = preload("res://scripts/resources/status_effect_data.gd")
	return {
		"id": effect.id,
		"display_name": effect.display_name,
		"description": effect.description,
		"type": StatusEffectData.EffectType.keys()[effect.effect_type],
		"duration": effect.duration
	}

## 카테고리별 효과 목록
static func get_debuff_ids() -> Array[String]:
	return ["poison", "burn", "stun", "slow", "freeze", "blind"]

static func get_damage_over_time_ids() -> Array[String]:
	return ["poison", "burn"]

static func get_crowd_control_ids() -> Array[String]:
	return ["stun", "freeze", "slow"]

static func get_vision_debuff_ids() -> Array[String]:
	return ["blind"]
