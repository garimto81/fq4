extends "res://scripts/units/unit.gd"
class_name EnemyUnit
## EnemyUnit: 적 AI 유닛
##
## 플레이어 부대를 공격하는 적 유닛입니다.
## 단순한 공격 AI를 가집니다.

# AI 상태
enum EnemyAIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETREAT
}

var ai_state: EnemyAIState = EnemyAIState.PATROL
var target_enemy = null  # Unit
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var combat_system: CombatSystem = null  # CombatSystem 참조

var detection_range: float = 180.0
var retreat_hp_threshold: float = 0.2

# AI 틱 타이머
var ai_tick_interval: float = 0.4
var ai_tick_timer: float = 0.0

func _ready() -> void:
	super._ready()
	GameManager.register_unit(self, false)
	_setup_patrol_points()

	# CombatSystem 찾기 (부모 씬에서)
	combat_system = get_node_or_null("../CombatSystem")
	if not combat_system:
		combat_system = get_tree().get_first_node_in_group("combat_system")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	ai_tick_timer += delta
	if ai_tick_timer >= ai_tick_interval:
		ai_tick_timer = 0.0
		_process_ai()

## 순찰 포인트 설정
func _setup_patrol_points() -> void:
	patrol_points = [
		global_position + Vector2(80, 0),
		global_position + Vector2(80, 80),
		global_position + Vector2(0, 80),
		global_position
	]

## AI 메인 로직
func _process_ai() -> void:
	if not is_alive:
		return

	# HP 체크 → 후퇴
	if float(current_hp) / float(max_hp) < retreat_hp_threshold:
		_change_ai_state(EnemyAIState.RETREAT)

	# 적(플레이어) 감지
	target_enemy = _find_nearest_enemy()

	match ai_state:
		EnemyAIState.IDLE:
			_ai_idle()
		EnemyAIState.PATROL:
			_ai_patrol()
		EnemyAIState.CHASE:
			_ai_chase()
		EnemyAIState.ATTACK:
			_ai_attack()
		EnemyAIState.RETREAT:
			_ai_retreat()

## 상태 전환
func _change_ai_state(new_state: EnemyAIState) -> void:
	if ai_state != new_state:
		ai_state = new_state

## 가장 가까운 적(플레이어) 찾기
func _find_nearest_enemy():
	return _find_nearest_target(GameManager.player_units, detection_range)

## 대기 행동
func _ai_idle() -> void:
	if target_enemy:
		_change_ai_state(EnemyAIState.CHASE)
	else:
		_change_ai_state(EnemyAIState.PATROL)

## 순찰 행동
func _ai_patrol() -> void:
	if target_enemy:
		_change_ai_state(EnemyAIState.CHASE)
		return

	if patrol_points.is_empty():
		return

	var target = patrol_points[current_patrol_index]
	_move_towards(target)

	if global_position.distance_to(target) < 10.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

## 추격 행동
func _ai_chase() -> void:
	if not target_enemy or not target_enemy.is_alive:
		target_enemy = null
		_change_ai_state(EnemyAIState.PATROL)
		return

	var distance = global_position.distance_to(target_enemy.global_position)

	if distance <= attack_range:
		_change_ai_state(EnemyAIState.ATTACK)
	else:
		_move_towards(target_enemy.global_position)

## 공격 행동
func _ai_attack() -> void:
	if not target_enemy or not target_enemy.is_alive:
		target_enemy = null
		_change_ai_state(EnemyAIState.PATROL)
		return

	var distance = global_position.distance_to(target_enemy.global_position)

	if distance > attack_range:
		_change_ai_state(EnemyAIState.CHASE)
	else:
		change_state(UnitState.ATTACKING)
		if combat_system:
			combat_system.execute_attack(self, target_enemy)
		else:
			var damage = max(1, attack_power - target_enemy.defense)
			target_enemy.take_damage(damage)
			add_fatigue(10)  # FATIGUE_ATTACK

## 후퇴 행동
func _ai_retreat() -> void:
	if float(current_hp) / float(max_hp) > 0.5:
		_change_ai_state(EnemyAIState.PATROL)
		return

	if target_enemy:
		var retreat_direction = (global_position - target_enemy.global_position).normalized()
		_move_towards(global_position + retreat_direction * 100.0)

	change_state(UnitState.RESTING)
