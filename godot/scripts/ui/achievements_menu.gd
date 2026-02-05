extends Control
## 업적 메뉴 UI

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var progress_label: Label = $MarginContainer/VBoxContainer/Header/Progress
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

const ACHIEVEMENT_ITEM = preload("res://scenes/ui/achievement_item.tscn")

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false
	_update_list()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_on_close_pressed()
		accept_event()

func show_menu() -> void:
	_update_list()
	visible = true

func _update_list() -> void:
	# 기존 아이템 제거
	for child in grid_container.get_children():
		child.queue_free()

	if not has_node("/root/AchievementSystem"):
		return

	var all_achievements = AchievementSystem.get_all_achievements()
	var unlocked_count = AchievementSystem.unlocked.size()

	# 진행률 업데이트
	var percentage = AchievementSystem.get_completion_percentage()
	progress_label.text = "%d / %d (%.1f%%)" % [unlocked_count, all_achievements.size(), percentage]

	# 업적 아이템 생성
	for achievement in all_achievements:
		var item = ACHIEVEMENT_ITEM.instantiate()
		grid_container.add_child(item)
		item.set_achievement(achievement)

func _on_close_pressed() -> void:
	visible = false
