extends Control
## 업적 시스템 테스트 씬

@onready var info_label: Label = $MarginContainer/VBoxContainer/Info
@onready var achievements_menu = $AchievementsMenu

var formation_count: int = 0

func _ready() -> void:
	# 버튼 시그널 연결
	$MarginContainer/VBoxContainer/GridContainer/UnlockChapter1.pressed.connect(_on_unlock_chapter1)
	$MarginContainer/VBoxContainer/GridContainer/UnlockBoss.pressed.connect(_on_defeat_boss)
	$MarginContainer/VBoxContainer/GridContainer/Add10Kills.pressed.connect(_on_add_kills)
	$MarginContainer/VBoxContainer/GridContainer/LevelUp.pressed.connect(_on_level_up)
	$MarginContainer/VBoxContainer/GridContainer/UseFormation.pressed.connect(_on_use_formation)
	$MarginContainer/VBoxContainer/GridContainer/CastSpell.pressed.connect(_on_cast_spells)
	$MarginContainer/VBoxContainer/GridContainer/ReachEnding.pressed.connect(_on_reach_ending)
	$MarginContainer/VBoxContainer/GridContainer/StartNGPlus.pressed.connect(_on_start_ng_plus)
	$MarginContainer/VBoxContainer/GridContainer/CompleteGame.pressed.connect(_on_complete_game)

	$MarginContainer/VBoxContainer/ControlButtons/ShowMenu.pressed.connect(_on_show_menu)
	$MarginContainer/VBoxContainer/ControlButtons/ResetAll.pressed.connect(_on_reset_all)

	# 업적 해금 시그널 연결
	if has_node("/root/AchievementSystem"):
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)

	_update_info()

func _update_info() -> void:
	if not has_node("/root/AchievementSystem"):
		info_label.text = "AchievementSystem not found"
		return

	var total = AchievementSystem.achievements.size()
	var unlocked = AchievementSystem.unlocked.size()
	var percentage = AchievementSystem.get_completion_percentage()

	info_label.text = "Total: %d / %d | Unlocked: %d (%.1f%%)" % [unlocked, total, unlocked, percentage]

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	print("[Test] Achievement unlocked: %s" % achievement.id)
	_update_info()

func _on_unlock_chapter1() -> void:
	AchievementSystem.complete_chapter("chapter_1")
	_update_info()

func _on_defeat_boss() -> void:
	AchievementSystem.defeat_boss("demon_general")
	_update_info()

func _on_add_kills() -> void:
	for i in 10:
		AchievementSystem.add_kill()
	_update_info()

func _on_level_up() -> void:
	AchievementSystem.reach_level(10)
	_update_info()

func _on_use_formation() -> void:
	# 5개 대형을 순차적으로 사용
	AchievementSystem.use_formation(formation_count)
	formation_count += 1
	if formation_count >= 5:
		formation_count = 0
	_update_info()

func _on_cast_spells() -> void:
	for i in 10:
		AchievementSystem.add_spell_cast()
	_update_info()

func _on_reach_ending() -> void:
	AchievementSystem.reach_ending("good")
	_update_info()

func _on_start_ng_plus() -> void:
	AchievementSystem.start_ng_plus()
	_update_info()

func _on_complete_game() -> void:
	# 스피드런 조건 (1시간)
	AchievementSystem.check_completion_achievements(3600.0)
	_update_info()

func _on_show_menu() -> void:
	achievements_menu.show_menu()

func _on_reset_all() -> void:
	AchievementSystem.unlocked.clear()
	AchievementSystem.progress.clear()
	AchievementSystem.stats = {
		"total_kills": 0,
		"spells_cast": 0,
		"gold_earned": 0,
		"formations_used": {},
		"chapters_cleared": [],
		"bosses_defeated": [],
		"endings_reached": [],
		"items_collected": [],
		"total_play_time": 0.0,
		"death_count": 0,
		"ng_plus_count": 0
	}
	formation_count = 0
	print("[Test] All achievements reset")
	_update_info()
