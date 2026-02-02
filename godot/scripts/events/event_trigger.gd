extends Area2D
class_name EventTrigger
## EventTrigger: 맵 내 이벤트 트리거 영역
##
## 플레이어가 진입하거나 상호작용하면 이벤트를 발동합니다.

# 트리거 설정
@export var trigger_id: String = ""
@export var one_shot: bool = true  # 한 번만 실행
@export var requires_interaction: bool = false  # Enter 키 필요
@export var required_flags: Array[String] = []  # 필수 플래그
@export var blocked_flags: Array[String] = []   # 차단 플래그

# 이벤트 타입
@export_enum("Dialogue", "Battle", "MapTransition", "Custom") var event_type: String = "Dialogue"

# 이벤트별 설정
@export var dialogue_path: String = ""
@export var target_map: String = ""
@export var spawn_point: String = "default"
@export var enemy_ids: Array[String] = []
@export var boss_battle: bool = false
@export var on_victory_flag: String = ""

# 상태
var is_player_inside: bool = false
var has_triggered: bool = false

# 시그널
signal trigger_executed(trigger_id: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 이미 실행된 트리거인지 체크
	if one_shot and has_node("/root/ProgressionSystem"):
		has_triggered = get_node("/root/ProgressionSystem").has_flag("trigger_" + trigger_id)

func _input(event: InputEvent) -> void:
	if not requires_interaction:
		return

	if not is_player_inside:
		return

	if event.is_action_pressed("ui_accept"):
		_execute_trigger()

func _on_body_entered(body: Node2D) -> void:
	# 플레이어 유닛인지 확인
	if not _is_player_unit(body):
		return

	is_player_inside = true

	if not requires_interaction:
		_execute_trigger()

func _on_body_exited(body: Node2D) -> void:
	if _is_player_unit(body):
		is_player_inside = false

func _is_player_unit(body: Node2D) -> bool:
	return GameManager.player_units.has(body)

func _execute_trigger() -> void:
	# 이미 실행된 일회성 트리거
	if one_shot and has_triggered:
		return

	# 조건 체크
	if not _check_conditions():
		return

	has_triggered = true

	# 플래그 설정
	if one_shot and has_node("/root/ProgressionSystem"):
		get_node("/root/ProgressionSystem").set_flag("trigger_" + trigger_id)

	# 이벤트 생성 및 실행
	var event_data = _build_event_data()

	if has_node("/root/EventSystem"):
		get_node("/root/EventSystem").execute_event(event_data)

	trigger_executed.emit(trigger_id)

func _check_conditions() -> bool:
	if not has_node("/root/ProgressionSystem"):
		return true

	var progression = get_node("/root/ProgressionSystem")

	# 필수 플래그
	for flag in required_flags:
		if not progression.has_flag(flag):
			return false

	# 차단 플래그
	for flag in blocked_flags:
		if progression.has_flag(flag):
			return false

	return true

func _build_event_data() -> Dictionary:
	var data: Dictionary = {}

	match event_type:
		"Dialogue":
			data = {
				"type": EventSystem.EventType.DIALOGUE,
				"dialogue_path": dialogue_path
			}
		"Battle":
			data = {
				"type": EventSystem.EventType.BATTLE,
				"enemies": enemy_ids,
				"boss": boss_battle,
				"on_victory_flag": on_victory_flag
			}
		"MapTransition":
			data = {
				"type": EventSystem.EventType.MAP_TRANSITION,
				"target_map": target_map,
				"spawn_point": spawn_point,
				"fade": true
			}
		"Custom":
			data = {
				"type": EventSystem.EventType.CUSTOM,
				"trigger_id": trigger_id
			}

	return data

## 트리거 리셋 (디버그용)
func reset_trigger() -> void:
	has_triggered = false
	if has_node("/root/ProgressionSystem"):
		get_node("/root/ProgressionSystem").set_flag("trigger_" + trigger_id, false)
