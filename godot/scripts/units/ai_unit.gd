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

# 대형 시스템 (Gocha-Kyara)
enum Formation {
	V_SHAPE,         # V자 대형 (기본)
	LINE,            # 일렬 대형
	CIRCLE,          # 원형 대형
	WEDGE,           # 쐐기 대형
	SCATTERED        # 분산 대형
}

# 부대 명령 시스템
enum SquadCommand {
	NONE,            # 명령 없음
	GATHER,          # 집합
	SCATTER,         # 분산
	ATTACK_ALL,      # 전원 공격
	DEFEND_ALL,      # 전원 방어
	RETREAT_ALL      # 전원 후퇴
}

@export var personality: Personality = Personality.BALANCED
@export var is_player_controlled: bool = false  # 현재 플레이어가 조작 중인지
@export var formation: Formation = Formation.V_SHAPE  # 현재 대형

var ai_state: AIState = AIState.FOLLOW
var current_command: SquadCommand = SquadCommand.NONE
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

	# combat_system은 MainGameController 또는 UnitSpawner에서 주입

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
	return _find_nearest_target(GameManager.enemy_units, detection_range)

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
	match formation:
		Formation.V_SHAPE:
			return _calculate_v_shape_offset()
		Formation.LINE:
			return _calculate_line_offset()
		Formation.CIRCLE:
			return _calculate_circle_offset()
		Formation.WEDGE:
			return _calculate_wedge_offset()
		Formation.SCATTERED:
			return _calculate_scattered_offset()
		_:
			return _calculate_v_shape_offset()

## V자 대형 오프셋 (기본)
func _calculate_v_shape_offset() -> Vector2:
	var angle_offset = (squad_position - 2) * 0.5  # -1, -0.5, 0, 0.5, 1
	var base_angle = PI * 0.75  # 리더 뒤쪽 (135도)
	var angle = base_angle + angle_offset

	var offset = Vector2(
		cos(angle) * follow_distance,
		sin(angle) * follow_distance * 0.6  # Y축 압축
	)

	offset += Vector2(
		(squad_position % 3 - 1) * follow_spread,
		(squad_position / 3) * follow_spread
	)

	return offset

## 일렬 대형 오프셋
func _calculate_line_offset() -> Vector2:
	var horizontal_offset = (squad_position - 2) * follow_spread * 1.5
	return Vector2(horizontal_offset, follow_distance)

## 원형 대형 오프셋
func _calculate_circle_offset() -> Vector2:
	var total_units = 5  # 기본 부대원 수
	var angle = (2 * PI / total_units) * squad_position
	return Vector2(
		cos(angle) * follow_distance,
		sin(angle) * follow_distance
	)

## 쐐기 대형 오프셋
func _calculate_wedge_offset() -> Vector2:
	var row = squad_position / 2
	var col = squad_position % 2
	var x_offset = (col * 2 - 1) * follow_spread * (row + 1) * 0.5
	var y_offset = follow_distance + (row * follow_spread)
	return Vector2(x_offset, y_offset)

## 분산 대형 오프셋
func _calculate_scattered_offset() -> Vector2:
	# 시드 기반 의사난수로 분산 위치 결정
	var seed_offset = squad_position * 137 + squad_id * 31
	var angle = fmod(seed_offset * 0.618033988749, 1.0) * 2 * PI
	var distance = follow_distance * (1.0 + fmod(seed_offset * 0.314159, 0.5))
	return Vector2(cos(angle) * distance, sin(angle) * distance)

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
		if combat_system:
			combat_system.execute_attack(self, target_enemy)
		else:
			# Fallback: 직접 데미지 (CombatSystem 없을 때)
			var damage = max(1, attack_power - target_enemy.defense)
			target_enemy.take_damage(damage)
			add_fatigue(FatigueSystem.FATIGUE_ATTACK if FatigueSystem else 10)

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
			if combat_system:
				combat_system.execute_attack(self, target_enemy)
			else:
				var damage = max(1, attack_power - target_enemy.defense)
				target_enemy.take_damage(damage)
				add_fatigue(FatigueSystem.FATIGUE_ATTACK if FatigueSystem else 10)
		elif enemy_distance < attack_engage_range * 0.5:
			# 적이 다가오면 맞서 싸움
			_move_towards(target_enemy.global_position)
	else:
		_change_ai_state(AIState.FOLLOW)

## 지원 행동 (Phase 1 stub: 부상 아군 찾아 이동)
func _ai_support() -> void:
	# Phase 1 stub: find wounded ally, move toward them
	# Full spell casting in Phase 3
	var allies = GameManager.player_units
	var wounded_ally = null
	var lowest_hp_ratio = 1.0

	for ally in allies:
		if ally == self or not ally.is_alive:
			continue
		var hp_ratio = float(ally.current_hp) / float(ally.max_hp)
		if hp_ratio < lowest_hp_ratio and hp_ratio < 0.5:
			lowest_hp_ratio = hp_ratio
			wounded_ally = ally

	if wounded_ally:
		var distance = global_position.distance_to(wounded_ally.global_position)
		if distance > attack_range:
			_move_towards(wounded_ally.global_position)
		# Phase 3에서 힐 마법 시전 추가
	elif leader and leader.is_alive:
		_change_ai_state(AIState.FOLLOW)

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

## 대형 변경
func set_formation(new_formation: Formation) -> void:
	formation = new_formation

## 부대 명령 수신
func receive_command(command: SquadCommand) -> void:
	current_command = command
	match command:
		SquadCommand.GATHER:
			_execute_gather_command()
		SquadCommand.SCATTER:
			_execute_scatter_command()
		SquadCommand.ATTACK_ALL:
			_execute_attack_command()
		SquadCommand.DEFEND_ALL:
			_execute_defend_command()
		SquadCommand.RETREAT_ALL:
			_execute_retreat_command()

## 집합 명령 실행
func _execute_gather_command() -> void:
	formation = Formation.CIRCLE
	follow_distance = 40.0  # 더 가깝게 모임
	if leader:
		_change_ai_state(AIState.FOLLOW)

## 분산 명령 실행
func _execute_scatter_command() -> void:
	formation = Formation.SCATTERED
	follow_distance = 150.0  # 더 넓게 분산
	if leader:
		_change_ai_state(AIState.FOLLOW)

## 전원 공격 명령 실행
func _execute_attack_command() -> void:
	target_enemy = _find_nearest_enemy()
	if target_enemy:
		_change_ai_state(AIState.CHASE)
	else:
		_change_ai_state(AIState.PATROL)

## 전원 방어 명령 실행
func _execute_defend_command() -> void:
	formation = Formation.CIRCLE
	follow_distance = 50.0
	_change_ai_state(AIState.DEFEND)

## 전원 후퇴 명령 실행
func _execute_retreat_command() -> void:
	_change_ai_state(AIState.RETREAT)

## 명령 초기화
func clear_command() -> void:
	current_command = SquadCommand.NONE
	follow_distance = 80.0  # 기본값 복원
