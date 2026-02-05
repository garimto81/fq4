extends Resource
class_name StatusEffectData
## 상태 효과 데이터 리소스
## POISON, SLOW, STUN 등의 상태 효과 속성 정의

enum EffectType {
	POISON,   ## 지속 데미지
	SLOW,     ## 이동 속도 감소
	STUN,     ## 행동 불가
	BURN,     ## 지속 데미지 (불)
	FREEZE,   ## 행동 불가 + 이동 불가
	BLIND     ## 감지 범위 감소
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var effect_type: EffectType = EffectType.POISON

## 지속 시간 (초)
@export var duration: float = 5.0

## tick 데미지 간격 (초, POISON/BURN용)
@export var tick_interval: float = 1.0

## tick당 데미지 (POISON, BURN용)
@export var tick_damage: int = 5

## 이동 속도 배율 (SLOW: 0.5, FREEZE: 0.0)
@export var speed_modifier: float = 1.0

## 능력치 변화 {"atk": -5, "def": -3}
@export var stat_modifier: Dictionary = {}

## 행동 가능 여부 (STUN, FREEZE: false)
@export var can_act: bool = true

## 감지 범위 배율 (BLIND: 0.2)
@export var detection_modifier: float = 1.0

## 중첩 가능 여부
@export var stackable: bool = false

## UI 아이콘
@export var icon: Texture2D = null


func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_effect_type: EffectType = EffectType.POISON,
	p_duration: float = 5.0
) -> void:
	id = p_id
	display_name = p_display_name
	effect_type = p_effect_type
	duration = p_duration

	# 효과 타입별 기본값 설정
	match effect_type:
		EffectType.POISON:
			tick_interval = 1.0
			tick_damage = 5
		EffectType.SLOW:
			speed_modifier = 0.5
		EffectType.STUN:
			can_act = false
		EffectType.BURN:
			tick_interval = 1.0
			tick_damage = 8
		EffectType.FREEZE:
			speed_modifier = 0.0
			can_act = false
		EffectType.BLIND:
			detection_modifier = 0.2


## 효과 타입 이름 반환
static func get_effect_type_name(type: EffectType) -> String:
	match type:
		EffectType.POISON: return "독"
		EffectType.SLOW: return "둔화"
		EffectType.STUN: return "기절"
		EffectType.BURN: return "화상"
		EffectType.FREEZE: return "빙결"
		EffectType.BLIND: return "실명"
		_: return "알 수 없음"
