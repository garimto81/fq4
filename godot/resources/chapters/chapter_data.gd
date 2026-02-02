extends Resource
class_name ChapterData
## ChapterData: 챕터 데이터 리소스
##
## 챕터별 정보, 맵 목록, 스토리 정보를 포함합니다.

# 챕터 기본 정보
@export var chapter_id: int = 1
@export var chapter_name: String = ""
@export var chapter_subtitle: String = ""
@export_multiline var description: String = ""

# 맵 목록 (순서대로)
@export var maps: Array[String] = []  # 맵 씬 경로

# 시작/종료 이벤트
@export var intro_dialogue: String = ""  # 챕터 시작 대화
@export var outro_dialogue: String = ""  # 챕터 종료 대화

# 클리어 조건
@export var clear_flags: Array[String] = []

# 보스 정보
@export var boss_map: String = ""
@export var boss_enemy_id: String = ""

# 배경 음악
@export var bgm_path: String = ""

## 첫 번째 맵 경로
func get_first_map() -> String:
	if maps.is_empty():
		return ""
	return maps[0]

## 보스 맵 여부
func has_boss() -> bool:
	return not boss_map.is_empty()

## 맵 인덱스
func get_map_index(map_path: String) -> int:
	return maps.find(map_path)

## 다음 맵
func get_next_map(current_map: String) -> String:
	var idx = get_map_index(current_map)
	if idx < 0 or idx >= maps.size() - 1:
		return ""
	return maps[idx + 1]
