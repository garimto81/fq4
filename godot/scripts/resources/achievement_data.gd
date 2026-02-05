extends Resource
class_name AchievementData
## 업적 데이터 리소스

@export var id: String = ""
@export var name_key: String = ""  # LocalizationManager 키
@export var description_key: String = ""  # LocalizationManager 키
@export var icon_path: String = ""
@export var secret: bool = false  # 숨김 업적 여부

# 업적 조건
enum AchievementType {
	CHAPTER_CLEAR,      # 챕터 클리어
	BOSS_DEFEAT,        # 보스 처치
	UNIT_LEVEL,         # 유닛 레벨 달성
	TOTAL_KILLS,        # 총 처치 수
	FORMATION_USE,      # 대형 사용
	SPELL_CAST,         # 마법 시전 횟수
	ENDING_REACHED,     # 엔딩 도달
	SPEED_RUN,          # 스피드런
	NO_DEATH,           # 무사망 클리어
	COLLECT_ITEMS,      # 아이템 수집
	GOLD_EARNED,        # 골드 획득량
	NEWGAME_PLUS        # 회차 플레이
}

@export var type: AchievementType = AchievementType.CHAPTER_CLEAR
@export var target_value: int = 1  # 달성 조건 값
@export var target_id: String = ""  # 특정 챕터/보스/엔딩 ID (필요시)

# Steam 연동용
@export var steam_api_name: String = ""  # Steam 업적 API 이름

## 프로그레스 체크
func check_progress(current_value: int) -> bool:
	return current_value >= target_value
