extends Node
class_name MapManager
## MapManager: 맵 로딩/전환 관리
##
## 타일맵 연동, 충돌 레이어, 맵 전환 이펙트를 처리합니다.

# 맵 경로 상수
const MAP_BASE_PATH: String = "res://scenes/maps/"

# 현재 맵 정보
var current_map_scene: Node = null
var current_map_data: MapData = null
var is_transitioning: bool = false

# 충돌 레이어 정의
enum CollisionLayer {
	WORLD = 1,       # 벽, 지형
	PLAYER = 2,      # 플레이어 유닛
	ENEMY = 4,       # 적 유닛
	TRIGGER = 8,     # 이벤트 트리거
	PROJECTILE = 16  # 투사체
}

# 시그널
signal map_loading_started(map_name: String)
signal map_loaded(map_name: String)
signal map_transition_started(from_map: String, to_map: String)
signal map_transition_completed(to_map: String)
signal spawn_point_reached(spawn_id: String)

## 맵 로드 (씬 경로로)
func load_map(map_path: String, spawn_point: String = "default") -> bool:
	if is_transitioning:
		push_warning("Map transition already in progress")
		return false

	is_transitioning = true
	var old_map = current_map_data.map_id if current_map_data else ""

	map_loading_started.emit(map_path)

	# 기존 맵 정리
	if current_map_scene:
		current_map_scene.queue_free()
		current_map_scene = null

	# 새 맵 로드
	var scene = load(map_path)
	if scene == null:
		push_error("Failed to load map: " + map_path)
		is_transitioning = false
		return false

	current_map_scene = scene.instantiate()
	get_tree().current_scene.add_child(current_map_scene)

	# MapData 찾기
	if current_map_scene.has_node("MapData"):
		current_map_data = current_map_scene.get_node("MapData")

	# 스폰 포인트로 플레이어 이동
	_move_players_to_spawn(spawn_point)

	map_loaded.emit(map_path)
	map_transition_completed.emit(map_path)

	# ProgressionSystem 업데이트
	if has_node("/root/ProgressionSystem"):
		var progression = get_node("/root/ProgressionSystem")
		progression.change_map(map_path)

	is_transitioning = false
	return true

## 챕터/맵 ID로 로드
func load_map_by_id(chapter: int, map_id: String, spawn_point: String = "default") -> bool:
	var map_path = "%schapter%d/%s.tscn" % [MAP_BASE_PATH, chapter, map_id]
	return load_map(map_path, spawn_point)

## 맵 전환 (페이드 효과 포함)
func transition_to_map(map_path: String, spawn_point: String = "default",
		fade_duration: float = 0.5) -> void:
	if is_transitioning:
		return

	var old_map = current_map_data.map_id if current_map_data else ""
	map_transition_started.emit(old_map, map_path)

	# 페이드 아웃
	var tween = create_tween()
	var fade_rect = _get_or_create_fade_rect()
	fade_rect.visible = true
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished

	# 맵 로드
	load_map(map_path, spawn_point)

	# 페이드 인
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	fade_rect.visible = false

## 스폰 포인트로 플레이어 이동
func _move_players_to_spawn(spawn_id: String) -> void:
	if not current_map_scene:
		return

	# SpawnPoints 노드 찾기
	var spawn_points = current_map_scene.get_node_or_null("SpawnPoints")
	if not spawn_points:
		return

	# 해당 스폰 포인트 찾기
	var spawn_point = spawn_points.get_node_or_null(spawn_id)
	if not spawn_point:
		# default로 폴백
		spawn_point = spawn_points.get_node_or_null("default")

	if not spawn_point:
		return

	# 플레이어 유닛들 이동
	var spawn_pos = spawn_point.global_position
	var offset = Vector2.ZERO

	for unit in GameManager.player_units:
		unit.global_position = spawn_pos + offset
		offset += Vector2(50, 0)  # 유닛 간격

	spawn_point_reached.emit(spawn_id)

## 페이드 효과용 ColorRect 생성
func _get_or_create_fade_rect() -> ColorRect:
	var canvas = get_tree().current_scene.get_node_or_null("FadeCanvas")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "FadeCanvas"
		canvas.layer = 100
		get_tree().current_scene.add_child(canvas)

	var fade_rect = canvas.get_node_or_null("FadeRect")
	if not fade_rect:
		fade_rect = ColorRect.new()
		fade_rect.name = "FadeRect"
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(fade_rect)

	return fade_rect

## 현재 맵의 적 스폰
func spawn_enemies() -> void:
	if not current_map_scene:
		return

	var enemy_spawns = current_map_scene.get_node_or_null("EnemySpawns")
	if not enemy_spawns:
		return

	for spawn_point in enemy_spawns.get_children():
		if spawn_point is Marker2D and spawn_point.has_meta("enemy_id"):
			_spawn_enemy_at(spawn_point)

## 적 스폰 처리
func _spawn_enemy_at(spawn_point: Marker2D) -> void:
	var enemy_id = spawn_point.get_meta("enemy_id", "goblin")
	var enemy_scene = load("res://scenes/units/enemies/%s.tscn" % enemy_id)

	if enemy_scene == null:
		# 기본 적 씬 사용
		enemy_scene = load("res://scenes/units/enemy_unit.tscn")

	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_point.global_position
		current_map_scene.add_child(enemy)
		GameManager.register_unit(enemy, false)

## 트리거 영역 체크
func check_triggers(unit_position: Vector2) -> Array[String]:
	var triggered: Array[String] = []

	if not current_map_scene:
		return triggered

	var triggers = current_map_scene.get_node_or_null("Triggers")
	if not triggers:
		return triggered

	for trigger in triggers.get_children():
		if trigger is Area2D:
			# 간단한 거리 체크 (실제로는 Area2D 시그널 사용)
			var trigger_pos = trigger.global_position
			if unit_position.distance_to(trigger_pos) < 50:
				triggered.append(trigger.name)

	return triggered

## 맵 경계 가져오기
func get_map_bounds() -> Rect2:
	if current_map_data:
		return current_map_data.get_bounds()

	# 기본값
	return Rect2(0, 0, 1280, 800)

## 맵 데이터 가져오기
func get_current_map_data() -> MapData:
	return current_map_data
