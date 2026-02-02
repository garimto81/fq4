extends Control
class_name InventoryUI
## InventoryUI: 인벤토리 UI
##
## 아이템 그리드, 상세 패널, 골드 표시를 제공합니다.

@onready var item_grid: GridContainer = $Container/VBox/Content/ItemScroll/ItemGrid
@onready var detail_panel: Panel = $Container/VBox/Content/DetailPanel
@onready var item_name_label: Label = $Container/VBox/Content/DetailPanel/VBox/ItemName
@onready var item_desc_label: RichTextLabel = $Container/VBox/Content/DetailPanel/VBox/ItemDesc
@onready var item_icon: TextureRect = $Container/VBox/Content/DetailPanel/VBox/ItemIcon
@onready var use_button: Button = $Container/VBox/Content/DetailPanel/VBox/Buttons/UseButton
@onready var drop_button: Button = $Container/VBox/Content/DetailPanel/VBox/Buttons/DropButton
@onready var gold_label: Label = $Container/VBox/Footer/GoldLabel
@onready var close_button: Button = $Container/VBox/Header/CloseButton

# 시그널
signal inventory_closed()
signal item_used(item_id: String)
signal item_dropped(item_id: String)

var inventory = null  # InventorySystem - removed type annotation to avoid load order issues
var selected_item_id: String = ""
var item_buttons: Dictionary = {}  # item_id -> Button

# 아이템 버튼은 동적으로 생성 (Button.new())

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)

	# 초기 상태
	detail_panel.visible = false
	hide()

func _input(event: InputEvent) -> void:
	# I 키로 열기/닫기 토글
	# Note: Inventory open is handled externally (e.g., player script calls open())
	if event.is_action_pressed("toggle_inventory") and visible:
		close()
		get_viewport().set_input_as_handled()

	# ESC로 닫기
	elif event.is_action_pressed("ui_cancel") and visible:
		close()
		get_viewport().set_input_as_handled()

## 인벤토리 열기
func open(inv) -> void:  # inv: InventorySystem - removed type annotation to avoid load order issues
	if inv == null:
		push_error("InventoryUI: Cannot open with null inventory")
		return

	inventory = inv
	refresh()
	show()

	# 포커스 설정
	if item_buttons.size() > 0:
		var first_button = item_buttons.values()[0]
		first_button.grab_focus()

## 인벤토리 닫기
func close() -> void:
	hide()
	inventory_closed.emit()

	# 포커스 해제
	if has_focus():
		release_focus()

## 아이템 목록 새로고침
func refresh() -> void:
	if inventory == null:
		return

	# 기존 버튼 제거
	for child in item_grid.get_children():
		child.queue_free()
	item_buttons.clear()

	# 골드 업데이트
	gold_label.text = "Gold: %d" % inventory.gold

	# 아이템 버튼 생성
	var items = inventory.get_all_items()
	for item in items:
		_create_item_button(item)

	# 선택 초기화
	selected_item_id = ""
	detail_panel.visible = false

## 아이템 버튼 생성
func _create_item_button(item: Dictionary) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 80)
	button.text = ""
	button.tooltip_text = item["data"].display_name

	# 아이콘과 수량 표시를 위한 컨테이너
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 아이콘
	if item["data"].icon != null:
		var icon = TextureRect.new()
		icon.texture = item["data"].icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

	# 수량 레이블
	var quantity_label = Label.new()
	quantity_label.text = "x%d" % item["quantity"]
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.add_theme_font_size_override("font_size", 14)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(quantity_label)

	button.add_child(vbox)

	# 클릭 이벤트
	var item_id = item["id"]
	button.pressed.connect(_on_item_button_pressed.bind(item_id))

	item_grid.add_child(button)
	item_buttons[item_id] = button

## 아이템 선택
func select_item(item_id: String) -> void:
	if inventory == null:
		return

	selected_item_id = item_id
	var item_data = inventory.get_item_data(item_id)
	var quantity = inventory.get_item_count(item_id)

	if item_data == null:
		detail_panel.visible = false
		return

	# 상세 패널 업데이트
	detail_panel.visible = true
	item_name_label.text = "%s (x%d)" % [item_data.display_name, quantity]
	item_desc_label.text = item_data.description

	# 아이콘 표시
	if item_data.icon != null:
		item_icon.texture = item_data.icon
		item_icon.visible = true
	else:
		item_icon.visible = false

	# 사용/드롭 버튼 활성화
	use_button.disabled = not item_data.can_use()
	drop_button.disabled = false

## 아이템 사용 (타겟은 현재 플레이어)
func use_selected_item() -> void:
	if selected_item_id == "" or inventory == null:
		return

	var target = GameManager.get("current_player") if GameManager.has("current_player") else null
	if target == null:
		push_warning("InventoryUI: No target to use item on")
		return

	var result = inventory.use_item(selected_item_id, target)
	if result["success"]:
		item_used.emit(selected_item_id)
		refresh()  # UI 새로고침

		# 피드백 (옵션)
		_show_use_feedback(result)
	else:
		push_warning("Failed to use item: %s" % result.get("reason", "Unknown"))

## 아이템 드롭
func drop_selected_item() -> void:
	if selected_item_id == "" or inventory == null:
		return

	var result = inventory.remove_item(selected_item_id, 1)
	if result["success"]:
		item_dropped.emit(selected_item_id)
		refresh()

## 사용 피드백 표시 (옵션)
func _show_use_feedback(result: Dictionary) -> void:
	# TODO: 파티클 효과, 사운드 등
	pass

# --- 시그널 핸들러 ---

func _on_close_pressed() -> void:
	close()

func _on_use_pressed() -> void:
	use_selected_item()

func _on_drop_pressed() -> void:
	drop_selected_item()

func _on_item_button_pressed(item_id: String) -> void:
	select_item(item_id)
