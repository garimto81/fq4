extends Resource
class_name SpellData
## SpellData: 마법 데이터 리소스
##
## 각 마법의 속성을 정의합니다.

## 마법 타입
enum SpellType {
	DAMAGE,      # 공격 마법
	HEAL,        # 회복 마법
	BUFF,        # 버프
	DEBUFF,      # 디버프
	SUMMON       # 소환
}

## 속성 타입
enum ElementType {
	NONE,        # 무속성
	FIRE,        # 화염
	ICE,         # 빙결
	LIGHTNING,   # 번개
	HOLY,        # 신성
	DARK         # 암흑
}

## 타겟 타입
enum TargetType {
	SELF,        # 자신
	SINGLE_ALLY, # 아군 단일
	SINGLE_ENEMY,# 적 단일
	ALL_ALLIES,  # 아군 전체
	ALL_ENEMIES, # 적 전체
	AREA         # 범위
}

# 기본 정보
@export var spell_id: String = ""
@export var spell_name: String = "Unknown Spell"
@export var description: String = ""
@export var spell_type: SpellType = SpellType.DAMAGE
@export var element: ElementType = ElementType.NONE
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

# 비용/범위
@export var mp_cost: int = 10
@export var cast_range: float = 200.0
@export var area_radius: float = 50.0  # AREA 타입일 때

# 효과
@export var base_power: int = 20       # 데미지/힐 기본량
@export var buff_stat: int = 0         # 버프/디버프 대상 스탯 (StatType enum)
@export var buff_value: float = 0.0    # 버프/디버프 수치 (음수면 디버프)
@export var buff_duration: float = 10.0 # 버프 지속시간 (초)

# 타이밍
@export var cooldown: float = 3.0      # 재사용 대기시간
@export var cast_time: float = 0.5     # 시전 시간

# 시각 효과
@export var effect_scene: PackedScene = null
@export var icon: Texture2D = null
@export var cast_sound: AudioStream = null
@export var hit_sound: AudioStream = null
