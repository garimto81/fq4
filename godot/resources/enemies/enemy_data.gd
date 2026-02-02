extends Resource
class_name EnemyData
## EnemyData: 적 데이터 리소스
##
## 적 유닛의 기본 데이터를 정의합니다.

enum EnemyType {
	NORMAL,         # 일반 적
	ELITE,          # 정예 적
	BOSS            # 보스
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var sprite: Texture2D

# 적 타입
@export var enemy_type: EnemyType = EnemyType.NORMAL

# 기본 스탯
@export var base_hp: int = 50
@export var base_mp: int = 20
@export var base_atk: int = 8
@export var base_def: int = 3
@export var base_spd: int = 80
@export var base_lck: int = 5

# 전투 설정
@export var attack_range: float = 50.0
@export var detection_range: float = 180.0
@export var ai_tick_interval: float = 0.4

# 보상
@export var exp_reward: int = 10
@export var gold_reward: int = 5
@export var drop_table: Array[Dictionary] = []  # [{item_id: String, chance: float}]

# 레벨 스케일링
@export var hp_per_level: int = 10
@export var atk_per_level: int = 2
@export var def_per_level: int = 1

## 레벨에 따른 스탯 계산
func get_scaled_stats(level: int) -> Dictionary:
	var level_bonus = level - 1
	return {
		"hp": base_hp + (hp_per_level * level_bonus),
		"mp": base_mp,
		"atk": base_atk + (atk_per_level * level_bonus),
		"def": base_def + (def_per_level * level_bonus),
		"spd": base_spd,
		"lck": base_lck
	}

## 경험치 계산 (레벨 보정)
func get_exp_reward(level: int) -> int:
	var type_multiplier = 1.0
	match enemy_type:
		EnemyType.ELITE:
			type_multiplier = 2.0
		EnemyType.BOSS:
			type_multiplier = 5.0

	return int(exp_reward * level * type_multiplier)

## 드롭 아이템 결정
func roll_drops() -> Array[String]:
	var drops: Array[String] = []
	for drop in drop_table:
		if randf() <= drop.get("chance", 0.0):
			drops.append(drop.get("item_id", ""))
	return drops
