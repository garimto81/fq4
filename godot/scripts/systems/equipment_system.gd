extends RefCounted
class_name EquipmentSystem
## EquipmentSystem: 장비 시스템
##
## 무기, 방어구, 액세서리 장착/해제를 관리합니다.

# 소유 유닛 참조
var owner_unit = null

# 장비 슬롯
var equipped: Dictionary = {
	EquipmentData.EquipmentSlot.WEAPON: null,
	EquipmentData.EquipmentSlot.ARMOR: null,
	EquipmentData.EquipmentSlot.ACCESSORY: null
}

# 스탯 시스템 참조 (장비 보너스 적용용)
var stats_system: StatsSystem = null

# 시그널
signal equipment_changed(slot: int, old_item: EquipmentData, new_item: EquipmentData)
signal equipment_failed(slot: int, reason: String)

## 초기화 (Unit._init_data_systems()에서 호출)
func init(unit) -> void:
	owner_unit = unit

## 초기화 (구 버전 호환)
func initialize(stats: StatsSystem) -> void:
	stats_system = stats
	_recalculate_bonuses()

## 장비 장착
func equip(item: EquipmentData, unit_level: int = 1) -> Dictionary:
	if item == null:
		return {"success": false, "reason": "Invalid item"}

	# 레벨 체크
	if not item.can_equip(unit_level):
		equipment_failed.emit(item.slot, "Level requirement not met")
		return {"success": false, "reason": "Level requirement not met", "required_level": item.required_level}

	var slot = item.slot
	var old_item = equipped[slot]

	# 장비 교체
	equipped[slot] = item
	_recalculate_bonuses()

	equipment_changed.emit(slot, old_item, item)

	return {
		"success": true,
		"slot": slot,
		"old_item": old_item,
		"new_item": item
	}

## 장비 해제
func unequip(slot: EquipmentData.EquipmentSlot) -> Dictionary:
	if not equipped.has(slot):
		return {"success": false, "reason": "Invalid slot"}

	var old_item = equipped[slot]
	if old_item == null:
		return {"success": false, "reason": "No equipment in slot"}

	equipped[slot] = null
	_recalculate_bonuses()

	equipment_changed.emit(slot, old_item, null)

	return {
		"success": true,
		"slot": slot,
		"unequipped_item": old_item
	}

## 슬롯별 장비 확인
func get_equipped(slot: EquipmentData.EquipmentSlot) -> EquipmentData:
	return equipped.get(slot, null)

## 모든 장비 정보
func get_all_equipped() -> Dictionary:
	return equipped.duplicate()

## 총 장비 보너스 계산
func get_total_bonuses() -> Dictionary:
	var total: Dictionary = {
		"hp": 0,
		"mp": 0,
		"atk": 0,
		"def": 0,
		"spd": 0,
		"lck": 0,
		"attack_range": 0.0,
		"critical_chance": 0.0,
		"evasion": 0.0
	}

	for slot in equipped:
		var item = equipped[slot]
		if item != null:
			var bonuses = item.get_stat_bonuses()
			for key in bonuses:
				if total.has(key):
					total[key] += bonuses[key]

	return total

## 스탯 시스템에 보너스 적용
func _recalculate_bonuses() -> void:
	if stats_system == null:
		return

	stats_system.clear_equipment_bonus()
	var bonuses = get_total_bonuses()

	if bonuses["hp"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.HP, bonuses["hp"])
	if bonuses["mp"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.MP, bonuses["mp"])
	if bonuses["atk"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.ATK, bonuses["atk"])
	if bonuses["def"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.DEF, bonuses["def"])
	if bonuses["spd"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.SPD, bonuses["spd"])
	if bonuses["lck"] != 0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.LCK, bonuses["lck"])
	if bonuses["attack_range"] != 0.0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.ATTACK_RANGE, bonuses["attack_range"])
	if bonuses["critical_chance"] != 0.0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.CRITICAL_CHANCE, bonuses["critical_chance"])
	if bonuses["evasion"] != 0.0:
		stats_system.set_equipment_bonus(StatsSystem.StatType.EVASION, bonuses["evasion"])

## 슬롯 이름 반환
static func get_slot_name(slot: EquipmentData.EquipmentSlot) -> String:
	match slot:
		EquipmentData.EquipmentSlot.WEAPON:
			return "Weapon"
		EquipmentData.EquipmentSlot.ARMOR:
			return "Armor"
		EquipmentData.EquipmentSlot.ACCESSORY:
			return "Accessory"
		_:
			return "Unknown"

## 직렬화 (세이브용)
func serialize() -> Dictionary:
	var data: Dictionary = {}
	for slot in equipped:
		if equipped[slot] != null:
			data[slot] = equipped[slot].id
		else:
			data[slot] = ""
	return data

## 역직렬화 (로드용) - 아이템 ID로 리소스 로드 필요
func deserialize(data: Dictionary, item_loader: Callable) -> void:
	for slot in data:
		var item_id = data[slot]
		if item_id != "":
			var item = item_loader.call(item_id)
			if item != null:
				equipped[int(slot)] = item
		else:
			equipped[int(slot)] = null

	_recalculate_bonuses()
