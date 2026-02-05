extends Node
class_name SteamManagerNode
## Steam 연동 매니저 (GodotSteam 플러그인 준비)
##
## GodotSteam 설치 후 활성화됩니다.
## https://godotsteam.com/

# Steam App ID (출시 시 실제 ID로 교체)
const STEAM_APP_ID: int = 480  # Spacewar 테스트용

# Steam 상태
var is_steam_running: bool = false
var steam_id: int = 0
var persona_name: String = ""

# 시그널
signal steam_initialized(success: bool)
signal overlay_toggled(active: bool)

func _ready() -> void:
	_initialize_steam()

func _initialize_steam() -> void:
	# GodotSteam 플러그인 확인
	if not Engine.has_singleton("Steam"):
		print("[Steam] GodotSteam not installed. Running in offline mode.")
		is_steam_running = false
		steam_initialized.emit(false)
		return

	# Steam 초기화는 GodotSteam 설치 후 주석 해제
	# var init_result = Steam.steamInit()
	# is_steam_running = init_result["status"] == 1
	#
	# if is_steam_running:
	#     steam_id = Steam.getSteamID()
	#     persona_name = Steam.getPersonaName()
	#     Steam.overlay_toggled.connect(_on_overlay_toggled)
	#     print("[Steam] Initialized: %s (ID: %d)" % [persona_name, steam_id])
	# else:
	#     print("[Steam] Failed to initialize: %s" % init_result["verbal"])

	is_steam_running = false
	steam_initialized.emit(false)

func _process(_delta: float) -> void:
	if is_steam_running:
		# Steam.run_callbacks()
		pass

## 업적 해금
func unlock_achievement(api_name: String) -> bool:
	if not is_steam_running:
		return false

	# Steam.setAchievement(api_name)
	# Steam.storeStats()
	print("[Steam] Achievement unlocked (simulated): %s" % api_name)
	return true

## 업적 진행도 설정
func set_achievement_progress(api_name: String, current: int, max_value: int) -> void:
	if not is_steam_running:
		return

	# Steam.indicateAchievementProgress(api_name, current, max_value)
	pass

## 업적 초기화 (디버그용)
func clear_achievement(api_name: String) -> void:
	if not is_steam_running:
		return

	# Steam.clearAchievement(api_name)
	# Steam.storeStats()
	pass

## 리더보드 점수 등록
func submit_score(leaderboard_name: String, score: int) -> void:
	if not is_steam_running:
		return

	# var handle = Steam.findLeaderboard(leaderboard_name)
	# Steam.uploadLeaderboardScore(score, true, [])
	print("[Steam] Score submitted (simulated): %s = %d" % [leaderboard_name, score])

## 리치 프레즌스 업데이트
func set_rich_presence(key: String, value: String) -> void:
	if not is_steam_running:
		return

	# Steam.setRichPresence(key, value)
	pass

## 현재 챕터 리치 프레즌스
func update_chapter_presence(chapter: int, chapter_name: String) -> void:
	set_rich_presence("steam_display", "#Playing")
	set_rich_presence("chapter", "Chapter %d: %s" % [chapter, chapter_name])

## 오버레이 토글 콜백
func _on_overlay_toggled(active: bool) -> void:
	overlay_toggled.emit(active)
	# 오버레이 활성화 시 게임 일시정지 (선택사항)
	# get_tree().paused = active

## Steam 클라우드 저장
func save_to_cloud(filename: String, data: PackedByteArray) -> bool:
	if not is_steam_running:
		return false

	# return Steam.fileWrite(filename, data)
	return false

## Steam 클라우드 로드
func load_from_cloud(filename: String) -> PackedByteArray:
	if not is_steam_running:
		return PackedByteArray()

	# if Steam.fileExists(filename):
	#     return Steam.fileRead(filename, Steam.getFileSize(filename))
	return PackedByteArray()

## 워크샵 아이템 업로드 준비 (향후 확장)
func prepare_workshop_item() -> void:
	if not is_steam_running:
		return
	# 워크샵 기능은 향후 모드 지원 시 구현
	pass

## 종료 처리
func _exit_tree() -> void:
	if is_steam_running:
		# Steam.steamShutdown()
		pass
