extends Control
## 업적 해금 팝업 UI

@onready var title_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Title
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Name
@onready var desc_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Description
@onready var icon_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/Icon
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const DISPLAY_DURATION: float = 4.0
const SLIDE_IN_DURATION: float = 0.5
const SLIDE_OUT_DURATION: float = 0.3

var _queue: Array[AchievementData] = []
var _is_displaying: bool = false

func _ready() -> void:
	# 초기 위치: 화면 우측 상단 밖
	position = Vector2(get_viewport_rect().size.x, 20)
	visible = false

	# 애니메이션 생성
	_create_animations()

	# AchievementSystem 시그널 연결
	if has_node("/root/AchievementSystem"):
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)

func _create_animations() -> void:
	var anim_lib = Animation.new()

	# Slide In 애니메이션
	var slide_in = Animation.new()
	slide_in.length = SLIDE_IN_DURATION

	var track_idx = slide_in.add_track(Animation.TYPE_VALUE)
	slide_in.track_set_path(track_idx, ".:position:x")
	slide_in.track_insert_key(track_idx, 0.0, get_viewport_rect().size.x)
	slide_in.track_insert_key(track_idx, SLIDE_IN_DURATION, get_viewport_rect().size.x - size.x - 20)
	slide_in.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)

	anim_player.add_animation_library("popup", AnimationLibrary.new())
	anim_player.get_animation_library("popup").add_animation("slide_in", slide_in)

	# Slide Out 애니메이션
	var slide_out = Animation.new()
	slide_out.length = SLIDE_OUT_DURATION

	track_idx = slide_out.add_track(Animation.TYPE_VALUE)
	slide_out.track_set_path(track_idx, ".:position:x")
	slide_out.track_insert_key(track_idx, 0.0, get_viewport_rect().size.x - size.x - 20)
	slide_out.track_insert_key(track_idx, SLIDE_OUT_DURATION, get_viewport_rect().size.x)
	slide_out.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)

	anim_player.get_animation_library("popup").add_animation("slide_out", slide_out)

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	_queue.append(achievement)
	if not _is_displaying:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_is_displaying = false
		return

	_is_displaying = true
	var achievement = _queue.pop_front()

	# UI 업데이트
	if has_node("/root/LocalizationManager"):
		name_label.text = LocalizationManager.get_text(achievement.name_key)
		desc_label.text = LocalizationManager.get_text(achievement.description_key)
	else:
		name_label.text = achievement.name_key
		desc_label.text = achievement.description_key

	# 아이콘 로드 (있으면)
	if achievement.icon_path and FileAccess.file_exists(achievement.icon_path):
		icon_rect.texture = load(achievement.icon_path)
	else:
		icon_rect.texture = null

	# 애니메이션 재생
	visible = true
	anim_player.play("popup/slide_in")
	await anim_player.animation_finished

	# 일정 시간 표시
	await get_tree().create_timer(DISPLAY_DURATION).timeout

	# Slide Out
	anim_player.play("popup/slide_out")
	await anim_player.animation_finished

	visible = false

	# 다음 업적 표시
	_show_next()

func queue_achievement(achievement: AchievementData) -> void:
	_on_achievement_unlocked(achievement)
