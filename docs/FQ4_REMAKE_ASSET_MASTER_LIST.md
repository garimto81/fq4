# First Queen 4 리메이크 에셋 마스터 리스트

**Version**: 1.0.0 | **Date**: 2026-02-08 | **Engine**: Flutter/Flame + Rive + Godot 4.4

---

## 1. 프로젝트 개요

First Queen 4 (DOS, 1994) 실시간 전술 RPG를 Flutter/Rive/Godot 기반으로 크로스 플랫폼 리메이크.
현대 모바일 시대에 맞는 자동화 전투, 배속 시스템, 터치 최적화 UI를 접목.

| 항목 | 내용 |
|------|------|
| 원작 | First Queen 4 (DOS, 1994, Kure Software Koubou) |
| 장르 | 실시간 전술 RPG (Gocha-Kyara) |
| 엔진 | Flutter 3.24+ / Flame 1.18+ / Rive 0.13+ / Godot 4.4 |
| 플랫폼 | iOS, Android, Windows, macOS, Web + Steam (Godot) |
| 해상도 | 논리 1280x800 (원본 320x200의 4배), 기기 적응형 |

### 1.1 엔진별 역할

| 엔진 | 역할 | 플랫폼 |
|------|------|--------|
| **Flutter/Flame** | 모바일/웹 메인 클라이언트, UI, 게임 루프 | iOS, Android, Web, Desktop |
| **Rive** | 벡터 애니메이션 (캐릭터, 적, 이펙트, UI) | Flutter 내 통합 |
| **Godot 4.4** | PC/Steam 빌드, 프로토타입 레퍼런스 | Windows, Steam |

### 1.2 현재 보유 에셋 현황

| 카테고리 | 보유 수량 | 설명 |
|----------|----------|------|
| GDScript 코드 | 78파일 (~12,000 LOC) | 핵심 시스템 16개 구현 완료 |
| 씬 파일 (.tscn) | 38개 | 맵 9개, UI 11개, 이펙트 5개 등 |
| 리소스 (.tres) | 88개 | 적 25종, 아이템 10종, 장비 11종 등 |
| 이미지 에셋 | 43장 | 캐릭터 6장, 배경 12장, 오프닝 10장 등 |
| 셰이더 | 4개 | CRT, palette swap, outline, pixelate |
| 번역 CSV | 7파일 | ja/ko/en (UI, system, items, spells, enemies, dialogues, achievements) |
| 오디오 | 0개 | 전량 미확보 |
| Rive 파일 | 0개 | 전량 신규 제작 필요 |
| Dart 코드 | 0파일 | 전량 신규 작성 |

---

## 2. 이미지/그래픽 에셋

### 2.1 캐릭터 에셋

| 항목 | 현재 보유 | 최종 필요 | Gap | 우선순위 | 재활용 | 담당 |
|------|----------|----------|-----|---------|--------|------|
| 아군 캐릭터 스프라이트시트 | 3장 + HD 3장 | Godot: 3장 / Rive: 0장 | Rive 전면 신규 | P0 | Godot에서만 | 아티스트 |
| 캐릭터 초상화 (대화 UI) | 0장 | 7~15장 | 전면 신규 | P0 | 불가 | 아티스트 |
| 캐릭터 일러스트 | 3장 (SUEMI_A1~A3) | 7~10장 | 4~7장 부족 | P1 | 3장 재활용 | 아티스트 |

**아군 캐릭터 목록** (5명):

| 코드명 | 캐릭터 | 역할 | 클래스 |
|--------|--------|------|--------|
| たぬけ | 아레스 | 주인공 | 전사 |
| うらな | 아레인 | 히로인 | 마법사 |
| しぬせ | 시누세 | 동료 | 검사 |
| そとか | 소토카 | 동료 | 기사 |
| たろも | 타로 | 동료 | 마법사 |

### 2.2 적 캐릭터 에셋

| 분류 | 종류 | 수량 | 현재 | Gap | 우선순위 |
|------|------|------|------|-----|---------|
| 소형 일반 | goblin, goblin_archer, goblin_shaman, slime, wolf, skeleton, bandit, orc | 8종 | .tres만 존재 | 개별 스프라이트 없음 | P0 |
| 대형 일반 | dark_knight, golem, wyvern, lich, demon, frost_giant, water_elemental, swamp_beast, ice_wolf, poison_spider, shadow_wraith, corrupted_noble, fallen_hero | 13종 | .tres만 존재 | 개별 스프라이트 없음 | P1 |
| 보스 | goblin_chief/king, demon_general, demon_king | 3종 | .tres만 존재 | 전용 에셋 없음 | P1 |
| **합계** | | **25종** | | | |

### 2.3 배경/맵 이미지

| 항목 | 현재 보유 | 최종 필요 | Gap | 우선순위 |
|------|----------|----------|-----|---------|
| HD 배경 (DOSBox 캡처) | 12장 | 30장 | 18장 | P1 |
| 타일셋 이미지 | 0세트 | 5세트 | 5세트 전면 신규 | P0 |
| 환경 오브젝트 | 0개 | 30~50종 | 전면 신규 | P1 |

**타일셋 5세트**:

| 세트 | 환경 | 사용 챕터 | 타일 종류 |
|------|------|----------|----------|
| Forest | 숲/초원 | Ch1, Ch3 | 잔디, 나무, 길, 물, 다리 |
| Desert | 사막/황야 | Ch2, Ch4 | 모래, 바위, 오아시스, 유적 |
| Snow | 설산/동굴 | Ch5, Ch6 | 눈, 얼음, 동굴벽, 횃불 |
| Dungeon | 던전/성 | Ch7, Ch8 | 석벽, 바닥, 문, 계단, 함정 |
| Castle | 마왕성/최종 | Ch9, Ch10 | 장식벽, 왕좌, 마법진, 용암 |

### 2.4 UI/아이콘

| 항목 | 현재 | 필요 | Gap | 우선순위 |
|------|------|------|-----|---------|
| UI 스프라이트 | 3장 + HD 3장 | Flutter에서 불필요 | - | - |
| 아이템 아이콘 | 0개 | 10종 | 전면 신규 | P1 |
| 장비 아이콘 | 0개 | 14종 | 전면 신규 | P1 |
| 마법 아이콘 | 0개 | 8종 | 전면 신규 | P1 |
| 상태이상 아이콘 | 0개 | 6종 | 전면 신규 | P1 |
| **아이콘 합계** | **0개** | **38종** | **전면 신규** | |

### 2.5 기타 이미지

| 항목 | 현재 | 필요 | 재활용 | 우선순위 |
|------|------|------|--------|---------|
| 오프닝 일러스트 | 10장 (FQOP_01~10) | 10장 | 전체 재활용 | P2 |
| 타이틀 화면 | 1장 | 1장 | 재활용 | P2 |
| 로고/스플래시 | 2장 | 2장 | 재활용 | P2 |
| 로고 (FQ4G16, FQGLOGO) | 2장 | 2장 | 재활용 | P2 |

---

## 3. Rive 벡터 애니메이션 에셋 (전량 신규)

### 3.1 아군 캐릭터 Rive (.riv)

| 캐릭터 | 파일명 | 애니메이션 상태 수 | 상세 |
|--------|--------|------------------|------|
| 아레스 | `ares.riv` | 16 | idle(x3 피로도), walk(x3), attack(melee/critical/skill), spell(cast/end), hit(normal/critical), death, status overlay(x6) |
| 아레인 | `alein.riv` | 16 | 동일 구조 |
| 시누세 | `sinuse.riv` | 16 | 동일 구조 |
| 소토카 | `sotoka.riv` | 16 | 동일 구조 |
| 타로 | `taro.riv` | 16 | 동일 구조 |
| **합계** | **5 .riv** | **80 states** | 각 파일 500KB 이하 |

**State Machine 구성**:
```
Idle Layer:
  - idle_normal (피로도 0-30%)
  - idle_tired (피로도 31-60%)
  - idle_exhausted (피로도 61%+)

Movement Layer:
  - walk_normal / walk_tired / walk_exhausted

Combat Layer:
  - attack_melee / attack_critical / attack_skill
  - spell_cast / spell_end

Damage Layer:
  - hit_normal / hit_critical
  - death

Status Overlay Layer (독립):
  - poison / burn / stun / freeze / slow / blind
```

### 3.2 적 Rive (.riv)

| 분류 | 수량 | States/파일 | 템플릿 | 비고 |
|------|------|-----------|--------|------|
| 소형 일반 | 8종 | 10 | humanoid_small 템플릿 | idle, walk, attack, hit, death + status |
| 대형 일반 | 13종 | 10 | monster_large 템플릿 | 동일 |
| 보스 | 3종 | 18 | boss 템플릿 | 페이즈 전환 + 광폭화 + 미니언 소환 |
| **합계** | **24 .riv** | **~258 states** | **3 템플릿** | 스킨 변형으로 확장 |

### 3.3 이펙트 Rive (.riv)

| 이펙트 | 파일명 | 상세 |
|--------|--------|------|
| 근접 타격 | `melee_hit.riv` | 일반/크리티컬 2종 |
| 원거리 타격 | `ranged_hit.riv` | 화살/투사체 |
| 불 마법 | `spell_fire.riv` | FIRE_BALL |
| 얼음 마법 | `spell_ice.riv` | ICE_BOLT |
| 번개 마법 | `spell_thunder.riv` | THUNDER |
| 회복 마법 | `spell_heal.riv` | HEAL |
| 전체 회복 | `spell_mass_heal.riv` | MASS_HEAL |
| 버프 마법 | `spell_buff.riv` | SHIELD, HASTE |
| 상태이상 6종 | `status_{type}.riv` | poison, burn, stun, freeze, slow, blind |
| 레벨업 | `level_up.riv` | 레벨업 연출 |
| 사망 | `death.riv` | 사망 파티클 |
| 데미지 팝업 | `damage_popup.riv` | NORMAL/CRITICAL/MISS/EVADE/HEAL 5종 |
| **합계** | **~16 .riv** | |

### 3.4 UI Rive (.riv)

| UI 요소 | 파일명 | 상세 |
|---------|--------|------|
| 버튼 세트 | `ui_buttons.riv` | hover/press/disabled states |
| HP/MP/피로도 게이지 | `ui_gauge.riv` | HP(적/황/녹), MP(청), 피로도(4단계) |
| 화면 전환 | `ui_transition.riv` | 페이드, 맵 전환 |
| 타이틀 | `ui_title.riv` | 로고 애니메이션, 메뉴 전환 |
| 인벤토리 | `ui_inventory.riv` | 아이템/장비 슬롯 |
| 업적 팝업 | `ui_achievement.riv` | 업적 해금 연출 |
| 대화 UI | `ui_dialogue.riv` | 대화창 등장/퇴장, 타이핑 |
| 미니맵 | `ui_minimap.riv` | 미니맵 프레임, 유닛 아이콘 |
| **합계** | **8 .riv** | |

### 3.5 Rive 에셋 총합

| 카테고리 | 파일 수 | 총 States | 제작 공수 (인일) |
|----------|---------|-----------|----------------|
| 아군 캐릭터 | 5 | 80 | 10~15 |
| 적 | 24 | ~258 | 24~36 (템플릿 활용) |
| 이펙트 | 16 | ~48 | 8~12 |
| UI | 8 | ~40 | 8~12 |
| **합계** | **53** | **~426** | **50~75 인일** |

---

## 4. 오디오 에셋 (전량 신규)

### 4.1 BGM

| 카테고리 | 수량 | 포맷 | 길이 | 우선순위 |
|----------|------|------|------|---------|
| 타이틀 BGM | 1곡 | OGG Vorbis | 1:30~3:00 | P0 |
| 필드 BGM (환경별) | 5~8곡 | OGG Vorbis | 2:00~3:00 (루프) | P0 |
| 전투 BGM (일반) | 2곡 | OGG Vorbis | 2:00~3:00 (루프) | P0 |
| 전투 BGM (보스) | 2곡 | OGG Vorbis | 2:00~3:00 (루프) | P0 |
| 이벤트 BGM | 3~5곡 | OGG Vorbis | 1:00~2:00 | P1 |
| 엔딩 BGM | 3곡 | OGG Vorbis | 2:00~4:00 | P1 |
| **합계** | **16~21곡** | | | |

### 4.2 SFX

| 카테고리 | 수량 | 포맷 | 길이 | 우선순위 |
|----------|------|------|------|---------|
| 전투 SFX (검격/타격/사망/회복 등) | 15~20종 | OGG/WAV | 0.1~2초 | P0 |
| UI SFX (커서/결정/취소/레벨업/업적) | 10~15종 | OGG/WAV | 0.1~1초 | P0 |
| 환경 SFX (물/바람/불/독/얼음/숲) | 6~10종 | OGG | 1~5초 (루프) | P1 |
| 대화 SFX (타이핑/선택/전환) | 3~5종 | WAV | 0.1~0.5초 | P2 |
| 마법 SFX (8종 마법별) | 8종 | OGG | 0.5~2초 | P1 |
| **합계** | **42~58종** | | | |

### 4.3 오디오 사양

| 항목 | BGM | SFX |
|------|-----|-----|
| 포맷 | OGG Vorbis | OGG Vorbis / WAV |
| 비트레이트 | 128kbps+ | 44.1kHz |
| 채널 | 스테레오 | 모노 |
| 최대 파일 크기 | 3MB | 200KB |
| 루프 | 필수 | 선택 |

---

## 5. 맵/레벨 에셋

### 5.1 맵 목록 (10챕터 x 3맵 = 30맵)

| 챕터 | 맵 1 | 맵 2 | 맵 3 | 환경 | .tscn 현황 |
|------|------|------|------|------|-----------|
| Ch1 | castle_entrance | forest_path | goblin_camp | Forest | 3/3 존재 |
| Ch2 | village_square | training_grounds | mercenary_guild | Desert | 3/3 존재 |
| Ch3 | dark_forest_entrance | corrupted_shrine | dark_knight_arena | Forest/Dark | 3/3 존재 |
| Ch4 | river_crossing | swamp_maze | water_temple | Swamp | 0/3 미구현 |
| Ch5 | mountain_pass | ice_cavern | frost_peak | Snow | 0/3 미구현 |
| Ch6 | poison_marsh | spider_nest | corrupted_garden | Poison/Dark | 0/3 미구현 |
| Ch7 | castle_town | noble_court | shadow_throne | Castle | 0/3 미구현 |
| Ch8 | demon_frontier | fallen_fortress | general_arena | Dungeon | 0/3 미구현 |
| Ch9 | demon_wasteland | demon_castle_gate | demon_throne | Castle/Dark | 0/3 미구현 |
| Ch10 | final_approach | demon_king_hall | epilogue_field | Castle/Final | 0/3 미구현 |
| **합계** | | | | | **9/30 (30%)** |

### 5.2 맵 에셋 구성

| 에셋 | 필요 수량 | 현재 | Gap | 우선순위 |
|------|----------|------|-----|---------|
| Godot 씬 (.tscn) | 30개 | 9개 | 21개 | P0 (Godot) |
| Tiled 맵 (.tmx) | 30개 | 0개 | 30개 | P0 (Flutter) |
| 타일셋 이미지 | 5세트 | 0세트 | 5세트 | P0 |
| 맵 배경 이미지 | 30장 | 12장 | 18장 | P1 |
| 환경 오브젝트 (나무/바위/건물 등) | 30~50종 | 0종 | 전면 신규 | P1 |

---

## 6. 개발 에셋 (코드/데이터)

### 6.1 Flutter/Dart 코드 (신규 ~82파일)

| 레이어 | 파일 수 | 상세 |
|--------|---------|------|
| `core/constants/` | 5 | combat, fatigue, ai, spell, level 상수 |
| `core/utils/` | 3 | math, extensions, logger |
| `data/models/` | 8 | unit, spell, item, equipment, chapter, dialogue, enemy, save (freezed) |
| `data/repositories/` | 4 | save, settings, achievement, game_data |
| `data/databases/` | 2 | Isar 스키마 |
| `game/fq4_game.dart` | 1 | FlameGame 메인 |
| `game/components/units/` | 5 | unit, ai_unit, player_unit, enemy_unit, boss_unit |
| `game/components/map/` | 3 | map, terrain, trigger |
| `game/components/effects/` | 4 | damage_popup, hit_flash, magic, death |
| `game/components/ui/` | 3 | hud, minimap, floating_hp |
| `game/systems/` | 14 | 전 시스템 1:1 이식 |
| `game/managers/` | 4 | game, chapter, audio, save |
| `game/ai/` | 4 | ai_brain, personality, formation, squad_command |
| `presentation/screens/` | 5 | title, game, inventory, settings, achievement |
| `presentation/widgets/` | 8 | hud, dialogs, rive_widgets |
| `presentation/providers/` | 6 | Riverpod state providers |
| `l10n/` | 3 | ARB 파일 (ja, ko, en) |
| 모바일 전용 | 5 | 터치 입력, 배속, 방치, 클라우드 세이브 |
| **합계** | **~82파일** | **~15,000 LOC 추정** |

### 6.2 GDScript -> Dart 이식 비율

| 시스템 | GDScript LOC | 이식 난이도 | 로직 재사용률 |
|--------|-------------|-----------|-------------|
| CombatSystem | 243 | 낮음 | 95% |
| AIUnit (Gocha-Kyara) | 571 | 중간 | 90% |
| MagicSystem | 241 | 낮음 | 95% |
| StatusEffectSystem | 265 | 낮음 | 95% |
| EnvironmentSystem | 239 | 중간 | 80% |
| SpatialHash | 61 | 낮음 | 100% |
| GameManager | 383 | 중간 | 85% |
| SaveSystem | 345 | 중간 | 70% |
| FatigueSystem | ~80 | 낮음 | 100% |
| BossUnit | 103 | 낮음 | 95% |
| EndingSystem | 90 | 낮음 | 90% |
| NewGamePlusSystem | 171 | 낮음 | 90% |
| AchievementSystem | ~200 | 낮음 | 85% |
| **전체** | **~12,000** | | **88% 재사용** |

### 6.3 공유 데이터 (JSON 변환 필요)

Godot .tres -> JSON 변환하여 양 엔진에서 공유:

| 데이터 | 현재 형식 | JSON 파일 | 수량 |
|--------|----------|----------|------|
| 마법 | SpellData Resource | `spells.json` | 8종 |
| 아이템 | ItemData .tres | `items.json` | 10종 (최종 15~20) |
| 장비 | EquipmentData .tres | `equipment.json` | 11종 (최종 20~30) |
| 적 | EnemyData .tres | `enemies.json` | 25종 |
| 챕터 | ChapterData .tres | `chapters.json` | 10종 |
| 레벨 테이블 | LevelTable .tres | `level_table.json` | 1개 (50레벨) |
| 대화 | DialogueData .tres | `dialogues/*.json` | 30+개 (최종 60~80) |
| 상태이상 | 코드 내 Dictionary | `status_effects.json` | 6종 |

### 6.4 셰이더 이식

| Godot 셰이더 | Flutter 대응 | 이식 난이도 |
|-------------|-------------|-----------|
| `crt_filter.gdshader` (60줄) | FragmentShader | 중 |
| `palette_swap.gdshader` (23줄) | FragmentShader | 낮음 |
| `outline.gdshader` | CustomPaint | 낮음 |
| `pixelate.gdshader` | FragmentShader | 낮음 |

---

## 7. UI/UX 에셋 (Flutter 신규 설계)

### 7.1 화면 목록

| 화면 | Flutter 위젯 | Rive 연동 | 우선순위 |
|------|-------------|----------|---------|
| 타이틀 화면 | TitleScreen | ui_title.riv | P0 |
| 게임 화면 (Flame) | GameScreen + HUD Overlay | ui_gauge.riv | P0 |
| 인벤토리 | InventoryScreen | ui_inventory.riv | P0 |
| 장비 | EquipmentScreen | - | P1 |
| 상점 | ShopScreen | - | P1 |
| 대화 UI | DialogueOverlay | ui_dialogue.riv | P0 |
| 일시정지 메뉴 | PauseMenu | - | P0 |
| 설정 | SettingsScreen | - | P1 |
| 업적 | AchievementScreen | ui_achievement.riv | P2 |
| 세이브/로드 | SaveLoadScreen | - | P1 |
| 부대 편성 | SquadScreen | - | P1 |
| 캐릭터 프로필 | CharacterProfileScreen | - | P2 |

### 7.2 모바일 터치 UI (신규)

| UI 요소 | 설명 | 우선순위 |
|---------|------|---------|
| 가상 조이스틱 | 이동 컨트롤 (좌측 하단) | P0 |
| 액션 버튼 | 공격/마법/아이템 (우측 하단) | P0 |
| 부대 명령 바 | 집합/분산/공격/방어/후퇴 (상단 또는 스와이프) | P0 |
| 부대원 전환 | 좌우 스와이프 or 탭 | P0 |
| 부대 전환 | 상하 스와이프 | P0 |
| 미니맵 | 우측 상단 (탭으로 확대) | P1 |

---

## 8. 현대 모바일 자동화 기능 에셋

Gocha-Kyara가 이미 AI 기반이므로, "자동 전투"는 플레이어 유닛까지 AI에 위임하는 기능.

### 8.1 기능 목록

| 기능 | 에셋 종류 | 수량 | 우선순위 | 비고 |
|------|----------|------|---------|------|
| **자동 전투 ON/OFF** | 토글 버튼 아이콘 + Rive 애니메이션 | 1종 | P0 | `is_player_controlled = false`로 전환 |
| **배속 (1x/2x/3x)** | 배속 아이콘 3종 + 전환 애니메이션 | 1종 | P0 | `Engine.time_scale` / FlameGame delta 배율 |
| **자동 전투 AI 전략** | 설정 패널 UI (공격적/방어적/균형) | 1개 위젯 | P1 | 기존 Personality 시스템 재활용 |
| **대화/컷씬 스킵** | 스킵 버튼 아이콘 | 1종 | P0 | 전체 대화 즉시 넘기기 |
| **방치/유휴 모드** | 결과 요약 화면 | 1개 Screen | P2 | 오프라인 시간 보상 |
| **자동 편성** | 편성 추천 UI | 1개 위젯 | P2 | 스탯 기반 최적 배치 |
| **자동 장비** | 장비 최적화 버튼 + 비교 UI | 1개 위젯 | P2 | 장비 스탯 비교 |
| **미니맵 자동 이동** | 미니맵 탭 경로 탐색 | 미니맵 위젯 | P1 | A* 경로탐색 |

### 8.2 자동화 시스템 코드

| 시스템 | 파일 | LOC 추정 | 기존 자산 |
|--------|------|---------|----------|
| AutoBattleController | `auto_battle_controller.dart` | ~200 | AIUnit 로직 90% 재사용 |
| SpeedController | `speed_controller.dart` | ~100 | 신규 |
| IdleRewardCalculator | `idle_reward_calculator.dart` | ~300 | 신규 |
| AutoFormation | `auto_formation.dart` | ~200 | Formation 시스템 재활용 |
| AutoEquip | `auto_equip.dart` | ~200 | EquipmentSystem 재활용 |

---

## 9. 에셋 파이프라인

### 9.1 전체 흐름

```
[원본 DOS 에셋]
    |
    +-- tools/fq4_extractor.py -----> 텍스트/팔레트/타일 추출
    +-- tools/dosbox_capture.py ----> 배경 캡처 (640x400)
    +-- tools/upscale_ai.py -------> HD 업스케일 (realesrgan-ncnn 4x)
    |
    v
[중간 에셋 (output/)]
    |
    +--[Godot 경로]------> godot/assets/ --> .tres Resource --> Godot 빌드
    |
    +--[공유 데이터]-----> shared/
    |                      +-- data/*.json (적/아이템/장비/마법/챕터)
    |                      +-- translations/*.csv (ja/ko/en)
    |                      +-- maps/*.tmx (Tiled Editor)
    |                      +-- audio/bgm/*.ogg, sfx/*.ogg
    |
    +--[Flutter 경로]----> fq4_flutter/assets/
    |                      +-- data/ (JSON)
    |                      +-- audio/ (공유 OGG)
    |                      +-- rive/ (Rive Editor 신규 제작)
    |                      +-- images/ (배경/일러스트)
    |
    +--[Rive 경로]-------> Rive Editor (.rev 프로젝트)
                               |
                               v
                           .riv export --> assets/rive/
```

### 9.2 도구 매트릭스

| 도구 | 용도 | 입력 | 출력 |
|------|------|------|------|
| `fq4_extractor.py` | 원본 추출 | DOS 파일 | PNG/TXT |
| `dosbox_capture_workflow.py` | 배경 캡처 | DOSBox | PNG (640x400) |
| `upscale_ai.py` | AI 업스케일 | PNG | HD PNG (4x) |
| `spriteframes_generator.py` | SpriteFrames | PNG | .tres |
| **tres_to_json.py (신규 필요)** | 리소스 변환 | .tres | .json |
| Rive Editor | 벡터 애니메이션 | 디자인 | .riv |
| Tiled Map Editor | 맵 제작 | 타일셋 | .tmx |
| Audacity/FL Studio | 사운드 편집 | 녹음 | .ogg/.wav |

---

## 10. 총 에셋 수량 요약

| 카테고리 | 현재 보유 | 최종 필요 | 신규 제작 | 난이도 |
|----------|----------|----------|----------|--------|
| 이미지/래스터 | 43장 | 80~100장 | 40~60장 | 중 |
| Rive 벡터 (.riv) | 0개 | 53개 | 53개 | **상** |
| 오디오 (BGM+SFX) | 0개 | 58~79종 | 58~79종 | **상** |
| 맵/타일 | 9 씬 | 30 맵 + 5 타일셋 | 21맵 + 30 tmx + 5 타일셋 | 중 |
| 데이터 (JSON) | 88 .tres | JSON 변환 + 확장 | 변환 작업 | 하 |
| 번역 | 7 CSV | 7 CSV + 3 ARB | ARB 변환 | 하 |
| UI 위젯 (Flutter) | 0개 | 12~15 Screen | 12~15개 | 중 |
| Dart 코드 | 0파일 | ~82파일 (~15K LOC) | ~82파일 | **상** |
| GDScript (Godot 추가) | 78파일 | ~83파일 | ~5파일 | 하 |
| 셰이더 (Flutter 이식) | 4 .gdshader | 4 FragmentShader | 4개 | 하 |
| 아이콘 | 0개 | 38종 | 38종 | 중 |
| 캐릭터 초상화 | 0장 | 7~15장 | 7~15장 | 중 |

---

## 11. 팀 구성 제안

### 11.1 필요 역할

| 역할 | 인원 | 주요 담당 | 예상 공수 |
|------|------|----------|----------|
| **Rive 아티스트** | 1~2명 | 캐릭터 53종 Rive 제작 | 50~75 인일 |
| **2D 아티스트** | 1명 | 타일셋, 배경, 초상화, 아이콘 | 40~60 인일 |
| **Flutter 개발자** | 2명 | Dart 코드 82파일, UI, 시스템 이식 | 60~90 인일 |
| **Godot 개발자** | 1명 | 미완성 시스템, 맵 추가, 유지보수 | 30~40 인일 |
| **레벨 디자이너** | 1명 | 30맵 Tiled 제작 | 30~45 인일 |
| **사운드 디자이너** | 1명 | BGM 16~21곡 + SFX 42~58종 | 40~60 인일 |
| **QA** | 1명 | 멀티 플랫폼 테스트 | 전체 기간 |

### 11.2 병렬 작업 가능 영역

```
[Week 1-4] 병렬 시작
  +-- Rive 아티스트: 캐릭터 템플릿 + 아레스 1체 제작
  +-- 2D 아티스트: 타일셋 Forest/Desert 2세트 제작
  +-- Flutter 개발자 A: core/constants + data/models (freezed)
  +-- Flutter 개발자 B: game/systems 이식 (combat, fatigue, stats)
  +-- Godot 개발자: Ch4-7 맵 추가
  +-- 레벨 디자이너: Tiled 맵 Ch1-3 제작
  +-- 사운드: BGM 타이틀 + 필드 3곡 작곡

[Week 4] Rive 성능 게이트 (Go/No-Go)
  100 Rive 인스턴스 60FPS 달성?
  +-- YES: Rive 계속
  +-- NO: Sprite Sheet 대안 전환
```

---

## 12. 우선순위별 에셋 로드맵

### P0 - MVP 필수 (8주)

| 에셋 | 수량 | 담당 |
|------|------|------|
| 아군 캐릭터 Rive 5종 | 5 .riv | Rive 아티스트 |
| 적 소형 Rive 8종 | 8 .riv | Rive 아티스트 |
| Forest/Desert 타일셋 | 2세트 | 2D 아티스트 |
| 캐릭터 초상화 5장 | 5장 | 2D 아티스트 |
| 타이틀 + 전투 BGM | 3곡 | 사운드 |
| 전투/UI SFX | 25종 | 사운드 |
| Flutter core/game/systems | 40파일 | Flutter 개발자 |
| Ch1-3 Tiled 맵 | 9 .tmx | 레벨 디자이너 |
| 자동 전투/배속 UI | 2 위젯 | Flutter 개발자 |
| HUD/대화 UI | 3 위젯 | Flutter 개발자 |

### P1 - 전체 콘텐츠 (12주)

| 에셋 | 수량 | 담당 |
|------|------|------|
| 적 대형 Rive 13종 | 13 .riv | Rive 아티스트 |
| 보스 Rive 3종 | 3 .riv | Rive 아티스트 |
| 마법 이펙트 Rive 8종 | 8 .riv | Rive 아티스트 |
| Snow/Dungeon/Castle 타일셋 | 3세트 | 2D 아티스트 |
| 배경 이미지 18장 추가 | 18장 | 2D 아티스트/AI |
| 아이콘 38종 | 38장 | 2D 아티스트 |
| 필드 + 이벤트 BGM | 8~13곡 | 사운드 |
| 환경/마법 SFX | 14~18종 | 사운드 |
| Ch4-10 Tiled 맵 | 21 .tmx | 레벨 디자이너 |
| 추가 대화 데이터 | 20~40개 | 기획자 |

### P2 - 폴리시 (4주)

| 에셋 | 수량 | 담당 |
|------|------|------|
| UI Rive 8종 | 8 .riv | Rive 아티스트 |
| 상태이상 Rive 6종 | 6 .riv | Rive 아티스트 |
| 캐릭터 일러스트 추가 | 4~7장 | 2D 아티스트 |
| 엔딩 BGM | 3곡 | 사운드 |
| 대화 SFX | 3~5종 | 사운드 |
| 방치/도감/설정 UI | 3 Screen | Flutter 개발자 |
| 클라우드 세이브 | 4파일 | Flutter 개발자 |

---

## 13. 핵심 리스크

| 리스크 | 영향도 | 대응 전략 |
|--------|--------|----------|
| **Rive 100 유닛 성능 미달** | 치명적 | 4주차 Go/No-Go 게이트. 실패 시 Sprite Sheet 폴백 |
| **오디오 전량 미확보** | 높음 | Phase 1에서 로열티 프리로 프로토타입, 커스텀 작곡은 후순위 |
| **원작 저작권 미확인** | 높음 | Kure Software Koubou 라이선스 확인 필수 |
| **맵 30개 제작 병목** | 중간 | 타일셋 5세트 제한, 맵 템플릿 재사용 |
| **Godot/Flutter 데이터 불일치** | 중간 | 공유 JSON 데이터 레이어 선행 구축 |

---

## 14. PRD-0002 상세 분석 보완

PRD-0002 전문 (2170줄) 분석을 통해 보완한 상세 사양.

### 14.1 Flutter/Flame 아키텍처 상세

PRD-0002 Section 8에서 정의된 전체 구조:

```
Flutter App
├── Flutter UI Layer (Screens, Widgets, Dialogs, Overlays)
├── Riverpod State Management
│   ├── gameStateProvider (GameState: menu/battle/paused/gameOver/victory)
│   ├── controlledUnitProvider (현재 조작 유닛)
│   ├── squadProvider (부대 정보)
│   ├── inventoryProvider (인벤토리)
│   ├── settingsProvider (설정)
│   └── achievementProvider (업적)
├── Flame Game Layer (FQ4Game extends FlameGame)
│   ├── GameWorld (Map, Units[], Effects[])
│   ├── Systems (Combat, Fatigue, Magic, AI, Squad, SpatialHash, StatusEffect, Environment)
│   └── Camera (유닛 추적)
└── Data Layer (Isar DB, SharedPreferences, JSON Assets)
```

### 14.2 게임 시스템 전체 사양 (PRD-0002 Section 3)

PRD-0002에서 확정된 16개 시스템의 상수/공식 총정리:

| 시스템 | PRD-0002 위치 | 핵심 상수 | 에셋 영향 |
|--------|-------------|----------|----------|
| Gocha-Kyara | 3.1 (246-372줄) | AIState 9종, Personality 3종, Formation 5종, SquadCommand 6종 | AI 설정 UI 필요 |
| 전투 | 3.2 (374-438줄) | 데미지 공식, 명중 95%, 크리티컬 5%/2배, 최소 데미지 1 | 전투 SFX/이펙트 |
| 피로도 | 3.3 (440-468줄) | 4단계 (NORMAL/TIRED/EXHAUSTED/COLLAPSED), 공격+10, 마법+20 | 피로도 UI 게이지 |
| 마법 | 3.4 (470-531줄) | 8종 마법 (fire_ball, ice_bolt, thunder, heal, mass_heal, shield, haste, slow) | 마법 Rive 이펙트 8종, 아이콘 8종 |
| 상태이상 | 3.5 (533-556줄) | 6종 (poison, burn, stun, slow, freeze, blind) | 상태이상 Rive 오버레이 6종, 아이콘 6종 |
| 환경 | 3.6 (558-586줄) | 6종 지형 (NORMAL, WATER, COLD, DARK, POISON, FIRE) | 타일셋에 지형 타일 포함 필요 |
| 장비/인벤토리/상점 | 3.7 (588-613줄) | 3슬롯 (WEAPON/ARMOR/ACCESSORY), 50슬롯 인벤토리, 구매/판매 배율 | 인벤토리 UI, 상점 UI |
| 경험치/레벨업 | 3.8 (614-661줄) | 최대 Lv50, 기본 100 EXP, 1.2배 증가, HP+15/ATK+2/DEF+1/SPD+1/LCK+1 | 레벨업 이펙트 |
| 보스 | 3.9 (663-698줄) | 3페이즈 (HP 66%/33%), 광폭화 (HP 20%, ATK 1.5배, SPD 1.3배) | 보스 Rive 18 states |
| 엔딩 | 3.10 (700-722줄) | GOOD (전원 생존+전 챕터), NORMAL (2명+), BAD (주인공만) | 엔딩 일러스트 3종, BGM 3곡 |
| NG+ | 3.11 (724-745줄) | 적 HP/ATK/DEF 1.5배, SPD 최대 1.2배, EXP 0.8배, 골드 1.2배 | - |
| 업적 | 3.12 (747-798줄) | 28개 (챕터10+보스4+레벨3+처치3+엔딩3+특수5) | 업적 아이콘 28종 |
| 대화 | 3.13 (800-900줄) | DialogueData (노드 기반 그래프), 타이핑 30자/초, 자동진행 2초 | 초상화, 대화 UI Rive |
| 이벤트 | 3.14 (904-970줄) | 9종 EventType, 5종 TriggerCondition, 이벤트 큐 | 맵 내 트리거 영역 |
| 맵 관리 | 3.15 (971-1065줄) | MapData, 5개 충돌 레이어, 페이드 전환 0.5초 | 30개 Tiled 맵 |

### 14.3 스토리/캐릭터 확정 사양 (PRD-0002 Section 4)

**챕터 구조 확정** (PRD-0002:1092-1105):

| 챕터 | 제목 | 주요 이벤트 | 보스 | 신규 동료 | 해금 시스템 |
|------|------|-----------|------|----------|-----------|
| 1 | 마을의 습격 | 바르시아 침공, 튜토리얼 | - | - | 기본 전투 |
| 2 | 숲의 시련 | 대형 해금 | - | 시누세 | 대형 시스템 |
| 3 | 성채 탈환 | 장비 시스템 | 하급 장군 | 소토카 | 장비 시스템 |
| 4 | 사막 횡단 | FIRE/COLD 환경 | - | 타로 | 환경 시스템 |
| 5 | 항구 도시 | 상점, 해상 전투 | 해적 두목 | - | 상점 시스템 |
| 6 | 마법의 탑 | 마법 확장, 퍼즐 | 마법사 | - | 마법 확장 |
| 7 | 제국 변경 | 대규모 전투 | 쿠가이아 (1차) | - | - |
| 8 | 제국 수도 | 배신 이벤트 | 모르드레드 | - | - |
| 9 | 마계의 문 | 마물 등장 | 쿠가이아 (최종) | - | - |
| 10 | 최종 결전 | 엔딩 분기 | 마왕 (3페이즈) | - | - |

**보스 7종 확정** (에셋 제작 필요):
1. 하급 장군 (Ch3)
2. 해적 두목 (Ch5)
3. 마법사 (Ch6)
4. 쿠가이아 1차 (Ch7)
5. 모르드레드 (Ch8)
6. 쿠가이아 최종 (Ch9)
7. 마왕 (Ch10, 3페이즈)

### 14.4 Rive State Machine 상세 (PRD-0002 Section 5.2-5.3)

PRD-0002에서 확정된 Rive-게임 연동 인터페이스:

**State Machine Inputs**:

| Input 타입 | 이름 | 타입 | 연동 |
|-----------|------|------|------|
| Trigger | attackTrigger | SMITrigger | 공격 시 fire |
| Trigger | hitTrigger | SMITrigger | 피격 시 fire |
| Trigger | deathTrigger | SMITrigger | 사망 시 fire |
| Boolean | isMoving | SMIBool | 이동 중 true |
| Boolean | isPoisoned | SMIBool | 독 상태 true |
| Boolean | isBurning | SMIBool | 화상 상태 true |
| Boolean | isStunned | SMIBool | 기절 상태 true |
| Boolean | isFrozen | SMIBool | 빙결 상태 true |
| Boolean | isSlowed | SMIBool | 둔화 상태 true |
| Boolean | isBlinded | SMIBool | 실명 상태 true |
| Number | fatigueLevel | SMINumber | 0=NORMAL, 1=TIRED, 2=EXHAUSTED, 3=COLLAPSED |
| Number | hpRatio | SMINumber | 0.0~1.0 HP 비율 |
| Number | directionX | SMINumber | -1~1 이동 방향 |

이 인터페이스는 모든 Rive 캐릭터 파일에 동일하게 적용되어야 합니다.

### 14.5 터치 조작 에셋 상세 (PRD-0002 Section 6.3)

| 입력 | 동작 | 에셋 |
|------|------|------|
| 빈 영역 탭 | 해당 위치로 이동 | 이동 마커 이펙트 |
| 빈 영역 길게 누르기 + 드래그 | 연속 이동 (조이스틱) | 가상 조이스틱 UI |
| 적 유닛 탭 | 타겟 설정 + 이동/공격 | 타겟 마커 이펙트 |
| 적 유닛 더블 탭 | 즉시 공격 (사거리 내) | - |
| 아군 유닛 탭 | 해당 유닛으로 조작 전환 | 선택 링 이펙트 |
| HUD 초상화 좌우 스와이프 | 부대 내 유닛 전환 | 스와이프 UI 피드백 |
| HUD 초상화 상하 스와이프 | 부대 전환 | 스와이프 UI 피드백 |
| 마법 버튼 탭 | 마법 선택 팝업 | 마법 선택 UI |
| 마법 선택 후 타겟 탭 | 시전 | 마법 범위 표시 |
| 명령 버튼 탭 | 명령 선택 팝업 (5종) | 명령 UI |
| 두 손가락 핀치 | 카메라 줌 | - |

### 14.6 Rive vs Sprite 대안 전략 (PRD-0002:1840-1858)

100 유닛 Rive 동시 렌더링 성능 병목 시 대안:

| 전략 | 설명 | Rive 유지 범위 | 성능 영향 |
|------|------|-------------|----------|
| **A: Hybrid (권장)** | 근접 유닛만 Rive 풀, 원거리는 심플 모드 | 조작 유닛 + 근접 | 최적 |
| **B: Sprite 대체** | Rive에서 Sprite Sheet 사전 렌더링, 인게임은 SpriteBatch | UI/대화/메뉴만 | 검증됨 |
| **C: 유닛 수 제한** | 동시 유닛 50으로 제한 | 전체 Rive | 원본보다 적음 |

### 14.7 개발 로드맵 상세 (PRD-0002 Section 10)

| Phase | 기간 | 핵심 산출물 |
|-------|------|-----------|
| **Phase 0: Pre-production** | 6주 | 프로젝트 스캐폴드, 아트 스타일 가이드, **100 Rive 60FPS 성능 게이트 (Week 4)**, UX 프로토타입 |
| **Phase 1: Foundation** | 8주 | Unit 컴포넌트 계층, CombatSystem, FatigueSystem, GameManager, Ch1-3, 기본 HUD |
| **Phase 2: Core Systems** | 12주 | AISystem, MagicSystem, StatusEffect, Environment, Equipment/Inventory/Shop, Experience/Stats, 대화 |
| **Phase 3: Content** | 10주 | Ch4-10, BossUnit, EndingSystem, NG+, Achievement, 세이브/로드 |
| **Phase 4: Polish** | 6주 | 성능 최적화, 다국어, 접근성, QA, 사운드 통합 |
| **Phase 5: Release** | 4주 | 앱스토어 심사, 베타 테스트, 출시 |
| **총 기간** | **46주 (약 11개월)** | |

### 14.8 GDScript -> Dart 마이그레이션 가이드 (PRD-0002 Section 12)

PRD-0002에서 확정된 핵심 매핑 규칙:

| 변환 대상 | GDScript | Dart/Flame | 비고 |
|----------|----------|-----------|------|
| 유닛 기반 클래스 | CharacterBody2D | PositionComponent + HasCollisionDetection | move_and_slide() 제거, position += 직접 계산 |
| 트리거 영역 | Area2D | ShapeHitbox | 충돌 콜백 |
| 시그널 | signal X / X.emit() | StreamController.broadcast() / .add() | EventBus 패턴 |
| 싱글톤 | Autoload | Riverpod Provider | 의존성 주입 |
| 리소스 | extends Resource | @freezed class | 불변 데이터 모델 |
| 생명주기 | _ready() / _process() | onLoad() / update(dt) | Flame Component |
| 노드 제거 | queue_free() | removeFromParent() | |

### 14.9 테스트 전략 (PRD-0002 Section 13)

| 테스트 레벨 | 비율 | 커버리지 목표 | 핵심 대상 |
|------------|------|-------------|----------|
| Unit Test | 50% | 90%+ | CombatSystem, FatigueSystem, AISystem, MagicSystem |
| Widget Test | 30% | 70%+ | HUD, 대화 UI, 인벤토리, 상점 |
| Integration Test | 15% | - | 전투 흐름, AI 행동, 마법 시전, 대화, 맵 전환, 세이브/로드 |
| E2E Test | 5% | - | 챕터 1 클리어, 풀 플레이스루, NG+ 사이클 |

### 14.10 KPI/성공 지표 (PRD-0002:1871-1882)

| 지표 | 목표 |
|------|------|
| 다운로드 (출시 1개월) | 10,000+ |
| DAU | 500+ |
| D7 리텐션 | 25%+ |
| D30 리텐션 | 10%+ |
| 크래시율 | < 0.1% |
| 앱 평점 | 4.0+ |
| 챕터 10 클리어율 | 15%+ |
| 평균 플레이 시간 | 8시간+ |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.1.0 | 2026-02-08 | PRD-0002 전문 분석 보완 (2170줄): 아키텍처 상세, 시스템 사양 확정, 캐릭터/스토리, Rive State Machine, 터치 조작, 대안 전략, 로드맵, 마이그레이션 가이드, 테스트 전략, KPI |
| 1.0.0 | 2026-02-08 | 초기 에셋 마스터 리스트 (Autopilot 분석) |
