extends RefCounted
class_name ItemDatabase
## ItemDatabase: 기본 아이템 데이터베이스
##
## 모든 아이템 데이터를 Dictionary로 관리하고 ItemData 리소스 생성을 지원합니다.

static var items: Dictionary = {
	"health_potion_small": {
		"display_name": "작은 체력 물약",
		"description": "체력을 50 회복한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 50,
		"sell_price": 25,
		"effect_type": ItemData.ItemEffect.HEAL_HP,
		"effect_value": 50,
		"effect_duration": 0.0,
	},
	"health_potion_medium": {
		"display_name": "중간 체력 물약",
		"description": "체력을 150 회복한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 150,
		"sell_price": 75,
		"effect_type": ItemData.ItemEffect.HEAL_HP,
		"effect_value": 150,
		"effect_duration": 0.0,
	},
	"health_potion_large": {
		"display_name": "큰 체력 물약",
		"description": "체력을 300 회복한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 400,
		"sell_price": 200,
		"effect_type": ItemData.ItemEffect.HEAL_HP,
		"effect_value": 300,
		"effect_duration": 0.0,
	},
	"mana_potion_small": {
		"display_name": "작은 마나 물약",
		"description": "마나를 30 회복한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 80,
		"sell_price": 40,
		"effect_type": ItemData.ItemEffect.HEAL_MP,
		"effect_value": 30,
		"effect_duration": 0.0,
	},
	"mana_potion_medium": {
		"display_name": "중간 마나 물약",
		"description": "마나를 80 회복한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 200,
		"sell_price": 100,
		"effect_type": ItemData.ItemEffect.HEAL_MP,
		"effect_value": 80,
		"effect_duration": 0.0,
	},
	"stamina_drink": {
		"display_name": "스태미나 드링크",
		"description": "피로도를 30 감소시킨다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 100,
		"sell_price": 50,
		"effect_type": ItemData.ItemEffect.HEAL_FATIGUE,
		"effect_value": 30,
		"effect_duration": 0.0,
	},
	"revive_herb": {
		"display_name": "부활의 허브",
		"description": "전투 불능 상태의 아군을 HP 30%로 부활시킨다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 500,
		"sell_price": 250,
		"effect_type": ItemData.ItemEffect.REVIVE,
		"effect_value": 30,  # 30% HP
		"effect_duration": 0.0,
	},
	"antidote": {
		"display_name": "해독제",
		"description": "독 상태이상을 해제한다.",
		"item_type": ItemData.ItemType.CONSUMABLE,
		"max_stack": 99,
		"buy_price": 60,
		"sell_price": 30,
		"effect_type": ItemData.ItemEffect.NONE,  # 상태이상 해제는 별도 처리
		"effect_value": 0,
		"effect_duration": 0.0,
	},
}

## ItemData 리소스 생성
## @param item_id: 아이템 ID (예: "health_potion_small")
## @return: ItemData 리소스 또는 null (존재하지 않는 ID일 경우)
static func create_item(item_id: String) -> ItemData:
	if not items.has(item_id):
		push_error("ItemDatabase: Unknown item_id '%s'" % item_id)
		return null

	var data = items[item_id]
	var item = ItemData.new()
	item.id = item_id

	# Dictionary 데이터를 ItemData 필드로 복사
	for key in data:
		if key in item:
			item.set(key, data[key])

	return item

## 모든 아이템 ID 반환
## @return: 아이템 ID 배열
static func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(items.keys())
	return result

## 특정 타입의 아이템 ID 반환
## @param item_type: ItemData.ItemType
## @return: 해당 타입의 아이템 ID 배열
static func get_items_by_type(item_type: ItemData.ItemType) -> Array[String]:
	var result: Array[String] = []
	for item_id in items:
		if items[item_id]["item_type"] == item_type:
			result.append(item_id)
	return result

## 특정 효과의 아이템 ID 반환
## @param effect: ItemData.ItemEffect
## @return: 해당 효과의 아이템 ID 배열
static func get_items_by_effect(effect: ItemData.ItemEffect) -> Array[String]:
	var result: Array[String] = []
	for item_id in items:
		if items[item_id].get("effect_type", ItemData.ItemEffect.NONE) == effect:
			result.append(item_id)
	return result
