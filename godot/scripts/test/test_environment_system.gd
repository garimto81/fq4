extends Node2D

## EnvironmentSystem 테스트 스크립트
## 각 지형 영역을 등록하고 유닛 이동 시 효과 확인

const EnvironmentSystem = preload("res://scripts/systems/environment_system.gd")

@onready var status_effect_system = $StatusEffectSystem
@onready var environment_system = $EnvironmentSystem

@onready var water_zone = $WaterZone
@onready var cold_zone = $ColdZone
@onready var dark_zone = $DarkZone
@onready var poison_zone = $PoisonZone
@onready var fire_zone = $FireZone

@onready var test_unit = $TestUnit

var move_speed := 200.0
var current_terrain_info := ""

func _ready() -> void:
	print("\n=== EnvironmentSystem Test Started ===\n")

	# 시스템 초기화
	environment_system.init(status_effect_system)

	# 지형 영역 등록
	environment_system.register_terrain_zone(water_zone, EnvironmentSystem.TerrainType.WATER)
	environment_system.register_terrain_zone(cold_zone, EnvironmentSystem.TerrainType.COLD)
	environment_system.register_terrain_zone(dark_zone, EnvironmentSystem.TerrainType.DARK)
	environment_system.register_terrain_zone(poison_zone, EnvironmentSystem.TerrainType.POISON)
	environment_system.register_terrain_zone(fire_zone, EnvironmentSystem.TerrainType.FIRE)

	# 시그널 연결
	environment_system.terrain_entered.connect(_on_terrain_entered)
	environment_system.terrain_exited.connect(_on_terrain_exited)

	print("Registered 5 terrain zones")
	print("Use WASD to move test unit")
	print("Current terrain effects will be displayed\n")

func _process(delta: float) -> void:
	# 유닛 이동 (WASD)
	var velocity := Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		velocity.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		velocity.x += 1

	if velocity.length() > 0:
		velocity = velocity.normalized()
		var speed_modifier: float = environment_system.get_speed_modifier(test_unit)
		test_unit.velocity = velocity * move_speed * speed_modifier
		test_unit.move_and_slide()

func _on_terrain_entered(unit: Node, terrain_type) -> void:
	if unit != test_unit:
		return

	var terrain_name: String = EnvironmentSystem.TerrainType.keys()[terrain_type]
	print("\n[Terrain Entered] ", terrain_name)

	match terrain_type:
		EnvironmentSystem.TerrainType.WATER:
			var speed_mod: float = environment_system.get_speed_modifier(test_unit)
			print("  → Speed: ", speed_mod * 100, "%")
			current_terrain_info = "WATER (Speed -30%)"

		EnvironmentSystem.TerrainType.COLD:
			var fatigue_mult: float = environment_system.get_fatigue_multiplier(test_unit)
			print("  → Fatigue: x", fatigue_mult)
			current_terrain_info = "COLD (Fatigue +50%)"

		EnvironmentSystem.TerrainType.DARK:
			var detection_mod: float = environment_system.get_detection_modifier(test_unit)
			print("  → Detection: ", detection_mod * 100, "%")
			current_terrain_info = "DARK (Detection -50%)"

		EnvironmentSystem.TerrainType.POISON:
			print("  → Applied POISON status effect")
			current_terrain_info = "POISON (5 dmg/sec)"

		EnvironmentSystem.TerrainType.FIRE:
			print("  → Applied BURN status effect")
			current_terrain_info = "FIRE (8 dmg/sec)"

func _on_terrain_exited(unit: Node, terrain_type) -> void:
	if unit != test_unit:
		return

	var terrain_name: String = EnvironmentSystem.TerrainType.keys()[terrain_type]
	print("\n[Terrain Exited] ", terrain_name)

	# 디버프 제거 확인
	var speed_mod: float = environment_system.get_speed_modifier(test_unit)
	var fatigue_mult: float = environment_system.get_fatigue_multiplier(test_unit)
	var detection_mod: float = environment_system.get_detection_modifier(test_unit)

	print("  → Speed: ", speed_mod * 100, "%")
	print("  → Fatigue: x", fatigue_mult)
	print("  → Detection: ", detection_mod * 100, "%")

	current_terrain_info = "NORMAL"

func _input(event: InputEvent) -> void:
	# ESC로 종료
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	# I 키로 디버그 정보 출력
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		print("\n=== Debug Info ===")
		print("Current Terrain: ", current_terrain_info)
		print(environment_system.get_debug_info())
		print("==================\n")
