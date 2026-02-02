extends "res://scripts/units/unit.gd"
class_name AIUnit
## AIUnit: Gocha-Kyara AI가 제어하는 유닛
##
## 상태머신 기반 AI 행동을 구현합니다.
## First Queen 4 원작의 Gocha-Kyara 시스템을 재현합니다.

# AI 상태
enum AIState {
	IDLE,            # 대기
	FOLLOW,          # 리더 따라가기 (Gocha-Kyara 핵심)
	PATROL,          # 순찰
	CHASE,           # 추격
	ATTACK,          # 공격
	RETREAT,         # 후퇴
	DEFEND,          # 방어
	SUPPORT,         # 지원
	REST             # 휴식 (피로도 회복)
}

# 성격 시스템
enum Personality {
	AGGRESSIVE,      # 공격적: 적극적으로 적 추격
	DEFENSIVE,       # 방어적: 리더 근처 유지, 신중한 전투
	BALANCED         # 균형: 상황에 따라 유연하게 대응
}

@export var personality: Personality = Personality.BALANCED
@export var is_player_controlled: bool = false  # 현재 플레이어가 조작 중인지

var ai_state: AIState = AIState.FOLLOW
var leader = null  # Unit  # 따라갈 리더 유닛
var squad_id: int = 0    # 소속 부대 ID
var squad_position: int = 0  # 부대 내 위치 (전환용)

var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var target_enemy = null  # Unit

# 거리/임계값 설정
var detection_range: float = 200.0
var follow_distance: float = 80.0       # 리더와 유지할 거리
var follow_spread: float = 40.0         # 부대원 간 분산 거리
var attack_engage_range: float = 150.0  # 공격 개시 거리

# 피로도 기반 임계값
var retreat_hp_threshold: float = 0.3
var fatigue_retreat_threshold: float = 0.7   # 피로도 70% 이상이면 후퇴 고려
var fatigue_rest_threshold: float = 0.9      # 피로도 90% 이상이면 강제 휴식

# AI 틱 타이머
var ai_tick_interval: float = 0.3
var ai_tick_timer: float = 0.0

# 성격별 파라미터
var personality_params: Dictionary = {
	Personality.AGGRESSIVE: {
		"chase_range_mult": 1.5,
		"retreat_hp_mult": 0.7,
		"attack_priority": 1.0,
		"follow_priority": 0.5
	},
	Personality.DEFENSIVE: {
		"chase_range_mult": 0.7,
		"retreat_hp_mult": 1.3,
		"attack_priority": 0.5,
		"follow_priority": 1.0
	},
	Personality.BALANCED: {
		"chase_range_mult": 1.0,
		"retreat_hp_mult": 1.0,
		"attack_priority": 0.8,
		"follow_priority": 0.8
	}
}

func _ready() -> void:
	super._ready()
	_apply_personality()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# 플레이어 조작 중이면 AI 비활성화
	if is_player_controlled:
		return

	ai_tick_timer += delta
	if ai_tick_timer >= ai_tick_interval:
		ai_tick_timer = 0.0
		_process_ai()

## 성격에 따른 파라미터 적용
func _apply_personality() -> void:
	var params = personality_params[personality]
	detection_range *= params["chase_range_mult"]
	retreat_hp_threshold *= params["retreat_hp_mult"]

## 리더 설정
func set_leader(new_leader) -> void:  # Unit
	leader = new_leader
	if leader:
		_change_ai_state(AIState.FOLLOW)

## 부대 정보 설정
func set_squad_info(squad: int, position: int) -> void:
	squad_id = squad
	squad_position = position

## 플레이어 조작 전환
func set_player_controlled(controlled: bool) -> void:
	is_player_controlled = controlled
	is_selected = controlled
	if not controlled and leader:
		_change_ai_state(AIState.FOLLOW)

## AI 메인 로직
func _process_ai() -> void:
	if not is_alive:
		return

	# 피로도 체크 → 강제 휴식
	var fatigue_ratio = float(current_fatigue) / float(max_fatigue)
	if fatigue_ratio >= fatigue_rest_threshold:
		_change_ai_state(AIState.REST)
		return

	# HP 체크 → 후퇴 조건
	var hp_ratio = float(current_hp) / float(max_hp)
	if hp_ratio < retreat_hp_threshold:
		_change_ai_state(AIState.RETREAT)
		return

	# 피로도 높으면 후퇴 우선
	if fatigue_ratio >= fatigue_retreat_threshold and ai_state != AIState.REST:
		_change_ai_state(AIState.RETREAT)
		return

	# 적 감지
	target_enemy = _find_nearest_enemy()

	# 상태별 행동
	match ai_state:
		AIState.IDLE:
			_ai_idle()
		AIState.FOLLOW:
			_ai_follow()
		AIState.PATROL:
			_ai_patrol()
		AIState.CHASE:
			_ai_chase()
		AIState.ATTACK:
			_ai_attack()
		AIState.RETREAT:
			_ai_retreat()
		AIState.DEFEND:
			_ai_defend()
		AIState.SUPPORT:
			_ai_support()
		AIState.REST:
			_ai_rest()

## AI 상태 전환
func _change_ai_state(new_state: AIState) -> void:
	if ai_state != new_state:
		ai_state = new_state
		# print(unit_name, " AI state: ", AIState.keys()[new_state])

## 가장 가까운 적 찾기
func _find_nearest_enemy():
	var nearest = null  # Unit
	var nearest_distance: float = detection_range

	# 적 유닛 목록 가져오기
	var enemy_list = GameManager.enemy_units

	for unit in enemy_list:
		if not unit.is_alive:
			continue
		var distance = global_position.distance_to(unit.global_position)
		if distance < nearest_distance:
			nearest = unit
			nearest_distance = distance

	return nearest

## 대기 행동
func _ai_idle() -> void:
	if leader:
		_change_ai_state(AIState.FOLLOW)
	elif target_enemy:
		_change_ai_state(AIState.CHASE)

## 리더 따라가기 (Gocha-Kyara 핵심)
func _ai_follow() -> void:
	if not leader or not leader.is_alive:
		_change_ai_state(AIState.IDLE)
		return

	# 성격에 따른 적 반응
	var params = personality_params[personality]

	if target_enemy:
		var enemy_distance = global_position.distance_to(target_enemy.global_position)
		var leader_distance = global_position.distance_to(leader.global_position)

		# 공격적: 적이 가까우면 바로 추격
		if personality == Personality.AGGRESSIVE and enemy_distance < attack_engage_range:
			_change_ai_state(AIState.CHASE)
			return

		# 균형: 적이 매우 가까우면 공격
		if personality == Personality.BALANCED and enemy_distance < attack_range * 1.5:
			_change_ai_state(AIState.ATTACK)
			return

		# 방어적: 리더 가까이 있으면서 적이 접근하면 방어
		if personality == Personality.DEFENSIVE and leader_distance < follow_distance:
			if enemy_distance < attack_engage_range * 0.5:
				_change_ai_state(AIState.DEFEND)
				return

	# 리더 따라가기 위치 계산 (부대원마다 다른 위치)
	var follow_offset = _calculate_follow_offset()
	var target_pos = leader.global_position + follow_offset
	var distance_to_target = global_position.distance_to(target_pos)

	if distance_to_target > follow_distance * 0.5:
		_move_towards(target_pos)
	else:
		change_state(UnitState.IDLE)
		velocity = Vector2.ZERO

## 부대 내 위치에 따른 오프셋 계산
func _calculate_follow_offset() -> Vector2:
	# 리더 뒤쪽에 V자 대형으로 배치
	var angle_offset = (squad_position - 2) * 0.5  # -1, -0.5, 0, 0.5, 1
	var base_angle = PI * 0.75  # 리더 뒤쪽 (135도)
	var angle = base_angle + angle_offset

	var offset = Vector2(
		cos(angle) * follow_distance,
		sin(angle) * follow_distance * 0.6  # Y축 압축
	)

	# 부대원끼리 겹치지 않도록 분산
	offset += Vector2(
		(squad_position % 3 - 1) * follow_spread,
		(squad_position / 3) * follow_spread
	)

	return offset

## 순찰 행동
func _ai_patrol() -> void:
	if target_enemy:
		_change_ai_state(AIState.CHASE)
		return

	if patrol_points.is_empty():
		_setup_patrol_points()

	var target = patrol_points[current_patrol_index]
	_move_towards(target)

	if global_position.distance_to(target) < 10.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

## 순찰 포인트 초기 설정
func _setup_patrol_points() -> void:
	patrol_points = [
		global_position + Vector2(100, 0),
		global_position + Vector2(100, 100),
		global_position + Vector2(0, 100),
		global_position
	]

## 추격 행동
func _ai_chase() -> void:
	if not target_enemy or not target_enemy.is_alive:
		target_enemy = null
		if leader:
			_change_ai_state(AIState.FOLLOW)
		else:
			_change_ai_state(AIState.PATROL)
		return

	var distance = global_position.distance_to(target_enemy.global_position)

	# 리더와 너무 멀어지면 복귀
	if leader and leader.is_alive:
		var leader_distance = global_position.distance_to(leader.global_position)
		if leader_distance > detection_range * 1.5:
			_change_ai_state(AIState.FOLLOW)
			return

	if distance <= attack_range:
		_change_ai_state(AIState.ATTACK)
	else:
		_move_towards(target_enemy.global_position)

## 공격 행동
func _ai_attack() -> void:
	if not target_enemy or not target_enemy.is_alive:
		target_enemy = null
		if leader:
			_change_ai_state(AIState.FOLLOW)
		else:
			_change_ai_state(AIState.PATROL)
		return

	var distance = global_position.distance_to(target_enemy.global_position)

	if distance > attack_range:
		_change_ai_state(AIState.CHASE)
	else:
		change_state(UnitState.ATTACKING)
		target_enemy.take_damage(attack_power)
		add_fatigue(10)  # FATIGUE_ATTACK

## 후퇴 행동
func _ai_retreat() -> void:
	var hp_ratio = float(current_hp) / float(max_hp)
	var fatigue_ratio = float(current_fatigue) / float(max_fatigue)

	# 회복 조건
	if hp_ratio > 0.5 and fatigue_ratio < fatigue_retreat_threshold:
		if leader:
			_change_ai_state(AIState.FOLLOW)
		else:
			_change_ai_state(AIState.PATROL)
		return

	# 리더 쪽으로 후퇴 (리더가 있으면)
	if leader and leader.is_alive:
		var retreat_target = leader.global_position
		_move_towards(retreat_target)
	elif target_enemy:
		# 적으로부터 멀어지는 방향으로 이동
		var retreat_direction = (global_position - target_enemy.global_position).normalized()
		_move_towards(global_position + retreat_direction * 100.0)

	# 이동 중 피로도 회복
	change_state(UnitState.RESTING)

## 방어 행동
func _ai_defend() -> void:
	# 리더 근처에서 적 견제
	if not leader or not leader.is_alive:
		_change_ai_state(AIState.IDLE)
		return

	var leader_distance = global_position.distance_to(leader.global_position)

	# 리더와 거리 유지
	if leader_distance > follow_distance:
		_move_towards(leader.global_position)
		return

	# 가까운 적 공격
	if target_enemy and target_enemy.is_alive:
		var enemy_distance = global_position.distance_to(target_enemy.global_position)
		if enemy_distance <= attack_range:
			change_state(UnitState.ATTACKING)
			target_enemy.take_damage(attack_power)
			add_fatigue(10)  # FATIGUE_ATTACK
		elif enemy_distance < attack_engage_range * 0.5:
			# 적이 다가오면 맞서 싸움
			_move_towards(target_enemy.global_position)
	else:
		_change_ai_state(AIState.FOLLOW)

## 지원 행동
func _ai_support() -> void:
	# 아군 지원 (힐러/버퍼용)
	pass

## 휴식 행동
func _ai_rest() -> void:
	change_state(UnitState.RESTING)
	velocity = Vector2.ZERO

	var fatigue_ratio = float(current_fatigue) / float(max_fatigue)
	if fatigue_ratio < 0.3:
		if leader:
			_change_ai_state(AIState.FOLLOW)
		else:
			_change_ai_state(AIState.IDLE)

## 이동 명령 (플레이어 조작 시)
func move_to(target: Vector2) -> void:
	if is_player_controlled:
		_move_towards(target)

## 목표 지점으로 이동
func _move_towards(target: Vector2) -> void:
	change_state(UnitState.MOVING)

	# 피로도에 따른 이동속도 조절 (인라인)
	var fatigue_percent = float(current_fatigue) / float(max_fatigue)
	var speed_mult = 1.0
	if fatigue_percent > 0.9:
		speed_mult = 0.0  # COLLAPSED
	elif fatigue_percent > 0.6:
		speed_mult = 0.5  # EXHAUSTED
	elif fatigue_percent > 0.3:
		speed_mult = 0.8  # TIRED

	var direction = (target - global_position).normalized()
	velocity = direction * move_speed * speed_mult
	move_and_slide()

	# 이동 시 피로도 증가 (인라인: 100픽셀당 1 피로도)
	var distance_moved = velocity.length() * ai_tick_interval
	var move_fatigue = int(distance_moved / 100.0)
	if move_fatigue > 0:
		add_fatigue(move_fatigue)
