extends CharacterBody2D
class_name Unit
## Unit: 모든 유닛의 기본 클래스
##
## HP, MP, 피로도, 이동/공격 등 기본 속성과 동작을 정의합니다.

# 유닛 속성
@export var unit_name: String = "Unknown"
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var max_fatigue: int = 100
@export var attack_power: int = 10
@export var defense: int = 5
@export var move_speed: float = 100.0
@export var attack_range: float = 50.0
var known_spells: Array[SpellData] = []

# 현재 상태
var current_hp: int
var current_mp: int
var current_fatigue: int = 0
var is_alive: bool = true
var is_selected: bool = false

# 상태머신
enum UnitState {
	IDLE,
	MOVING,
	ATTACKING,
	RESTING,
	DEAD
}
var current_state: UnitState = UnitState.IDLE

# 시그널
signal hp_changed(new_hp: int, max_hp: int)
signal mp_changed(new_mp: int, max_mp: int)
signal fatigue_changed(new_fatigue: int, max_fatigue: int)
signal state_changed(new_state: UnitState)
signal unit_died()

func _ready() -> void:
	current_hp = max_hp
	current_mp = max_mp
	current_fatigue = 0

	# CollisionShape2D 자동 설정 (없으면 생성)
	_ensure_collision_shape()

func _physics_process(delta: float) -> void:
	match current_state:
		UnitState.IDLE:
			_process_idle(delta)
		UnitState.MOVING:
			_process_moving(delta)
		UnitState.ATTACKING:
			_process_attacking(delta)
		UnitState.RESTING:
			_process_resting(delta)

## 상태 전환
func change_state(new_state: UnitState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

## HP 변경 (최종 데미지 - defense 계산 없음)
func take_damage(final_damage: int) -> void:
	var actual = max(0, final_damage)
	current_hp = max(0, current_hp - actual)
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		die()

## 환경 데미지용 (defense 적용)
func take_raw_damage(raw_damage: int) -> void:
	var actual = max(0, raw_damage - defense)
	current_hp = max(0, current_hp - actual)
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		die()

## HP 회복
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

## 피로도 증가
func add_fatigue(amount: int) -> void:
	current_fatigue = min(max_fatigue, current_fatigue + amount)
	fatigue_changed.emit(current_fatigue, max_fatigue)

## 피로도 회복
func rest(amount: int) -> void:
	current_fatigue = max(0, current_fatigue - amount)
	fatigue_changed.emit(current_fatigue, max_fatigue)

## 사망 처리
func die() -> void:
	is_alive = false
	change_state(UnitState.DEAD)
	unit_died.emit()
	GameManager.unregister_unit(self)

# 가상 함수 (하위 클래스에서 오버라이드)
func _process_idle(_delta: float) -> void:
	pass

func _process_moving(_delta: float) -> void:
	pass

func _process_attacking(_delta: float) -> void:
	pass

func _process_resting(delta: float) -> void:
	# 초당 5 피로도 회복 (delta 기반)
	var recovery = int(5.0 * delta * 60.0)
	recovery = max(1, recovery) if delta > 0 else 0
	rest(recovery)
	if current_fatigue <= 0:
		change_state(UnitState.IDLE)

## 이동 명령 (하위 클래스에서 오버라이드)
func move_to(_target: Vector2) -> void:
	pass

## 목표 지점으로 이동 (공유 메서드)
func _move_towards(target: Vector2) -> void:
	change_state(UnitState.MOVING)
	# FatigueSystem으로 속도 배율 계산
	var speed_mult = 1.0
	if current_fatigue > 0 and max_fatigue > 0:
		var fatigue_percent = float(current_fatigue) / float(max_fatigue)
		if fatigue_percent > 0.9:
			speed_mult = 0.0  # COLLAPSED
		elif fatigue_percent > 0.6:
			speed_mult = 0.5  # EXHAUSTED
		elif fatigue_percent > 0.3:
			speed_mult = 0.8  # TIRED

	var direction = (target - global_position).normalized()
	velocity = direction * move_speed * speed_mult
	move_and_slide()

## 가장 가까운 타겟 찾기 (공유 메서드)
func _find_nearest_target(target_list: Array, max_range: float):
	var nearest = null
	var nearest_distance: float = max_range
	for unit in target_list:
		if not unit.is_alive:
			continue
		var distance = global_position.distance_to(unit.global_position)
		if distance < nearest_distance:
			nearest = unit
			nearest_distance = distance
	return nearest

## 마법 시전 인터페이스 (MagicSystem이 호출)
func cast_spell(spell: SpellData, target = null) -> bool:
	# Stub - Phase 3에서 MagicSystem과 연동
	if current_mp < spell.mp_cost:
		return false
	# MagicSystem.cast_spell(self, spell, target) 호출 예정
	return true

## 마법 학습
func learn_spell(spell: SpellData) -> void:
	if spell and not known_spells.has(spell):
		known_spells.append(spell)

## CollisionShape2D 자동 설정
func _ensure_collision_shape() -> void:
	var collision = get_node_or_null("CollisionShape2D")
	if collision and not collision.shape:
		var circle = CircleShape2D.new()
		circle.radius = 16.0  # 기본 충돌 반경
		collision.shape = circle
	elif not collision:
		# CollisionShape2D 노드 자체가 없으면 생성
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var circle = CircleShape2D.new()
		circle.radius = 16.0
		collision.shape = circle
		add_child(collision)
