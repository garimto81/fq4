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

## HP 변경
func take_damage(damage: int) -> void:
	var actual_damage = max(0, damage - defense)
	current_hp = max(0, current_hp - actual_damage)
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

func _process_resting(_delta: float) -> void:
	rest(5)  # 초당 5 피로도 회복
	if current_fatigue <= 0:
		change_state(UnitState.IDLE)

## 이동 명령 (하위 클래스에서 오버라이드)
func move_to(_target: Vector2) -> void:
	pass
