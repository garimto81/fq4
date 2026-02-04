extends CanvasLayer
class_name BattleHUD
## Battle HUD: 전투 UI 시스템
##
## 적 HP 표시, 전투 로그, 콤보/데미지 표시를 제공합니다.

# UI 노드
var enemy_hp_container: VBoxContainer
var combat_log_container: VBoxContainer
var combat_log_scroll: ScrollContainer
var target_info_panel: PanelContainer
var target_name_label: Label
var target_hp_bar: ProgressBar
var target_hp_label: Label

# 설정
const MAX_LOG_ENTRIES: int = 10
const LOG_FADE_TIME: float = 5.0
const DAMAGE_POPUP_DURATION: float = 1.0

# 상태
var current_target: Node = null
var log_entries: Array[Dictionary] = []

# 시그널
signal target_changed(target: Node)

func _ready() -> void:
	layer = 10
	_create_ui()
	hide()

func _create_ui() -> void:
	# 메인 컨테이너
	var main_container = MarginContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("margin_left", 16)
	main_container.add_theme_constant_override("margin_top", 16)
	main_container.add_theme_constant_override("margin_right", 16)
	main_container.add_theme_constant_override("margin_bottom", 16)
	add_child(main_container)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_child(hbox)

	# 왼쪽: 전투 로그
	_create_combat_log(hbox)

	# 중앙 스페이서
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# 오른쪽: 타겟 정보
	_create_target_info(hbox)

func _create_combat_log(parent: Control) -> void:
	var log_panel = PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(300, 200)
	log_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	parent.add_child(log_panel)

	var vbox = VBoxContainer.new()
	log_panel.add_child(vbox)

	var title = Label.new()
	title.text = "[ 전투 로그 ]"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	combat_log_scroll = ScrollContainer.new()
	combat_log_scroll.custom_minimum_size = Vector2(280, 160)
	combat_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(combat_log_scroll)

	combat_log_container = VBoxContainer.new()
	combat_log_scroll.add_child(combat_log_container)

func _create_target_info(parent: Control) -> void:
	target_info_panel = PanelContainer.new()
	target_info_panel.custom_minimum_size = Vector2(200, 80)
	target_info_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	target_info_panel.visible = false
	parent.add_child(target_info_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	target_info_panel.add_child(vbox)

	target_name_label = Label.new()
	target_name_label.add_theme_font_size_override("font_size", 16)
	target_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(target_name_label)

	target_hp_bar = ProgressBar.new()
	target_hp_bar.custom_minimum_size = Vector2(180, 20)
	target_hp_bar.show_percentage = false
	vbox.add_child(target_hp_bar)

	target_hp_label = Label.new()
	target_hp_label.add_theme_font_size_override("font_size", 12)
	target_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(target_hp_label)

## 전투 HUD 표시
func show_battle_hud() -> void:
	show()
	clear_log()

## 전투 HUD 숨기기
func hide_battle_hud() -> void:
	hide()
	current_target = null
	target_info_panel.visible = false

## 타겟 설정
func set_target(target: Node) -> void:
	current_target = target

	if target == null:
		target_info_panel.visible = false
		return

	target_info_panel.visible = true
	_update_target_info()
	target_changed.emit(target)

func _update_target_info() -> void:
	if current_target == null:
		return

	# 이름
	var unit_name = current_target.unit_name if "unit_name" in current_target else current_target.name
	target_name_label.text = unit_name

	# HP
	if "current_hp" in current_target and "max_hp" in current_target:
		target_hp_bar.max_value = current_target.max_hp
		target_hp_bar.value = current_target.current_hp
		target_hp_label.text = "%d / %d" % [current_target.current_hp, current_target.max_hp]

		# HP 색상
		var hp_ratio = float(current_target.current_hp) / current_target.max_hp
		if hp_ratio > 0.5:
			target_hp_bar.modulate = Color.GREEN
		elif hp_ratio > 0.25:
			target_hp_bar.modulate = Color.YELLOW
		else:
			target_hp_bar.modulate = Color.RED

## 전투 로그 추가
func add_log(message: String, color: Color = Color.WHITE) -> void:
	var entry = {
		"message": message,
		"color": color,
		"time": Time.get_ticks_msec()
	}
	log_entries.append(entry)

	# 로그 레이블 생성
	var label = Label.new()
	label.text = message
	label.modulate = color
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log_container.add_child(label)

	# 오래된 로그 제거
	while combat_log_container.get_child_count() > MAX_LOG_ENTRIES:
		var old_child = combat_log_container.get_child(0)
		old_child.queue_free()
		if log_entries.size() > 0:
			log_entries.pop_front()

	# 스크롤 맨 아래로
	await get_tree().process_frame
	combat_log_scroll.scroll_vertical = combat_log_scroll.get_v_scroll_bar().max_value

## 데미지 로그
func log_damage(attacker_name: String, target_name: String, damage: int, is_critical: bool = false) -> void:
	var msg = ""
	if is_critical:
		msg = "[CRITICAL] %s → %s: %d 데미지!" % [attacker_name, target_name, damage]
		add_log(msg, Color.ORANGE)
	else:
		msg = "%s → %s: %d 데미지" % [attacker_name, target_name, damage]
		add_log(msg, Color.WHITE)

## 회복 로그
func log_heal(unit_name: String, amount: int) -> void:
	var msg = "%s: %d HP 회복" % [unit_name, amount]
	add_log(msg, Color.GREEN)

## 사망 로그
func log_death(unit_name: String) -> void:
	var msg = "%s 쓰러짐!" % unit_name
	add_log(msg, Color.RED)

## 스킬 사용 로그
func log_skill(user_name: String, skill_name: String) -> void:
	var msg = "%s: [%s] 사용" % [user_name, skill_name]
	add_log(msg, Color.CYAN)

## 상태 이상 로그
func log_status(unit_name: String, status_name: String, applied: bool) -> void:
	var msg = ""
	if applied:
		msg = "%s: [%s] 상태 이상" % [unit_name, status_name]
		add_log(msg, Color.PURPLE)
	else:
		msg = "%s: [%s] 해제" % [unit_name, status_name]
		add_log(msg, Color.GRAY)

## 로그 초기화
func clear_log() -> void:
	log_entries.clear()
	for child in combat_log_container.get_children():
		child.queue_free()

func _process(_delta: float) -> void:
	if current_target != null and is_instance_valid(current_target):
		_update_target_info()
	elif current_target != null:
		# 타겟이 삭제됨
		set_target(null)

## 데미지 팝업 생성 (월드 좌표)
func spawn_damage_popup(position: Vector2, damage: int, is_critical: bool = false) -> void:
	var popup = Label.new()
	popup.text = str(damage)
	popup.add_theme_font_size_override("font_size", 24 if is_critical else 18)
	popup.modulate = Color.ORANGE if is_critical else Color.WHITE
	popup.position = position
	popup.z_index = 100

	# 월드에 추가 (CanvasLayer가 아닌)
	if get_tree().current_scene:
		get_tree().current_scene.add_child(popup)

	# 애니메이션
	var tween = create_tween()
	tween.tween_property(popup, "position:y", position.y - 50, DAMAGE_POPUP_DURATION)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, DAMAGE_POPUP_DURATION)
	tween.tween_callback(popup.queue_free)
