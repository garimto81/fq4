extends Node
class_name ShopSystem
## ShopSystem: 상점 시스템
##
## 아이템 구매, 판매, 상점 재고 관리를 담당합니다.

# 시그널
signal item_purchased(buyer, item_data: ItemData, price: int)
signal item_sold(seller, item_data: ItemData, price: int)
signal purchase_failed(buyer, item_data: ItemData, reason: String)
signal shop_opened(shop_data: ShopData)
signal shop_closed()
signal stock_changed(item_id: String, remaining: int)

# 의존성 (dependency injection)
var inventory_system: InventorySystem

# 현재 열린 상점
var current_shop_data: ShopData = null
var current_stock: Dictionary = {}  # item_id -> remaining quantity (-1 = infinite)

## 초기화 (의존성 주입)
func init(inventory_sys: InventorySystem) -> void:
	inventory_system = inventory_sys

## 상점 열기 (ShopData 기반)
func open_shop(shop_data: ShopData) -> void:
	current_shop_data = shop_data
	_initialize_stock(shop_data)
	shop_opened.emit(shop_data)

## 상점 닫기
func close_shop() -> void:
	current_shop_data = null
	current_stock.clear()
	shop_closed.emit()

## 재고 초기화 (무한 재고로 설정)
func _initialize_stock(shop_data: ShopData) -> void:
	current_stock.clear()
	for item in shop_data.items_for_sale:
		if item is ItemData:
			# -1 = 무한 재고
			current_stock[item.id] = -1

## 제한 재고 설정 (옵션)
func set_stock_limit(item_id: String, quantity: int) -> void:
	if current_stock.has(item_id):
		current_stock[item_id] = quantity

## 아이템 구매
func buy_item(buyer: Node, item_data: ItemData) -> Dictionary:
	if current_shop_data == null:
		return {"success": false, "reason": "No shop opened"}

	if inventory_system == null:
		return {"success": false, "reason": "InventorySystem not initialized"}

	# 재고 확인
	if not _has_stock(item_data.id):
		purchase_failed.emit(buyer, item_data, "Out of stock")
		return {"success": false, "reason": "Out of stock"}

	# 구매가 계산
	var price = get_item_buy_price(item_data, current_shop_data)

	# 골드 충분 여부
	if not inventory_system.can_afford(price):
		purchase_failed.emit(buyer, item_data, "Not enough gold")
		return {"success": false, "reason": "Not enough gold"}

	# 골드 소모
	if not inventory_system.spend_gold(price):
		return {"success": false, "reason": "Failed to spend gold"}

	# 아이템 추가
	var add_result = inventory_system.add_item(item_data, 1)
	if not add_result["success"]:
		# 롤백: 골드 환불
		inventory_system.add_gold(price)
		purchase_failed.emit(buyer, item_data, add_result["reason"])
		return {"success": false, "reason": add_result["reason"]}

	# 재고 감소
	_decrease_stock(item_data.id)

	item_purchased.emit(buyer, item_data, price)
	return {
		"success": true,
		"price": price,
		"item": item_data,
		"remaining_stock": current_stock.get(item_data.id, -1)
	}

## 아이템 판매
func sell_item(seller: Node, item_id: String) -> Dictionary:
	if current_shop_data == null:
		return {"success": false, "reason": "No shop opened"}

	if inventory_system == null:
		return {"success": false, "reason": "InventorySystem not initialized"}

	# 아이템 보유 여부
	if not inventory_system.has_item(item_id):
		return {"success": false, "reason": "Item not found in inventory"}

	var item_data = inventory_system.get_item_data(item_id)
	if item_data == null:
		return {"success": false, "reason": "Invalid item"}

	# 판매가 계산
	var price = get_item_sell_price(item_data, current_shop_data)

	# 아이템 제거
	var remove_result = inventory_system.remove_item(item_id, 1)
	if not remove_result["success"]:
		return {"success": false, "reason": remove_result["reason"]}

	# 골드 추가
	inventory_system.add_gold(price)

	item_sold.emit(seller, item_data, price)
	return {
		"success": true,
		"price": price,
		"item": item_data
	}

## 아이템 구매가 계산
func get_item_buy_price(item_data: ItemData, shop_data: ShopData) -> int:
	var base_price = item_data.buy_price
	if base_price <= 0:
		base_price = item_data.sell_price * 2  # 판매가의 2배

	var multiplier = shop_data.buy_price_multiplier if shop_data else 1.0
	return int(base_price * multiplier)

## 아이템 판매가 계산
func get_item_sell_price(item_data: ItemData, shop_data: ShopData) -> int:
	var base_price = item_data.sell_price
	if base_price <= 0:
		base_price = int(item_data.buy_price * 0.5)  # 구매가의 50%

	var multiplier = shop_data.sell_price_multiplier if shop_data else 0.5
	return int(base_price * multiplier)

## 재고 확인
func _has_stock(item_id: String) -> bool:
	if not current_stock.has(item_id):
		return false

	var stock = current_stock[item_id]
	return stock == -1 or stock > 0

## 재고 감소
func _decrease_stock(item_id: String) -> void:
	if current_stock.has(item_id):
		var stock = current_stock[item_id]
		if stock > 0:
			current_stock[item_id] = stock - 1
			stock_changed.emit(item_id, current_stock[item_id])
		# stock == -1 (무한 재고)는 감소하지 않음

## 현재 재고 확인
func get_stock(item_id: String) -> int:
	return current_stock.get(item_id, 0)

## 상점에서 판매 중인지 확인
func is_item_available(item_id: String) -> bool:
	return current_stock.has(item_id) and _has_stock(item_id)

## 현재 상점 정보
func get_current_shop() -> ShopData:
	return current_shop_data

## 판매 아이템 목록 (재고 있는 것만)
func get_available_items() -> Array[ItemData]:
	var result: Array[ItemData] = []

	if current_shop_data == null:
		return result

	for item in current_shop_data.items_for_sale:
		if item is ItemData and is_item_available(item.id):
			result.append(item)

	return result
