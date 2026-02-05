extends Node
class_name EnvironmentSystem

## 환경 효과 시스템
## 지형 타입에 따른 상태 이상 및 능력치 디버프 관리

const StatusEffectDatabase = preload("res://scripts/systems/status_effect_database.gd")

enum TerrainType {
	NORMAL,   # 일반 지형 (효과 없음)
	WATER,    # 물 (이동속도 -30%)
	COLD,     # 한랭 (피로도 누적 +50%)
	DARK,     # 어둠 (감지 범위 -50%)
	POISON,   # 독 지대 (독 상태이상)
	FIRE      # 화염 (화상 상태이상)
}

# 현재 맵의 지형 영역 (Area2D 기반)
var terrain_zones: Array[Dictionary] = []  # [{area: Area2D, type: TerrainType, modifier: Dictionary}]

# 참조 (타입 명시하지 않음 - 런타임에 설정)
var status_effect_system = null

# 지형 디버프 적용 상태 추적 (status effect와 별개로 직접 관리)
var terrain_debuffs: Dictionary = {}  # unit_id -> {debuff_id -> modifier}

# 시그널
signal terrain_entered(unit, terrain_type: TerrainType)
signal terrain_exited(unit, terrain_type: TerrainType)

## 초기화
func init(ses) -> void:
	status_effect_system = ses
	terrain_zones.clear()
	terrain_debuffs.clear()
	print("[EnvironmentSystem] Initialized")

## 지형 영역 등록
func register_terrain_zone(area: Area2D, terrain_type: TerrainType, modifier: Dictionary = {}) -> void:
	if not area:
		push_error("[EnvironmentSystem] Cannot register null area")
		return

	var zone_data := {
		"area": area,
		"type": terrain_type,
		"modifier": modifier
	}
	terrain_zones.append(zone_data)

	# 시그널 연결
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered.bind(terrain_type, modifier))
	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited.bind(terrain_type))

	print("[EnvironmentSystem] Registered terrain zone: ", TerrainType.keys()[terrain_type])

## 지형 영역 등록 해제
func unregister_terrain_zone(area: Area2D) -> void:
	for i in range(terrain_zones.size() - 1, -1, -1):
		if terrain_zones[i].area == area:
			if area.body_entered.is_connected(_on_body_entered):
				area.body_entered.disconnect(_on_body_entered)
			if area.body_exited.is_connected(_on_body_exited):
				area.body_exited.disconnect(_on_body_exited)
			terrain_zones.remove_at(i)
			print("[EnvironmentSystem] Unregistered terrain zone")
			break

## 모든 지형 영역 초기화
func clear_terrain_zones() -> void:
	for zone in terrain_zones:
		var area: Area2D = zone.area
		if area and area.body_entered.is_connected(_on_body_entered):
			area.body_entered.disconnect(_on_body_entered)
		if area and area.body_exited.is_connected(_on_body_exited):
			area.body_exited.disconnect(_on_body_exited)
	terrain_zones.clear()
	terrain_debuffs.clear()
	print("[EnvironmentSystem] Cleared all terrain zones")

## 지형 진입 시
func _on_body_entered(body: Node2D, terrain_type: TerrainType, modifier: Dictionary) -> void:
	if not body.is_in_group("units"):
		return

	terrain_entered.emit(body, terrain_type)

	match terrain_type:
		TerrainType.WATER:
			# 이동속도 -30%
			var speed_mod: float = modifier.get("speed_modifier", 0.7)
			_apply_terrain_debuff(body, "water_slow", {"speed_modifier": speed_mod})
			print("[EnvironmentSystem] Unit entered WATER: speed x", speed_mod)

		TerrainType.COLD:
			# 피로도 누적 +50%
			var fatigue_mult: float = modifier.get("fatigue_multiplier", 1.5)
			_apply_terrain_debuff(body, "cold_fatigue", {"fatigue_multiplier": fatigue_mult})
			print("[EnvironmentSystem] Unit entered COLD: fatigue x", fatigue_mult)

		TerrainType.DARK:
			# 감지 범위 -50%
			var detection_mod: float = modifier.get("detection_modifier", 0.5)
			_apply_terrain_debuff(body, "darkness", {"detection_modifier": detection_mod})
			print("[EnvironmentSystem] Unit entered DARK: detection x", detection_mod)

		TerrainType.POISON:
			# 독 상태이상 적용
			if status_effect_system:
				var poison_effect = StatusEffectDatabase.create_effect("poison")
				if poison_effect:
					status_effect_system.apply_effect(body, poison_effect)
					print("[EnvironmentSystem] Unit entered POISON: applied poison effect")

		TerrainType.FIRE:
			# 화상 상태이상 적용
			if status_effect_system:
				var burn_effect = StatusEffectDatabase.create_effect("burn")
				if burn_effect:
					status_effect_system.apply_effect(body, burn_effect)
					print("[EnvironmentSystem] Unit entered FIRE: applied burn effect")

		TerrainType.NORMAL:
			# 효과 없음
			pass

## 지형 이탈 시
func _on_body_exited(body: Node2D, terrain_type: TerrainType) -> void:
	if not body.is_in_group("units"):
		return

	terrain_exited.emit(body, terrain_type)
	_remove_terrain_debuff(body, terrain_type)
	print("[EnvironmentSystem] Unit exited ", TerrainType.keys()[terrain_type])

## 지형 디버프 적용
func _apply_terrain_debuff(unit: Node, debuff_id: String, modifier: Dictionary) -> void:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		terrain_debuffs[uid] = {}
	terrain_debuffs[uid][debuff_id] = modifier

## 지형 디버프 제거
func _remove_terrain_debuff(unit: Node, terrain_type: TerrainType) -> void:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		return

	# 지형 타입별 디버프 ID 매핑
	var debuff_id := ""
	match terrain_type:
		TerrainType.WATER:
			debuff_id = "water_slow"
		TerrainType.COLD:
			debuff_id = "cold_fatigue"
		TerrainType.DARK:
			debuff_id = "darkness"
		_:
			return

	if terrain_debuffs[uid].has(debuff_id):
		terrain_debuffs[uid].erase(debuff_id)
		if terrain_debuffs[uid].is_empty():
			terrain_debuffs.erase(uid)

## 특정 유닛의 모든 지형 디버프 제거 (유닛 제거 시 호출)
func clear_unit_debuffs(unit: Node) -> void:
	var uid := unit.get_instance_id()
	if terrain_debuffs.has(uid):
		terrain_debuffs.erase(uid)

## 속도 배율 가져오기 (물 지형 효과)
func get_speed_modifier(unit: Node) -> float:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		return 1.0

	var modifiers: Dictionary = terrain_debuffs[uid]
	if modifiers.has("water_slow"):
		var water_slow: Dictionary = modifiers["water_slow"]
		return water_slow.get("speed_modifier", 1.0)

	return 1.0

## 피로도 배율 가져오기 (한랭 지형 효과)
func get_fatigue_multiplier(unit: Node) -> float:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		return 1.0

	var modifiers: Dictionary = terrain_debuffs[uid]
	if modifiers.has("cold_fatigue"):
		var cold_fatigue: Dictionary = modifiers["cold_fatigue"]
		return cold_fatigue.get("fatigue_multiplier", 1.0)

	return 1.0

## 감지 범위 배율 가져오기 (어둠 지형 효과)
func get_detection_modifier(unit: Node) -> float:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		return 1.0

	var modifiers: Dictionary = terrain_debuffs[uid]
	if modifiers.has("darkness"):
		var darkness: Dictionary = modifiers["darkness"]
		return darkness.get("detection_modifier", 1.0)

	return 1.0

## 유닛이 특정 지형에 있는지 확인
func is_unit_in_terrain(unit: Node, terrain_type: TerrainType) -> bool:
	var uid := unit.get_instance_id()
	if not terrain_debuffs.has(uid):
		return false

	var debuff_id := ""
	match terrain_type:
		TerrainType.WATER:
			debuff_id = "water_slow"
		TerrainType.COLD:
			debuff_id = "cold_fatigue"
		TerrainType.DARK:
			debuff_id = "darkness"
		_:
			return false

	return terrain_debuffs[uid].has(debuff_id)

## 디버그 정보 출력
func get_debug_info() -> Dictionary:
	return {
		"terrain_zones_count": terrain_zones.size(),
		"affected_units_count": terrain_debuffs.size(),
		"terrain_debuffs": terrain_debuffs
	}
