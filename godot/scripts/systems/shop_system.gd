extends Node
class_name ShopSystem
## ShopSystem: 상점 시스템 (Architecture Stub)
##
## Phase 4에서 완전 구현 예정. 현재는 인터페이스만 정의.

# 시그널
signal item_purchased(buyer, item, price: int)
signal item_sold(seller, item, price: int)
signal purchase_failed(buyer, item, reason: String)
signal shop_opened(shop_id: String)
signal shop_closed()

# 현재 열린 상점
var current_shop_id: String = ""
var current_shop_inventory: Array = []

## 상점 열기
func open_shop(shop_id: String, inventory: Array) -> void:
	current_shop_id = shop_id
	current_shop_inventory = inventory
	shop_opened.emit(shop_id)

## 상점 닫기
func close_shop() -> void:
	current_shop_id = ""
	current_shop_inventory = []
	shop_closed.emit()

## 아이템 구매
func buy_item(buyer, item, price: int) -> Dictionary:
	# InventorySystem과 연동 필요
	if not _can_afford(buyer, price):
		purchase_failed.emit(buyer, item, "Not enough gold")
		return {"success": false, "reason": "Not enough gold"}

	# TODO: InventorySystem.spend_gold(price)
	# TODO: InventorySystem.add_item(item)

	item_purchased.emit(buyer, item, price)
	return {"success": true}

## 아이템 판매
func sell_item(seller, item, price: int) -> Dictionary:
	# TODO: InventorySystem.remove_item(item)
	# TODO: InventorySystem.add_gold(price)

	item_sold.emit(seller, item, price)
	return {"success": true}

## 구매 가능 여부 (gold 체크)
func _can_afford(_buyer, price: int) -> bool:
	# TODO: InventorySystem.can_afford(price) 연동
	return price >= 0

## 판매가 계산 (구매가의 50%)
func get_sell_price(buy_price: int) -> int:
	return int(buy_price * 0.5)
