extends Node
## 업적 시스템 (전역 싱글톤)

# 시그널
signal achievement_unlocked(achievement: AchievementData)
signal achievement_progress(achievement_id: String, current: int, target: int)

# 업적 데이터베이스
var achievements: Dictionary = {}  # id -> AchievementData
var unlocked: Dictionary = {}  # id -> unlock_timestamp
var progress: Dictionary = {}  # id -> current_value

# 통계 추적
var stats: Dictionary = {
	"total_kills": 0,
	"spells_cast": 0,
	"gold_earned": 0,
	"formations_used": {},  # formation_type -> count
	"chapters_cleared": [],
	"bosses_defeated": [],
	"endings_reached": [],
	"items_collected": [],
	"total_play_time": 0.0,
	"death_count": 0,
	"ng_plus_count": 0
}

func _ready() -> void:
	_register_all_achievements()
	_connect_signals()

func _register_all_achievements() -> void:
	# 챕터 클리어 (10개)
	for i in range(1, 11):
		_register_achievement(_create_chapter_achievement(i))

	# 보스 처치 (3개 + 1 숨김)
	_register_achievement(_create_boss_achievement("demon_general", "boss_demon_general"))
	_register_achievement(_create_boss_achievement("fallen_hero", "boss_fallen_hero"))
	_register_achievement(_create_boss_achievement("demon_king", "boss_demon_king"))
	_register_achievement(_create_boss_achievement("all_bosses", "boss_all", true))

	# 레벨 업적 (3개)
	_register_achievement(_create_level_achievement(10, "novice"))
	_register_achievement(_create_level_achievement(30, "veteran"))
	_register_achievement(_create_level_achievement(50, "master"))

	# 처치 수 (3개)
	_register_achievement(_create_kills_achievement(100, "hunter"))
	_register_achievement(_create_kills_achievement(500, "slayer"))
	_register_achievement(_create_kills_achievement(1000, "legend"))

	# 엔딩 (3개)
	_register_achievement(_create_ending_achievement("good", "ending_good"))
	_register_achievement(_create_ending_achievement("normal", "ending_normal"))
	_register_achievement(_create_ending_achievement("bad", "ending_bad"))

	# 특수 업적 (5개)
	_register_achievement(_create_speed_run_achievement())
	_register_achievement(_create_no_death_achievement())
	_register_achievement(_create_ng_plus_achievement())
	_register_achievement(_create_all_formations_achievement())
	_register_achievement(_create_spell_master_achievement())

func _create_chapter_achievement(chapter: int) -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "chapter_%d_clear" % chapter
	ach.name_key = "ACH_CHAPTER_%d_NAME" % chapter
	ach.description_key = "ACH_CHAPTER_%d_DESC" % chapter
	ach.type = AchievementData.AchievementType.CHAPTER_CLEAR
	ach.target_value = chapter
	ach.target_id = "chapter_%d" % chapter
	ach.steam_api_name = "CHAPTER_%d" % chapter
	return ach

func _create_boss_achievement(boss_id: String, ach_id: String, secret: bool = false) -> AchievementData:
	var ach = AchievementData.new()
	ach.id = ach_id
	ach.name_key = "ACH_%s_NAME" % ach_id.to_upper()
	ach.description_key = "ACH_%s_DESC" % ach_id.to_upper()
	ach.type = AchievementData.AchievementType.BOSS_DEFEAT
	ach.target_value = 1
	ach.target_id = boss_id
	ach.secret = secret
	ach.steam_api_name = ach_id.to_upper()
	return ach

func _create_level_achievement(level: int, tier: String) -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "level_%s" % tier
	ach.name_key = "ACH_LEVEL_%s_NAME" % tier.to_upper()
	ach.description_key = "ACH_LEVEL_%s_DESC" % tier.to_upper()
	ach.type = AchievementData.AchievementType.UNIT_LEVEL
	ach.target_value = level
	ach.steam_api_name = "LEVEL_%s" % tier.to_upper()
	return ach

func _create_kills_achievement(kills: int, tier: String) -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "kills_%s" % tier
	ach.name_key = "ACH_KILLS_%s_NAME" % tier.to_upper()
	ach.description_key = "ACH_KILLS_%s_DESC" % tier.to_upper()
	ach.type = AchievementData.AchievementType.TOTAL_KILLS
	ach.target_value = kills
	ach.steam_api_name = "KILLS_%s" % tier.to_upper()
	return ach

func _create_ending_achievement(ending_type: String, ach_id: String) -> AchievementData:
	var ach = AchievementData.new()
	ach.id = ach_id
	ach.name_key = "ACH_%s_NAME" % ach_id.to_upper()
	ach.description_key = "ACH_%s_DESC" % ach_id.to_upper()
	ach.type = AchievementData.AchievementType.ENDING_REACHED
	ach.target_value = 1
	ach.target_id = ending_type
	ach.steam_api_name = ach_id.to_upper()
	return ach

func _create_speed_run_achievement() -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "speed_run"
	ach.name_key = "ACH_SPEED_RUN_NAME"
	ach.description_key = "ACH_SPEED_RUN_DESC"
	ach.type = AchievementData.AchievementType.SPEED_RUN
	ach.target_value = 7200  # 2시간 = 7200초
	ach.secret = true
	ach.steam_api_name = "SPEED_RUN"
	return ach

func _create_no_death_achievement() -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "no_death"
	ach.name_key = "ACH_NO_DEATH_NAME"
	ach.description_key = "ACH_NO_DEATH_DESC"
	ach.type = AchievementData.AchievementType.NO_DEATH
	ach.target_value = 1
	ach.secret = true
	ach.steam_api_name = "NO_DEATH"
	return ach

func _create_ng_plus_achievement() -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "ng_plus"
	ach.name_key = "ACH_NG_PLUS_NAME"
	ach.description_key = "ACH_NG_PLUS_DESC"
	ach.type = AchievementData.AchievementType.NEWGAME_PLUS
	ach.target_value = 1
	ach.steam_api_name = "NG_PLUS"
	return ach

func _create_all_formations_achievement() -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "formation_master"
	ach.name_key = "ACH_FORMATION_MASTER_NAME"
	ach.description_key = "ACH_FORMATION_MASTER_DESC"
	ach.type = AchievementData.AchievementType.FORMATION_USE
	ach.target_value = 5  # 5개 대형 모두 사용
	ach.steam_api_name = "FORMATION_MASTER"
	return ach

func _create_spell_master_achievement() -> AchievementData:
	var ach = AchievementData.new()
	ach.id = "spell_master"
	ach.name_key = "ACH_SPELL_MASTER_NAME"
	ach.description_key = "ACH_SPELL_MASTER_DESC"
	ach.type = AchievementData.AchievementType.SPELL_CAST
	ach.target_value = 100
	ach.steam_api_name = "SPELL_MASTER"
	return ach

func _register_achievement(ach: AchievementData) -> void:
	achievements[ach.id] = ach
	progress[ach.id] = 0

func _connect_signals() -> void:
	# GameManager 시그널은 call_deferred로 연결
	call_deferred("_connect_game_manager")

func _connect_game_manager() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("enemy_killed"):
			if not gm.enemy_killed.is_connected(_on_enemy_killed):
				gm.enemy_killed.connect(_on_enemy_killed)
		if gm.has_signal("chapter_completed"):
			if not gm.chapter_completed.is_connected(_on_chapter_completed):
				gm.chapter_completed.connect(_on_chapter_completed)

## 업적 해금
func unlock(achievement_id: String) -> void:
	if unlocked.has(achievement_id):
		return

	if not achievements.has(achievement_id):
		push_warning("[Achievement] Unknown achievement: %s" % achievement_id)
		return

	unlocked[achievement_id] = Time.get_unix_time_from_system()
	var ach = achievements[achievement_id]
	achievement_unlocked.emit(ach)

	# Steam 업적 동기화 (GodotSteam 연동 시)
	_sync_steam_achievement(ach)

	print("[Achievement] Unlocked: %s - %s" % [achievement_id, ach.name_key])

## 프로그레스 업데이트
func update_progress(achievement_id: String, value: int) -> void:
	if unlocked.has(achievement_id):
		return

	if not achievements.has(achievement_id):
		return

	progress[achievement_id] = value
	var ach = achievements[achievement_id]
	achievement_progress.emit(achievement_id, value, ach.target_value)

	if ach.check_progress(value):
		unlock(achievement_id)

## 통계 업데이트
func add_kill() -> void:
	stats["total_kills"] += 1
	_check_kills_achievements()

func add_spell_cast() -> void:
	stats["spells_cast"] += 1
	update_progress("spell_master", stats["spells_cast"])

func add_gold(amount: int) -> void:
	stats["gold_earned"] += amount

func use_formation(formation_type: int) -> void:
	if not stats["formations_used"].has(formation_type):
		stats["formations_used"][formation_type] = 0
	stats["formations_used"][formation_type] += 1
	update_progress("formation_master", stats["formations_used"].size())

func complete_chapter(chapter_id: String) -> void:
	if not stats["chapters_cleared"].has(chapter_id):
		stats["chapters_cleared"].append(chapter_id)
	# 해당 챕터 업적 해금
	var ach_id = "%s_clear" % chapter_id
	unlock(ach_id)

func defeat_boss(boss_id: String) -> void:
	if not stats["bosses_defeated"].has(boss_id):
		stats["bosses_defeated"].append(boss_id)
	# 해당 보스 업적 해금
	var ach_id = "boss_%s" % boss_id
	if achievements.has(ach_id):
		unlock(ach_id)
	# 모든 보스 처치 체크
	if stats["bosses_defeated"].size() >= 3:
		unlock("boss_all")

func reach_ending(ending_type: String) -> void:
	if not stats["endings_reached"].has(ending_type):
		stats["endings_reached"].append(ending_type)
	var ach_id = "ending_%s" % ending_type
	if achievements.has(ach_id):
		unlock(ach_id)

func reach_level(level: int) -> void:
	if level >= 10:
		unlock("level_novice")
	if level >= 30:
		unlock("level_veteran")
	if level >= 50:
		unlock("level_master")

func add_death() -> void:
	stats["death_count"] += 1

func start_ng_plus() -> void:
	stats["ng_plus_count"] += 1
	unlock("ng_plus")

func _check_kills_achievements() -> void:
	var kills = stats["total_kills"]
	if kills >= 100:
		unlock("kills_hunter")
	if kills >= 500:
		unlock("kills_slayer")
	if kills >= 1000:
		unlock("kills_legend")

func _on_enemy_killed() -> void:
	add_kill()

func _on_chapter_completed(chapter_id: String) -> void:
	complete_chapter(chapter_id)

## 스피드런/무사망 체크 (게임 종료 시)
func check_completion_achievements(play_time: float) -> void:
	stats["total_play_time"] = play_time

	# 스피드런 (2시간 이내)
	if play_time <= 7200.0:
		unlock("speed_run")

	# 무사망
	if stats["death_count"] == 0:
		unlock("no_death")

## Steam 업적 동기화
func _sync_steam_achievement(ach: AchievementData) -> void:
	# GodotSteam 플러그인이 있을 때만 동작
	if not Engine.has_singleton("Steam"):
		return
	# Steam.setAchievement(ach.steam_api_name)
	# Steam.storeStats()

## 저장/로드
func serialize() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(),
		"progress": progress.duplicate(),
		"stats": stats.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	if data.has("unlocked"):
		unlocked = data["unlocked"]
	if data.has("progress"):
		progress = data["progress"]
	if data.has("stats"):
		stats = data["stats"]

## 업적 목록 조회
func get_all_achievements() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	for ach in achievements.values():
		result.append(ach)
	return result

func get_unlocked_achievements() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	for id in unlocked:
		if achievements.has(id):
			result.append(achievements[id])
	return result

func is_unlocked(achievement_id: String) -> bool:
	return unlocked.has(achievement_id)

func get_progress(achievement_id: String) -> int:
	return progress.get(achievement_id, 0)

func get_completion_percentage() -> float:
	if achievements.is_empty():
		return 0.0
	return (float(unlocked.size()) / float(achievements.size())) * 100.0
