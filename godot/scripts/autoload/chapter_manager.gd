extends Node
## ChapterManager: 챕터 관리 시스템
##
## 챕터 데이터 로드, 챕터 진행, 스토리 관리를 담당합니다.

# 챕터 데이터 경로
const CHAPTER_DATA_PATH: String = "res://resources/chapters/"

# 현재 챕터 데이터 (타입 어노테이션 제거 - Autoload 로드 순서 이슈)
var current_chapter_data = null  # ChapterData
var chapters: Dictionary = {}  # chapter_id -> ChapterData

# 시그널
signal chapter_loaded(chapter_data)
signal chapter_started(chapter_id: int)
signal chapter_completed(chapter_id: int)

func _ready() -> void:
	_load_all_chapters()

## 모든 챕터 데이터 로드
func _load_all_chapters() -> void:
	for i in range(1, 4):  # 챕터 1-3
		var path = "%schapter_%d.tres" % [CHAPTER_DATA_PATH, i]
		var data = load(path)  # ChapterData
		if data:
			chapters[i] = data
			print("[ChapterManager] Loaded chapter %d: %s" % [i, data.chapter_name])

## 챕터 시작
func start_chapter(chapter_id: int) -> bool:
	if not chapters.has(chapter_id):
		push_error("Chapter not found: " + str(chapter_id))
		return false

	current_chapter_data = chapters[chapter_id]
	chapter_loaded.emit(current_chapter_data)

	# ProgressionSystem 업데이트
	if has_node("/root/ProgressionSystem"):
		get_node("/root/ProgressionSystem").change_chapter(chapter_id)

	# 첫 번째 맵 로드
	var first_map = current_chapter_data.get_first_map()
	if not first_map.is_empty():
		_load_map(first_map)

	# 인트로 대화 실행
	if not current_chapter_data.intro_dialogue.is_empty():
		_start_dialogue(current_chapter_data.intro_dialogue)

	chapter_started.emit(chapter_id)
	return true

## 맵 로드 (MapManager 연동)
func _load_map(map_path: String) -> void:
	# 씬 전환
	get_tree().change_scene_to_file(map_path)

## 대화 시작 (DialogueSystem 연동)
func _start_dialogue(dialogue_path: String) -> void:
	if has_node("/root/DialogueSystem"):
		get_node("/root/DialogueSystem").load_and_start(dialogue_path)

## 현재 챕터의 다음 맵으로 이동
func advance_to_next_map() -> bool:
	if current_chapter_data == null:
		return false

	var progression = get_node("/root/ProgressionSystem") if has_node("/root/ProgressionSystem") else null
	if progression == null:
		return false

	var next_map = current_chapter_data.get_next_map(progression.current_map)
	if next_map.is_empty():
		return false

	_load_map(next_map)
	return true

## 챕터 완료 처리
func complete_chapter(chapter_id: int) -> void:
	chapter_completed.emit(chapter_id)

	# 아웃트로 대화
	if current_chapter_data and not current_chapter_data.outro_dialogue.is_empty():
		await _start_dialogue(current_chapter_data.outro_dialogue)

	# 다음 챕터로 자동 진행 (3챕터까지)
	if chapter_id < 3:
		start_chapter(chapter_id + 1)
	else:
		print("[ChapterManager] All chapters completed!")
		# 엔딩 씬으로 전환
		# get_tree().change_scene_to_file("res://scenes/ending.tscn")

## 챕터 데이터 가져오기
func get_chapter_data(chapter_id: int):
	return chapters.get(chapter_id, null)

## 현재 챕터 데이터
func get_current_chapter():
	return current_chapter_data

## 새 게임 시작
func start_new_game() -> void:
	# ProgressionSystem 리셋
	if has_node("/root/ProgressionSystem"):
		get_node("/root/ProgressionSystem").reset()

	# GameManager 리셋
	GameManager.reset_game()

	# 챕터 1 시작
	start_chapter(1)

## 계속하기 (세이브에서)
func continue_game() -> void:
	if has_node("/root/ProgressionSystem"):
		var progression = get_node("/root/ProgressionSystem")
		var chapter_id = progression.current_chapter
		var current_map = progression.current_map

		# 챕터 데이터 로드
		if chapters.has(chapter_id):
			current_chapter_data = chapters[chapter_id]
			chapter_loaded.emit(current_chapter_data)

		# 저장된 맵으로 이동
		if not current_map.is_empty():
			_load_map(current_map)
		else:
			# 맵 정보 없으면 챕터 첫 맵으로
			start_chapter(chapter_id)
