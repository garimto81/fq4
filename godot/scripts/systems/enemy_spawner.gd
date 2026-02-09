extends Node
class_name EnemySpawner

## EnemySpawner
## MapData의 enemy_spawns 정보를 읽어 적 유닛을 스폰하는 시스템

# 적 프리팹 캐시
var enemy_prefabs: Dictionary = {}  # enemy_id -> PackedScene

# 적 데이터 캐시
var enemy_data_cache: Dictionary = {}  # enemy_id -> EnemyData

# 스폰된 적 추적
var spawned_enemies: Array[Node] = []
var active_enemies: Array[Node] = []

# 참조
var combat_system: CombatSystem = null

# 시그널
signal enemy_spawned(enemy: Node)
signal boss_spawned(boss: Node)
signal all_enemies_defeated

## 초기화
func init(cs: CombatSystem) -> void:
	combat_system = cs
	print("[EnemySpawner] Initialized")

## 맵 데이터 기반 스폰
func spawn_from_map_data(map_data: MapData) -> void:
	if not map_data:
		push_error("[EnemySpawner] MapData is null")
		return

	clear_spawned_enemies()

	# enemy_spawns 처리
	var spawn_list = map_data.get_enemy_spawns()
	if spawn_list.is_empty():
		print("[EnemySpawner] No enemy spawns defined in MapData")
		return

	print("[EnemySpawner] Spawning %d enemy groups from MapData" % spawn_list.size())

	for spawn_info in spawn_list:
		var enemy_id = spawn_info.get("enemy_id", "goblin")
		var position = spawn_info.get("position", Vector2.ZERO)
		var count = spawn_info.get("count", 1)
		var is_boss = spawn_info.get("is_boss", false)
		var patrol_path = spawn_info.get("patrol_path", [])

		for i in range(count):
			# 스폰 위치에 약간의 랜덤 오프셋 추가 (겹침 방지)
			var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			var spawn_pos = position + offset

			var enemy: Node = null
			if is_boss:
				enemy = spawn_boss(enemy_id, spawn_pos)
			else:
				enemy = spawn_enemy(enemy_id, spawn_pos)

			# 패트롤 경로 설정
			if enemy and not patrol_path.is_empty() and enemy.has_method("set_patrol_path"):
				enemy.set_patrol_path(patrol_path)

	print("[EnemySpawner] Spawned %d enemies total" % spawned_enemies.size())

## 일반 적 스폰
func spawn_enemy(enemy_id: String, position: Vector2) -> Node:
	# EnemyData 로드
	var enemy_data = _load_enemy_data(enemy_id)
	if not enemy_data:
		push_error("[EnemySpawner] Failed to load EnemyData for: %s" % enemy_id)
		return null

	# EnemyUnit 인스턴스 생성
	var enemy_scene = _load_enemy_prefab(enemy_id)
	if not enemy_scene:
		push_error("[EnemySpawner] Failed to load enemy prefab for: %s" % enemy_id)
		return null

	var enemy = enemy_scene.instantiate()
	if not enemy:
		push_error("[EnemySpawner] Failed to instantiate enemy: %s" % enemy_id)
		return null

	# 위치 설정
	enemy.position = position

	# EnemyData 적용 (EnemyUnit이 init_from_data 메서드를 가지고 있다고 가정)
	if enemy.has_method("init_from_data"):
		enemy.init_from_data(enemy_data)

	# CombatSystem 주입
	if combat_system and enemy.has_method("set_combat_system"):
		enemy.set_combat_system(combat_system)

	# 씬에 추가
	get_tree().current_scene.add_child(enemy)

	# GameManager에 등록
	if GameManager:
		GameManager.register_unit(enemy, false)

	# 추적 목록에 추가
	spawned_enemies.append(enemy)
	active_enemies.append(enemy)

	# 사망 시그널 연결
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	elif enemy.has_signal("unit_died"):
		enemy.unit_died.connect(_on_enemy_died.bind(enemy))

	enemy_spawned.emit(enemy)

	print("[EnemySpawner] Spawned enemy: %s at %s" % [enemy_id, position])
	return enemy

## 보스 스폰
func spawn_boss(boss_id: String, position: Vector2) -> Node:
	var boss = spawn_enemy(boss_id, position)
	if boss:
		# 보스 마커 추가 (체력바 UI 등)
		if boss.has_method("set_is_boss"):
			boss.set_is_boss(true)

		boss_spawned.emit(boss)
		print("[EnemySpawner] Spawned BOSS: %s at %s" % [boss_id, position])

	return boss

## 특정 위치에 웨이브 스폰
func spawn_wave(enemy_id: String, positions: Array, wave_index: int = 0) -> void:
	print("[EnemySpawner] Spawning wave %d with %d enemies" % [wave_index, positions.size()])

	for pos in positions:
		spawn_enemy(enemy_id, pos)

## 스폰된 모든 적 제거
func clear_spawned_enemies() -> void:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			# GameManager에서 등록 해제
			if GameManager:
				GameManager.unregister_unit(enemy)

			enemy.queue_free()

	spawned_enemies.clear()
	active_enemies.clear()
	print("[EnemySpawner] Cleared all spawned enemies")

## 활성 적 수 반환
func get_active_enemy_count() -> int:
	return active_enemies.size()

## 모든 적이 처치되었는지 확인
func are_all_enemies_defeated() -> bool:
	return active_enemies.is_empty()

## 적 프리팹 로드 (캐싱)
func _load_enemy_prefab(enemy_id: String) -> PackedScene:
	# 캐시 확인
	if enemy_prefabs.has(enemy_id):
		return enemy_prefabs[enemy_id]

	# 프리팹 경로 구성
	var prefab_path = "res://scenes/units/enemies/%s.tscn" % enemy_id

	# 파일 존재 확인
	if not FileAccess.file_exists(prefab_path):
		push_warning("[EnemySpawner] Enemy prefab not found: %s, using fallback" % prefab_path)
		# 폴백: 기본 EnemyUnit 씬 사용
		prefab_path = "res://scenes/units/enemy_unit.tscn"

		if not FileAccess.file_exists(prefab_path):
			push_error("[EnemySpawner] Fallback prefab not found: %s" % prefab_path)
			return null

	# 리소스 로드
	var prefab = load(prefab_path)
	if not prefab:
		push_error("[EnemySpawner] Failed to load prefab: %s" % prefab_path)
		return null

	# 캐싱
	enemy_prefabs[enemy_id] = prefab
	return prefab

## EnemyData 로드 (캐싱)
func _load_enemy_data(enemy_id: String) -> Resource:
	# 캐시 확인
	if enemy_data_cache.has(enemy_id):
		return enemy_data_cache[enemy_id]

	# 데이터 경로 구성
	var data_path = "res://resources/enemies/%s.tres" % enemy_id

	# 파일 존재 확인
	if not FileAccess.file_exists(data_path):
		push_warning("[EnemySpawner] EnemyData not found: %s" % data_path)
		return null

	# 리소스 로드
	var data = load(data_path)
	if not data:
		push_error("[EnemySpawner] Failed to load EnemyData: %s" % data_path)
		return null

	# 캐싱
	enemy_data_cache[enemy_id] = data
	return data

## 적 사망 처리
func _on_enemy_died(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return

	# 활성 목록에서 제거
	var idx = active_enemies.find(enemy)
	if idx >= 0:
		active_enemies.remove_at(idx)

	print("[EnemySpawner] Enemy died. Remaining: %d" % active_enemies.size())

	# 모든 적 처치 확인
	if active_enemies.is_empty():
		print("[EnemySpawner] All enemies defeated!")
		all_enemies_defeated.emit()

## 디버그: 스폰 정보 출력
func debug_print_spawn_info() -> void:
	print("[EnemySpawner] === Spawn Info ===")
	print("  Total Spawned: %d" % spawned_enemies.size())
	print("  Active Enemies: %d" % active_enemies.size())
	print("  Cached Prefabs: %d" % enemy_prefabs.size())
	print("  Cached Data: %d" % enemy_data_cache.size())
