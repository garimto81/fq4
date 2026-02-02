extends Node
## EventSystem: 이벤트 시스템
##
## 트리거 기반 이벤트, 대화/전투/씬 전환 이벤트를 관리합니다.
## Autoload로 등록되어 있으므로 class_name을 사용하지 않습니다.

# 이벤트 타입
enum EventType {
	DIALOGUE,       # 대화 이벤트
	BATTLE,         # 전투 이벤트
	CUTSCENE,       # 컷씬
	MAP_TRANSITION, # 맵 전환
	ITEM_PICKUP,    # 아이템 획득
	FLAG_SET,       # 플래그 설정
	SPAWN_ENEMY,    # 적 스폰
	HEAL_PARTY,     # 파티 회복
	CUSTOM          # 커스텀 이벤트
}

# 트리거 조건
enum TriggerCondition {
	ON_ENTER,       # 영역 진입 시
	ON_INTERACT,    # 상호작용 시 (키 입력)
	ON_FLAG,        # 특정 플래그 설정 시
	ON_BATTLE_END,  # 전투 종료 시
	AUTO            # 맵 로드 시 자동
}

# 이벤트 큐
var event_queue: Array[Dictionary] = []
var is_processing: bool = false
var current_event: Dictionary = {}

# 등록된 트리거
var registered_triggers: Array[Dictionary] = []

# 참조
var dialogue_system = null
var map_manager = null

# 시그널
signal event_started(event_data: Dictionary)
signal event_completed(event_data: Dictionary)
signal trigger_activated(trigger_id: String)

func _ready() -> void:
	# 시스템 참조 설정 (지연 초기화)
	call_deferred("_setup_references")

func _setup_references() -> void:
	if has_node("/root/DialogueSystem"):
		dialogue_system = get_node("/root/DialogueSystem")
	if has_node("/root/MapManager"):
		map_manager = get_node("/root/MapManager")

## 이벤트 큐에 추가
func queue_event(event_data: Dictionary) -> void:
	event_queue.append(event_data)

	if not is_processing:
		_process_next_event()

## 이벤트 즉시 실행
func execute_event(event_data: Dictionary) -> void:
	current_event = event_data
	is_processing = true

	event_started.emit(event_data)

	var event_type = event_data.get("type", EventType.CUSTOM)

	match event_type:
		EventType.DIALOGUE:
			await _execute_dialogue_event(event_data)
		EventType.BATTLE:
			await _execute_battle_event(event_data)
		EventType.CUTSCENE:
			await _execute_cutscene_event(event_data)
		EventType.MAP_TRANSITION:
			await _execute_map_transition_event(event_data)
		EventType.ITEM_PICKUP:
			_execute_item_pickup_event(event_data)
		EventType.FLAG_SET:
			_execute_flag_set_event(event_data)
		EventType.SPAWN_ENEMY:
			_execute_spawn_enemy_event(event_data)
		EventType.HEAL_PARTY:
			_execute_heal_party_event(event_data)
		EventType.CUSTOM:
			await _execute_custom_event(event_data)

	event_completed.emit(event_data)
	is_processing = false

	# 다음 이벤트 처리
	_process_next_event()

## 다음 이벤트 처리
func _process_next_event() -> void:
	if event_queue.is_empty():
		return

	var next_event = event_queue.pop_front()
	execute_event(next_event)

## 대화 이벤트 실행
func _execute_dialogue_event(event_data: Dictionary) -> void:
	var dialogue_path = event_data.get("dialogue_path", "")

	if dialogue_system == null:
		push_warning("DialogueSystem not found")
		return

	if dialogue_path.ends_with(".json"):
		dialogue_system.load_from_json_and_start(dialogue_path)
	else:
		dialogue_system.load_and_start(dialogue_path)

	# 대화 종료 대기
	await dialogue_system.dialogue_ended

## 전투 이벤트 실행
func _execute_battle_event(event_data: Dictionary) -> void:
	var enemy_ids = event_data.get("enemies", [])
	var boss_battle = event_data.get("boss", false)
	var on_victory_flag = event_data.get("on_victory_flag", "")

	print("[Event] Starting battle: ", enemy_ids)

	# 적 스폰
	for enemy_id in enemy_ids:
		_spawn_enemy(enemy_id, Vector2.ZERO)

	# 전투 시작
	GameManager.start_battle()

	# 전투 종료 대기
	await GameManager.state_changed

	# 승리 시 플래그 설정
	if GameManager.current_state == GameManager.GameState.VICTORY:
		if not on_victory_flag.is_empty() and has_node("/root/ProgressionSystem"):
			get_node("/root/ProgressionSystem").set_flag(on_victory_flag)

## 컷씬 이벤트 실행
func _execute_cutscene_event(event_data: Dictionary) -> void:
	var cutscene_id = event_data.get("cutscene_id", "")
	var duration = event_data.get("duration", 2.0)

	print("[Event] Playing cutscene: ", cutscene_id)

	# 간단한 대기 (실제 컷씬 시스템은 별도 구현)
	await get_tree().create_timer(duration).timeout

## 맵 전환 이벤트 실행
func _execute_map_transition_event(event_data: Dictionary) -> void:
	var target_map = event_data.get("target_map", "")
	var spawn_point = event_data.get("spawn_point", "default")
	var fade = event_data.get("fade", true)

	if map_manager == null:
		push_warning("MapManager not found")
		return

	if fade:
		await map_manager.transition_to_map(target_map, spawn_point)
	else:
		map_manager.load_map(target_map, spawn_point)

## 아이템 획득 이벤트
func _execute_item_pickup_event(event_data: Dictionary) -> void:
	var item_id = event_data.get("item_id", "")
	var quantity = event_data.get("quantity", 1)

	print("[Event] Item pickup: %s x%d" % [item_id, quantity])
	# TODO: InventorySystem 연동

## 플래그 설정 이벤트
func _execute_flag_set_event(event_data: Dictionary) -> void:
	var flag_name = event_data.get("flag", "")
	var value = event_data.get("value", true)

	if has_node("/root/ProgressionSystem"):
		get_node("/root/ProgressionSystem").set_flag(flag_name, value)

## 적 스폰 이벤트
func _execute_spawn_enemy_event(event_data: Dictionary) -> void:
	var enemy_id = event_data.get("enemy_id", "goblin")
	var position = event_data.get("position", Vector2.ZERO)
	var count = event_data.get("count", 1)

	for i in range(count):
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		_spawn_enemy(enemy_id, position + offset)

## 파티 회복 이벤트
func _execute_heal_party_event(event_data: Dictionary) -> void:
	var heal_hp = event_data.get("heal_hp", true)
	var heal_mp = event_data.get("heal_mp", true)
	var amount_percent = event_data.get("amount_percent", 100)

	for unit in GameManager.player_units:
		if heal_hp:
			var heal_amount = int(unit.max_hp * amount_percent / 100.0)
			unit.heal(heal_amount)
		if heal_mp:
			unit.current_mp = int(unit.max_mp * amount_percent / 100.0)

	print("[Event] Party healed: %d%%" % amount_percent)

## 커스텀 이벤트 실행
func _execute_custom_event(event_data: Dictionary) -> void:
	var callback = event_data.get("callback", Callable())
	if callback.is_valid():
		await callback.call()

## 적 스폰 헬퍼
func _spawn_enemy(enemy_id: String, position: Vector2) -> Node:
	var enemy_scene = load("res://scenes/units/enemies/%s.tscn" % enemy_id)
	if enemy_scene == null:
		enemy_scene = load("res://scenes/units/enemy_unit.tscn")

	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = position
		get_tree().current_scene.add_child(enemy)
		GameManager.register_unit(enemy, false)
		return enemy

	return null

## 트리거 등록
func register_trigger(trigger_data: Dictionary) -> void:
	registered_triggers.append(trigger_data)

## 트리거 체크 (특정 조건에서 호출)
func check_triggers(condition: TriggerCondition, context: Dictionary = {}) -> void:
	for trigger in registered_triggers:
		if trigger.get("condition") != condition:
			continue

		# 추가 조건 체크
		if not _check_trigger_requirements(trigger, context):
			continue

		# 이미 실행된 일회성 트리거인지 확인
		var trigger_id = trigger.get("id", "")
		var one_shot = trigger.get("one_shot", true)

		if one_shot and has_node("/root/ProgressionSystem"):
			if get_node("/root/ProgressionSystem").has_flag("trigger_" + trigger_id):
				continue

		# 트리거 활성화
		trigger_activated.emit(trigger_id)

		# 일회성 트리거 표시
		if one_shot and has_node("/root/ProgressionSystem"):
			get_node("/root/ProgressionSystem").set_flag("trigger_" + trigger_id)

		# 이벤트 실행
		var events = trigger.get("events", [])
		for event in events:
			queue_event(event)

## 트리거 요구사항 체크
func _check_trigger_requirements(trigger: Dictionary, context: Dictionary) -> bool:
	var required_flags = trigger.get("required_flags", [])
	var blocked_flags = trigger.get("blocked_flags", [])

	if has_node("/root/ProgressionSystem"):
		var progression = get_node("/root/ProgressionSystem")

		# 필수 플래그 체크
		for flag in required_flags:
			if not progression.has_flag(flag):
				return false

		# 차단 플래그 체크
		for flag in blocked_flags:
			if progression.has_flag(flag):
				return false

	return true

## 영역 진입 트리거 체크
func check_area_triggers(area_name: String) -> void:
	check_triggers(TriggerCondition.ON_ENTER, {"area": area_name})

## 상호작용 트리거 체크
func check_interact_triggers(object_name: String) -> void:
	check_triggers(TriggerCondition.ON_INTERACT, {"object": object_name})

## 자동 트리거 체크 (맵 로드 시)
func check_auto_triggers() -> void:
	check_triggers(TriggerCondition.AUTO, {})
