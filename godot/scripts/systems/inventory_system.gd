extends Node
class_name InventorySystem
## InventorySystem: 인벤토리 시스템
##
## 아이템 저장, 사용, 관리를 담당합니다.

# 인벤토리 슬롯 구조: {item_id: ItemData, quantity: int}
var items: Dictionary = {}  # item_id -> {data: ItemData, quantity: int}
var max_slots: int = 50
var gold: int = 0

# 시그널
signal item_added(item_id: String, quantity: int, new_total: int)
signal item_removed(item_id: String, quantity: int, remaining: int)
signal item_used(item_id: String, target: Node, result: Dictionary)
signal inventory_full()
signal gold_changed(new_amount: int, delta: int)

## 아이템 추가
func add_item(item_data: ItemData, quantity: int = 1) -> Dictionary:
	if item_data == null:
		return {"success": false, "reason": "Invalid item"}

	var item_id = item_data.id

	if items.has(item_id):
		# 기존 아이템 수량 증가
		var current = items[item_id]["quantity"]
		var max_stack = item_data.max_stack
		var new_quantity = min(current + quantity, max_stack)
		var added = new_quantity - current

		items[item_id]["quantity"] = new_quantity
		item_added.emit(item_id, added, new_quantity)

		return {
			"success": true,
			"added": added,
			"overflow": quantity - added,
			"new_total": new_quantity
		}
	else:
		# 새 아이템 추가
		if items.size() >= max_slots:
			inventory_full.emit()
			return {"success": false, "reason": "Inventory full"}

		var add_quantity = min(quantity, item_data.max_stack)
		items[item_id] = {
			"data": item_data,
			"quantity": add_quantity
		}
		item_added.emit(item_id, add_quantity, add_quantity)

		return {
			"success": true,
			"added": add_quantity,
			"overflow": quantity - add_quantity,
			"new_total": add_quantity
		}

## 아이템 제거
func remove_item(item_id: String, quantity: int = 1) -> Dictionary:
	if not items.has(item_id):
		return {"success": false, "reason": "Item not found"}

	var current = items[item_id]["quantity"]
	if current < quantity:
		return {"success": false, "reason": "Not enough items", "available": current}

	var remaining = current - quantity
	if remaining <= 0:
		items.erase(item_id)
		remaining = 0
	else:
		items[item_id]["quantity"] = remaining

	item_removed.emit(item_id, quantity, remaining)

	return {
		"success": true,
		"removed": quantity,
		"remaining": remaining
	}

## 아이템 사용
func use_item(item_id: String, target: Node) -> Dictionary:
	if not items.has(item_id):
		return {"success": false, "reason": "Item not found"}

	var item_data: ItemData = items[item_id]["data"]
	if not item_data.can_use():
		return {"success": false, "reason": "Cannot use this item"}

	# 효과 적용
	var result = item_data.apply_effect(target)

	if result["success"]:
		# 수량 감소
		remove_item(item_id, 1)
		item_used.emit(item_id, target, result)

	return result

## 아이템 보유 여부
func has_item(item_id: String, quantity: int = 1) -> bool:
	if not items.has(item_id):
		return false
	return items[item_id]["quantity"] >= quantity

## 아이템 수량 확인
func get_item_count(item_id: String) -> int:
	if not items.has(item_id):
		return 0
	return items[item_id]["quantity"]

## 아이템 데이터 가져오기
func get_item_data(item_id: String) -> ItemData:
	if not items.has(item_id):
		return null
	return items[item_id]["data"]

## 모든 아이템 목록
func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items:
		result.append({
			"id": item_id,
			"data": items[item_id]["data"],
			"quantity": items[item_id]["quantity"]
		})
	return result

## 특정 타입 아이템 필터
func get_items_by_type(item_type: ItemData.ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in items:
		var item_data: ItemData = items[item_id]["data"]
		if item_data.item_type == item_type:
			result.append({
				"id": item_id,
				"data": item_data,
				"quantity": items[item_id]["quantity"]
			})
	return result

## 인벤토리 공간 확인
func get_free_slots() -> int:
	return max_slots - items.size()

## 인벤토리가 가득 찼는지
func is_full() -> bool:
	return items.size() >= max_slots

## 골드 추가
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold, amount)

## 골드 사용
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold, -amount)
	return true

## 골드 충분 여부
func can_afford(amount: int) -> bool:
	return gold >= amount

## 인벤토리 비우기
func clear() -> void:
	items.clear()
	gold = 0
	gold_changed.emit(0, 0)

## 직렬화 (세이브용)
func serialize() -> Dictionary:
	var items_data: Dictionary = {}
	for item_id in items:
		items_data[item_id] = items[item_id]["quantity"]

	return {
		"items": items_data,
		"gold": gold
	}

## 역직렬화 (로드용) - 아이템 ID로 리소스 로드 필요
func deserialize(data: Dictionary, item_loader: Callable) -> void:
	items.clear()

	if data.has("items"):
		for item_id in data["items"]:
			var item_data = item_loader.call(item_id)
			if item_data != null:
				items[item_id] = {
					"data": item_data,
					"quantity": data["items"][item_id]
				}

	if data.has("gold"):
		gold = data["gold"]
