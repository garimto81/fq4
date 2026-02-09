extends Control
## TitleScreen: 타이틀 화면 UI
##
## 새 게임, 계속하기, 설정, 종료 처리

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var options_button: Button = $VBox/OptionsButton
@onready var exit_button: Button = $VBox/ExitButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# 세이브 파일 확인
	_check_save_exists()

func _check_save_exists() -> void:
	var has_save = false

	if has_node("/root/SaveSystem"):
		var slots = SaveSystem.get_all_slots_info()
		for slot in slots:
			if slot.get("exists", false):
				has_save = true
				break

	continue_button.disabled = not has_save

func _on_new_game_pressed() -> void:
	if has_node("/root/ChapterManager"):
		get_node("/root/ChapterManager").start_new_game()
	else:
		# ChapterManager 없으면 직접 첫 맵 로드
		get_tree().change_scene_to_file("res://scenes/maps/chapter1/castle_entrance.tscn")

func _on_continue_pressed() -> void:
	# 세이브 슬롯 선택 UI (간단 버전: 자동 저장 슬롯)
	if SaveSystem.load_game(0):
		if has_node("/root/ChapterManager"):
			get_node("/root/ChapterManager").continue_game()

func _on_options_pressed() -> void:
	# TODO: 옵션 메뉴 열기
	print("Options not implemented yet")

func _on_exit_pressed() -> void:
	get_tree().quit()
