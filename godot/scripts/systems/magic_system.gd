extends Node
class_name MagicSystem
## MagicSystem: 마법 시스템

# 상수
const FATIGUE_SKILL: int = 20

# 시그널
signal spell_cast(caster, spell: SpellData, targets: Array)
signal spell_failed(caster, spell: SpellData, reason: String)
signal mp_changed(unit, new_mp: int, max_mp: int)
signal cooldown_started(unit, spell: SpellData, duration: float)

# 쿨다운 추적 (unit_id -> {spell_id -> remaining_cooldown})
var cooldowns: Dictionary = {}

# CombatSystem 참조 (데미지 마법용)
var combat_system: CombatSystem = null

func _ready() -> void:
	add_to_group("magic_system")

func _process(delta: float) -> void:
	_update_cooldowns(delta)

## 쿨다운 업데이트
func _update_cooldowns(delta: float) -> void:
	for unit_id in cooldowns:
		var unit_cooldowns = cooldowns[unit_id]
		var expired: Array = []
		for spell_id in unit_cooldowns:
			unit_cooldowns[spell_id] -= delta
			if unit_cooldowns[spell_id] <= 0:
				expired.append(spell_id)
		for spell_id in expired:
			unit_cooldowns.erase(spell_id)

## 마법 시전
func cast_spell(caster, spell: SpellData, target = null) -> Dictionary:
	# 1. 검증
	if not spell:
		spell_failed.emit(caster, spell, "No spell data")
		return {"success": false, "reason": "No spell data"}

	var can_cast_result = can_cast(caster, spell)
	if not can_cast_result["can_cast"]:
		spell_failed.emit(caster, spell, can_cast_result["reason"])
		return {"success": false, "reason": can_cast_result["reason"]}

	# 2. 타겟 결정
	var targets = _resolve_targets(caster, spell, target)
	if targets.is_empty() and spell.target_type != SpellData.TargetType.SELF:
		spell_failed.emit(caster, spell, "No valid targets")
		return {"success": false, "reason": "No valid targets"}

	# 3. MP 소모
	caster.current_mp -= spell.mp_cost
	mp_changed.emit(caster, caster.current_mp, caster.max_mp)

	# 4. 피로도 추가
	if caster.has_method("add_fatigue"):
		caster.add_fatigue(FATIGUE_SKILL)

	# 5. 쿨다운 시작
	_start_cooldown(caster, spell)

	# 6. 효과 적용
	match spell.spell_type:
		SpellData.SpellType.DAMAGE:
			_apply_damage(caster, spell, targets)
		SpellData.SpellType.HEAL:
			_apply_heal(caster, spell, targets)
		SpellData.SpellType.BUFF:
			_apply_buff(caster, spell, targets)
		SpellData.SpellType.DEBUFF:
			_apply_debuff(caster, spell, targets)
		SpellData.SpellType.SUMMON:
			pass  # Phase 5+ 구현

	spell_cast.emit(caster, spell, targets)
	return {"success": true, "targets": targets}

## 시전 가능 여부 확인
func can_cast(caster, spell: SpellData) -> Dictionary:
	if not caster.is_alive:
		return {"can_cast": false, "reason": "Caster is dead"}

	if caster.current_mp < spell.mp_cost:
		return {"can_cast": false, "reason": "Not enough MP"}

	if _is_on_cooldown(caster, spell):
		return {"can_cast": false, "reason": "On cooldown"}

	return {"can_cast": true, "reason": ""}

## 쿨다운 확인
func _is_on_cooldown(caster, spell: SpellData) -> bool:
	var unit_id = caster.get_instance_id()
	if not cooldowns.has(unit_id):
		return false
	return cooldowns[unit_id].has(spell.spell_id)

## 쿨다운 시작
func _start_cooldown(caster, spell: SpellData) -> void:
	var unit_id = caster.get_instance_id()
	if not cooldowns.has(unit_id):
		cooldowns[unit_id] = {}
	cooldowns[unit_id][spell.spell_id] = spell.cooldown
	cooldown_started.emit(caster, spell, spell.cooldown)

## 타겟 결정
func _resolve_targets(caster, spell: SpellData, target) -> Array:
	var targets: Array = []

	match spell.target_type:
		SpellData.TargetType.SELF:
			targets = [caster]

		SpellData.TargetType.SINGLE_ALLY:
			if target and target.is_alive:
				targets = [target]

		SpellData.TargetType.SINGLE_ENEMY:
			if target and target.is_alive:
				targets = [target]

		SpellData.TargetType.ALL_ALLIES:
			targets = _get_all_allies(caster)

		SpellData.TargetType.ALL_ENEMIES:
			targets = _get_all_enemies(caster)

		SpellData.TargetType.AREA:
			var center = target if target is Vector2 else (target.global_position if target else caster.global_position)
			targets = _get_units_in_radius(caster, center, spell.area_radius, spell.spell_type)

	return targets

## 범위 내 유닛 찾기
func _get_units_in_radius(caster, center: Vector2, radius: float, spell_type) -> Array:
	var units: Array = []
	var target_list: Array

	# 힐/버프는 아군, 데미지/디버프는 적
	if spell_type == SpellData.SpellType.HEAL or spell_type == SpellData.SpellType.BUFF:
		target_list = _get_all_allies(caster)
	else:
		target_list = _get_all_enemies(caster)

	for unit in target_list:
		if unit.is_alive:
			var distance = center.distance_to(unit.global_position)
			if distance <= radius:
				units.append(unit)

	return units

## 아군 목록
func _get_all_allies(caster) -> Array:
	if GameManager.player_units.has(caster):
		return GameManager.player_units.filter(func(u): return u.is_alive)
	else:
		return GameManager.enemy_units.filter(func(u): return u.is_alive)

## 적 목록
func _get_all_enemies(caster) -> Array:
	if GameManager.player_units.has(caster):
		return GameManager.enemy_units.filter(func(u): return u.is_alive)
	else:
		return GameManager.player_units.filter(func(u): return u.is_alive)

## 데미지 적용
func _apply_damage(caster, spell: SpellData, targets: Array) -> void:
	for target in targets:
		var damage = spell.base_power
		# TODO: 속성 상성 보너스 (Phase 3+)
		target.take_damage(damage)

## 힐 적용
func _apply_heal(_caster, spell: SpellData, targets: Array) -> void:
	for target in targets:
		if target.has_method("heal"):
			target.heal(spell.base_power)

## 버프 적용
func _apply_buff(_caster, spell: SpellData, targets: Array) -> void:
	for target in targets:
		if target.stats_system and target.stats_system.has_method("apply_buff"):
			target.stats_system.apply_buff(spell.buff_stat, spell.buff_value, spell.buff_duration)

## 디버프 적용
func _apply_debuff(_caster, spell: SpellData, targets: Array) -> void:
	for target in targets:
		if target.stats_system and target.stats_system.has_method("apply_buff"):
			target.stats_system.apply_buff(spell.buff_stat, spell.buff_value, spell.buff_duration)

## AI가 마법 시전 결정 (AIUnit에서 호출)
func ai_should_cast_spell(caster, allies: Array, enemies: Array) -> Dictionary:
	# 반환: {"should_cast": bool, "spell": SpellData, "target": Unit/Vector2}
	if not caster.known_spells or caster.known_spells.is_empty():
		return {"should_cast": false, "spell": null, "target": null}

	# 1. 체력 낮은 아군 있으면 힐 우선
	var wounded_ally = _find_wounded_ally(allies)
	if wounded_ally:
		var heal_spell = _find_spell_by_type(caster, SpellData.SpellType.HEAL)
		if heal_spell and can_cast(caster, heal_spell)["can_cast"]:
			return {"should_cast": true, "spell": heal_spell, "target": wounded_ally}

	# 2. 적이 있으면 공격 마법
	if not enemies.is_empty():
		var damage_spell = _find_spell_by_type(caster, SpellData.SpellType.DAMAGE)
		if damage_spell and can_cast(caster, damage_spell)["can_cast"]:
			# 범위 마법이면 적 밀집 지역 타겟
			if damage_spell.target_type == SpellData.TargetType.AREA:
				return {"should_cast": true, "spell": damage_spell, "target": enemies[0].global_position}
			else:
				return {"should_cast": true, "spell": damage_spell, "target": enemies[0]}

	return {"should_cast": false, "spell": null, "target": null}

## 부상 아군 찾기
func _find_wounded_ally(allies: Array):
	var most_wounded = null
	var lowest_hp_ratio = 1.0
	for ally in allies:
		if not ally.is_alive:
			continue
		var hp_ratio = float(ally.current_hp) / float(ally.max_hp)
		if hp_ratio < 0.5 and hp_ratio < lowest_hp_ratio:
			lowest_hp_ratio = hp_ratio
			most_wounded = ally
	return most_wounded

## 타입별 마법 찾기
func _find_spell_by_type(caster, spell_type) -> SpellData:
	for spell in caster.known_spells:
		if spell.spell_type == spell_type:
			return spell
	return null
