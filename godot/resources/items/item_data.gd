extends Resource
class_name ItemData
## ItemData: 아이템 데이터 리소스
##
## 모든 아이템의 기본 데이터를 정의합니다.

enum ItemType {
	CONSUMABLE,     # 소모품 (포션, 음식 등)
	MATERIAL,       # 재료
	KEY_ITEM,       # 키 아이템
	QUEST           # 퀘스트 아이템
}

enum ItemEffect {
	NONE,
	HEAL_HP,
	HEAL_MP,
	HEAL_FATIGUE,
	BUFF_ATK,
	BUFF_DEF,
	BUFF_SPD,
	REVIVE
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var max_stack: int = 99
@export var buy_price: int = 0
@export var sell_price: int = 0

# 효과 관련
@export var effect_type: ItemEffect = ItemEffect.NONE
@export var effect_value: int = 0
@export var effect_duration: float = 0.0  # 버프 지속시간 (초)

## 아이템 사용 가능 여부
func can_use() -> bool:
	return item_type == ItemType.CONSUMABLE and effect_type != ItemEffect.NONE

## 아이템 효과 적용
func apply_effect(target: Node) -> Dictionary:
	if not can_use():
		return {"success": false, "reason": "Cannot use this item"}

	var result = {"success": true, "effect": effect_type, "value": effect_value}

	match effect_type:
		ItemEffect.HEAL_HP:
			if target.has_method("heal"):
				target.heal(effect_value)
		ItemEffect.HEAL_MP:
			if target.has_method("restore_mp"):
				target.restore_mp(effect_value)
		ItemEffect.HEAL_FATIGUE:
			if target.has_method("rest"):
				target.rest(effect_value)
		ItemEffect.REVIVE:
			if target.has_method("revive"):
				target.revive(effect_value)
		ItemEffect.BUFF_ATK, ItemEffect.BUFF_DEF, ItemEffect.BUFF_SPD:
			result["duration"] = effect_duration
			# 버프 시스템에서 처리

	return result
