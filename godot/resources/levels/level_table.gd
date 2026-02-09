extends Resource
class_name LevelTable
## LevelTable: 레벨업 테이블 리소스
##
## 레벨별 필요 경험치와 스탯 성장을 정의합니다.

const MAX_LEVEL: int = 50

# 경험치 공식 파라미터
@export var base_exp: int = 100          # 레벨 2 필요 경험치
@export var exp_growth_rate: float = 1.2  # 경험치 증가율

# 스탯 성장 (레벨당)
@export var hp_growth: int = 15
@export var mp_growth: int = 5
@export var atk_growth: int = 2
@export var def_growth: int = 1
@export var spd_growth: int = 1
@export var lck_growth: int = 1

# 캐시된 경험치 테이블
var _exp_table: Array[int] = []

func _init() -> void:
	_generate_exp_table()

## 경험치 테이블 생성
func _generate_exp_table() -> void:
	_exp_table.clear()
	_exp_table.append(0)  # 레벨 1

	for level in range(2, MAX_LEVEL + 1):
		var required = int(base_exp * pow(exp_growth_rate, level - 2))
		_exp_table.append(_exp_table[level - 2] + required)

## 특정 레벨의 누적 필요 경험치
func get_total_exp_for_level(level: int) -> int:
	level = clamp(level, 1, MAX_LEVEL)
	if _exp_table.is_empty():
		_generate_exp_table()
	return _exp_table[level - 1]

## 현재 레벨에서 다음 레벨까지 필요한 경험치
func get_exp_to_next_level(current_level: int) -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return get_total_exp_for_level(current_level + 1) - get_total_exp_for_level(current_level)

## 경험치로 레벨 계산
func get_level_from_exp(total_exp: int) -> int:
	if _exp_table.is_empty():
		_generate_exp_table()

	for level in range(MAX_LEVEL, 0, -1):
		if total_exp >= _exp_table[level - 1]:
			return level
	return 1

## 레벨업 시 스탯 증가량
func get_level_up_stats() -> Dictionary:
	return {
		"hp": hp_growth,
		"mp": mp_growth,
		"atk": atk_growth,
		"def": def_growth,
		"spd": spd_growth,
		"lck": lck_growth
	}

## 특정 레벨의 기본 스탯 (레벨 1 기준 + 성장)
func get_stats_at_level(level: int, base_stats: Dictionary) -> Dictionary:
	var growth_multiplier = level - 1
	return {
		"hp": base_stats.get("hp", 100) + (hp_growth * growth_multiplier),
		"mp": base_stats.get("mp", 50) + (mp_growth * growth_multiplier),
		"atk": base_stats.get("atk", 10) + (atk_growth * growth_multiplier),
		"def": base_stats.get("def", 5) + (def_growth * growth_multiplier),
		"spd": base_stats.get("spd", 100) + (spd_growth * growth_multiplier),
		"lck": base_stats.get("lck", 5) + (lck_growth * growth_multiplier)
	}
