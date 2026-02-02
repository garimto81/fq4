extends Node2D
class_name UnitSpawner
## UnitSpawner: 유닛 동적 생성 시스템
##
## 플레이어, AI 유닛, 적 유닛을 동적으로 생성하고 배치합니다.

# 유닛 프리팹 경로
const PLAYER_UNIT_SCENE = "res://scenes/units/player_unit.tscn"
const AI_UNIT_SCENE = "res://scenes/units/ai_unit.tscn"
const ENEMY_UNIT_SCENE = "res://scenes/units/enemy_unit.tscn"

# 스폰 설정
@export var spawn_area_size: Vector2 = Vector2(400, 300)
@export var unit_spacing: float = 50.0

# 유닛 이름 풀
var player_names = ["Arthur", "Lancelot", "Gawain", "Percival", "Galahad",
					"Tristan", "Bors", "Kay", "Bedivere", "Lamorak"]
var enemy_names = ["Goblin", "Orc", "Troll", "Skeleton", "Zombie",
				   "Bandit", "Assassin", "Dark Knight", "Demon", "Dragon"]

# 성격 풀
var personalities = [
	AIUnit.Personality.AGGRESSIVE,
	AIUnit.Personality.DEFENSIVE,
	AIUnit.Personality.BALANCED
]

## 플레이어 부대 생성
func spawn_player_squad(squad_id: int, count: int, start_position: Vector2, is_player_team: bool = true) -> Array:
	var spawned_units: Array = []
	var leader: Node = null

	for i in range(count):
		var unit: Node
		var spawn_pos = _calculate_squad_position(start_position, i, count)

		if i == 0:
			# 첫 번째 유닛은 리더 (플레이어 조작 가능)
			unit = _spawn_ai_unit(spawn_pos, is_player_team)
			leader = unit
		else:
			# 나머지는 AI 유닛
			unit = _spawn_ai_unit(spawn_pos, is_player_team)

		# 유닛 설정
		unit.unit_name = player_names[i % player_names.size()] if is_player_team else enemy_names[i % enemy_names.size()]

		# 성격 다양화
		if unit.has_method("set_squad_info"):
			unit.personality = personalities[i % personalities.size()]

		# 부대 등록
		GameManager.add_unit_to_squad(unit, squad_id)
		spawned_units.append(unit)

	# 리더 설정
	if leader:
		GameManager.set_squad_leader(squad_id, leader)

	return spawned_units

## 적 부대 생성
func spawn_enemy_squad(squad_id: int, count: int, start_position: Vector2) -> Array:
	var spawned_units: Array = []

	for i in range(count):
		var spawn_pos = _calculate_squad_position(start_position, i, count)
		var unit = _spawn_enemy_unit(spawn_pos)

		unit.unit_name = enemy_names[i % enemy_names.size()] + " " + str(i + 1)

		spawned_units.append(unit)

	return spawned_units

## AI 유닛 스폰
func _spawn_ai_unit(pos: Vector2, is_player_team: bool) -> Node:
	var unit = _create_unit_node("AIUnit")
	unit.global_position = pos

	if is_player_team:
		GameManager.register_unit(unit, true)
	else:
		GameManager.register_unit(unit, false)

	get_parent().add_child(unit)
	return unit

## 적 유닛 스폰
func _spawn_enemy_unit(pos: Vector2) -> Node:
	var unit = _create_unit_node("EnemyUnit")
	unit.global_position = pos
	GameManager.register_unit(unit, false)
	get_parent().add_child(unit)
	return unit

## 유닛 노드 생성 (프리팹 없이 코드로 생성)
func _create_unit_node(unit_type: String) -> Node:
	var unit: CharacterBody2D

	match unit_type:
		"AIUnit":
			unit = AIUnit.new()
		"EnemyUnit":
			unit = EnemyUnit.new()
		_:
			unit = Unit.new()

	# 기본 시각적 표현 추가
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)

	if unit_type == "EnemyUnit":
		sprite.color = Color.RED
	else:
		sprite.color = Color.BLUE

	unit.add_child(sprite)

	# 선택 표시기
	var selection_indicator = ColorRect.new()
	selection_indicator.name = "SelectionIndicator"
	selection_indicator.size = Vector2(20, 20)
	selection_indicator.position = Vector2(-10, -10)
	selection_indicator.color = Color(1, 1, 0, 0.5)
	selection_indicator.visible = false
	unit.add_child(selection_indicator)

	# 충돌 영역 추가
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	unit.add_child(collision)

	return unit

## 부대 대형 위치 계산
func _calculate_squad_position(base_pos: Vector2, index: int, total: int) -> Vector2:
	# 3x3 그리드 배치
	var cols = 3
	var row = index / cols
	var col = index % cols

	# 중앙 정렬
	var offset_x = (col - 1) * unit_spacing
	var offset_y = row * unit_spacing

	return base_pos + Vector2(offset_x, offset_y)

## 랜덤 위치에 유닛 스폰
func spawn_random_units(count: int, is_player_team: bool, area_center: Vector2) -> Array:
	var spawned: Array = []

	for i in range(count):
		var random_offset = Vector2(
			randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
			randf_range(-spawn_area_size.y / 2, spawn_area_size.y / 2)
		)
		var spawn_pos = area_center + random_offset

		var unit: Node
		if is_player_team:
			unit = _spawn_ai_unit(spawn_pos, true)
			unit.unit_name = player_names[i % player_names.size()]
		else:
			unit = _spawn_enemy_unit(spawn_pos)
			unit.unit_name = enemy_names[i % enemy_names.size()]

		spawned.append(unit)

	return spawned
