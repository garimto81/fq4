# Achievement System Quick Reference

First Queen 4 HD Remake 업적 시스템 빠른 참조.

## 1분 요약

**28개 업적**: 챕터 클리어 10개, 보스 처치 4개, 레벨 3개, 전투 성과 3개, 엔딩 3개, 특수 5개

**자동 추적**: `AchievementSystem.add_kill()`, `add_spell_cast()`, `use_formation()`, `complete_chapter()`, `defeat_boss()`

**UI**: 업적 해금 시 자동 팝업 (우측 상단 슬라이드), 메뉴에서 전체 목록 확인

**저장**: SaveSystem에 자동 통합 (해금 시간, 프로그레스, 통계)

## 게임 코드 통합

### Unit 스크립트

```gdscript
# scripts/units/unit.gd
func die():
    if is_enemy and has_node("/root/AchievementSystem"):
        AchievementSystem.add_kill()
    # ...
```

### 보스 유닛

```gdscript
# scripts/units/boss_unit.gd
func _ready():
    set_meta("is_boss", true)
    set_meta("boss_id", "demon_general")  # "demon_general", "fallen_hero", "demon_king"
```

### 대형 변경

```gdscript
# scripts/systems/formation_system.gd
func set_formation(formation_type: int):
    if has_node("/root/AchievementSystem"):
        AchievementSystem.use_formation(formation_type)
    # ...
```

### 마법 시전

```gdscript
# scripts/systems/spell_system.gd
func cast_spell():
    if has_node("/root/AchievementSystem"):
        AchievementSystem.add_spell_cast()
    # ...
```

### 레벨업

```gdscript
# scripts/autoload/progression_system.gd
func level_up(unit: Unit, new_level: int):
    if has_node("/root/AchievementSystem"):
        AchievementSystem.reach_level(new_level)
    # ...
```

### 엔딩

```gdscript
# scripts/scenes/ending_scene.gd
func show_ending(ending_type: String):  # "good", "normal", "bad"
    if has_node("/root/AchievementSystem"):
        AchievementSystem.reach_ending(ending_type)
    # ...
```

### 뉴게임 플러스

```gdscript
# scripts/ui/title_screen.gd
func start_new_game_plus():
    if has_node("/root/AchievementSystem"):
        AchievementSystem.start_ng_plus()
    # ...
```

## UI 통합

### 메인 게임 씬

```gdscript
# scripts/scenes/main_game.gd
const ACHIEVEMENT_POPUP = preload("res://scenes/ui/achievement_popup.tscn")

func _ready():
    var popup = ACHIEVEMENT_POPUP.instantiate()
    add_child(popup)
```

### 일시정지 메뉴

```gdscript
# scripts/ui/pause_menu.gd
func _on_achievements_button_pressed():
    var menu = load("res://scenes/ui/achievements_menu.tscn").instantiate()
    add_child(menu)
    menu.show_menu()
```

## 업적 ID 목록

### 챕터 클리어
- `chapter_1_clear` ~ `chapter_10_clear`

### 보스 처치
- `boss_demon_general`
- `boss_fallen_hero`
- `boss_demon_king`
- `boss_all` (숨김)

### 레벨
- `level_novice` (10)
- `level_veteran` (30)
- `level_master` (50)

### 전투
- `kills_hunter` (100)
- `kills_slayer` (500)
- `kills_legend` (1000)

### 엔딩
- `ending_good`
- `ending_normal`
- `ending_bad`

### 특수
- `speed_run` (2시간 이내, 숨김)
- `no_death` (무사망, 숨김)
- `ng_plus`
- `formation_master` (5개 대형)
- `spell_master` (마법 100회)

## 테스트

```powershell
# 테스트 씬 실행
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/achievement_test.tscn
```

## 디버그

```gdscript
# 업적 해금 확인
print(AchievementSystem.is_unlocked("chapter_1_clear"))

# 프로그레스 확인
print(AchievementSystem.get_progress("kills_hunter"))  # 0-100

# 완료율 확인
print(AchievementSystem.get_completion_percentage())  # 0.0-100.0

# 통계 확인
print(AchievementSystem.stats["total_kills"])
```

## 시그널 구독

```gdscript
func _ready():
    AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement: AchievementData):
    print("Achievement unlocked: %s" % achievement.id)
    # 커스텀 UI, 사운드, 파티클 등
```

## 새 업적 추가 (4단계)

1. `achievement_system.gd` → `_create_new_achievement()` 함수 작성
2. `_register_all_achievements()` → `_register_achievement(_create_new_achievement())` 호출
3. `achievements.csv` → 번역 추가
4. 게임 코드 → `AchievementSystem.unlock("new_id")` 호출

## 자주 묻는 질문

**Q: 업적이 해금되지 않아요.**
A: `AchievementSystem.is_unlocked("id")` 확인. 디버그 출력 `[Achievement] Unlocked: ...` 확인.

**Q: 프로그레스바가 안 보여요.**
A: `target_value > 1`인 경우만 표시. `current_progress > 0`이어야 함.

**Q: 숨김 업적이 보여요.**
A: `secret: true`이고 `is_unlocked() == false`일 때만 "???"로 표시.

**Q: Steam 연동은?**
A: GodotSteam 플러그인 설치 시 자동. `steam_api_name` 필드 확인.

**Q: 저장이 안 돼요.**
A: `SaveSystem.save_game(slot)` 호출 시 자동 저장. `achievements` 필드 확인.

## 파일 경로

| 파일 | 경로 |
|------|------|
| 시스템 | `godot/scripts/autoload/achievement_system.gd` |
| 데이터 | `godot/scripts/resources/achievement_data.gd` |
| 팝업 | `godot/scenes/ui/achievement_popup.tscn` |
| 메뉴 | `godot/scenes/ui/achievements_menu.tscn` |
| 번역 | `godot/resources/translations/achievements.csv` |
| 테스트 | `godot/scenes/test/achievement_test.tscn` |
| 문서 | `docs/ACHIEVEMENT_SYSTEM.md` |
