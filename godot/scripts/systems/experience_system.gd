extends RefCounted
class_name ExperienceSystem
## ExperienceSystem: 경험치 및 레벨 시스템
##
## 적 처치 시 EXP 획득, 레벨업 처리를 담당합니다.

const MAX_LEVEL: int = 50

# 레벨업 테이블 (LevelTable 리소스 사용 가능)
var level_table: LevelTable

# 현재 상태
var current_level: int = 1
var current_exp: int = 0
var total_exp: int = 0

# 시그널
signal exp_gained(amount: int, new_total: int)
signal level_up(new_level: int, stat_gains: Dictionary)
signal max_level_reached()

func _init() -> void:
	level_table = LevelTable.new()

## 초기화
func initialize(level: int = 1, exp: int = 0) -> void:
	current_level = clamp(level, 1, MAX_LEVEL)
	current_exp = exp
	total_exp = level_table.get_total_exp_for_level(current_level) + exp

## 경험치 획득
func gain_exp(amount: int) -> Dictionary:
	if current_level >= MAX_LEVEL:
		max_level_reached.emit()
		return {"level_ups": 0, "stat_gains": {}}

	var old_level = current_level
	total_exp += amount
	current_exp += amount
	exp_gained.emit(amount, total_exp)

	# 레벨업 체크
	var level_ups = 0
	var total_stat_gains: Dictionary = {}

	while current_level < MAX_LEVEL:
		var exp_needed = level_table.get_exp_to_next_level(current_level)
		if current_exp >= exp_needed:
			current_exp -= exp_needed
			current_level += 1
			level_ups += 1

			var stat_gains = level_table.get_level_up_stats()
			_accumulate_stats(total_stat_gains, stat_gains)
			level_up.emit(current_level, stat_gains)
		else:
			break

	if current_level >= MAX_LEVEL:
		current_exp = 0
		max_level_reached.emit()

	return {
		"level_ups": level_ups,
		"old_level": old_level,
		"new_level": current_level,
		"stat_gains": total_stat_gains
	}

## 스탯 누적
func _accumulate_stats(total: Dictionary, gains: Dictionary) -> void:
	for key in gains:
		if total.has(key):
			total[key] += gains[key]
		else:
			total[key] = gains[key]

## 다음 레벨까지 필요한 경험치
func get_exp_to_next_level() -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return level_table.get_exp_to_next_level(current_level)

## 현재 레벨 진행도 (0.0 ~ 1.0)
func get_level_progress() -> float:
	if current_level >= MAX_LEVEL:
		return 1.0
	var needed = get_exp_to_next_level()
	if needed <= 0:
		return 1.0
	return float(current_exp) / float(needed)

## 경험치 정보
func get_exp_info() -> Dictionary:
	return {
		"level": current_level,
		"current_exp": current_exp,
		"total_exp": total_exp,
		"exp_to_next": get_exp_to_next_level(),
		"progress": get_level_progress(),
		"is_max_level": current_level >= MAX_LEVEL
	}

## 레벨 직접 설정 (치트/디버그용)
func set_level(new_level: int) -> void:
	new_level = clamp(new_level, 1, MAX_LEVEL)
	current_level = new_level
	current_exp = 0
	total_exp = level_table.get_total_exp_for_level(new_level)

## 적 처치 시 경험치 계산
static func calculate_enemy_exp(enemy_level: int, enemy_type: int, player_level: int) -> int:
	# 기본 경험치
	var base_exp = 10 + (enemy_level * 5)

	# 적 타입 보정 (0=Normal, 1=Elite, 2=Boss)
	var type_mult = 1.0
	match enemy_type:
		1:  # Elite
			type_mult = 2.0
		2:  # Boss
			type_mult = 5.0

	# 레벨 차이 보정 (너무 약한 적은 경험치 감소)
	var level_diff = enemy_level - player_level
	var level_mult = 1.0
	if level_diff < -5:
		level_mult = max(0.1, 1.0 + (level_diff * 0.1))
	elif level_diff > 5:
		level_mult = min(2.0, 1.0 + (level_diff * 0.05))

	return int(base_exp * type_mult * level_mult)

## 직렬화 (세이브용)
func serialize() -> Dictionary:
	return {
		"current_level": current_level,
		"current_exp": current_exp,
		"total_exp": total_exp
	}

## 역직렬화 (로드용)
func deserialize(data: Dictionary) -> void:
	current_level = data.get("current_level", 1)
	current_exp = data.get("current_exp", 0)
	total_exp = data.get("total_exp", 0)
