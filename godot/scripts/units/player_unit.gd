extends "res://scripts/units/ai_unit.gd"
class_name PlayerUnit
## PlayerUnit: 플레이어가 제어하는 유닛
##
## 마우스/키보드 입력을 처리하고, 플레이어의 명령을 실행합니다.

var target_position: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var is_moving_to_target: bool = false

func _ready() -> void:
	super._ready()
	GameManager.register_unit(self, true)

func _input(event: InputEvent) -> void:
	if not is_selected or not is_alive:
		return

	# 우클릭: 이동 명령
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		move_to(get_global_mouse_position())

## 이동 명령
func move_to(target: Vector2) -> void:
	move_target = target
	is_moving_to_target = true
	change_state(UnitState.MOVING)
	# 피로도는 실제 이동 중에 _process_moving()에서 누적됨

func _process_idle(_delta: float) -> void:
	# Idle 상태에서는 자동으로 피로도 회복
	if current_fatigue > 0:
		rest(1)

func _process_moving(delta: float) -> void:
	if not is_moving_to_target:
		change_state(UnitState.IDLE)
		return

	var direction = (move_target - global_position).normalized()
	var distance = global_position.distance_to(move_target)

	if distance < 5.0:
		# 목표 도착
		is_moving_to_target = false
		velocity = Vector2.ZERO
		change_state(UnitState.IDLE)
	else:
		# 이동 중
		velocity = direction * move_speed
		move_and_slide()
		# 실제 이동 시 피로도 누적 (100픽셀당 1 피로도)
		var moved = velocity.length() * delta
		var fatigue = int(moved / 100.0)
		if fatigue > 0:
			add_fatigue(fatigue)

## 선택 상태 토글
func set_selected(selected: bool) -> void:
	is_selected = selected
	# TODO: 비주얼 피드백 (선택 링 표시 등)

## 공격 명령
func attack_target(target) -> void:  # Unit 타입
	if not is_alive:
		return

	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		change_state(UnitState.ATTACKING)
		if combat_system:
			combat_system.execute_attack(self, target)
		else:
			var damage = max(1, attack_power - target.defense)
			target.take_damage(damage)
			add_fatigue(10)
	else:
		# 사거리 밖: 먼저 이동
		move_to(target.global_position)
