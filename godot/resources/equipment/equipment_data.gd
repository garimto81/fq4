extends Resource
class_name EquipmentData
## EquipmentData: 장비 데이터 리소스
##
## 무기, 방어구, 액세서리의 데이터를 정의합니다.

enum EquipmentSlot {
	WEAPON,         # 무기
	ARMOR,          # 방어구
	ACCESSORY       # 액세서리
}

enum WeaponType {
	SWORD,          # 검
	AXE,            # 도끼
	SPEAR,          # 창
	BOW,            # 활
	STAFF,          # 지팡이
	NONE            # 무기 아님
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var slot: EquipmentSlot = EquipmentSlot.WEAPON
@export var weapon_type: WeaponType = WeaponType.NONE

# 기본 스탯 보너스
@export var bonus_hp: int = 0
@export var bonus_mp: int = 0
@export var bonus_atk: int = 0
@export var bonus_def: int = 0
@export var bonus_spd: int = 0
@export var bonus_lck: int = 0

# 추가 효과
@export var attack_range_bonus: float = 0.0
@export var critical_chance_bonus: float = 0.0
@export var evasion_bonus: float = 0.0

# 요구 조건
@export var required_level: int = 1
@export var buy_price: int = 0
@export var sell_price: int = 0

## 장비 가능 여부 체크
func can_equip(unit_level: int) -> bool:
	return unit_level >= required_level

## 스탯 보너스 딕셔너리 반환
func get_stat_bonuses() -> Dictionary:
	return {
		"hp": bonus_hp,
		"mp": bonus_mp,
		"atk": bonus_atk,
		"def": bonus_def,
		"spd": bonus_spd,
		"lck": bonus_lck,
		"attack_range": attack_range_bonus,
		"critical_chance": critical_chance_bonus,
		"evasion": evasion_bonus
	}
