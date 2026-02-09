extends Node
class_name StatusEffectSystem
## 상태 효과 관리 시스템
## 유닛에 적용된 POISON, SLOW, STUN 등의 효과를 추적하고 처리

## 활성 효과 저장소: {unit_id: [ActiveEffect, ...]}
var active_effects: Dictionary = {}

## 활성 효과 데이터 구조
class ActiveEffect:
	var effect: StatusEffectData
	var remaining_time: float
	var tick_timer: float  # 다음 tick까지 남은 시간

	func _init(p_effect: StatusEffectData) -> void:
		effect = p_effect
		remaining_time = p_effect.duration
		tick_timer = p_effect.tick_interval


## 시그널
signal effect_applied(unit, effect: StatusEffectData)
signal effect_removed(unit, effect: StatusEffectData)
signal effect_tick(unit, effect: StatusEffectData, damage: int)


## 효과 적용
func apply_effect(unit, effect: StatusEffectData) -> bool:
	if not unit or not effect:
		return false

	var unit_id = unit.get_instance_id()

	# active_effects 초기화
	if not active_effects.has(unit_id):
		active_effects[unit_id] = []

	var effects_list: Array = active_effects[unit_id]

	# 중복 체크
	if not effect.stackable:
		for active in effects_list:
			if active.effect.effect_type == effect.effect_type:
				# 기존 효과 갱신 (시간 리셋)
				active.remaining_time = effect.duration
				active.tick_timer = effect.tick_interval
				return true

	# 새 효과 추가
	var new_effect = ActiveEffect.new(effect)
	effects_list.append(new_effect)
	active_effects[unit_id] = effects_list

	effect_applied.emit(unit, effect)
	return true


## 특정 타입 효과 제거
func remove_effect(unit, effect_type: StatusEffectData.EffectType) -> void:
	if not unit:
		return

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return

	var effects_list: Array = active_effects[unit_id]
	for i in range(effects_list.size() - 1, -1, -1):
		var active: ActiveEffect = effects_list[i]
		if active.effect.effect_type == effect_type:
			effect_removed.emit(unit, active.effect)
			effects_list.remove_at(i)

	if effects_list.is_empty():
		active_effects.erase(unit_id)


## 모든 효과 제거
func remove_all_effects(unit) -> void:
	if not unit:
		return

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return

	var effects_list: Array = active_effects[unit_id]
	for active in effects_list:
		effect_removed.emit(unit, active.effect)

	active_effects.erase(unit_id)


## 특정 효과 보유 여부
func has_effect(unit, effect_type: StatusEffectData.EffectType) -> bool:
	if not unit:
		return false

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return false

	var effects_list: Array = active_effects[unit_id]
	for active in effects_list:
		if active.effect.effect_type == effect_type:
			return true

	return false


## 활성 효과 목록 반환
func get_active_effects(unit) -> Array:
	if not unit:
		return []

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return []

	var result: Array = []
	for active in active_effects[unit_id]:
		result.append(active.effect)

	return result


## 매 프레임 업데이트
func _process(delta: float) -> void:
	var units_to_remove: Array = []

	for unit_id in active_effects.keys():
		var unit = instance_from_id(unit_id)
		if not unit or not is_instance_valid(unit):
			units_to_remove.append(unit_id)
			continue

		var effects_list: Array = active_effects[unit_id]
		var effects_to_remove: Array = []

		for i in range(effects_list.size()):
			var active: ActiveEffect = effects_list[i]

			# 시간 감소
			active.remaining_time -= delta

			# 만료 체크
			if active.remaining_time <= 0:
				effects_to_remove.append(i)
				effect_removed.emit(unit, active.effect)
				continue

			# tick 데미지 처리 (POISON, BURN)
			if active.effect.tick_damage > 0 and active.effect.tick_interval > 0:
				active.tick_timer -= delta

				if active.tick_timer <= 0:
					# tick 데미지 적용
					if unit.has_method("take_raw_damage"):
						unit.take_raw_damage(active.effect.tick_damage)
						effect_tick.emit(unit, active.effect, active.effect.tick_damage)

					# 다음 tick 준비
					active.tick_timer = active.effect.tick_interval

		# 만료된 효과 제거 (역순)
		for i in range(effects_to_remove.size() - 1, -1, -1):
			effects_list.remove_at(effects_to_remove[i])

		# 효과가 모두 제거되면 유닛 엔트리 삭제
		if effects_list.is_empty():
			units_to_remove.append(unit_id)

	# 빈 유닛 엔트리 삭제
	for unit_id in units_to_remove:
		active_effects.erase(unit_id)


## 이동 속도 배율 계산
func get_speed_modifier(unit) -> float:
	if not unit:
		return 1.0

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return 1.0

	var modifier: float = 1.0
	var effects_list: Array = active_effects[unit_id]

	for active in effects_list:
		modifier *= active.effect.speed_modifier

	return modifier


## 행동 가능 여부 (STUN, FREEZE 체크)
func can_act(unit) -> bool:
	if not unit:
		return true

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return true

	var effects_list: Array = active_effects[unit_id]

	for active in effects_list:
		if not active.effect.can_act:
			return false

	return true


## 감지 범위 배율 계산 (BLIND)
func get_detection_modifier(unit) -> float:
	if not unit:
		return 1.0

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return 1.0

	var modifier: float = 1.0
	var effects_list: Array = active_effects[unit_id]

	for active in effects_list:
		modifier *= active.effect.detection_modifier

	return modifier


## 능력치 변화 합산
func get_stat_modifier(unit, stat_name: String) -> int:
	if not unit:
		return 0

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		return 0

	var total: int = 0
	var effects_list: Array = active_effects[unit_id]

	for active in effects_list:
		if active.effect.stat_modifier.has(stat_name):
			total += active.effect.stat_modifier[stat_name]

	return total


## 디버그: 유닛의 활성 효과 출력
func debug_print_effects(unit) -> void:
	if not unit:
		return

	var unit_id = unit.get_instance_id()
	if not active_effects.has(unit_id):
		print("유닛 %s: 활성 효과 없음" % unit.unit_name)
		return

	print("유닛 %s의 활성 효과:" % unit.unit_name)
	var effects_list: Array = active_effects[unit_id]
	for active in effects_list:
		print("  - %s (%.1f초 남음)" % [active.effect.display_name, active.remaining_time])
