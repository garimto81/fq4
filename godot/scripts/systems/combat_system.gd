extends Node
class_name CombatSystem
## CombatSystem: 전투 시스템
##
## 유닛 간 전투 로직을 처리합니다.
## 데미지 계산, 사거리 체크, 전투 이벤트 등을 관리합니다.

func _ready() -> void:
	# combat_system 그룹에 추가하여 유닛들이 찾을 수 있게 함
	add_to_group("combat_system")

# 전투 상수
const BASE_DAMAGE_VARIANCE: float = 0.1        # +-10% 데미지 편차
const CRITICAL_HIT_CHANCE: float = 0.05        # 5% 크리티컬 확률
const CRITICAL_HIT_MULTIPLIER: float = 2.0     # 크리티컬 데미지 2배
const BASE_HIT_CHANCE: float = 0.95            # 95% 기본 명중률
const BASE_EVASION: float = 0.05               # 5% 기본 회피율
const MIN_DAMAGE: int = 1                      # 최소 데미지

# 시그널 (타입 어노테이션 제거 - 스크립트 로드 순서 이슈)
signal combat_started(attacker, target)
signal damage_dealt(attacker, target, damage: int, is_critical: bool)
signal attack_missed(attacker, target)
signal attack_evaded(attacker, target)
signal damage_popup_requested(position: Vector2, damage: int, popup_type: int)
signal unit_killed(attacker, victim)
signal exp_gained(unit, amount: int)
signal gold_rewarded(unit, amount: int)

# 팝업 타입
enum PopupType {
	NORMAL,
	CRITICAL,
	MISS,
	EVADE,
	HEAL
}

## 공격 실행
func execute_attack(attacker, target) -> Dictionary:
	if not _can_attack(attacker, target):
		return {
			"success": false,
			"reason": "Cannot attack"
		}

	combat_started.emit(attacker, target)

	# 명중 판정
	var hit_result = _calculate_hit(attacker, target)
	if not hit_result["hit"]:
		# 공격 실패 (회피 또는 빗나감)
		attacker.add_fatigue(FatigueSystem.FATIGUE_ATTACK)

		if hit_result["evaded"]:
			attack_evaded.emit(attacker, target)
			damage_popup_requested.emit(target.global_position, 0, PopupType.EVADE)
		else:
			attack_missed.emit(attacker, target)
			damage_popup_requested.emit(target.global_position, 0, PopupType.MISS)

		return {
			"success": true,
			"hit": false,
			"evaded": hit_result["evaded"],
			"damage": 0,
			"is_critical": false,
			"target_died": false
		}

	# 데미지 계산
	var damage_info = calculate_damage(attacker, target)
	var final_damage = damage_info["damage"]
	var is_critical = damage_info["is_critical"]

	# 피로도 적용
	var fatigue_info = FatigueSystem.get_fatigue_info(attacker)
	final_damage = int(final_damage * fatigue_info["attack_power_multiplier"])

	# 최소 데미지 보장
	final_damage = max(MIN_DAMAGE, final_damage)

	# 데미지 적용
	target.take_damage(final_damage)
	damage_dealt.emit(attacker, target, final_damage, is_critical)

	# 데미지 팝업
	var popup_type = PopupType.CRITICAL if is_critical else PopupType.NORMAL
	damage_popup_requested.emit(target.global_position, final_damage, popup_type)

	# 공격자 피로도 증가
	attacker.add_fatigue(FatigueSystem.FATIGUE_ATTACK)

	# 사망 체크
	var target_died = not target.is_alive
	if target_died:
		unit_killed.emit(attacker, target)
		_handle_enemy_kill(attacker, target)

	return {
		"success": true,
		"hit": true,
		"damage": final_damage,
		"is_critical": is_critical,
		"target_died": target_died
	}

## 명중/회피 판정
func _calculate_hit(attacker, target) -> Dictionary:
	# 공격자 명중률 (LCK 보정)
	var attacker_lck = 5  # 기본값
	if attacker.has_method("get_stat"):
		attacker_lck = attacker.get_stat(StatsSystem.StatType.LCK)

	var hit_chance = BASE_HIT_CHANCE + (attacker_lck * 0.01)

	# 대상 회피율 (SPD + LCK 보정)
	var target_spd = 100  # 기본값
	var target_lck = 5
	var target_evasion_bonus = 0.0

	if target.has_method("get_stat"):
		target_spd = target.get_stat(StatsSystem.StatType.SPD)
		target_lck = target.get_stat(StatsSystem.StatType.LCK)
		target_evasion_bonus = target.get_stat(StatsSystem.StatType.EVASION)

	var evasion_chance = BASE_EVASION + (target_spd * 0.001) + (target_lck * 0.005) + target_evasion_bonus

	# 명중 판정
	var roll = randf()
	if roll > hit_chance:
		return {"hit": false, "evaded": false}  # 빗나감

	# 회피 판정
	if randf() < evasion_chance:
		return {"hit": false, "evaded": true}  # 회피

	return {"hit": true, "evaded": false}

## 적 처치 시 경험치 처리
func _handle_enemy_kill(attacker, victim) -> void:
	# 적 유닛에서 경험치 계산
	var exp_amount = 10  # 기본값

	if victim.has_method("get_exp_reward"):
		exp_amount = victim.get_exp_reward()
	else:
		# EnemyData가 있으면 사용
		exp_amount = 10 + (victim.max_hp / 10)

	# 공격자에게 경험치 부여
	if attacker.has_method("gain_exp"):
		attacker.gain_exp(exp_amount)
		exp_gained.emit(attacker, exp_amount)

	# 골드 보상 (Phase 4에서 InventorySystem 연동)
	var gold_amount = 5 + (victim.max_hp / 20)
	gold_rewarded.emit(attacker, gold_amount)

## 데미지 계산
func calculate_damage(attacker, target) -> Dictionary:
	var base_damage = attacker.attack_power
	var defense = target.defense

	# 스탯 시스템이 있으면 사용
	if attacker.has_method("get_stat"):
		base_damage = attacker.get_stat(StatsSystem.StatType.ATK)
	if target.has_method("get_stat"):
		defense = target.get_stat(StatsSystem.StatType.DEF)

	# 크리티컬 확률 계산
	var crit_chance = CRITICAL_HIT_CHANCE
	if attacker.has_method("get_stat"):
		crit_chance += attacker.get_stat(StatsSystem.StatType.CRITICAL_CHANCE)
		var attacker_lck = attacker.get_stat(StatsSystem.StatType.LCK)
		crit_chance += attacker_lck * 0.005  # LCK 1당 0.5% 크리티컬

	# 크리티컬 판정
	var is_critical = randf() < crit_chance
	if is_critical:
		base_damage = int(base_damage * CRITICAL_HIT_MULTIPLIER)

	# 데미지 편차 (+-10%)
	var variance = randf_range(-BASE_DAMAGE_VARIANCE, BASE_DAMAGE_VARIANCE)
	base_damage = int(base_damage * (1.0 + variance))

	# 방어력 적용 (ATK - DEF 공식, 최소 1)
	var final_damage = max(MIN_DAMAGE, base_damage - defense)

	return {
		"damage": final_damage,
		"is_critical": is_critical,
		"base_damage": base_damage,
		"defense_reduced": defense
	}

## 공격 가능 여부 체크
func _can_attack(attacker, target) -> bool:
	if not attacker.is_alive or not target.is_alive:
		return false

	# 거리 체크
	var distance = attacker.global_position.distance_to(target.global_position)
	if distance > attacker.attack_range:
		return false

	# 피로도 체크
	var fatigue_info = FatigueSystem.get_fatigue_info(attacker)
	if not fatigue_info["can_act"]:
		return false

	return true

## 범위 내 적 검색
func find_enemies_in_range(unit, search_range: float, is_player: bool) -> Array:
	var enemies: Array = []
	var target_list = GameManager.enemy_units if is_player else GameManager.player_units

	for enemy in target_list:
		if not enemy.is_alive:
			continue
		var distance = unit.global_position.distance_to(enemy.global_position)
		if distance <= search_range:
			enemies.append(enemy)

	return enemies

## 가장 가까운 적 찾기
func find_nearest_enemy(unit, is_player: bool):
	var target_list = GameManager.enemy_units if is_player else GameManager.player_units
	var nearest = null
	var nearest_distance = INF

	for enemy in target_list:
		if not enemy.is_alive:
			continue
		var distance = unit.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance

	return nearest
