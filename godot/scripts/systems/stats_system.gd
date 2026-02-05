extends RefCounted
class_name StatsSystem
## StatsSystem: RPG 스탯 시스템
##
## HP, MP, ATK, DEF, SPD, LCK 스탯을 관리합니다.
## 기본 스탯 + 장비 보너스 + 버프를 계산합니다.

# 스탯 타입
enum StatType {
	HP,
	MP,
	ATK,
	DEF,
	SPD,
	LCK,
	ATTACK_RANGE,
	CRITICAL_CHANCE,
	EVASION
}

# 기본 스탯
var base_stats: Dictionary = {
	StatType.HP: 100,
	StatType.MP: 50,
	StatType.ATK: 10,
	StatType.DEF: 5,
	StatType.SPD: 100,
	StatType.LCK: 5,
	StatType.ATTACK_RANGE: 50.0,
	StatType.CRITICAL_CHANCE: 0.05,
	StatType.EVASION: 0.05
}

# 장비 보너스
var equipment_bonus: Dictionary = {}

# 버프 (일시적 효과)
var active_buffs: Array[Dictionary] = []  # [{stat: StatType, value: int, duration: float, elapsed: float}]

# 시그널
signal stats_changed()
signal buff_applied(stat: StatType, value: int, duration: float)
signal buff_expired(stat: StatType)

## 초기화
func initialize(initial_stats: Dictionary) -> void:
	for key in initial_stats:
		if base_stats.has(key):
			base_stats[key] = initial_stats[key]
	equipment_bonus.clear()
	active_buffs.clear()
	stats_changed.emit()

## 기본 스탯 설정
func set_base_stat(stat: StatType, value) -> void:
	base_stats[stat] = value
	stats_changed.emit()

## 장비 보너스 설정
func set_equipment_bonus(stat: StatType, value) -> void:
	equipment_bonus[stat] = value
	stats_changed.emit()

## 장비 보너스 초기화
func clear_equipment_bonus() -> void:
	equipment_bonus.clear()
	stats_changed.emit()

## 버프 적용
func apply_buff(stat: StatType, value: int, duration: float) -> void:
	var buff = {
		"stat": stat,
		"value": value,
		"duration": duration,
		"elapsed": 0.0
	}
	active_buffs.append(buff)
	buff_applied.emit(stat, value, duration)
	stats_changed.emit()

## 버프 업데이트 (매 프레임 호출)
func update_buffs(delta: float) -> void:
	var expired_buffs: Array[int] = []

	for i in range(active_buffs.size()):
		active_buffs[i]["elapsed"] += delta
		if active_buffs[i]["elapsed"] >= active_buffs[i]["duration"]:
			expired_buffs.append(i)

	# 역순으로 제거
	for i in range(expired_buffs.size() - 1, -1, -1):
		var buff = active_buffs[expired_buffs[i]]
		buff_expired.emit(buff["stat"])
		active_buffs.remove_at(expired_buffs[i])

	if not expired_buffs.is_empty():
		stats_changed.emit()

## 최종 스탯 계산
func get_final_stat(stat: StatType):
	var base_value = base_stats.get(stat, 0)
	var equipment_value = equipment_bonus.get(stat, 0)
	var buff_value = _get_buff_total(stat)

	return base_value + equipment_value + buff_value

## 버프 합계 계산
func _get_buff_total(stat: StatType):
	var total = 0
	for buff in active_buffs:
		if buff["stat"] == stat:
			total += buff["value"]
	return total

## 모든 최종 스탯 반환
func get_all_stats() -> Dictionary:
	var result: Dictionary = {}
	for stat in StatType.values():
		result[stat] = get_final_stat(stat)
	return result

## 스탯 이름 반환
static func get_stat_name(stat: StatType) -> String:
	match stat:
		StatType.HP:
			return "HP"
		StatType.MP:
			return "MP"
		StatType.ATK:
			return "ATK"
		StatType.DEF:
			return "DEF"
		StatType.SPD:
			return "SPD"
		StatType.LCK:
			return "LCK"
		StatType.ATTACK_RANGE:
			return "Range"
		StatType.CRITICAL_CHANCE:
			return "Crit%"
		StatType.EVASION:
			return "Evade%"
		_:
			return "Unknown"

## 레벨업 스탯 적용
func apply_level_up_stats(growth: Dictionary) -> void:
	if growth.has("hp"):
		base_stats[StatType.HP] += growth["hp"]
	if growth.has("mp"):
		base_stats[StatType.MP] += growth["mp"]
	if growth.has("atk"):
		base_stats[StatType.ATK] += growth["atk"]
	if growth.has("def"):
		base_stats[StatType.DEF] += growth["def"]
	if growth.has("spd"):
		base_stats[StatType.SPD] += growth["spd"]
	if growth.has("lck"):
		base_stats[StatType.LCK] += growth["lck"]

	stats_changed.emit()

## 직렬화 (세이브용)
func serialize() -> Dictionary:
	return {
		"base_stats": base_stats.duplicate(),
		"equipment_bonus": equipment_bonus.duplicate(),
		"active_buffs": active_buffs.duplicate()
	}

## 역직렬화 (로드용)
func deserialize(data: Dictionary) -> void:
	if data.has("base_stats"):
		base_stats = data["base_stats"]
	if data.has("equipment_bonus"):
		equipment_bonus = data["equipment_bonus"]
	if data.has("active_buffs"):
		active_buffs.assign(data["active_buffs"])
	stats_changed.emit()
