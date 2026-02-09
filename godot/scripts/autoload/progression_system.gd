extends Node
## ProgressionSystem: 게임 진행 관리 싱글톤
##
## 현재 챕터/맵 추적, 플래그 시스템, 게임 클리어 조건을 관리합니다.

# 현재 진행 상태
var current_chapter: int = 1
var current_map: String = ""
var play_time_seconds: float = 0.0

# 플래그 시스템 (이벤트 완료 여부)
var flags: Dictionary = {}

# 챕터별 클리어 조건
var chapter_clear_conditions: Dictionary = {
	1: ["tutorial_complete", "goblin_boss_defeated"],
	2: ["ally_recruited", "forest_cleared"],
	3: ["first_boss_defeated"]
}

# 시그널
signal chapter_changed(chapter: int)
signal map_changed(map_name: String)
signal flag_set(flag_name: String, value: bool)
signal chapter_cleared(chapter: int)
signal game_cleared()

func _ready() -> void:
	print("ProgressionSystem initialized")

func _process(delta: float) -> void:
	# 플레이 시간 추적 (전투 중일 때만)
	if GameManager.current_state == GameManager.GameState.BATTLE:
		play_time_seconds += delta

## 플래그 설정
func set_flag(flag_name: String, value: bool = true) -> void:
	var old_value = flags.get(flag_name, false)
	flags[flag_name] = value

	if old_value != value:
		flag_set.emit(flag_name, value)
		print("[Progression] Flag set: %s = %s" % [flag_name, value])

		# 챕터 클리어 체크
		_check_chapter_clear()

## 플래그 확인
func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

## 플래그 가져오기
func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)

## 챕터 변경
func change_chapter(chapter: int) -> void:
	if chapter != current_chapter:
		current_chapter = chapter
		chapter_changed.emit(chapter)
		print("[Progression] Chapter changed to: ", chapter)

## 맵 변경
func change_map(map_name: String) -> void:
	if map_name != current_map:
		current_map = map_name
		map_changed.emit(map_name)
		print("[Progression] Map changed to: ", map_name)

## 챕터 클리어 체크
func _check_chapter_clear() -> void:
	if not chapter_clear_conditions.has(current_chapter):
		return

	var conditions = chapter_clear_conditions[current_chapter]
	var all_cleared = true

	for condition in conditions:
		if not has_flag(condition):
			all_cleared = false
			break

	if all_cleared:
		set_flag("chapter_%d_cleared" % current_chapter)
		chapter_cleared.emit(current_chapter)
		print("[Progression] Chapter %d cleared!" % current_chapter)

		# 업적 시스템 알림
		if has_node("/root/AchievementSystem"):
			var chapter_id = "chapter_%d" % current_chapter
			AchievementSystem.complete_chapter(chapter_id)
		if has_node("/root/GameManager"):
			GameManager.chapter_completed.emit("chapter_%d" % current_chapter)

		# 다음 챕터로 자동 진행 (3챕터까지)
		if current_chapter < 3:
			change_chapter(current_chapter + 1)
		else:
			game_cleared.emit()
			print("[Progression] Game cleared!")
			# 게임 클리어 시 스피드런/무사망 체크
			if has_node("/root/AchievementSystem"):
				AchievementSystem.check_completion_achievements(play_time_seconds)

## 챕터 클리어 여부
func is_chapter_cleared(chapter: int) -> bool:
	return has_flag("chapter_%d_cleared" % chapter)

## 챕터별 진행률 (0.0 ~ 1.0)
func get_chapter_progress(chapter: int) -> float:
	if not chapter_clear_conditions.has(chapter):
		return 0.0

	var conditions = chapter_clear_conditions[chapter]
	var completed = 0

	for condition in conditions:
		if has_flag(condition):
			completed += 1

	return float(completed) / float(conditions.size())

## 현재 챕터 진행률
func get_current_progress() -> float:
	return get_chapter_progress(current_chapter)

## 전체 진행률 (0.0 ~ 1.0)
func get_total_progress() -> float:
	var total_conditions = 0
	var completed = 0

	for chapter in chapter_clear_conditions:
		var conditions = chapter_clear_conditions[chapter]
		total_conditions += conditions.size()
		for condition in conditions:
			if has_flag(condition):
				completed += 1

	if total_conditions == 0:
		return 0.0
	return float(completed) / float(total_conditions)

## 플레이 시간 포맷 (HH:MM:SS)
func get_formatted_play_time() -> String:
	var total_seconds = int(play_time_seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

## 진행 데이터 직렬화 (세이브용)
func serialize() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"current_map": current_map,
		"play_time_seconds": play_time_seconds,
		"flags": flags.duplicate()
	}

## 진행 데이터 복원 (로드용)
func deserialize(data: Dictionary) -> void:
	current_chapter = data.get("current_chapter", 1)
	current_map = data.get("current_map", "")
	play_time_seconds = data.get("play_time_seconds", 0.0)
	flags = data.get("flags", {}).duplicate()

	chapter_changed.emit(current_chapter)
	map_changed.emit(current_map)

## 리셋
func reset() -> void:
	current_chapter = 1
	current_map = ""
	play_time_seconds = 0.0
	flags.clear()

	chapter_changed.emit(current_chapter)
	map_changed.emit(current_map)
