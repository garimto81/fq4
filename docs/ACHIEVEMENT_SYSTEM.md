# Achievement System Documentation

First Queen 4 HD Remake 업적 시스템 가이드

## 개요

28개 업적을 통한 플레이어 성취감 제공 및 재플레이 가치 향상.

| 카테고리 | 업적 수 | 설명 |
|---------|--------|------|
| 챕터 클리어 | 10개 | 각 챕터 완료 |
| 보스 처치 | 4개 | 주요 보스 처치 (숨김 1개 포함) |
| 레벨 달성 | 3개 | 레벨 10/30/50 |
| 전투 성과 | 3개 | 적 처치 100/500/1000 |
| 엔딩 | 3개 | Good/Normal/Bad 엔딩 |
| 특수 | 5개 | 스피드런, 무사망, NG+, 대형 마스터, 마법 마스터 |

## 파일 구조

```
godot/
├── scripts/
│   ├── resources/
│   │   └── achievement_data.gd           # 업적 데이터 리소스
│   ├── autoload/
│   │   └── achievement_system.gd         # 업적 시스템 싱글톤
│   ├── ui/
│   │   ├── achievement_popup.gd          # 업적 해금 팝업
│   │   ├── achievements_menu.gd          # 업적 리스트 메뉴
│   │   └── achievement_item.gd           # 업적 아이템 UI
│   └── test/
│       └── achievement_test.gd           # 테스트 씬 스크립트
├── scenes/
│   ├── ui/
│   │   ├── achievement_popup.tscn        # 팝업 씬
│   │   ├── achievements_menu.tscn        # 메뉴 씬
│   │   └── achievement_item.tscn         # 아이템 씬
│   └── test/
│       └── achievement_test.tscn         # 테스트 씬
└── resources/
    └── translations/
        └── achievements.csv              # 업적 번역 (한/영/일)
```

## 업적 타입

### AchievementData.AchievementType

| 타입 | 설명 | 예시 |
|------|------|------|
| `CHAPTER_CLEAR` | 챕터 클리어 | "chapter_1_clear" |
| `BOSS_DEFEAT` | 보스 처치 | "boss_demon_general" |
| `UNIT_LEVEL` | 유닛 레벨 달성 | "level_master" (레벨 50) |
| `TOTAL_KILLS` | 총 처치 수 | "kills_legend" (1000명) |
| `FORMATION_USE` | 대형 사용 | "formation_master" (5개 전부) |
| `SPELL_CAST` | 마법 시전 횟수 | "spell_master" (100회) |
| `ENDING_REACHED` | 엔딩 도달 | "ending_good" |
| `SPEED_RUN` | 스피드런 | "speed_run" (2시간 이내) |
| `NO_DEATH` | 무사망 클리어 | "no_death" |
| `NEWGAME_PLUS` | 회차 플레이 | "ng_plus" |

## API 사용법

### 업적 해금

```gdscript
# 직접 해금
AchievementSystem.unlock("chapter_1_clear")

# 프로그레스 업데이트 (자동 해금)
AchievementSystem.update_progress("kills_hunter", 50)  # 50/100

# 통계 기반 자동 추적
AchievementSystem.add_kill()              # 1명 처치
AchievementSystem.add_spell_cast()        # 마법 1회 시전
AchievementSystem.use_formation(0)        # 대형 사용
AchievementSystem.complete_chapter("chapter_1")
AchievementSystem.defeat_boss("demon_general")
AchievementSystem.reach_level(10)
AchievementSystem.reach_ending("good")
```

### 통합 예시 (Unit 스크립트)

```gdscript
# Unit.gd
func _on_unit_died():
    if is_enemy:
        # 적 처치 시 자동 업적 추적
        if has_node("/root/AchievementSystem"):
            AchievementSystem.add_kill()

    # 보스 체크
    if has_meta("is_boss") and get_meta("is_boss"):
        var boss_id = get_meta("boss_id", "unknown")
        if has_node("/root/AchievementSystem"):
            AchievementSystem.defeat_boss(boss_id)
```

### 레벨업 추적 (ProgressionSystem)

```gdscript
# ProgressionSystem.gd
func level_up(unit: Unit, new_level: int):
    if has_node("/root/AchievementSystem"):
        AchievementSystem.reach_level(new_level)
```

### 챕터 클리어 (ProgressionSystem)

```gdscript
# ProgressionSystem.gd
func _check_chapter_clear():
    if all_cleared:
        if has_node("/root/AchievementSystem"):
            AchievementSystem.complete_chapter("chapter_%d" % current_chapter)
```

## 시그널

### AchievementSystem

| 시그널 | 파라미터 | 용도 |
|--------|---------|------|
| `achievement_unlocked` | `achievement: AchievementData` | 업적 해금 시 발생 |
| `achievement_progress` | `achievement_id: String, current: int, target: int` | 프로그레스 업데이트 |

### 연결 예시

```gdscript
func _ready():
    AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement: AchievementData):
    print("Achievement: %s" % achievement.name_key)
    # 팝업 표시, 사운드 재생 등
```

## 저장/로드

업적 데이터는 SaveSystem에 자동 통합됩니다.

```gdscript
# 저장 시
var save_data = {
    # ...
    "achievements": AchievementSystem.serialize()
}

# 로드 시
AchievementSystem.deserialize(save_data["achievements"])
```

### 데이터 구조

```gdscript
{
    "unlocked": {
        "chapter_1_clear": 1738708800,  # Unix timestamp
        "kills_hunter": 1738709100
    },
    "progress": {
        "kills_slayer": 250,  # 250/500
        "spell_master": 45    # 45/100
    },
    "stats": {
        "total_kills": 250,
        "spells_cast": 45,
        "formations_used": {0: 5, 1: 3},
        "chapters_cleared": ["chapter_1"],
        "bosses_defeated": ["demon_general"],
        # ...
    }
}
```

## UI 통합

### 업적 팝업 (자동)

`AchievementPopup`은 자동으로 업적 해금 시 화면 우측 상단에 슬라이드인/아웃합니다.

```gdscript
# 메인 게임 씬에 추가
const ACHIEVEMENT_POPUP = preload("res://scenes/ui/achievement_popup.tscn")

func _ready():
    var popup = ACHIEVEMENT_POPUP.instantiate()
    add_child(popup)
```

### 업적 메뉴

```gdscript
# PauseMenu.gd
func _on_achievements_button_pressed():
    var menu = load("res://scenes/ui/achievements_menu.tscn").instantiate()
    add_child(menu)
    menu.show_menu()
```

## 숨김 업적

`secret: true`로 설정하면 잠금 상태일 때 "???" 표시:

```gdscript
var ach = AchievementData.new()
ach.id = "boss_all"
ach.secret = true  # 숨김 업적
```

UI에서 자동 처리:
- 잠금: "??? - Secret Achievement"
- 해금: 실제 이름/설명 표시

## Steam 연동 (선택)

GodotSteam 플러그인 사용 시 자동 동기화:

```gdscript
# AchievementSystem.gd (이미 구현됨)
func _sync_steam_achievement(ach: AchievementData):
    if Engine.has_singleton("Steam"):
        Steam.setAchievement(ach.steam_api_name)
        Steam.storeStats()
```

각 업적의 `steam_api_name` 필드에 Steam API 이름 설정.

## 테스트

### 테스트 씬 실행

```powershell
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/achievement_test.tscn
```

### 테스트 기능

| 버튼 | 동작 |
|------|------|
| Unlock Chapter 1 | 1장 클리어 업적 해금 |
| Defeat Boss | 보스 처치 업적 해금 |
| Add 10 Kills | 처치 수 10 증가 |
| Level Up (10) | 레벨 10 업적 해금 |
| Use Formation | 대형 사용 (5회면 자동 해금) |
| Cast 10 Spells | 마법 10회 시전 |
| Reach Good Ending | 해피 엔딩 업적 해금 |
| Start NG+ | NG+ 업적 해금 |
| Complete Game (Fast) | 스피드런 업적 해금 (1시간) |
| Show Achievements Menu | 업적 리스트 메뉴 열기 |
| Reset All Achievements | 모든 업적 초기화 |

### 디버그 출력

```
[Achievement] Unlocked: chapter_1_clear - ACH_CHAPTER_1_NAME
[Achievement] Progress: kills_hunter (50 / 100)
```

## 번역

`resources/translations/achievements.csv`에 한/영/일 번역 정의:

```csv
key,en,ja,ko
ACH_CHAPTER_1_NAME,Chapter 1 Complete,第1章クリア,1장 클리어
ACH_CHAPTER_1_DESC,Clear Chapter 1: The Beginning,第1章「始まり」をクリアする,1장 '시작'을 클리어하세요
```

LocalizationManager가 자동으로 현재 언어에 맞게 표시.

## 확장 가이드

### 새 업적 추가

1. **업적 생성 함수 추가** (`achievement_system.gd`)

```gdscript
func _create_custom_achievement() -> AchievementData:
    var ach = AchievementData.new()
    ach.id = "my_achievement"
    ach.name_key = "ACH_MY_NAME"
    ach.description_key = "ACH_MY_DESC"
    ach.type = AchievementData.AchievementType.CUSTOM
    ach.target_value = 10
    return ach
```

2. **등록** (`_register_all_achievements()`)

```gdscript
_register_achievement(_create_custom_achievement())
```

3. **번역 추가** (`achievements.csv`)

```csv
ACH_MY_NAME,My Achievement,私の実績,나의 업적
ACH_MY_DESC,Do something amazing,すごいことをする,멋진 일을 하세요
```

4. **트리거 구현** (게임 코드)

```gdscript
# 적절한 시점에 호출
AchievementSystem.update_progress("my_achievement", current_value)
```

### 새 통계 추가

```gdscript
# achievement_system.gd의 stats Dictionary에 추가
var stats: Dictionary = {
    # ...
    "new_stat": 0
}

# 추적 함수 추가
func track_new_stat(value: int):
    stats["new_stat"] += value
    update_progress("new_stat_achievement", stats["new_stat"])
```

## 알려진 제한사항

1. **아이콘 미구현**: `achievement.icon_path` 필드는 있지만 실제 아이콘 에셋 미제공
2. **Steam 연동 미테스트**: GodotSteam 플러그인 없이 구현됨
3. **업적 통계 초기화**: 테스트 목적 외 프로덕션에선 초기화 API 제거 권장

## 참고 자료

- GodotSteam: https://godotsteam.com/
- Steam 업적 API: https://partner.steamgames.com/doc/features/achievements
- Godot 싱글톤: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
