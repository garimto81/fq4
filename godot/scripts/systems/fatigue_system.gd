extends Node
class_name FatigueSystem
## FatigueSystem: 피로도 관리 시스템
##
## First Queen 4의 핵심 메커니즘인 피로도 시스템을 구현합니다.
## 행동, 시간, 환경에 따라 피로도가 변화하며, 유닛 성능에 영향을 줍니다.

# 피로도 증가 요인
const FATIGUE_MOVE_PER_10_UNITS: int = 1       # 10 픽셀당 1 피로도
const FATIGUE_ATTACK: int = 10                 # 공격 시 10 피로도
const FATIGUE_SKILL: int = 20                  # 스킬 사용 시 20 피로도
const FATIGUE_IDLE_RECOVERY: int = 1           # 초당 1 피로도 회복
const FATIGUE_REST_RECOVERY: int = 5           # 휴식 시 초당 5 피로도 회복

# 피로도 단계별 패널티
enum FatigueLevel {
	NORMAL,     # 0-30%: 패널티 없음
	TIRED,      # 31-60%: 이동속도 -20%, 공격력 -10%
	EXHAUSTED,  # 61-90%: 이동속도 -50%, 공격력 -30%
	COLLAPSED   # 91-100%: 이동/공격 불가, 강제 휴식
}

## 피로도 레벨 계산
static func get_fatigue_level(current: int, max_value: int) -> FatigueLevel:
	var percentage = float(current) / float(max_value)

	if percentage <= 0.3:
		return FatigueLevel.NORMAL
	elif percentage <= 0.6:
		return FatigueLevel.TIRED
	elif percentage <= 0.9:
		return FatigueLevel.EXHAUSTED
	else:
		return FatigueLevel.COLLAPSED

## 피로도에 따른 이동속도 배율
static func get_move_speed_multiplier(fatigue_level: FatigueLevel) -> float:
	match fatigue_level:
		FatigueLevel.NORMAL:
			return 1.0
		FatigueLevel.TIRED:
			return 0.8
		FatigueLevel.EXHAUSTED:
			return 0.5
		FatigueLevel.COLLAPSED:
			return 0.0
		_:
			return 1.0

## 피로도에 따른 공격력 배율
static func get_attack_power_multiplier(fatigue_level: FatigueLevel) -> float:
	match fatigue_level:
		FatigueLevel.NORMAL:
			return 1.0
		FatigueLevel.TIRED:
			return 0.9
		FatigueLevel.EXHAUSTED:
			return 0.7
		FatigueLevel.COLLAPSED:
			return 0.0
		_:
			return 1.0

## 피로도 증가 계산
static func calculate_move_fatigue(distance: float) -> int:
	return int(distance / 10.0) * FATIGUE_MOVE_PER_10_UNITS

## 유닛의 현재 피로도 상태 정보 반환
static func get_fatigue_info(unit) -> Dictionary:  # Unit 타입은 동적 로딩
	var level = get_fatigue_level(unit.current_fatigue, unit.max_fatigue)
	return {
		"level": level,
		"level_name": FatigueLevel.keys()[level],
		"percentage": float(unit.current_fatigue) / float(unit.max_fatigue) * 100.0,
		"move_speed_multiplier": get_move_speed_multiplier(level),
		"attack_power_multiplier": get_attack_power_multiplier(level),
		"can_act": level != FatigueLevel.COLLAPSED
	}
