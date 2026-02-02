extends Node
class_name MapData
## MapData: 맵 메타데이터
##
## 각 맵 씬에 포함되어 맵 정보를 제공합니다.

# 맵 기본 정보
@export var map_id: String = ""
@export var map_name: String = ""
@export var chapter: int = 1

# 맵 크기
@export var map_width: int = 1280
@export var map_height: int = 800

# 배경음악
@export var bgm_path: String = ""

# 맵 타입
@export_enum("Field", "Dungeon", "Town", "Boss") var map_type: String = "Field"

# 연결된 맵들 (출구 -> 다음 맵)
@export var connections: Dictionary = {}  # {"exit_name": {"map": "path", "spawn": "point"}}

# 초기 이벤트 (맵 진입 시 실행)
@export var entry_events: Array[String] = []

# 적 웨이브 설정
@export var enemy_waves: Array[Dictionary] = []

## 경계 Rect2 반환
func get_bounds() -> Rect2:
	return Rect2(0, 0, map_width, map_height)

## 연결된 맵 정보 가져오기
func get_connection(exit_name: String) -> Dictionary:
	return connections.get(exit_name, {})

## 맵 타입 확인
func is_boss_map() -> bool:
	return map_type == "Boss"

func is_town() -> bool:
	return map_type == "Town"

func is_dungeon() -> bool:
	return map_type == "Dungeon"
