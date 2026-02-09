extends Control
## LocalizationManager 테스트 씬
##
## 로케일 변경 및 번역 기능 확인

@onready var current_locale_label = $VBoxContainer/CurrentLocale
@onready var test_label1 = $VBoxContainer/TestLabel1
@onready var test_label2 = $VBoxContainer/TestLabel2
@onready var test_label3 = $VBoxContainer/TestLabel3
@onready var stats_label = $VBoxContainer/StatsLabel

func _ready() -> void:
	# 로케일 변경 시그널 연결
	LocalizationManager.locale_changed.connect(_on_locale_changed)
	
	# 초기 표시
	_update_labels()

func _on_japanese_pressed() -> void:
	LocalizationManager.set_locale("ja")

func _on_korean_pressed() -> void:
	LocalizationManager.set_locale("ko")

func _on_english_pressed() -> void:
	LocalizationManager.set_locale("en")

func _on_locale_changed(_locale: String) -> void:
	_update_labels()

func _update_labels() -> void:
	# 현재 로케일 표시
	var locale_name = LocalizationManager.get_current_locale_name()
	current_locale_label.text = "Current Locale: " + locale_name
	
	# 테스트 1: 단순 번역
	test_label1.text = LocalizationManager.tr_key("ui.start_game")
	
	# 테스트 2: 파라미터 치환
	test_label2.text = LocalizationManager.tr_key("greeting_player", {"player_name": "テオ"})
	
	# 테스트 3: 복잡한 파라미터 치환
	test_label3.text = LocalizationManager.tr_key("damage_dealt", {
		"target": "ゴブリン",
		"damage": 150
	})
	
	# 통계
	var count = LocalizationManager.get_translation_count()
	var files = LocalizationManager.get_loaded_files().size()
	stats_label.text = "Loaded: " + str(files) + " files, " + str(count) + " keys"
