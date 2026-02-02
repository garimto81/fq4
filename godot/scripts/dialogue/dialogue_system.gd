extends CanvasLayer
class_name DialogueSystem
## DialogueSystem: 대화 시스템
##
## 대화 UI, 타이핑 효과, 선택지 처리를 담당합니다.

# UI 노드 참조
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $DialoguePanel/VBox/TextLabel
@onready var portrait_texture: TextureRect = $DialoguePanel/Portrait
@onready var choices_container: VBoxContainer = $DialoguePanel/VBox/ChoicesContainer
@onready var continue_indicator: Label = $DialoguePanel/ContinueIndicator

# 타이핑 효과 설정
@export var typing_speed: float = 30.0  # 초당 글자 수
@export var auto_advance_delay: float = 2.0  # 자동 진행 딜레이

# 현재 대화 상태
var current_dialogue: DialogueData = null
var current_node: Dictionary = {}
var is_active: bool = false
var is_typing: bool = false
var visible_characters: float = 0.0

# 시그널
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal node_displayed(node_id: String)
signal choice_selected(choice_index: int, choice_text: String)
signal event_triggered(event_string: String)

func _ready() -> void:
	_setup_ui()
	hide_dialogue()

func _process(delta: float) -> void:
	if not is_active:
		return

	# 타이핑 효과
	if is_typing:
		visible_characters += typing_speed * delta
		text_label.visible_characters = int(visible_characters)

		if text_label.visible_characters >= text_label.get_total_character_count():
			is_typing = false
			_on_typing_complete()

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("ui_accept"):
		_handle_accept_input()

## UI 초기 설정
func _setup_ui() -> void:
	# 동적으로 UI 생성 (씬이 없는 경우)
	if not has_node("DialoguePanel"):
		_create_dialogue_ui()

## 대화 UI 동적 생성
func _create_dialogue_ui() -> void:
	layer = 50

	# 메인 패널
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.custom_minimum_size = Vector2(900, 200)
	dialogue_panel.anchor_left = 0.1
	dialogue_panel.anchor_right = 0.9
	dialogue_panel.anchor_top = 0.7
	dialogue_panel.anchor_bottom = 0.95
	add_child(dialogue_panel)

	# VBox 컨테이너
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	dialogue_panel.add_child(vbox)

	# 화자 이름
	speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(speaker_label)

	# 대화 텍스트
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.custom_minimum_size = Vector2(0, 80)
	text_label.add_theme_font_size_override("normal_font_size", 18)
	vbox.add_child(text_label)

	# 선택지 컨테이너
	choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	vbox.add_child(choices_container)

	# 초상화
	portrait_texture = TextureRect.new()
	portrait_texture.name = "Portrait"
	portrait_texture.custom_minimum_size = Vector2(100, 100)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_panel.add_child(portrait_texture)

	# 계속 표시
	continue_indicator = Label.new()
	continue_indicator.name = "ContinueIndicator"
	continue_indicator.text = "[Enter] 계속..."
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_indicator.add_theme_font_size_override("font_size", 14)
	dialogue_panel.add_child(continue_indicator)

## 대화 시작
func start_dialogue(dialogue: DialogueData) -> void:
	if dialogue == null:
		push_error("Cannot start null dialogue")
		return

	current_dialogue = dialogue
	is_active = true

	# 게임 일시정지 (선택적)
	# get_tree().paused = true

	show_dialogue()
	dialogue_started.emit(dialogue.dialogue_id)

	# 시작 노드 표시
	var start = dialogue.get_start_node()
	if start.is_empty():
		push_error("No start node found in dialogue: " + dialogue.dialogue_id)
		end_dialogue()
		return

	display_node(start)

## 대화 종료
func end_dialogue() -> void:
	is_active = false
	is_typing = false

	var dialogue_id = current_dialogue.dialogue_id if current_dialogue else ""
	current_dialogue = null
	current_node = {}

	hide_dialogue()
	dialogue_ended.emit(dialogue_id)

	# get_tree().paused = false

## 노드 표시
func display_node(node: Dictionary) -> void:
	current_node = node

	# 화자
	speaker_label.text = node.get("speaker", "")

	# 초상화
	var portrait_path = node.get("portrait", "")
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait_texture.texture = load(portrait_path)
		portrait_texture.visible = true
	else:
		portrait_texture.visible = false

	# 텍스트 (타이핑 효과)
	var text = node.get("text", "")
	text_label.text = text
	text_label.visible_characters = 0
	visible_characters = 0.0
	is_typing = true

	# 선택지 숨기기
	_clear_choices()
	continue_indicator.visible = false

	# 이벤트 처리
	var event_str = node.get("event", "")
	if not event_str.is_empty():
		_process_event(event_str)

	node_displayed.emit(node.get("id", ""))

## 타이핑 완료 시
func _on_typing_complete() -> void:
	var choices = current_node.get("choices", [])

	if not choices.is_empty():
		# 선택지 표시
		_display_choices(choices)
		continue_indicator.visible = false
	else:
		# 계속 표시
		continue_indicator.visible = true

## 선택지 표시
func _display_choices(choices: Array) -> void:
	_clear_choices()

	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = "%d. %s" % [i + 1, choice.get("text", "")]
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

	choices_container.visible = true

## 선택지 클리어
func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.visible = false

## 선택지 선택 처리
func _on_choice_selected(choice_index: int) -> void:
	var choices = current_node.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return

	var choice = choices[choice_index]
	choice_selected.emit(choice_index, choice.get("text", ""))

	# 선택지에 이벤트가 있으면 처리
	var event_str = choice.get("event", "")
	if not event_str.is_empty():
		_process_event(event_str)

	# 다음 노드로 진행
	advance_to_next(choice_index)

## 다음 노드로 진행
func advance_to_next(choice_index: int = -1) -> void:
	var next_node = current_dialogue.get_next_node(current_node, choice_index)

	if next_node.is_empty():
		# 대화 종료
		end_dialogue()
	else:
		display_node(next_node)

## Accept 입력 처리
func _handle_accept_input() -> void:
	if is_typing:
		# 타이핑 스킵
		is_typing = false
		text_label.visible_characters = -1
		_on_typing_complete()
	elif current_node.get("choices", []).is_empty():
		# 다음 노드로 진행
		advance_to_next()

## 이벤트 처리
func _process_event(event_string: String) -> void:
	event_triggered.emit(event_string)

	# 기본 이벤트 파싱
	var parts = event_string.split(":")
	if parts.size() < 2:
		return

	var event_type = parts[0]
	var event_value = parts[1]

	match event_type:
		"set_flag":
			if has_node("/root/ProgressionSystem"):
				get_node("/root/ProgressionSystem").set_flag(event_value)
		"clear_flag":
			if has_node("/root/ProgressionSystem"):
				get_node("/root/ProgressionSystem").set_flag(event_value, false)
		"start_battle":
			# 전투 시작 (EventSystem에서 처리)
			pass
		"give_item":
			# 아이템 지급
			pass
		_:
			print("[Dialogue] Unknown event: ", event_string)

## 대화 UI 표시
func show_dialogue() -> void:
	visible = true
	if dialogue_panel:
		dialogue_panel.visible = true

## 대화 UI 숨기기
func hide_dialogue() -> void:
	visible = false
	if dialogue_panel:
		dialogue_panel.visible = false

## 대화 데이터 로드 (리소스 경로)
func load_and_start(dialogue_path: String) -> void:
	var dialogue = load(dialogue_path) as DialogueData
	if dialogue:
		start_dialogue(dialogue)
	else:
		push_error("Failed to load dialogue: " + dialogue_path)

## JSON 파일에서 대화 로드
func load_from_json_and_start(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open dialogue JSON: " + json_path)
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Failed to parse dialogue JSON: " + json_path)
		return

	var dialogue = DialogueData.from_json(json.get_data())
	start_dialogue(dialogue)
