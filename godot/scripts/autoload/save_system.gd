extends Node
## SaveSystem: 세이브/로드 시스템
##
## 3개 슬롯 + 자동 저장 슬롯
## JSON 직렬화로 유닛 상태, 인벤토리, 게임 진행 저장

const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".sav"
const AUTO_SAVE_SLOT: int = 0
const MAX_SLOTS: int = 3

# 저장 데이터 버전 (호환성 관리용)
const SAVE_VERSION: int = 1

# 시그널
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal auto_save_triggered()

func _ready() -> void:
	_ensure_save_directory()

## 저장 디렉토리 확인/생성
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")

## 슬롯 파일 경로
func _get_save_path(slot: int) -> String:
	var slot_name = "auto" if slot == AUTO_SAVE_SLOT else str(slot)
	return SAVE_DIR + "slot_" + slot_name + SAVE_EXTENSION

## 게임 저장
func save_game(slot: int) -> bool:
	if slot < 0 or slot > MAX_SLOTS:
		push_error("Invalid save slot: " + str(slot))
		save_completed.emit(slot, false)
		return false

	var save_data = _collect_save_data()
	var json_string = JSON.stringify(save_data, "\t")

	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file: " + str(FileAccess.get_open_error()))
		save_completed.emit(slot, false)
		return false

	file.store_string(json_string)
	file.close()

	print("Game saved to slot ", slot)
	save_completed.emit(slot, true)
	return true

## 게임 로드
func load_game(slot: int) -> bool:
	if slot < 0 or slot > MAX_SLOTS:
		push_error("Invalid save slot: " + str(slot))
		load_completed.emit(slot, false)
		return false

	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("Save file not found: " + path)
		load_completed.emit(slot, false)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: " + str(FileAccess.get_open_error()))
		load_completed.emit(slot, false)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		load_completed.emit(slot, false)
		return false

	var save_data = json.get_data()
	if not _validate_save_data(save_data):
		push_error("Invalid save data format")
		load_completed.emit(slot, false)
		return false

	_apply_save_data(save_data)

	print("Game loaded from slot ", slot)
	load_completed.emit(slot, true)
	return true

## 자동 저장
func auto_save() -> bool:
	auto_save_triggered.emit()
	return save_game(AUTO_SAVE_SLOT)

## 세이브 슬롯 정보 가져오기
func get_slot_info(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {
			"exists": false,
			"slot": slot
		}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "slot": slot}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {"exists": false, "slot": slot, "corrupted": true}

	var save_data = json.get_data()

	return {
		"exists": true,
		"slot": slot,
		"version": save_data.get("version", 0),
		"timestamp": save_data.get("timestamp", ""),
		"play_time": save_data.get("play_time", 0),
		"chapter": save_data.get("game_state", {}).get("chapter", 1),
		"player_level": _get_main_player_level(save_data)
	}

## 모든 슬롯 정보
func get_all_slots_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(AUTO_SAVE_SLOT, MAX_SLOTS + 1):
		result.append(get_slot_info(slot))
	return result

## 세이브 삭제
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:  # 자동 저장 슬롯은 삭제 불가
		return false

	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove("slot_" + str(slot) + SAVE_EXTENSION)
			return true
	return false

## 세이브 데이터 수집
func _collect_save_data() -> Dictionary:
	var timestamp = Time.get_datetime_string_from_system()

	return {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"play_time": _get_play_time(),
		"game_state": _collect_game_state(),
		"player_units": _collect_player_units(),
		"inventory": _collect_inventory(),
		"squads": _collect_squads()
	}

## 게임 상태 수집
func _collect_game_state() -> Dictionary:
	var chapter = 1
	var current_map = ""
	var progression_data = {}

	if has_node("/root/ProgressionSystem"):
		var progression = get_node("/root/ProgressionSystem")
		chapter = progression.current_chapter
		current_map = progression.current_map
		progression_data = progression.serialize()

	return {
		"current_state": GameManager.current_state,
		"current_turn": GameManager.current_turn,
		"current_squad_id": GameManager.current_squad_id,
		"chapter": chapter,
		"current_map": current_map,
		"progression": progression_data
	}

## 플레이어 유닛 데이터 수집
func _collect_player_units() -> Array:
	var units_data: Array = []

	for unit in GameManager.player_units:
		var unit_data = {
			"unit_name": unit.unit_name,
			"position": {"x": unit.global_position.x, "y": unit.global_position.y},
			"current_hp": unit.current_hp,
			"max_hp": unit.max_hp,
			"current_mp": unit.current_mp,
			"max_mp": unit.max_mp,
			"current_fatigue": unit.current_fatigue,
			"max_fatigue": unit.max_fatigue,
			"attack_power": unit.attack_power,
			"defense": unit.defense,
			"move_speed": unit.move_speed,
			"attack_range": unit.attack_range,
			"is_alive": unit.is_alive
		}

		# AIUnit 추가 데이터 (문자열로 타입 체크하여 순환 참조 방지)
		if unit.get_class() == "AIUnit" or unit.has_method("get_personality"):
			unit_data["personality"] = unit.personality
			unit_data["squad_id"] = unit.squad_id
			unit_data["squad_position"] = unit.squad_position

		# 경험치/레벨 시스템이 있으면 추가
		if unit.has_method("get_experience_data"):
			unit_data["experience"] = unit.get_experience_data()

		# 장비 시스템이 있으면 추가
		if unit.has_method("get_equipment_data"):
			unit_data["equipment"] = unit.get_equipment_data()

		units_data.append(unit_data)

	return units_data

## 인벤토리 데이터 수집
func _collect_inventory() -> Dictionary:
	# 글로벌 인벤토리가 있으면 직렬화
	# TODO: 글로벌 인벤토리 시스템 연결
	return {
		"items": {},
		"gold": 0
	}

## 부대 데이터 수집
func _collect_squads() -> Dictionary:
	var squads_data: Dictionary = {}

	for squad_id in GameManager.squads:
		var squad = GameManager.squads[squad_id]
		var unit_names: Array = []
		for unit in squad:
			unit_names.append(unit.unit_name)
		squads_data[str(squad_id)] = unit_names

	return squads_data

## 플레이 시간 (초)
func _get_play_time() -> int:
	if has_node("/root/ProgressionSystem"):
		return int(get_node("/root/ProgressionSystem").play_time_seconds)
	return 0

## 세이브 데이터 유효성 검증
func _validate_save_data(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if not data.has("game_state"):
		return false
	if not data.has("player_units"):
		return false
	return true

## 세이브 데이터 적용
func _apply_save_data(data: Dictionary) -> void:
	# 게임 상태 복원
	var game_state = data.get("game_state", {})
	GameManager.current_turn = game_state.get("current_turn", 0)
	GameManager.current_squad_id = game_state.get("current_squad_id", 0)

	# ProgressionSystem 복원
	if has_node("/root/ProgressionSystem"):
		var progression = get_node("/root/ProgressionSystem")
		var progression_data = game_state.get("progression", {})
		if not progression_data.is_empty():
			progression.deserialize(progression_data)

	# TODO: 유닛, 인벤토리, 부대 복원 구현
	# 이는 씬 로딩과 연결되어야 하므로 별도 처리 필요

	print("Save data applied")

## 메인 플레이어 레벨 추출
func _get_main_player_level(save_data: Dictionary) -> int:
	var units = save_data.get("player_units", [])
	if units.is_empty():
		return 1

	var first_unit = units[0]
	if first_unit.has("experience"):
		return first_unit["experience"].get("current_level", 1)
	return 1

## 범용 데이터 저장 (NG+ 등)
func save_data(key: String, data: Dictionary) -> bool:
	var path = SAVE_DIR + key + ".json"
	var json_string = JSON.stringify(data, "\t")

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save data: " + key)
		return false

	file.store_string(json_string)
	file.close()
	return true

## 범용 데이터 로드 (NG+ 등)
func load_data(key: String) -> Dictionary:
	var path = SAVE_DIR + key + ".json"
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("Failed to parse data: " + key)
		return {}

	return json.get_data()
