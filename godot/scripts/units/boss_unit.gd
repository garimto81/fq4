extends EnemyUnit
class_name BossUnit
## BossUnit: 보스 유닛
##
## EnemyUnit을 확장하여 멀티 페이즈 시스템, 광폭화, 미니언 소환 기능을 제공합니다.

# 페이즈 시스템
var current_phase: int = 1
var max_phases: int = 3
var phase_hp_thresholds: Array[float] = [0.66, 0.33]  # 66%, 33%에서 페이즈 전환

# 페이즈별 패턴
var phase_patterns: Dictionary = {}  # phase -> Array[AttackPattern]

# 보스 전용 속성
@export var boss_name: String = "Boss"
@export var is_boss: bool = true
@export var summon_minions: bool = false
@export var minion_ids: Array[String] = []
@export var enrage_threshold: float = 0.2  # 20% HP 이하 시 광폭화

# 상태
var is_enraged: bool = false
var phase_changed: bool = false

# 시그널
signal phase_changed_signal(new_phase: int)
signal boss_enraged()
signal boss_defeated()
signal boss_engaged()

func _ready() -> void:
	super._ready()
	_setup_phase_patterns()
	add_to_group("bosses")

func take_damage(final_damage: int) -> void:
	super.take_damage(final_damage)
	_check_phase_transition()
	_check_enrage()

## 페이즈 전환 체크
func _check_phase_transition() -> void:
	if current_phase >= max_phases:
		return

	var hp_ratio = float(current_hp) / float(max_hp)
	if hp_ratio <= phase_hp_thresholds[current_phase - 1]:
		current_phase += 1
		phase_changed = true
		phase_changed_signal.emit(current_phase)
		_on_phase_change()

## 페이즈 전환 시 동작 (하위 클래스에서 오버라이드)
func _on_phase_change() -> void:
	# 페이즈 전환 시 행동 (하위 클래스에서 오버라이드)
	# 예: 미니언 소환, 패턴 변경, 스킬 해금
	if summon_minions and not minion_ids.is_empty():
		_summon_minions()

## 광폭화 체크
func _check_enrage() -> void:
	if is_enraged:
		return

	var hp_ratio = float(current_hp) / float(max_hp)
	if hp_ratio <= enrage_threshold:
		is_enraged = true
		boss_enraged.emit()
		_apply_enrage_buff()

## 광폭화 버프 적용
func _apply_enrage_buff() -> void:
	# 광폭화: ATK +50%, SPD +30%
	attack_power = int(attack_power * 1.5)
	move_speed = move_speed * 1.3

## 미니언 소환
func _summon_minions() -> void:
	# EventSystem을 통해 미니언 스폰
	var spawn_positions = [
		global_position + Vector2(-100, 0),
		global_position + Vector2(100, 0)
	]

	for i in range(min(minion_ids.size(), spawn_positions.size())):
		EventSystem.queue_event({
			"type": EventSystem.EventType.SPAWN_ENEMY,
			"enemy_id": minion_ids[i],
			"position": spawn_positions[i],
			"count": 1
		})

## 페이즈별 패턴 설정 (하위 클래스에서 오버라이드)
func _setup_phase_patterns() -> void:
	# 기본 패턴 설정 (하위 클래스에서 오버라이드)
	pass

## 보스 사망 시 특수 처리
func die() -> void:
	boss_defeated.emit()
	super.die()
