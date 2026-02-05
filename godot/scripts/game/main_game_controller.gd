extends Node2D
class_name MainGameController
## MainGameController: 메인 게임 플레이 컨트롤러
##
## 게임 플레이의 핵심 로직을 관리합니다.
## - 맵 로딩
## - 유닛 스폰
## - 입력 처리
## - UI 업데이트

# 노드 참조
@onready var map_container: Node2D = $World/MapContainer
@onready var player_units_node: Node2D = $World/Units/PlayerUnits
@onready var enemy_units_node: Node2D = $World/Units/EnemyUnits
@onready var effects_node: Node2D = $World/Effects
@onready var chapter_label: Label = $UI/HUD/TopBar/ChapterLabel
@onready var unit_info_label: Label = $UI/HUD/UnitInfoPanel/UnitInfoLabel
@onready var camera: Camera2D = $Camera2D

# 현재 제어 중인 유닛 (타입 어노테이션 제거 - 스크립트 로드 순서 이슈)
var controlled_unit = null  # Unit
var current_squad_index: int = 0
var current_unit_index: int = 0

# 게임 상태
var is_paused: bool = false
var is_in_dialogue: bool = false

func _ready() -> void:
	print("MainGameController: Starting game...")

	# 게임 매니저 초기화 확인
	if not GameManager:
		push_error("GameManager not found!")
		return

	# CombatSystem 생성 (scene-local)
	var combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	print("CombatSystem created as scene-local node")

	# 시작 맵 로드
	_load_initial_map()

	# 초기 유닛 스폰
	_spawn_initial_units()

	# UI 업데이트
	_update_ui()

	print("MainGameController: Game started!")

func _process(_delta: float) -> void:
	if is_paused or is_in_dialogue:
		return

	_handle_input()
	_update_camera()
	_update_ui()

## 초기 맵 로드
func _load_initial_map() -> void:
	var map_path = "res://scenes/maps/chapter1/castle_entrance.tscn"

	if ProgressionSystem and ProgressionSystem.current_map != "":
		map_path = ProgressionSystem.current_map

	var map_scene = load(map_path)
	if map_scene:
		var map_instance = map_scene.instantiate()
		map_container.add_child(map_instance)
		print("Map loaded: ", map_path)
	else:
		push_warning("Failed to load map: ", map_path)

## 초기 유닛 스폰
func _spawn_initial_units() -> void:
	# 플레이어 유닛 스폰 (임시)
	_spawn_player_unit("Hero", Vector2(400, 400))
	_spawn_player_unit("Knight", Vector2(350, 450))
	_spawn_player_unit("Archer", Vector2(450, 450))
	_spawn_player_unit("Mage", Vector2(400, 500))

	# 적 유닛 스폰 (임시)
	_spawn_enemy_unit("Goblin", Vector2(800, 400))
	_spawn_enemy_unit("Goblin", Vector2(850, 450))
	_spawn_enemy_unit("Goblin", Vector2(750, 450))

	# 첫 번째 유닛 선택
	if GameManager.player_units.size() > 0:
		controlled_unit = GameManager.player_units[0]
		GameManager.set_controlled_unit(controlled_unit)

## 플레이어 유닛 스폰
func _spawn_player_unit(unit_name: String, pos: Vector2) -> void:
	var unit_scene = load("res://scenes/units/player_unit.tscn")
	if not unit_scene:
		# 씬이 없으면 기본 Node2D로 대체
		var unit = Node2D.new()
		unit.name = unit_name
		unit.position = pos
		player_units_node.add_child(unit)
		print("Spawned placeholder unit: ", unit_name)
		return

	var unit = unit_scene.instantiate()
	# 스크립트는 씬에 이미 설정되어 있음
	if unit.has_method("set") and "unit_name" in unit:
		unit.unit_name = unit_name
	else:
		unit.name = unit_name
	unit.position = pos
	player_units_node.add_child(unit)
	print("Spawned player unit: ", unit_name)

## 적 유닛 스폰
func _spawn_enemy_unit(unit_name: String, pos: Vector2) -> void:
	var unit_scene = load("res://scenes/units/enemy_unit.tscn")
	if not unit_scene:
		var unit = Node2D.new()
		unit.name = unit_name
		unit.position = pos
		enemy_units_node.add_child(unit)
		print("Spawned placeholder enemy: ", unit_name)
		return

	var unit = unit_scene.instantiate()
	# 스크립트는 씬에 이미 설정되어 있음
	if unit.has_method("set") and "unit_name" in unit:
		unit.unit_name = unit_name
	else:
		unit.name = unit_name
	unit.position = pos
	enemy_units_node.add_child(unit)
	print("Spawned enemy unit: ", unit_name)

## 입력 처리
func _handle_input() -> void:
	# ESC: 일시정지
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()
		return

	if not controlled_unit:
		return

	# 이동 입력 (WASD만 - 화살표는 GameManager에서 유닛 전환용)
	var move_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		move_dir.x += 1

	if move_dir != Vector2.ZERO:
		_move_controlled_unit(move_dir.normalized())

	# 유닛 전환은 GameManager._input()에서만 처리 (ui_left/ui_right)
	# 여기서 중복 처리하지 않음

	# 부대 전환 (상하 화살표) - 별도 처리 필요시

	# 공격
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_attack()

## 제어 유닛 이동
func _move_controlled_unit(direction: Vector2) -> void:
	if controlled_unit and controlled_unit.has_method("move"):
		controlled_unit.move(direction)
	elif controlled_unit:
		# 기본 이동 (Unit 클래스가 없는 경우)
		controlled_unit.position += direction * 5.0

## 유닛 전환
func _switch_unit(direction: int) -> void:
	var units = GameManager.player_units
	if units.is_empty():
		return

	current_unit_index = (current_unit_index + direction + units.size()) % units.size()
	controlled_unit = units[current_unit_index]
	GameManager.set_controlled_unit(controlled_unit)
	print("Switched to unit: ", controlled_unit.name if controlled_unit else "none")

## 공격
func _attack() -> void:
	if controlled_unit and controlled_unit.has_method("attack"):
		controlled_unit.attack()
	else:
		print("Attack!")

## 카메라 업데이트
func _update_camera() -> void:
	if controlled_unit:
		camera.position = camera.position.lerp(controlled_unit.position, 0.1)

## UI 업데이트
func _update_ui() -> void:
	# 챕터 라벨
	var chapter = 1
	if ProgressionSystem:
		chapter = ProgressionSystem.current_chapter
	chapter_label.text = "Chapter %d" % chapter

	# 유닛 정보
	if controlled_unit:
		var hp = 100
		var max_hp = 100
		var fatigue = 0
		var state = "IDLE"

		if controlled_unit.has_method("get_hp"):
			hp = controlled_unit.get_hp()
			max_hp = controlled_unit.get_max_hp()

		if controlled_unit.has_method("get_fatigue"):
			fatigue = controlled_unit.get_fatigue()

		unit_info_label.text = """유닛 정보:
이름: %s
HP: %d/%d
FT: %d%%
상태: %s""" % [controlled_unit.name, hp, max_hp, fatigue, state]
	else:
		unit_info_label.text = "유닛 정보:\n선택된 유닛 없음"

## 일시정지 토글
func _toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	print("Game paused: ", is_paused)
