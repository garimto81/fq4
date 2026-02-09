extends PanelContainer
## 업적 아이템 UI (리스트 항목)

@onready var name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/Name
@onready var desc_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/Description
@onready var icon_rect: TextureRect = $MarginContainer/HBoxContainer/Icon
@onready var status_label: Label = $MarginContainer/HBoxContainer/Status
@onready var progress_bar: ProgressBar = $MarginContainer/HBoxContainer/VBoxContainer/ProgressBar

var achievement_data: AchievementData

func set_achievement(achievement: AchievementData) -> void:
	achievement_data = achievement

	if not has_node("/root/AchievementSystem"):
		return

	var is_unlocked = AchievementSystem.is_unlocked(achievement.id)

	# 숨김 업적은 잠금 상태일 때 정보 숨김
	if achievement.secret and not is_unlocked:
		name_label.text = "???"
		desc_label.text = "Secret Achievement"
		status_label.text = "Locked"
		status_label.modulate = Color(0.6, 0.6, 0.6)
		modulate = Color(0.5, 0.5, 0.5)
		return

	# 이름/설명 로드
	if has_node("/root/LocalizationManager"):
		name_label.text = LocalizationManager.get_text(achievement.name_key)
		desc_label.text = LocalizationManager.get_text(achievement.description_key)
	else:
		name_label.text = achievement.name_key
		desc_label.text = achievement.description_key

	# 아이콘 로드
	if achievement.icon_path and FileAccess.file_exists(achievement.icon_path):
		icon_rect.texture = load(achievement.icon_path)
	else:
		icon_rect.texture = null

	# 잠금/해금 상태
	if is_unlocked:
		status_label.text = "Unlocked"
		status_label.modulate = Color(0.3, 1.0, 0.3)
		modulate = Color(1.0, 1.0, 1.0)
		progress_bar.visible = false

		# 해금 시간 표시
		var unlock_time = AchievementSystem.unlocked[achievement.id]
		var datetime = Time.get_datetime_dict_from_unix_time(unlock_time)
		var date_str = "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]
		status_label.text = "Unlocked\n%s" % date_str
	else:
		status_label.text = "Locked"
		status_label.modulate = Color(0.6, 0.6, 0.6)
		modulate = Color(0.7, 0.7, 0.7)

		# 프로그레스바 표시 (프로그레스가 있는 업적만)
		var current_progress = AchievementSystem.get_progress(achievement.id)
		if current_progress > 0 and achievement.target_value > 1:
			progress_bar.visible = true
			progress_bar.max_value = achievement.target_value
			progress_bar.value = current_progress

			# 프로그레스 텍스트
			var progress_text = "%d / %d" % [current_progress, achievement.target_value]
			status_label.text = "Locked\n%s" % progress_text
		else:
			progress_bar.visible = false
