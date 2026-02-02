extends Node
## GameManager: 게임 전역 상태 관리 싱글톤
##
## 게임 세션, 유닛 관리, 부대 관리, 이벤트 디스패치 등을 담당합니다.
## Gocha-Kyara 시스템의 핵심 관리자입니다.

# 게임 상태
enum GameState {
	MENU,
	BATTLE,
	PAUSED,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.MENU

# 유닛 관리
var player_units: Array[Node] = []
var enemy_units: Array[Node] = []

# 부대 시스템 (Gocha-Kyara)
var squads: Dictionary = {}  # squad_id -> Array[Unit]
var current_squad_id: int = 0
var current_unit_index: int = 0
var controlled_unit: Node = null  # 현재 플레이어가 조작 중인 유닛

var current_turn: int = 0

# 시그널
signal state_changed(new_state: GameState)
signal turn_advanced(turn_number: int)
signal unit_spawned(unit: Node)
signal unit_died(unit: Node)
signal squad_changed(squad_id: int)
signal controlled_unit_changed(unit: Node)

func _ready() -> void:
	print("GameManager initialized")

func _input(event: InputEvent) -> void:
	if current_state != GameState.BATTLE:
		return

	# 부대 내 캐릭터 전환 (← →)
	if event.is_action_pressed("ui_left"):
		switch_unit_in_squad(-1)
	elif event.is_action_pressed("ui_right"):
		switch_unit_in_squad(1)

	# 부대 전환 (↑ ↓)
	if event.is_action_pressed("ui_up"):
		switch_squad(-1)
	elif event.is_action_pressed("ui_down"):
		switch_squad(1)

## 게임 상태 전환
func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

## 턴 진행
func advance_turn() -> void:
	current_turn += 1
	turn_advanced.emit(current_turn)

## 유닛 등록
func register_unit(unit: Node, is_player: bool) -> void:
	if is_player:
		if not player_units.has(unit):
			player_units.append(unit)
	else:
		if not enemy_units.has(unit):
			enemy_units.append(unit)
	unit_spawned.emit(unit)

## 유닛 제거
func unregister_unit(unit: Node) -> void:
	player_units.erase(unit)
	enemy_units.erase(unit)

	# 부대에서도 제거
	for squad_id in squads:
		squads[squad_id].erase(unit)

	# 조작 중인 유닛이 죽으면 다음 유닛으로 전환
	if unit == controlled_unit:
		_find_next_controllable_unit()

	unit_died.emit(unit)
	_check_game_over()

## 부대 생성
func create_squad(squad_id: int) -> void:
	if not squads.has(squad_id):
		squads[squad_id] = []

## 부대에 유닛 추가
func add_unit_to_squad(unit: Node, squad_id: int) -> void:
	create_squad(squad_id)
	if not squads[squad_id].has(unit):
		var position = squads[squad_id].size()
		squads[squad_id].append(unit)

		# AIUnit이면 부대 정보 설정
		if unit.has_method("set_squad_info"):
			unit.set_squad_info(squad_id, position)

## 부대 리더 설정
func set_squad_leader(squad_id: int, leader: Node) -> void:
	if not squads.has(squad_id):
		return

	for unit in squads[squad_id]:
		if unit != leader and unit.has_method("set_leader"):
			unit.set_leader(leader)

## 부대 내 캐릭터 전환 (← →)
func switch_unit_in_squad(direction: int) -> void:
	if not squads.has(current_squad_id):
		return

	var squad = squads[current_squad_id]
	if squad.is_empty():
		return

	# 살아있는 유닛만 필터링
	var alive_units = squad.filter(func(u): return u.is_alive)
	if alive_units.is_empty():
		return

	# 현재 유닛의 인덱스 찾기
	var current_idx = alive_units.find(controlled_unit)
	if current_idx == -1:
		current_idx = 0

	# 다음/이전 유닛으로 전환
	var new_idx = (current_idx + direction) % alive_units.size()
	if new_idx < 0:
		new_idx = alive_units.size() - 1

	_set_controlled_unit(alive_units[new_idx])

## 부대 전환 (↑ ↓)
func switch_squad(direction: int) -> void:
	var squad_ids = squads.keys()
	if squad_ids.is_empty():
		return

	squad_ids.sort()

	var current_idx = squad_ids.find(current_squad_id)
	if current_idx == -1:
		current_idx = 0

	# 다음/이전 부대로 전환
	var new_idx = (current_idx + direction) % squad_ids.size()
	if new_idx < 0:
		new_idx = squad_ids.size() - 1

	current_squad_id = squad_ids[new_idx]
	squad_changed.emit(current_squad_id)

	# 해당 부대의 첫 번째 살아있는 유닛으로 전환
	if squads.has(current_squad_id):
		var squad = squads[current_squad_id]
		for unit in squad:
			if unit.is_alive:
				_set_controlled_unit(unit)
				break

## 조작 유닛 설정
func _set_controlled_unit(unit: Node) -> void:
	# 이전 유닛 AI 모드로 전환
	if controlled_unit and controlled_unit.has_method("set_player_controlled"):
		controlled_unit.set_player_controlled(false)

	controlled_unit = unit

	# 새 유닛 플레이어 모드로 전환
	if controlled_unit and controlled_unit.has_method("set_player_controlled"):
		controlled_unit.set_player_controlled(true)

	controlled_unit_changed.emit(controlled_unit)

## 조작 유닛 설정 (public)
func set_controlled_unit(unit: Node) -> void:
	_set_controlled_unit(unit)

## 다음 조작 가능한 유닛 찾기
func _find_next_controllable_unit() -> void:
	# 현재 부대에서 먼저 찾기
	if squads.has(current_squad_id):
		for unit in squads[current_squad_id]:
			if unit.is_alive:
				_set_controlled_unit(unit)
				return

	# 다른 부대에서 찾기
	for squad_id in squads:
		for unit in squads[squad_id]:
			if unit.is_alive:
				current_squad_id = squad_id
				_set_controlled_unit(unit)
				return

	# 조작 가능한 유닛 없음
	controlled_unit = null

## 게임 오버/승리 체크
func _check_game_over() -> void:
	var alive_players = player_units.filter(func(u): return u.is_alive)
	var alive_enemies = enemy_units.filter(func(u): return u.is_alive)

	if alive_players.is_empty():
		change_state(GameState.GAME_OVER)
	elif alive_enemies.is_empty():
		change_state(GameState.VICTORY)

## 현재 부대 가져오기
func get_current_squad() -> Array:
	if squads.has(current_squad_id):
		return squads[current_squad_id]
	return []

## 부대 정보 가져오기
func get_squad_info(squad_id: int) -> Dictionary:
	if not squads.has(squad_id):
		return {}

	var squad = squads[squad_id]
	var alive = squad.filter(func(u): return u.is_alive)

	return {
		"id": squad_id,
		"total": squad.size(),
		"alive": alive.size(),
		"units": squad
	}

## 게임 리셋
func reset_game() -> void:
	player_units.clear()
	enemy_units.clear()
	squads.clear()
	current_squad_id = 0
	current_unit_index = 0
	controlled_unit = null
	current_turn = 0
	change_state(GameState.MENU)

## 전투 시작
func start_battle() -> void:
	change_state(GameState.BATTLE)

	# 첫 번째 부대의 첫 번째 유닛을 조작 유닛으로 설정
	if not squads.is_empty():
		var first_squad_id = squads.keys()[0]
		current_squad_id = first_squad_id
		if not squads[first_squad_id].is_empty():
			_set_controlled_unit(squads[first_squad_id][0])
