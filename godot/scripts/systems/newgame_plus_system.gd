extends Node
class_name NewGamePlusSystem
## NewGamePlusSystem: New Game+ 관리 시스템
##
## 첫 클리어 후 레벨, 장비, 골드를 캐리오버하여 재시작
## 적 스탯 1.5배, 경험치 0.8배, 골드 1.2배 스케일링

const NG_PLUS_SAVE_KEY = "ng_plus_data"

# NG+ 캐리오버 데이터
var carry_over_data: Dictionary = {
	"levels": {},           # unit_name -> level
	"equipment": {},        # unit_name -> equipped items
	"gold": 0,
	"spells": [],          # 해금된 마법 리스트
	"achievements": [],    # 업적 리스트
	"play_count": 0        # NG+ 플레이 횟수
}

# NG+ 스케일링 설정
var enemy_scaling: float = 1.5   # 적 스탯 1.5배
var exp_scaling: float = 0.8     # 경험치 0.8배
var gold_scaling: float = 1.2    # 골드 1.2배

# 시그널
signal ng_plus_started()
signal ng_plus_data_loaded(data: Dictionary)

## NG+ 데이터 준비 (게임 클리어 시 호출)
func prepare_ng_plus_data() -> void:
	carry_over_data["play_count"] += 1

	# 플레이어 유닛 데이터 수집
	for unit in GameManager.player_units:
		var uid = unit.unit_name

		# 레벨 저장 (ExperienceSystem 있으면)
		if unit.has_method("get_experience_data"):
			var exp_data = unit.get_experience_data()
			carry_over_data["levels"][uid] = exp_data.get("current_level", 1)

		# 장비 저장 (EquipmentSystem 있으면)
		if unit.has_method("get_equipment_data"):
			carry_over_data["equipment"][uid] = unit.get_equipment_data()

	# 골드 저장 (InventorySystem 있으면)
	var inventory: Node = get_node_or_null("/root/InventorySystem")
	if inventory and inventory.has_method("get_gold"):
		carry_over_data["gold"] = inventory.get_gold()

	# ProgressionSystem 플래그에서 해금된 마법/업적 수집
	var progression: Node = get_node_or_null("/root/ProgressionSystem")
	if progression:
		carry_over_data["spells"] = _collect_unlocked_spells(progression)
		carry_over_data["achievements"] = _collect_achievements(progression)

	print("[NG+] Data prepared: play_count=%d, levels=%d, gold=%d" % [
		carry_over_data["play_count"],
		carry_over_data["levels"].size(),
		carry_over_data["gold"]
	])

## NG+ 데이터 저장
func save_ng_plus_data() -> void:
	prepare_ng_plus_data()
	SaveSystem.save_data(NG_PLUS_SAVE_KEY, carry_over_data)
	print("[NG+] Data saved")

## NG+ 데이터 로드
func load_ng_plus_data() -> bool:
	var data = SaveSystem.load_data(NG_PLUS_SAVE_KEY)
	if data.is_empty():
		print("[NG+] No NG+ data found")
		return false

	carry_over_data = data
	ng_plus_data_loaded.emit(data)
	print("[NG+] Data loaded: play_count=%d" % carry_over_data["play_count"])
	return true

## NG+ 시작
func start_new_game_plus() -> void:
	if not load_ng_plus_data():
		push_error("[NG+] Cannot start New Game+ without saved data")
		return

	ng_plus_started.emit()

	# ChapterManager로 챕터 1 시작
	if has_node("/root/ChapterManager"):
		get_node("/root/ChapterManager").start_chapter(1)

	# ProgressionSystem 리셋
	var progression: Node = get_node_or_null("/root/ProgressionSystem")
	if progression:
		progression.reset()
		progression.set_flag("ng_plus_active", true)

	print("[NG+] New Game+ started (difficulty: %.1fx)" % enemy_scaling)

## 유닛에 NG+ 데이터 적용 (ChapterManager가 유닛 생성 후 호출)
func apply_to_unit(unit) -> void:
	if carry_over_data["play_count"] == 0:
		return

	var uid = unit.unit_name

	# 레벨 복원
	if carry_over_data["levels"].has(uid):
		var level = carry_over_data["levels"][uid]
		if unit.has_method("set_level"):
			unit.set_level(level)
			print("[NG+] Applied level %d to %s" % [level, uid])

	# 장비 복원
	if carry_over_data["equipment"].has(uid):
		if unit.has_method("load_equipment_data"):
			unit.load_equipment_data(carry_over_data["equipment"][uid])

## 적 스탯 스케일링 (EnemyUnit 생성 시 호출)
func get_scaled_enemy_stats(base_stats: Dictionary) -> Dictionary:
	if carry_over_data["play_count"] == 0:
		return base_stats

	var scaled = base_stats.duplicate()
	scaled["hp"] = int(scaled.get("hp", 100) * enemy_scaling)
	scaled["atk"] = int(scaled.get("atk", 10) * enemy_scaling)
	scaled["def"] = int(scaled.get("def", 5) * enemy_scaling)
	scaled["spd"] = int(scaled.get("spd", 100) * min(enemy_scaling, 1.2))  # 속도는 1.2배까지만

	return scaled

## 경험치 스케일링 (경험치 획득 시 호출)
func get_scaled_exp(base_exp: int) -> int:
	if carry_over_data["play_count"] == 0:
		return base_exp
	return int(base_exp * exp_scaling)

## 골드 스케일링 (골드 획득 시 호출)
func get_scaled_gold(base_gold: int) -> int:
	if carry_over_data["play_count"] == 0:
		return base_gold
	return int(base_gold * gold_scaling)

## NG+ 데이터 존재 여부
func has_ng_plus_data() -> bool:
	return not SaveSystem.load_data(NG_PLUS_SAVE_KEY).is_empty()

## NG+ 활성화 여부 (현재 플레이스루가 NG+인지)
func is_ng_plus_active() -> bool:
	var progression: Node = get_node_or_null("/root/ProgressionSystem")
	if progression:
		return progression.has_flag("ng_plus_active")
	return false

## 해금된 마법 수집 (플래그 기반)
func _collect_unlocked_spells(progression: Node) -> Array:
	var spells: Array = []
	for flag in progression.flags:
		if flag.begins_with("spell_unlocked_"):
			spells.append(flag.replace("spell_unlocked_", ""))
	return spells

## 업적 수집 (플래그 기반)
func _collect_achievements(progression: Node) -> Array:
	var achievements: Array = []
	for flag in progression.flags:
		if flag.begins_with("achievement_"):
			achievements.append(flag.replace("achievement_", ""))
	return achievements
