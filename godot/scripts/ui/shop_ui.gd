extends Control
class_name ShopUI
## ShopUI: 상점 UI
##
## 상점 인터페이스를 제공하며, ShopSystem 및 InventorySystem과 연동됩니다.

# 시그널
signal shop_closed()
signal item_purchased(item_id: String)
signal item_sold(item_id: String)

# UI 노드 참조 (onready)
@onready var item_list: ItemList = get_node_or_null("ItemList")
@onready var item_description: RichTextLabel = get_node_or_null("ItemDescription")
@onready var gold_label: Label = get_node_or_null("GoldLabel")
@onready var buy_button: Button = get_node_or_null("BuyButton")
@onready var sell_button: Button = get_node_or_null("SellButton")
@onready var close_button: Button = get_node_or_null("CloseButton")

# 시스템 참조
var shop_system: ShopSystem
var inventory_system: InventorySystem
var current_shop_data: ShopData

# 현재 선택된 아이템
var selected_item_id: String = ""
var selected_item_index: int = -1

func _ready() -> void:
	# 버튼 시그널 연결 (노드가 존재하면)
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if item_list:
		item_list.item_selected.connect(_on_item_selected)

	# 초기 숨김
	visible = false

## 초기화 (시스템 참조 설정)
func init(shop: ShopSystem, inv: InventorySystem) -> void:
	shop_system = shop
	inventory_system = inv

	# InventorySystem 골드 변경 시그널 연결
	if inventory_system:
		inventory_system.gold_changed.connect(_on_gold_changed)

## 상점 열기
func open_shop(shop_data: ShopData) -> void:
	if shop_data == null:
		push_error("ShopUI.open_shop: shop_data is null")
		return

	current_shop_data = shop_data
	visible = true

	_populate_item_list()
	_update_gold_display()
	_update_buttons_state()

	# ShopSystem에 상점 열림 알림
	if shop_system:
		shop_system.open_shop(shop_data.shop_id, shop_data.available_items)

## 상점 닫기
func close_shop() -> void:
	visible = false
	current_shop_data = null
	selected_item_id = ""
	selected_item_index = -1

	if item_list:
		item_list.clear()

	# ShopSystem에 상점 닫힘 알림
	if shop_system:
		shop_system.close_shop()

	shop_closed.emit()

## 아이템 목록 채우기
func _populate_item_list() -> void:
	if not item_list or not current_shop_data:
		return

	item_list.clear()

	# 상점 아이템 목록 추가
	for item_data: ItemData in current_shop_data.available_items:
		if item_data == null:
			continue

		var item_text = "%s - %d Gold" % [item_data.name, item_data.price]
		item_list.add_item(item_text)

## 아이템 선택 시
func _on_item_selected(index: int) -> void:
	if not current_shop_data or index < 0 or index >= current_shop_data.available_items.size():
		return

	selected_item_index = index
	var item_data: ItemData = current_shop_data.available_items[index]

	if item_data == null:
		return

	selected_item_id = item_data.id

	# 아이템 설명 업데이트
	_update_item_description(item_data)
	_update_buttons_state()

## 아이템 설명 업데이트
func _update_item_description(item_data: ItemData) -> void:
	if not item_description:
		return

	var description_text = "[b]%s[/b]\n\n" % item_data.name
	description_text += "%s\n\n" % item_data.description
	description_text += "[color=yellow]Price:[/color] %d Gold\n" % item_data.price
	description_text += "[color=lightblue]Sell Price:[/color] %d Gold\n" % _get_sell_price(item_data.price)

	item_description.text = description_text

## 구매 버튼 클릭
func _on_buy_pressed() -> void:
	if not inventory_system or not shop_system:
		push_error("ShopUI: Systems not initialized")
		return

	if selected_item_index < 0 or not current_shop_data:
		return

	var item_data: ItemData = current_shop_data.available_items[selected_item_index]
	if item_data == null:
		return

	# 골드 확인
	if not inventory_system.can_afford(item_data.price):
		_show_message("Not enough gold!")
		return

	# 인벤토리 공간 확인
	if inventory_system.is_full() and not inventory_system.has_item(item_data.id):
		_show_message("Inventory is full!")
		return

	# 구매 처리
	var result = shop_system.buy_item(null, item_data, item_data.price)

	if result["success"]:
		# 골드 차감
		inventory_system.spend_gold(item_data.price)

		# 아이템 추가
		var add_result = inventory_system.add_item(item_data, 1)

		if add_result["success"]:
			_show_message("Purchased %s!" % item_data.name)
			item_purchased.emit(item_data.id)
			_update_gold_display()
			_update_buttons_state()
		else:
			# 실패 시 골드 환불
			inventory_system.add_gold(item_data.price)
			_show_message("Failed to add item to inventory")
	else:
		_show_message("Purchase failed: %s" % result.get("reason", "Unknown error"))

## 판매 버튼 클릭
func _on_sell_pressed() -> void:
	if not inventory_system or not shop_system:
		push_error("ShopUI: Systems not initialized")
		return

	if selected_item_id.is_empty():
		return

	# 인벤토리에서 아이템 확인
	if not inventory_system.has_item(selected_item_id):
		_show_message("You don't have this item!")
		return

	var item_data = inventory_system.get_item_data(selected_item_id)
	if item_data == null:
		return

	var sell_price = _get_sell_price(item_data.price)

	# 판매 처리
	var result = shop_system.sell_item(null, item_data, sell_price)

	if result["success"]:
		# 아이템 제거
		var remove_result = inventory_system.remove_item(selected_item_id, 1)

		if remove_result["success"]:
			# 골드 추가
			inventory_system.add_gold(sell_price)

			_show_message("Sold %s for %d gold!" % [item_data.name, sell_price])
			item_sold.emit(selected_item_id)
			_update_gold_display()
			_update_buttons_state()
		else:
			_show_message("Failed to remove item from inventory")
	else:
		_show_message("Sale failed: %s" % result.get("reason", "Unknown error"))

## 닫기 버튼 클릭
func _on_close_pressed() -> void:
	close_shop()

## 골드 표시 업데이트
func _update_gold_display() -> void:
	if not gold_label or not inventory_system:
		return

	gold_label.text = "Gold: %d" % inventory_system.gold

## 골드 변경 시그널 핸들러
func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	_update_gold_display()
	_update_buttons_state()

## 버튼 상태 업데이트 (활성화/비활성화)
func _update_buttons_state() -> void:
	if not buy_button or not sell_button:
		return

	# 구매 버튼: 아이템 선택 + 골드 충분
	var can_buy = false
	if selected_item_index >= 0 and current_shop_data and inventory_system:
		var item_data: ItemData = current_shop_data.available_items[selected_item_index]
		if item_data:
			can_buy = inventory_system.can_afford(item_data.price)

	buy_button.disabled = not can_buy

	# 판매 버튼: 아이템 선택 + 인벤토리에 보유
	var can_sell = false
	if not selected_item_id.is_empty() and inventory_system:
		can_sell = inventory_system.has_item(selected_item_id)

	sell_button.disabled = not can_sell

## 판매가 계산 (구매가의 50%)
func _get_sell_price(buy_price: int) -> int:
	if shop_system:
		return shop_system.get_sell_price(buy_price)
	return int(buy_price * 0.5)

## 메시지 표시 (임시 구현 - 나중에 MessageUI로 대체)
func _show_message(message: String) -> void:
	print("ShopUI: ", message)
	# TODO: MessageUI와 연동
