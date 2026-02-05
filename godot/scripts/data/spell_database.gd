extends RefCounted
class_name SpellDatabase
## SpellDatabase: 기본 마법 데이터베이스
##
## 모든 마법 데이터를 Dictionary로 관리하고 SpellData 리소스 생성을 지원합니다.

static var spells: Dictionary = {
	"fire_ball": {
		"spell_name": "Fire Ball",
		"description": "화염 구체를 발사하여 범위 내 적에게 화염 피해를 입힌다.",
		"spell_type": SpellData.SpellType.DAMAGE,
		"element": SpellData.ElementType.FIRE,
		"target_type": SpellData.TargetType.AREA,
		"mp_cost": 15,
		"base_power": 30,
		"cast_range": 250.0,
		"area_radius": 60.0,
		"cooldown": 4.0,
		"cast_time": 0.8,
	},
	"ice_bolt": {
		"spell_name": "Ice Bolt",
		"description": "얼음 화살을 발사하여 단일 적에게 빙결 피해를 입힌다.",
		"spell_type": SpellData.SpellType.DAMAGE,
		"element": SpellData.ElementType.ICE,
		"target_type": SpellData.TargetType.SINGLE_ENEMY,
		"mp_cost": 10,
		"base_power": 25,
		"cast_range": 200.0,
		"area_radius": 50.0,
		"cooldown": 2.0,
		"cast_time": 0.5,
	},
	"thunder": {
		"spell_name": "Thunder",
		"description": "번개를 내려 적에게 전격 피해를 입힌다.",
		"spell_type": SpellData.SpellType.DAMAGE,
		"element": SpellData.ElementType.LIGHTNING,
		"target_type": SpellData.TargetType.SINGLE_ENEMY,
		"mp_cost": 20,
		"base_power": 45,
		"cast_range": 300.0,
		"area_radius": 50.0,
		"cooldown": 5.0,
		"cast_time": 1.0,
	},
	"heal": {
		"spell_name": "Heal",
		"description": "아군 한 명의 체력을 회복한다.",
		"spell_type": SpellData.SpellType.HEAL,
		"element": SpellData.ElementType.HOLY,
		"target_type": SpellData.TargetType.SINGLE_ALLY,
		"mp_cost": 12,
		"base_power": 40,
		"cast_range": 150.0,
		"area_radius": 50.0,
		"cooldown": 3.0,
		"cast_time": 0.6,
		"buff_stat": 0,
		"buff_value": 0.0,
		"buff_duration": 0.0,
	},
	"mass_heal": {
		"spell_name": "Mass Heal",
		"description": "주변 아군 전체의 체력을 회복한다.",
		"spell_type": SpellData.SpellType.HEAL,
		"element": SpellData.ElementType.HOLY,
		"target_type": SpellData.TargetType.AREA,
		"mp_cost": 30,
		"base_power": 25,
		"cast_range": 100.0,
		"area_radius": 120.0,
		"cooldown": 8.0,
		"cast_time": 1.2,
		"buff_stat": 0,
		"buff_value": 0.0,
		"buff_duration": 0.0,
	},
	"shield": {
		"spell_name": "Shield",
		"description": "아군의 방어력을 일시적으로 증가시킨다.",
		"spell_type": SpellData.SpellType.BUFF,
		"element": SpellData.ElementType.NONE,
		"target_type": SpellData.TargetType.SINGLE_ALLY,
		"mp_cost": 8,
		"base_power": 0,
		"buff_stat": 1,  # DEF
		"buff_value": 10.0,
		"buff_duration": 15.0,
		"cast_range": 150.0,
		"area_radius": 50.0,
		"cooldown": 5.0,
		"cast_time": 0.5,
	},
	"haste": {
		"spell_name": "Haste",
		"description": "아군의 이동/공격 속도를 증가시킨다.",
		"spell_type": SpellData.SpellType.BUFF,
		"element": SpellData.ElementType.NONE,
		"target_type": SpellData.TargetType.SINGLE_ALLY,
		"mp_cost": 10,
		"base_power": 0,
		"buff_stat": 2,  # SPD
		"buff_value": 30.0,
		"buff_duration": 12.0,
		"cast_range": 150.0,
		"area_radius": 50.0,
		"cooldown": 6.0,
		"cast_time": 0.5,
	},
	"slow": {
		"spell_name": "Slow",
		"description": "적의 이동 속도를 감소시킨다.",
		"spell_type": SpellData.SpellType.DEBUFF,
		"element": SpellData.ElementType.ICE,
		"target_type": SpellData.TargetType.SINGLE_ENEMY,
		"mp_cost": 8,
		"base_power": 0,
		"buff_stat": 2,  # SPD
		"buff_value": -20.0,
		"buff_duration": 10.0,
		"cast_range": 180.0,
		"area_radius": 50.0,
		"cooldown": 4.0,
		"cast_time": 0.5,
	},
}

## SpellData 리소스 생성
## @param spell_id: 마법 ID (예: "fire_ball")
## @return: SpellData 리소스 또는 null (존재하지 않는 ID일 경우)
static func create_spell(spell_id: String) -> SpellData:
	if not spells.has(spell_id):
		push_error("SpellDatabase: Unknown spell_id '%s'" % spell_id)
		return null

	var data = spells[spell_id]
	var spell = SpellData.new()
	spell.spell_id = spell_id

	# Dictionary 데이터를 SpellData 필드로 복사
	for key in data:
		if key in spell:
			spell.set(key, data[key])

	return spell

## 모든 마법 ID 반환
## @return: 마법 ID 배열
static func get_all_spell_ids() -> Array:
	return spells.keys()

## 특정 타입의 마법 ID 반환
## @param spell_type: SpellData.SpellType
## @return: 해당 타입의 마법 ID 배열
static func get_spells_by_type(spell_type: SpellData.SpellType) -> Array:
	var result: Array = []
	for spell_id in spells:
		if spells[spell_id]["spell_type"] == spell_type:
			result.append(spell_id)
	return result

## 특정 속성의 마법 ID 반환
## @param element: SpellData.ElementType
## @return: 해당 속성의 마법 ID 배열
static func get_spells_by_element(element: SpellData.ElementType) -> Array:
	var result: Array = []
	for spell_id in spells:
		if spells[spell_id].get("element", SpellData.ElementType.NONE) == element:
			result.append(spell_id)
	return result
