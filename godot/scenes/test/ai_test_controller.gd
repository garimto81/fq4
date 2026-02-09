extends Node2D
## AITestController: Gocha-Kyara AI 테스트 씬 컨트롤러
##
## 테스트용 유닛 스폰, UI 업데이트, 입력 처리를 담당합니다.

@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var player_units_node: Node2D = $Units/PlayerUnits
@onready var enemy_units_node: Node2D = $Units/EnemyUnits
@onready var status_label: Label = $UI/HUD/StatusPanel/StatusLabel
@onready var game_state_label: Label = $UI/HUD/GameStateLabel
@onready var camera: Camera2D = $Camera2D

# 테스트 설정
@export var player_squad_size: int = 5
@export var enemy_squad_count: int = 5

var player_squads: Array = []
var enemy_units_list: Array = []

func _ready() -> void:
	# 부모를 유닛 컨테이너로 변경
	unit_spawner.reparent(player_units_node)

	# 시그널 연결
	GameManager.controlled_unit_changed.connect(_on_controlled_unit_changed)
	GameManager.squad_changed.connect(_on_squad_changed)
	GameManager.state_changed.connect(_on_game_state_changed)

	# 테스트 시작
	await get_tree().process_frame
	_setup_test_battle()

## 테스트 전투 설정
func _setup_test_battle() -> void:
	print("Setting up Gocha-Kyara AI test...")

	# 플레이어 부대 1 생성 (왼쪽)
	var squad1_pos = Vector2(250, 360)
	var squad1 = unit_spawner.spawn_player_squad(0, player_squad_size, squad1_pos, true)
	player_squads.append(squad1)

	# 플레이어 부대 2 생성 (왼쪽 아래)
	var squad2_pos = Vector2(250, 500)
	var squad2 = unit_spawner.spawn_player_squad(1, 3, squad2_pos, true)
	player_squads.append(squad2)

	# 적 유닛 생성 (오른쪽)
	var enemy_pos = Vector2(1000, 360)
	enemy_units_list = unit_spawner.spawn_enemy_squad(99, enemy_squad_count, enemy_pos)

	# 적 유닛을 적 컨테이너로 이동
	for unit in enemy_units_list:
		if unit.get_parent() != enemy_units_node:
			unit.reparent(enemy_units_node)

	# 전투 시작
	GameManager.start_battle()

	print("Test battle started!")
	print("Player units: ", GameManager.player_units.size())
	print("Enemy units: ", GameManager.enemy_units.size())
	print("Squads: ", GameManager.squads.size())

func _process(_delta: float) -> void:
	_update_status_ui()
	_update_camera()

func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.BATTLE:
		return

	# 플레이어 조작 유닛 이동 (WASD)
	var controlled = GameManager.controlled_unit
	if controlled and controlled.is_alive:
		var move_dir = Vector2.ZERO

		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			pass  # 부대 전환에 사용
		if Input.is_key_pressed(KEY_W):
			move_dir.y -= 1
		if Input.is_key_pressed(KEY_S):
			move_dir.y += 1
		if Input.is_key_pressed(KEY_A):
			move_dir.x -= 1
		if Input.is_key_pressed(KEY_D):
			move_dir.x += 1

		if move_dir != Vector2.ZERO:
			move_dir = move_dir.normalized()
			controlled.velocity = move_dir * controlled.move_speed
			controlled.move_and_slide()
			controlled.change_state(Unit.UnitState.MOVING)

	# 우클릭 이동
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if controlled and controlled.is_alive and controlled.has_method("move_to"):
			var target_pos = get_global_mouse_position()
			controlled.move_to(target_pos)

	# R키: 게임 리셋
	if event.is_action_pressed("ui_cancel"):  # Escape
		_reset_test()

## 상태 UI 업데이트
func _update_status_ui() -> void:
	var controlled = GameManager.controlled_unit
	var status_text = "Status:\n"

	if controlled:
		status_text += "Controlling: " + controlled.unit_name + "\n"
		status_text += "HP: " + str(controlled.current_hp) + "/" + str(controlled.max_hp) + "\n"
		status_text += "Fatigue: " + str(controlled.current_fatigue) + "/" + str(controlled.max_fatigue) + "\n"

		if controlled.has_method("get") and "ai_state" in controlled:
			var state_name = AIUnit.AIState.keys()[controlled.ai_state]
			status_text += "AI State: " + state_name + "\n"

		if controlled.has_method("get") and "personality" in controlled:
			var personality_name = AIUnit.Personality.keys()[controlled.personality]
			status_text += "Personality: " + personality_name + "\n"
	else:
		status_text += "No unit controlled\n"

	status_text += "\n"
	status_text += "Squad: " + str(GameManager.current_squad_id) + "\n"
	status_text += "Alive Players: " + str(GameManager.player_units.filter(func(u): return u.is_alive).size()) + "\n"
	status_text += "Alive Enemies: " + str(GameManager.enemy_units.filter(func(u): return u.is_alive).size()) + "\n"

	status_label.text = status_text

	# 게임 상태 표시
	game_state_label.text = "Game State: " + GameManager.GameState.keys()[GameManager.current_state]

## 카메라 업데이트 (조작 유닛 따라가기)
func _update_camera() -> void:
	var controlled = GameManager.controlled_unit
	if controlled and controlled.is_alive:
		camera.global_position = camera.global_position.lerp(controlled.global_position, 0.05)

## 조작 유닛 변경 콜백
func _on_controlled_unit_changed(unit: Node) -> void:
	if unit:
		print("Now controlling: ", unit.unit_name)

		# 선택 표시기 업데이트
		for player_unit in GameManager.player_units:
			var indicator = player_unit.get_node_or_null("SelectionIndicator")
			if indicator:
				indicator.visible = (player_unit == unit)

## 부대 변경 콜백
func _on_squad_changed(squad_id: int) -> void:
	print("Switched to squad: ", squad_id)

## 게임 상태 변경 콜백
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	print("Game state changed: ", GameManager.GameState.keys()[new_state])

	if new_state == GameManager.GameState.VICTORY:
		game_state_label.text = "VICTORY! Press ESC to restart"
	elif new_state == GameManager.GameState.GAME_OVER:
		game_state_label.text = "GAME OVER! Press ESC to restart"

## 테스트 리셋
func _reset_test() -> void:
	print("Resetting test...")

	# 기존 유닛 제거
	for child in player_units_node.get_children():
		if child != unit_spawner:
			child.queue_free()

	for child in enemy_units_node.get_children():
		child.queue_free()

	# 게임 매니저 리셋
	GameManager.reset_game()

	player_squads.clear()
	enemy_units_list.clear()

	# 재설정
	await get_tree().process_frame
	_setup_test_battle()
