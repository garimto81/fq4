# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

First Queen 4 (DOS, 1994) HD 리메이크. 실시간 전술 RPG의 핵심 시스템 "Gocha-Kyara"를 Godot 4.4로 구현.

| 항목 | 내용 |
|------|------|
| 엔진 | Godot 4.4 (Forward+) |
| 언어 | GDScript (게임), Python (에셋 도구) |
| 해상도 | 1280x800 (원본 320x200의 4배) |
| 텍스처 필터 | Nearest (`default_texture_filter=0`) |

## 빌드 및 실행

### Godot 게임

```powershell
# 에디터
.\Godot_v4.4-stable_win64.exe --path godot --editor

# 게임 실행
.\Godot_v4.4-stable_win64.exe --path godot

# 특정 씬
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/ai_test.tscn

# Headless 벤치마크
.\Godot_v4.4-stable_win64.exe --path godot --headless --script res://scripts/test/headless_benchmark.gd
```

메인 씬: `res://scenes/game/main_game.tscn`

### Python 에셋 도구

```powershell
pip install Pillow

# 전체 추출
python tools/fq4_extractor.py extract-all --output output

# 개별: palette, decode, chr, text, bank
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output
python tools/fq4_extractor.py chr GAME/FQ4.CHR --output output/sprites
python tools/fq4_extractor.py text GAME/FQ4MES --output output/text

# SpriteFrames 생성
python tools/spriteframes_generator.py --input output/sprites --output godot/resources/sprites

# 테스트
python tools/test_extraction.py
```

### DOSBox 캡처 파이프라인 (공식 에셋 경로)

RGBE Type 9 디코더 미완성으로 DOSBox 캡처가 공식 경로.

```powershell
python tools/dosbox_capture_workflow.py status    # 상태
python tools/dosbox_capture_workflow.py full       # 전체 (캡처→HD→Godot)
python tools/dosbox_capture_workflow.py upscale    # 캡처→HD
python tools/dosbox_capture_workflow.py deploy     # HD→Godot
```

에셋 흐름: `capture/*.png` (640x400) → `output/screenshots_dosbox_hd/` (2560x1600) → `godot/assets/images/backgrounds/hd/`

### AI 업스케일

```powershell
# 권장: realesrgan-ncnn (GPU 가속)
python tools/upscale_ai.py realesrgan-ncnn -i output/images -o output/images_ai -s 4 -m anime

# 기본 (nearest-neighbor)
python tools/upscale_basic.py batch -i output/images -o output/images_hd -s 4
```

`realesrgan` Python 패키지는 Error 400 발생 가능. `realesrgan-ncnn` 사용 권장.

### 성능 테스트

```powershell
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/performance_test.tscn
# SPACE: 자동 벤치마크 (10/50/100 유닛) | 0: 100 유닛 스폰 | R: 리셋
```

## 아키텍처

### Autoload 싱글톤 (project.godot, 13개)

| 싱글톤 | 경로 | 역할 |
|--------|------|------|
| `GameManager` | `autoload/game_manager.gd` | Gocha-Kyara 핵심: 부대/유닛 관리, 조작 전환, SpatialHash |
| `SaveSystem` | `autoload/save_system.gd` | 세이브/로드 |
| `GraphicsManager` | `autoload/graphics_manager.gd` | 그래픽 설정, 셰이더 |
| `ProgressionSystem` | `autoload/progression_system.gd` | 레벨업, 경험치 |
| `ChapterManager` | `autoload/chapter_manager.gd` | 챕터/맵 전환 |
| `EventSystem` | `events/event_system.gd` | 이벤트 트리거 |
| `AudioManager` | `autoload/audio_manager.gd` | 사운드/BGM |
| `LocalizationManager` | `autoload/localization_manager.gd` | 다국어 (ja/ko/en), CSV 번역 |
| `AccessibilitySystem` | `autoload/accessibility_system.gd` | 색맹 모드, 폰트 스케일, 고대비 |
| `InputManager` | `autoload/input_manager.gd` | 게임패드 감지, 버튼 프롬프트 |
| `PoolManager` | `autoload/pool_manager.gd` | 오브젝트 풀링 |
| `EffectManager` | `autoload/effect_manager.gd` | 데미지 팝업, HitFlash |
| `AchievementSystem` | `autoload/achievement_system.gd` | 업적 (28개) |

참고: `steam_manager.gd`는 GodotSteam 플러그인 설치 후 활성화 (현재 autoload 미등록).

### Godot 경로 매핑

`res://` = `godot/` 디렉토리. Godot 프로젝트 루트는 `godot/` 이므로 `res://scripts/` = `godot/scripts/`.

### Gocha-Kyara 시스템 (핵심)

플레이어는 1명만 직접 조작, 나머지 부대원은 AI가 자동 제어.

**클래스 계층:**
```
Unit (unit.gd) : CharacterBody2D
├── AIUnit (ai_unit.gd) : extends Unit
│   └── PlayerUnit (player_unit.gd) : extends AIUnit
└── EnemyUnit (enemy_unit.gd) : extends Unit
    └── BossUnit (boss_unit.gd) : extends EnemyUnit
```

**Unit**: HP/MP/피로도, 상태머신 (`IDLE`/`MOVING`/`ATTACKING`/`RESTING`/`DEAD`), `_physics_process`에서 상태별 처리.

**AIUnit**: 0.3초 간격 AI tick.
- 9개 `AIState`: `IDLE`, `FOLLOW`, `PATROL`, `CHASE`, `ATTACK`, `RETREAT`, `DEFEND`, `SUPPORT`, `REST`
- 3개 `Personality`: `AGGRESSIVE`, `DEFENSIVE`, `BALANCED`
- 5개 `Formation`: `V_SHAPE`, `LINE`, `CIRCLE`, `WEDGE`, `SCATTERED`
- `SquadCommand`: `GATHER`, `SCATTER`, `ATTACK_ALL`, `DEFEND_ALL`, `RETREAT_ALL`
- `is_player_controlled` = true이면 AI 비활성화

**BossUnit**: 멀티 페이즈 (HP 66%/33% 전환), 광폭화 (20% 이하), 미니언 소환.

**GameManager**: 부대 (`squads: Dictionary {squad_id -> Array}`), SpatialHash 자동 관리.
- `←→` / `ui_left`/`ui_right`: 같은 부대 내 유닛 전환
- `↑↓` / `ui_up`/`ui_down`: 부대 전환

### 시그널 흐름

```
Unit.unit_died → GameManager.unregister_unit() → _check_game_over()
                                               → controlled_unit_changed (조작 유닛 사망 시)

GameManager.state_changed → UI 업데이트 (BATTLE, PAUSED, VICTORY, GAME_OVER)
GameManager.squad_changed → UI 부대 정보 갱신
GameManager.enemy_killed → AchievementSystem 추적
GameManager.boss_defeated → EndingSystem/AchievementSystem

CombatSystem.damage_dealt → EffectManager 데미지 팝업
CombatSystem.unit_killed → ExperienceSystem 경험치 처리
```

### 씬-로컬 시스템 인스턴스 패턴

`CombatSystem` 등 `class_name`이 있는 시스템은 Autoload가 아닌 **씬-로컬 노드**로 생성됨. `MainGameController._ready()`에서 `CombatSystem.new()`로 생성 후 `add_child()`. 각 유닛은 `get_tree().get_nodes_in_group("combat_system")[0]`으로 접근.

### Input 매핑 (`project.godot`)

| 액션 | 키보드 | 게임패드 | 용도 |
|------|--------|----------|------|
| `move_left/right/up/down` | WASD | 좌스틱 | 유닛 이동 |
| `attack` | Space | A 버튼 | 공격 |
| `confirm` | Enter | A 버튼 | 확인 |
| `cancel` | ESC | B 버튼 | 취소 |
| `command` | C | Y 버튼 | 부대 명령 |
| `next_squad/prev_squad` | PgDn/PgUp | RB/LB | 부대 전환 |
| `pause` | ESC | Start | 일시정지 |
| `toggle_inventory` | I | - | 인벤토리 |

유닛 전환은 GameManager에서 `ui_left`/`ui_right` (같은 부대), `ui_up`/`ui_down` (부대 간) 처리.

### 충돌 레이어 (`MapManager`)

| 레이어 | 값 | 용도 |
|--------|-----|------|
| WORLD | 1 | 벽, 지형 |
| PLAYER | 2 | 플레이어 유닛 |
| ENEMY | 4 | 적 유닛 |
| TRIGGER | 8 | 이벤트 트리거 |
| PROJECTILE | 16 | 투사체 |

### 게임 시스템 (`scripts/systems/`)

| 시스템 | 역할 |
|--------|------|
| `CombatSystem` | 데미지 (분산 ±10%, 크리티컬 5%/2배, 명중 95%, 최소 1) |
| `FatigueSystem` | NORMAL(0-30%), TIRED(31-60%, 속도-20%), EXHAUSTED(61-90%, 속도-50%), COLLAPSED(91%+) |
| `StatsSystem` | 능력치 계산 |
| `EquipmentSystem` | 장비 관리 |
| `InventorySystem` | 인벤토리 |
| `ExperienceSystem` | 경험치/레벨업 |
| `MagicSystem` | 마법 시스템 |
| `ShopSystem` | 상점 |
| `UnitSpawner` | 아군 유닛 생성 |
| `EnemySpawner` | 적 유닛 생성 |
| `StatusEffectSystem` | 상태 이상 (POISON, SLOW, STUN 등) tick 처리 |
| `EnvironmentSystem` | 지형 효과 (WATER/COLD/DARK/POISON/FIRE → 디버프) |
| `EndingSystem` | GOOD/NORMAL/BAD 엔딩 판정 |
| `NewGamePlusSystem` | NG+ (적 1.5배, 경험치 0.8배, 골드 1.2배) |
| `SpatialHash` | 공간 분할 해시맵 (100 유닛 최적화) |
| `ObjectPool` | 오브젝트 풀링 |

### 데이터베이스 (`scripts/data/`)

`SpellDatabase`, `ItemDatabase`, `EquipmentDatabase` - 정적 데이터 조회용 클래스.

### 성능 최적화 패턴

**목표:** 100 유닛 동시 전투에서 60 FPS

```gdscript
# Spatial Hash (GameManager 경유)
var enemy = GameManager.find_nearest_enemy(global_position, 300.0, true)
var allies = GameManager.query_units_in_range(global_position, 200.0)

# Object Pooling (PoolManager)
PoolManager.register_pool("arrow", arrow_scene, 20)
var arrow = PoolManager.acquire("arrow")
PoolManager.release("arrow", arrow)
```

전체 순회 (`for unit in GameManager.enemy_units`) 대신 반드시 `SpatialHash` 활용.

### 리소스 데이터 패턴

게임 데이터는 `.tres` 리소스 파일과 커스텀 `Resource` 클래스로 관리:

- `resources/chapters/chapter_*.tres` → `ChapterData` (챕터 메타)
- `resources/dialogues/chapter*/` → `DialogueData` (대화 트리)
- `resources/enemies/*.tres` → `EnemyData` (적 스탯)
- `resources/equipment/*.tres` → `EquipmentData` (장비)
- `resources/items/*.tres` → `ItemData` (아이템)

정적 조회는 Database 클래스 (`scripts/data/`) 사용: `SpellDatabase.get_spell("fireball")`.

## GDScript 주의사항

**타입 어노테이션 제한**: `class_name` 참조 타입을 시그널/변수 어노테이션에 쓸 수 없음 (스크립트 로드 순서 이슈). Autoload 간 참조도 동일.

```gdscript
# ❌ 로드 순서 에러
signal damage_dealt(attacker: Unit, target: Unit, damage: int)
var controlled_unit: Unit = null

# ✅ 무타입 + 주석
signal damage_dealt(attacker, target, damage: int)
var controlled_unit = null  # Unit
```

**CharacterBody2D 기반**: Unit은 `CharacterBody2D` 상속 → `move_and_slide()` 사용.

**Per-Unit 시스템**: `StatsSystem`, `ExperienceSystem`, `EquipmentSystem`은 `RefCounted` 기반으로 각 Unit 인스턴스에 개별 생성됨 (`_init_data_systems()`에서 초기화).

## 에셋 포맷

| 포맷 | 파일 | 설명 |
|------|------|------|
| RGBE | `.B_`, `.R_`, `.G_`, `.E_` | 4-plane 320x200. Type 7(RLE, 정상), Type 9(심볼, **미완성**) |
| CHR | `.CHR` | 8x8 타일 (4bpp planar, 타일당 32B) |
| Bank | `CHRBANK`, `MAPBANK` | 16-bit offset table + 압축 엔트리 |
| FQ4MES | 텍스트 | 799개 메시지, 치환 암호 (복호화 완료) |

## 다국어 (Localization)

CSV 기반 번역 파일: `godot/resources/translations/` (ui, system, items, spells, enemies, dialogues, achievements). 지원 언어: ja(기본), ko, en.

## 문서

| 문서 | 내용 |
|------|------|
| `docs/PRD-0001-first-queen-4-remake.md` | 기획서 (Godot 리메이크) |
| `docs/PRD-0002-fq4-flutter-renewal.md` | Flutter 갱신 기획서 |
| `docs/FQ4_INTEGRATED_GDD.md` | 통합 GDD (Ralplan 합의, 메인 설계 문서) |
| `docs/FQ4MES_FINAL_REPORT.md` | 텍스트 복호화 최종 보고서 |
| `docs/FQ4_GAME_SCRIPT_NOVEL.md` | 게임 스크립트 + 캐릭터 매핑 (소설 형식) |
| `docs/ACHIEVEMENT_SYSTEM.md` | 업적 시스템 가이드 (28개 업적) |
| `docs/ACHIEVEMENT_QUICK_REFERENCE.md` | 업적 빠른 참조 치트시트 |
| `docs/ENVIRONMENT_SYSTEM.md` | 지형 효과 시스템 (6개 타입) |
| `docs/INPUT_MANAGER_GUIDE.md` | 게임패드 시스템 가이드 |
| `docs/LOCALIZATION_MANAGER_GUIDE.md` | 다국어 시스템 (ja/ko/en) |
| `docs/PERFORMANCE_OPTIMIZATION.md` | 100 유닛 60 FPS 최적화 |
| `docs/VISUAL_POLISH_EFFECTS.md` | 이펙트 시스템 가이드 |
| `docs/AI_UPSCALER_GUIDE.md` | AI 업스케일러 비교 및 파이프라인 |
| `docs/STEAM_INTEGRATION_GUIDE.md` | Steam 연동 전체 가이드 |
