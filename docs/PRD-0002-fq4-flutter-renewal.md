# PRD-0002: First Queen 4 Flutter/Rive Renewal

**Version**: 1.1.0 | **Date**: 2026-02-08 | **Status**: Draft

---

## 1. 개요

### 1.1 프로젝트 비전

First Queen 4(1994, DOS)의 게임성을 100% 유지하면서 그래픽, UI, 플랫폼을 완전히 새로 설계하는 리뉴얼 프로젝트. 픽셀아트를 Rive 벡터 애니메이션으로, PC 전용을 모바일/PC 크로스 플랫폼으로, 키보드 전용을 터치/키보드/게임패드 멀티 입력으로 전환한다.

| 항목 | 내용 |
|------|------|
| 원본 | First Queen 4 (DOS, 1994, Kure Software Koubou) |
| 장르 | 실시간 전술 RPG |
| 엔진 | Flutter + Flame + Rive |
| 플랫폼 | iOS, Android, Windows, macOS, Web |
| 해상도 | 기기 해상도 적응 (기준 1920x1080, 논리 좌표계) |
| 아트 스타일 | Rive 벡터 애니메이션 (신규 제작) |

### 1.2 원본 게임

First Queen 시리즈는 "Gocha-Kyara" 시스템으로 알려진 실시간 전술 RPG다. 플레이어가 1명만 직접 조작하고 나머지 부대원은 AI가 자동 제어하는 독특한 시스템이 핵심이다.

```
+-------------------------------------------------------------------+
|                    First Queen 4 (1994)                            |
+-------------------------------------------------------------------+
|                                                                   |
|  [로그리스 대륙]                                                   |
|                                                                   |
|  주인공 아레스(전사)가 바르시아 제국의 침공에 맞서                  |
|  동료들과 부대를 이끌고 대륙을 해방하는 이야기                     |
|                                                                   |
|  핵심 메커니즘:                                                    |
|  - Gocha-Kyara: AI 동료 자동 제어                                 |
|  - 실시간 전투: 수십 유닛 동시 교전                                |
|  - 피로도 관리: 전투 지속력 전략                                   |
|  - 부대 편성: 대형/명령 시스템                                     |
|                                                                   |
+-------------------------------------------------------------------+
```

### 1.3 리뉴얼 방향성

이것은 단순 포팅이 아닌 완전한 리뉴얼이다. 게임의 핵심 시스템과 밸런스는 원본을 그대로 이식하되, 모든 시각/청각/조작 경험을 현대적으로 재설계한다.

| 영역 | 원본 | 리뉴얼 |
|------|------|--------|
| 그래픽 | 16색 320x200 픽셀아트 | Rive 벡터 애니메이션 |
| 플랫폼 | DOS (PC 전용) | iOS, Android, Windows, macOS, Web |
| 입력 | 키보드 전용 | 터치 + 키보드 + 게임패드 |
| 사운드 | FM 음원 | 새 작곡 (오케스트라/신스) |
| UI | DOS 텍스트 UI | Flutter Material/Cupertino 기반 |
| 해상도 | 320x200 고정 | 기기 적응형 |

### 1.4 유지 vs 변경 원칙

```
+-------------------------------+-------------------------------+
|        100% 유지 (원본)       |      완전 변경 (신규)         |
+-------------------------------+-------------------------------+
| Gocha-Kyara 시스템 전 파라미터 | 모든 그래픽 에셋 (Rive)      |
| 전투 공식 (데미지/명중/회피)   | UI/UX (터치 최적화)          |
| 피로도 시스템 (4단계)          | 사운드/음악 (신규)           |
| 마법 8종 (스탯/쿨다운)         | 입력 체계 (멀티 입력)        |
| 상태이상 6종                   | 해상도/화면 비율             |
| 환경 지형 6종                  | 이펙트/파티클                |
| 장비/인벤토리/상점             | 온보딩/튜토리얼              |
| 스토리/시나리오/캐릭터          | 로컬라이제이션 UI            |
| 경험치/레벨업 공식             | 네트워크 (랭킹/클라우드)     |
| 보스 시스템 (3페이즈)          | 앱스토어 통합                |
| 엔딩 조건 (GOOD/NORMAL/BAD)   |                               |
| NG+ 스케일링                   |                               |
| 업적 28개                      |                               |
+-------------------------------+-------------------------------+
```

### 1.5 좌표계 정책

게임 내부는 논리 좌표계를 사용하고, 렌더링 시 기기 해상도에 맞춰 스케일링한다.

| 항목 | 내용 |
|------|------|
| 논리 좌표 비율 | 16:10 (원본 320x200 비율 유지) |
| 기준 논리 해상도 | 1280x800 (원본의 4배) |
| 렌더링 좌표 | 기기 해상도에 맞춰 Flame CameraComponent로 스케일링 |
| AI 파라미터 기준 | 모든 거리 파라미터 (감지 범위 200px, 추종 거리 80px 등)는 논리 좌표 기준 |

```
논리 좌표 (1280x800)
    |
    +-- Flame CameraComponent.viewfinder
    |   +-- visibleGameSize = Vector2(1280, 800)
    |   +-- 기기 해상도에 따라 자동 스케일
    |
    +-- 좌표 변환
        +-- 터치 입력 (기기 좌표) --> camera.globalToLocal() --> 논리 좌표
        +-- 논리 좌표 --> camera.localToGlobal() --> 화면 좌표
```

AI, 전투, 물리 계산은 모두 논리 좌표에서 수행되므로 기기 해상도에 무관하게 동일한 게임플레이를 보장한다.

---

## 2. 기술 스택

### 2.1 핵심 프레임워크

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.24+ | UI 프레임워크, 크로스 플랫폼 |
| Dart | 3.5+ | 메인 언어 |
| Flame | 1.18+ | 2D 게임 엔진 (게임 루프, 물리, 카메라) |
| Rive | 0.13+ | 벡터 애니메이션 (캐릭터, UI, 이펙트) |
| Riverpod | 2.5+ | 상태 관리 |
| Isar | 4.0+ | 로컬 데이터베이스 (세이브/설정) |
| Audioplayers | 6.0+ | 사운드/BGM |
| Flame Tiled | 1.20+ | 타일맵 (맵 에디터 연동) |

### 2.2 아키텍처 패키지

| 패키지 | 용도 |
|--------|------|
| `freezed` + `json_serializable` | 불변 데이터 모델 (세이브/로드) |
| `go_router` | 화면 라우팅 (타이틀, 게임, 메뉴) |
| `flame_riverpod` | Flame-Riverpod 브릿지 (주의: 비공식 패키지일 수 있음. 대안으로 GameWidget.overlayBuilderMap에서 ProviderScope로 감싸는 방식 검토) |
| `flame_audio` | 게임 내 오디오 |
| `flutter_localizations` | 다국어 |
| `shared_preferences` | 설정 저장 |
| `path_provider` | 파일 경로 |
| `gamepad` | 게임패드 입력 |

### 2.3 개발 도구

| 도구 | 용도 |
|------|------|
| Rive Editor | 캐릭터/UI 애니메이션 제작 |
| Tiled Map Editor | 맵 제작 |
| Audacity / FL Studio | 사운드 편집 |
| Flutter DevTools | 성능 프로파일링 |
| Firebase Analytics | 사용자 분석 (선택) |

### 2.4 프로젝트 구조

```
fq4_flutter/
+-- lib/
|   +-- main.dart                    # 앱 엔트리포인트
|   +-- app.dart                     # MaterialApp, 라우팅
|   +-- core/
|   |   +-- constants/               # 게임 상수 (원본 파라미터)
|   |   |   +-- combat_constants.dart
|   |   |   +-- fatigue_constants.dart
|   |   |   +-- ai_constants.dart
|   |   |   +-- spell_constants.dart
|   |   |   +-- level_constants.dart
|   |   +-- utils/                   # 유틸리티
|   |   +-- extensions/              # Dart extension methods
|   +-- data/
|   |   +-- models/                  # 데이터 모델 (freezed)
|   |   |   +-- unit_model.dart
|   |   |   +-- spell_model.dart
|   |   |   +-- item_model.dart
|   |   |   +-- equipment_model.dart
|   |   |   +-- chapter_model.dart
|   |   +-- repositories/            # 데이터 저장소
|   |   +-- databases/               # Isar 스키마
|   +-- game/
|   |   +-- fq4_game.dart            # FlameGame 메인 클래스
|   |   +-- components/
|   |   |   +-- units/               # 유닛 컴포넌트
|   |   |   |   +-- unit_component.dart
|   |   |   |   +-- ai_unit_component.dart
|   |   |   |   +-- player_unit_component.dart
|   |   |   |   +-- enemy_unit_component.dart
|   |   |   |   +-- boss_unit_component.dart
|   |   |   +-- map/                 # 맵 컴포넌트
|   |   |   +-- effects/             # 이펙트/파티클
|   |   |   +-- ui/                  # 인게임 HUD (Flame 레이어)
|   |   +-- systems/                 # 게임 시스템 (ECS-like)
|   |   |   +-- combat_system.dart
|   |   |   +-- fatigue_system.dart
|   |   |   +-- magic_system.dart
|   |   |   +-- status_effect_system.dart
|   |   |   +-- environment_system.dart
|   |   |   +-- equipment_system.dart
|   |   |   +-- inventory_system.dart
|   |   |   +-- shop_system.dart
|   |   |   +-- experience_system.dart
|   |   |   +-- ai_system.dart
|   |   |   +-- squad_system.dart
|   |   |   +-- spatial_hash.dart
|   |   +-- managers/
|   |   |   +-- game_manager.dart
|   |   |   +-- chapter_manager.dart
|   |   |   +-- audio_manager.dart
|   |   |   +-- save_manager.dart
|   |   +-- ai/                      # Gocha-Kyara AI
|   |   |   +-- ai_brain.dart
|   |   |   +-- personality.dart
|   |   |   +-- formation.dart
|   |   |   +-- squad_command.dart
|   +-- presentation/
|   |   +-- screens/                 # Flutter UI 화면
|   |   |   +-- title_screen.dart
|   |   |   +-- game_screen.dart
|   |   |   +-- inventory_screen.dart
|   |   |   +-- settings_screen.dart
|   |   |   +-- achievement_screen.dart
|   |   +-- widgets/                 # 재사용 위젯
|   |   |   +-- hud/
|   |   |   +-- dialogs/
|   |   |   +-- rive_widgets/
|   |   +-- providers/               # Riverpod providers
|   +-- l10n/                        # 다국어 리소스
+-- assets/
|   +-- rive/                        # Rive 애니메이션 파일 (.riv)
|   |   +-- characters/
|   |   +-- enemies/
|   |   +-- effects/
|   |   +-- ui/
|   +-- maps/                        # Tiled 맵 파일
|   +-- audio/
|   |   +-- bgm/
|   |   +-- sfx/
|   +-- data/                        # JSON 데이터
|   |   +-- spells.json
|   |   +-- items.json
|   |   +-- equipment.json
|   |   +-- enemies.json
|   |   +-- chapters.json
|   +-- fonts/
|   +-- images/                      # 정적 이미지 (배경, UI)
+-- test/                            # 테스트
+-- integration_test/                # 통합 테스트
```

---

## 3. 핵심 게임 시스템 (원본 1:1 이식)

모든 시스템은 Godot 4.4 구현체의 상수, 공식, 로직을 정확히 이식한다.

### 3.1 Gocha-Kyara 시스템

First Queen의 핵심 시스템. 플레이어는 1명만 직접 조작하고, 나머지 부대원은 AI가 자동 제어한다.

```
+-------------------------------------------------------------------+
|                    Gocha-Kyara System                              |
+-------------------------------------------------------------------+
|                                                                   |
|   [플레이어 조작 유닛]        [AI 자동 제어 유닛들]               |
|   - 터치 이동/공격            - AIState 상태머신 기반             |
|   - 마법 시전                 - 성격별 행동 패턴                  |
|   - 수동 타겟팅               - 리더 추종                        |
|                               - 자동 교전/후퇴                   |
|                                                                   |
|   조작 전환:                                                      |
|   - 좌/우 스와이프: 부대 내 유닛 전환                             |
|   - 상/하 스와이프: 부대 전환                                     |
|   - 유닛 탭: 해당 유닛으로 직접 전환                              |
|                                                                   |
+-------------------------------------------------------------------+
```

#### 3.1.1 AI 상태머신

| AIState | 설명 | 전이 조건 |
|---------|------|----------|
| `IDLE` | 대기 | 리더 있으면 FOLLOW, 적 감지하면 CHASE |
| `FOLLOW` | 리더 추종 | Gocha-Kyara 핵심. 대형에 따른 위치 유지 |
| `PATROL` | 순찰 | 적 감지 시 CHASE |
| `CHASE` | 적 추격 | 사거리 내 도달 시 ATTACK, 리더와 멀어지면 FOLLOW |
| `ATTACK` | 공격 | 적 사망 시 FOLLOW/PATROL, 사거리 이탈 시 CHASE |
| `RETREAT` | 후퇴 | HP/피로도 회복 시 FOLLOW |
| `DEFEND` | 방어 | 리더 근처에서 적 견제 |
| `SUPPORT` | 지원 | 힐러/버퍼 전용. 부상 아군 탐색 후 마법 시전 |
| `REST` | 휴식 | 피로도 30% 이하로 회복 시 FOLLOW |

#### 3.1.2 AI 핵심 파라미터

| 파라미터 | 아군 | 적 | 단위 |
|----------|------|-----|------|
| AI tick 간격 | 0.3 | 0.4 | 초 |
| 기본 감지 범위 | 200 | 180 | px |
| 추종 거리 | 80 | - | px |
| 분산 거리 | 40 | - | px |
| 공격 교전 거리 | 150 | - | px |
| 후퇴 HP 임계값 | 30% | 20% | HP비율 |
| 피로도 후퇴 임계값 | 70% | - | 피로도비율 |
| 피로도 강제 휴식 | 90% | - | 피로도비율 |

#### 3.1.3 성격 시스템

| Personality | chase_range_mult | retreat_hp_mult | attack_priority | follow_priority |
|-------------|-----------------|-----------------|-----------------|-----------------|
| AGGRESSIVE | 1.5 | 0.7 | 1.0 | 0.5 |
| DEFENSIVE | 0.7 | 1.3 | 0.5 | 1.0 |
| BALANCED | 1.0 | 1.0 | 0.8 | 0.8 |

성격에 따른 실제 적용:
- AGGRESSIVE: 감지 범위 300px (200*1.5), 후퇴 HP 21% (30%*0.7)
- DEFENSIVE: 감지 범위 140px (200*0.7), 후퇴 HP 39% (30%*1.3)
- BALANCED: 감지 범위 200px, 후퇴 HP 30%

#### 3.1.4 대형 시스템

| Formation | 배치 방식 | 용도 |
|-----------|----------|------|
| V_SHAPE | 리더 뒤쪽 V자 (기본) | 범용, 전방 돌파 |
| LINE | 횡대 일렬 | 넓은 전선 유지 |
| CIRCLE | 원형 | 리더 보호, 집합 명령 시 |
| WEDGE | 쐐기형 (역삼각) | 돌격, 돌파 |
| SCATTERED | 황금비 기반 분산 | 범위 공격 회피 |

분산 대형 오프셋 계산 (황금비 기반):
```
angle = fmod(seed * 0.618033988749, 1.0) * 2 * PI
distance = follow_distance * (1.0 + fmod(seed * 0.314159, 0.5))
offset = (cos(angle) * distance, sin(angle) * distance)
```

#### 3.1.5 부대 명령 시스템

| SquadCommand | 효과 | 대형 변경 | 거리 변경 |
|-------------|------|----------|----------|
| NONE | 명령 없음 (기본 상태) | 유지 | 유지 |
| GATHER | 집합 | CIRCLE | follow_distance = 40 |
| SCATTER | 분산 | SCATTERED | follow_distance = 150 |
| ATTACK_ALL | 전원 공격 | 유지 | 유지 |
| DEFEND_ALL | 전원 방어 | CIRCLE | follow_distance = 50 |
| RETREAT_ALL | 전원 후퇴 | 유지 | 유지 |

#### 3.1.6 AI 판단 흐름

```
_process_ai() 호출 (0.3초 간격)
    |
    +-- 피로도 >= 90%?
    |   +-- YES --> REST (강제 휴식)
    |
    +-- HP < retreat_hp_threshold?
    |   +-- YES --> RETREAT
    |
    +-- 피로도 >= 70%?
    |   +-- YES --> RETREAT (피로도 후퇴)
    |
    +-- 적 감지 (detection_range 내)
    |
    +-- 현재 상태에 따른 행동:
        |
        +-- FOLLOW: 리더 따라가기
        |   +-- AGGRESSIVE: 적 교전 거리 내 --> CHASE
        |   +-- BALANCED: 사거리 1.5배 내 --> ATTACK
        |   +-- DEFENSIVE: 교전 거리 50% 내 --> DEFEND
        |
        +-- CHASE: 적 추격
        |   +-- 사거리 내 --> ATTACK
        |   +-- 리더와 거리 > 감지범위 * 1.5 --> FOLLOW
        |
        +-- ATTACK: 공격
        |   +-- 적 사망 --> FOLLOW/PATROL
        |   +-- 사거리 밖 --> CHASE
        |   +-- 마법 사거리 내 & MP 충분 --> 마법 시전
        |
        +-- SUPPORT: 지원 (힐러/버퍼)
            +-- 부상 아군 (HP < 50%) --> 힐 마법 시전
            +-- 적 존재 --> 공격 마법 시전
```

### 3.2 전투 시스템

#### 3.2.1 데미지 공식

```
1. base_damage = ATK (StatsSystem 기반, 장비 보너스 포함)
2. 크리티컬 판정: rand() < (0.05 + LCK * 0.005 + equipment_crit_bonus)
   - 크리티컬 시: base_damage *= 2.0
3. 데미지 분산: base_damage *= (1.0 + rand(-0.1, +0.1))
4. 방어 적용: final_damage = max(1, base_damage - DEF)
5. 피로도 배율: final_damage *= fatigue_attack_power_multiplier
6. 최소 데미지 보장: final_damage = max(1, final_damage)
```

#### 3.2.2 명중/회피 판정

```
명중 판정:
  hit_chance = 0.95 + (attacker_LCK * 0.01)
  roll = rand()
  if roll > hit_chance --> MISS

회피 판정 (명중 후):
  evasion_chance = 0.05 + (target_SPD * 0.001) + (target_LCK * 0.005) + equipment_evasion
  if rand() < evasion_chance --> EVADE
```

#### 3.2.3 전투 상수

| 상수 | 값 | 설명 |
|------|-----|------|
| BASE_DAMAGE_VARIANCE | 0.1 | 데미지 편차 +-10% |
| CRITICAL_HIT_CHANCE | 0.05 | 기본 크리티컬 확률 5% |
| CRITICAL_HIT_MULTIPLIER | 2.0 | 크리티컬 데미지 배율 |
| BASE_HIT_CHANCE | 0.95 | 기본 명중률 95% |
| BASE_EVASION | 0.05 | 기본 회피율 5% |
| MIN_DAMAGE | 1 | 최소 데미지 |

#### 3.2.4 전투 흐름

```
execute_attack(attacker, target)
    |
    +-- _can_attack 체크
    |   +-- 양측 생존?
    |   +-- 사거리 내?
    |   +-- 피로도 COLLAPSED 아닌지?
    |
    +-- 명중 판정 (_calculate_hit)
    |   +-- MISS --> 피로도 +10, 팝업 표시
    |   +-- EVADE --> 피로도 +10, 팝업 표시
    |
    +-- 데미지 계산 (calculate_damage)
    |   +-- 크리티컬 판정
    |   +-- 분산 적용
    |   +-- 방어력 적용
    |
    +-- 피로도 배율 적용
    +-- target.take_damage(final_damage)
    +-- 공격자 피로도 +10
    |
    +-- 사망 체크
        +-- 사망 시: 경험치 지급 (상세 공식은 3.8.4 참조), 골드 보상
        +-- gold_amount = 5 + (enemy_max_hp / 20)
```

### 3.3 피로도 시스템

#### 3.3.1 피로도 증감

| 행동 | 피로도 변화 | 비고 |
|------|-----------|------|
| 공격 | +10 | FATIGUE_ATTACK |
| 스킬/마법 | +20 | FATIGUE_SKILL |
| 이동 10px | +1 | FATIGUE_MOVE_PER_10_UNITS |
| 대기 | -1/초 | FATIGUE_IDLE_RECOVERY |
| 휴식 (REST 상태) | -5/초 | FATIGUE_REST_RECOVERY |

#### 3.3.2 피로도 단계별 패널티

| 단계 | 범위 | 이동속도 배율 | 공격력 배율 | 행동 가능 |
|------|------|-------------|-----------|----------|
| NORMAL | 0-30% | 1.0 (100%) | 1.0 (100%) | O |
| TIRED | 31-60% | 0.8 (80%) | 0.9 (90%) | O |
| EXHAUSTED | 61-90% | 0.5 (50%) | 0.7 (70%) | O |
| COLLAPSED | 91-100% | 0.0 (0%) | 0.0 (0%) | X (강제 휴식) |

#### 3.3.3 피로도 시각 표현

```
NORMAL:     [##########----------]  녹색
TIRED:      [##############------]  황색
EXHAUSTED:  [##################--]  적색
COLLAPSED:  [####################]  점멸 (행동불가)
```

### 3.4 마법 시스템

#### 3.4.1 마법 데이터 (8종)

| spell_id | 유형 | 속성 | MP | 위력 | 사거리 | 범위 | 쿨다운 | 시전 시간 | 타겟 |
|----------|------|------|-----|------|--------|------|--------|----------|------|
| fire_ball | DAMAGE | FIRE | 15 | 30 | 250 | 60 | 4.0s | 0.8s | AREA |
| ice_bolt | DAMAGE | ICE | 10 | 25 | 200 | 50 | 2.0s | 0.5s | SINGLE_ENEMY |
| thunder | DAMAGE | LIGHTNING | 20 | 45 | 300 | 50 | 5.0s | 1.0s | SINGLE_ENEMY |
| heal | HEAL | HOLY | 12 | 40 | 150 | - | 3.0s | 0.6s | SINGLE_ALLY |
| mass_heal | HEAL | HOLY | 30 | 25 | 100 | 120 | 8.0s | 1.2s | AREA |
| shield | BUFF | NONE | 8 | - | 150 | - | 5.0s | 0.5s | SINGLE_ALLY |
| haste | BUFF | NONE | 10 | - | 150 | - | 6.0s | 0.5s | SINGLE_ALLY |
| slow | DEBUFF | ICE | 8 | - | 180 | - | 4.0s | 0.5s | SINGLE_ENEMY |

#### 3.4.2 버프/디버프 상세

| spell_id | 효과 스탯 | 변화량 | 지속 시간 |
|----------|----------|--------|----------|
| shield | DEF | +10 | 15.0s |
| haste | SPD | +30 | 12.0s |
| slow | SPD | -20 | 10.0s |

#### 3.4.3 마법 시전 흐름

```
cast_spell(caster, spell, target)
    |
    +-- 검증 (can_cast)
    |   +-- 시전자 생존?
    |   +-- MP >= mp_cost?
    |   +-- 쿨다운 해제?
    |
    +-- 타겟 결정 (_resolve_targets)
    |   +-- SELF: [caster]
    |   +-- SINGLE_ALLY/ENEMY: [target]
    |   +-- AREA: 범위 내 유닛 검색
    |   +-- ALL_ALLIES/ENEMIES: 전체
    |
    +-- MP 소모 (current_mp -= mp_cost)
    +-- 피로도 증가 (+20)
    +-- 쿨다운 시작
    |
    +-- 효과 적용:
        +-- DAMAGE: target.take_damage(base_power)
        +-- HEAL: target.heal(base_power)
        +-- BUFF: stats_system.apply_buff(stat, value, duration)
        +-- DEBUFF: stats_system.apply_buff(stat, -value, duration)
```

#### 3.4.4 AI 마법 시전 판단

```
ai_should_cast_spell(caster, allies, enemies)
    |
    +-- 1순위: 부상 아군 (HP < 50%) 존재?
    |   +-- YES: HEAL 마법 시전
    |
    +-- 2순위: 적 존재?
        +-- YES: DAMAGE 마법 시전
        +-- AREA 마법이면 적 밀집 지역 타겟
```

### 3.5 상태이상 시스템

#### 3.5.1 상태이상 6종

| 상태 | 지속 시간 | tick 간격 | tick 데미지 | 속도 배율 | 행동 가능 | 감지 배율 |
|------|----------|----------|-----------|----------|----------|----------|
| poison | 10.0s | 1.0s | 5 | 1.0 | O | 1.0 |
| burn | 8.0s | 1.0s | 8 | 1.0 | O | 1.0 |
| stun | 3.0s | - | - | 1.0 | X | 1.0 |
| slow | 5.0s | - | - | 0.5 | O | 1.0 |
| freeze | 4.0s | - | - | 0.0 | X | 1.0 |
| blind | 6.0s | - | - | 1.0 | O | 0.2 |

#### 3.5.2 상태이상 카테고리

| 카테고리 | 상태이상 |
|----------|---------|
| 지속 데미지 | poison, burn |
| 군중 제어 | stun, freeze, slow |
| 시야 방해 | blind |

#### 3.5.3 중복 처리

비중첩 효과는 기존 효과의 시간을 리셋한다. 같은 타입의 상태이상이 다시 적용되면 남은 시간이 갱신된다.

### 3.6 환경 시스템

#### 3.6.1 지형 6종

| TerrainType | 효과 | 상태이상 | 수치 |
|-------------|------|---------|------|
| NORMAL | 없음 | - | - |
| WATER | 이동속도 감소 | - | speed * 0.7 (-30%) |
| COLD | 피로도 누적 증가 | - | fatigue * 1.5 (+50%) |
| DARK | 감지 범위 감소 | - | detection * 0.5 (-50%) |
| POISON | 독 상태이상 부여 | poison | 10s, 5 dmg/s |
| FIRE | 화상 상태이상 부여 | burn | 8s, 8 dmg/s |

#### 3.6.2 지형 진입/이탈

```
유닛이 지형 Area2D 진입
    |
    +-- WATER: 이동속도 디버프 적용
    +-- COLD: 피로도 배율 변경
    +-- DARK: 감지 범위 디버프 적용
    +-- POISON: StatusEffectSystem에 poison 효과 적용
    +-- FIRE: StatusEffectSystem에 burn 효과 적용

유닛이 지형 Area2D 이탈
    |
    +-- 해당 지형 디버프 즉시 제거
    +-- (POISON/FIRE의 상태이상은 지속 시간 동안 유지)
```

### 3.7 장비/인벤토리/상점 시스템

#### 3.7.1 장비 슬롯

| 슬롯 | 장착 가능 유형 | 영향 스탯 |
|------|--------------|----------|
| WEAPON | 검, 창, 지팡이, 활 | ATK, ATTACK_RANGE, CRITICAL_CHANCE |
| ARMOR | 갑옷, 로브, 가죽 | DEF, HP, EVASION |
| ACCESSORY | 반지, 목걸이, 부적 | LCK, SPD, MP, 특수 효과 |

#### 3.7.2 인벤토리

| 파라미터 | 값 |
|----------|-----|
| 최대 슬롯 | 50 |
| 아이템 스택 | item_data.max_stack (아이템별) |
| 골드 | 무제한 |

#### 3.7.3 상점

| 기능 | 설명 |
|------|------|
| 구매 | buy_price * shop.buy_price_multiplier |
| 판매 | sell_price * shop.sell_price_multiplier (기본 구매가의 50%) |
| 재고 | -1 = 무한, 양수 = 제한 |

### 3.8 경험치/레벨업 시스템

#### 3.8.1 레벨 파라미터

| 파라미터 | 값 |
|----------|-----|
| 최대 레벨 | 50 |
| 기본 경험치 (Lv2) | 100 |
| 경험치 증가율 | 1.2 |

#### 3.8.2 경험치 공식

```
exp_to_next_level(level) = 100 * (1.2 ^ (level - 2))

예시:
  Lv1 -> Lv2: 100
  Lv2 -> Lv3: 120
  Lv3 -> Lv4: 144
  Lv10 -> Lv11: 516
  Lv49 -> Lv50: 7,937,914
```

#### 3.8.3 레벨업 스탯 성장 (레벨당)

| 스탯 | 성장량 |
|------|--------|
| HP | +15 |
| MP | +5 |
| ATK | +2 |
| DEF | +1 |
| SPD | +1 |
| LCK | +1 |

#### 3.8.4 적 처치 경험치

```
base_exp = 10 + (enemy_level * 5)

타입 배율:
  Normal: x1.0
  Elite: x2.0
  Boss: x5.0

레벨 차이 보정:
  적 레벨 - 내 레벨 < -5: max(0.1, 1.0 + diff * 0.1)
  적 레벨 - 내 레벨 > +5: min(2.0, 1.0 + diff * 0.05)
```

### 3.9 보스 시스템

#### 3.9.1 멀티 페이즈

| 페이즈 | HP 임계값 | 전환 시 이벤트 |
|--------|----------|---------------|
| Phase 1 | 100% - 66% | 초기 패턴 |
| Phase 2 | 66% - 33% | 패턴 변경, 미니언 소환 |
| Phase 3 | 33% - 0% | 최종 패턴, 미니언 소환 |

#### 3.9.2 광폭화 (Enrage)

| 파라미터 | 값 |
|----------|-----|
| 발동 HP | 20% 이하 |
| ATK 배율 | 1.5배 |
| SPD 배율 | 1.3배 |

#### 3.9.3 보스 AI 흐름

```
take_damage(damage)
    |
    +-- HP 비율 체크
    |   +-- HP <= 66% && phase == 1 --> Phase 2 전환
    |   +-- HP <= 33% && phase == 2 --> Phase 3 전환
    |
    +-- 광폭화 체크
    |   +-- HP <= 20% && !is_enraged --> 광폭화 발동
    |       +-- ATK *= 1.5
    |       +-- move_speed *= 1.3
    |
    +-- 페이즈 전환 시:
        +-- summon_minions == true --> 미니언 스폰
        +-- 패턴 변경
```

### 3.10 엔딩 시스템

#### 3.10.1 엔딩 조건

| 엔딩 | 조건 | 설명 |
|------|------|------|
| GOOD | 전원 생존 + 전 챕터 클리어 | 모든 동료와 함께 마왕을 물리치고 평화 |
| NORMAL | 2명 이상 생존 | 큰 희생 끝에 마왕을 물리침 |
| BAD | 주인공만 생존 | 홀로 살아남아 모든 것을 잃음 |

#### 3.10.2 엔딩 판정 로직

```
determine_ending()
    |
    +-- alive_count == total_count && all_chapters_cleared?
    |   +-- YES --> GOOD
    |
    +-- alive_count == 1?
    |   +-- YES --> BAD
    |
    +-- else --> NORMAL
```

### 3.11 New Game+ 시스템

#### 3.11.1 캐리오버 데이터

| 데이터 | 캐리오버 |
|--------|---------|
| 유닛 레벨 | O |
| 장비 | O |
| 골드 | O |
| 해금 마법 | O |
| 업적 | O |
| 스토리 진행 | X (리셋) |
| 맵 상태 | X (리셋) |

#### 3.11.2 NG+ 스케일링

| 항목 | 배율 | 비고 |
|------|------|------|
| 적 HP/ATK/DEF | 1.5배 | |
| 적 SPD | 최대 1.2배 | 속도는 상한 적용 |
| 경험치 | 0.8배 | 경험치 감소 |
| 골드 | 1.2배 | 골드 증가 |

### 3.12 업적 시스템

#### 3.12.1 업적 목록 (28개)

**챕터 클리어 (10개)**

| 업적 ID | 조건 |
|---------|------|
| chapter_1_clear ~ chapter_10_clear | 각 챕터 클리어 |

**보스 처치 (4개)**

| 업적 ID | 조건 | 비고 |
|---------|------|------|
| boss_demon_general | 마군 장군 처치 | |
| boss_fallen_hero | 타락한 영웅 처치 | |
| boss_demon_king | 마왕 처치 | |
| boss_all | 모든 보스 처치 | 숨김 업적 |

**레벨 (3개)**

| 업적 ID | 조건 |
|---------|------|
| level_novice | 레벨 10 달성 |
| level_veteran | 레벨 30 달성 |
| level_master | 레벨 50 달성 |

**처치 수 (3개)**

| 업적 ID | 조건 |
|---------|------|
| kills_hunter | 100 처치 |
| kills_slayer | 500 처치 |
| kills_legend | 1000 처치 |

**엔딩 (3개)**

| 업적 ID | 조건 |
|---------|------|
| ending_good | GOOD 엔딩 도달 |
| ending_normal | NORMAL 엔딩 도달 |
| ending_bad | BAD 엔딩 도달 |

**특수 (5개)**

| 업적 ID | 조건 | 비고 |
|---------|------|------|
| speed_run | 2시간 (7200초) 이내 클리어 | 숨김 |
| no_death | 사망 0회로 클리어 | 숨김 |
| ng_plus | New Game+ 시작 | |
| formation_master | 5개 대형 모두 사용 | |
| spell_master | 마법 100회 시전 | |

### 3.13 대화 시스템

원본 구현체: `godot/scripts/dialogue/dialogue_system.gd`, `dialogue_data.gd`

#### 3.13.1 DialogueData 리소스 구조

대화 데이터는 노드 기반 그래프 구조로, 각 노드가 한 장면의 대사를 나타낸다.

```dart
@freezed
class DialogueData with _$DialogueData {
  const factory DialogueData({
    required String dialogueId,
    required String title,
    @Default('start') String startNode,
    required List<DialogueNode> nodes,
  }) = _DialogueData;
}

@freezed
class DialogueNode with _$DialogueNode {
  const factory DialogueNode({
    required String id,
    @Default('') String speaker,     // 화자 이름
    @Default('') String portrait,    // 초상화 이미지 경로
    @Default('') String text,        // 대사 텍스트
    @Default([]) List<DialogueChoice> choices,  // 선택지 (없으면 자동 진행)
    @Default('') String next,        // 다음 노드 ID (선택지 없을 때)
    @Default('') String event,       // 이벤트 문자열 (선택적)
  }) = _DialogueNode;
}

@freezed
class DialogueChoice with _$DialogueChoice {
  const factory DialogueChoice({
    required String text,   // 선택지 텍스트
    required String next,   // 선택 시 이동할 노드 ID
    @Default('') String event,  // 선택 시 발생할 이벤트
  }) = _DialogueChoice;
}
```

#### 3.13.2 DialogueSystem

| 기능 | 메서드 | 설명 |
|------|--------|------|
| 대화 시작 | `startDialogue(DialogueData)` | 시작 노드부터 표시 |
| 대화 진행 | `advanceToNext(choiceIndex)` | 다음 노드로 이동, 없으면 대화 종료 |
| 대화 종료 | `endDialogue()` | UI 닫기, 상태 리셋 |
| JSON 로드 | `loadFromJson(path)` | JSON 파일에서 대화 데이터 로드 |

#### 3.13.3 타이핑 효과

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| typing_speed | 30 | 초당 표시 글자 수 |
| auto_advance_delay | 2.0 | 자동 진행 딜레이 (초) |

타이핑 중 확인 입력 시 즉시 전체 텍스트 표시 (스킵).

#### 3.13.4 이벤트 연동

대화 노드 및 선택지에 `event` 문자열을 통해 게임 이벤트를 트리거한다.

| 이벤트 포맷 | 예시 | 동작 |
|-------------|------|------|
| `set_flag:{name}` | `set_flag:met_npc` | ProgressionSystem에 플래그 설정 |
| `clear_flag:{name}` | `clear_flag:quest_active` | 플래그 해제 |
| `start_battle` | `start_battle` | EventSystem으로 전투 시작 전달 |
| `give_item` | `give_item` | InventorySystem으로 아이템 지급 전달 |

#### 3.13.5 시그널/이벤트

| 시그널 | 페이로드 | 발생 시점 |
|--------|---------|----------|
| dialogue_started | dialogue_id | 대화 시작 시 |
| dialogue_ended | dialogue_id | 대화 종료 시 |
| node_displayed | node_id | 노드 표시 시 |
| choice_selected | choice_index, choice_text | 선택지 선택 시 |
| event_triggered | event_string | 이벤트 문자열 발동 시 |

#### 3.13.6 Flutter 구현

대화 UI는 Flutter Overlay 위젯으로 구현한다.

```
+-------------------------------------------------------------------+
|  [게임 화면]                                                        |
|                                                                    |
|  +--------------------------------------------------------------+  |
|  |  +--------+  +--------------------------------------------+  |  |
|  |  |초상화  |  | [화자 이름]                                 |  |  |
|  |  |100x100 |  | 대사 텍스트가 타이핑 효과로 표시됩니다...   |  |  |
|  |  +--------+  |                                            |  |  |
|  |              | 1. 선택지 A                                 |  |  |
|  |              | 2. 선택지 B                                 |  |  |
|  |              +--------------------------------------------+  |  |
|  |                                       [Enter] 계속...     |  |  |
|  +--------------------------------------------------------------+  |
+-------------------------------------------------------------------+
```

패널 위치: 화면 하단 10%~90% 폭, 70%~95% 높이 (원본 Godot 구현과 동일).

### 3.14 이벤트 시스템

원본 구현체: `godot/scripts/events/event_system.gd`, `event_trigger.gd`

#### 3.14.1 EventType (9종)

| EventType | 설명 | 주요 파라미터 |
|-----------|------|-------------|
| DIALOGUE | 대화 이벤트 | dialogue_path |
| BATTLE | 전투 이벤트 | enemies[], boss, on_victory_flag |
| CUTSCENE | 컷씬 | cutscene_id, duration |
| MAP_TRANSITION | 맵 전환 | target_map, spawn_point, fade |
| ITEM_PICKUP | 아이템 획득 | item_id, quantity |
| FLAG_SET | 플래그 설정 | flag, value |
| SPAWN_ENEMY | 적 스폰 | enemy_id, position, count |
| HEAL_PARTY | 파티 회복 | heal_hp, heal_mp, amount_percent |
| CUSTOM | 커스텀 이벤트 | callback |

#### 3.14.2 TriggerCondition (5종)

| TriggerCondition | 발동 시점 | 사용 예 |
|------------------|----------|---------|
| ON_ENTER | 유닛이 트리거 영역에 진입 | 맵 전환, 이벤트 대화 |
| ON_INTERACT | 확인 키/탭으로 상호작용 | NPC 대화, 아이템 획득 |
| ON_FLAG | 특정 플래그 설정 시 | 퀘스트 진행 조건 |
| ON_BATTLE_END | 전투 종료 시 | 전투 후 이벤트 |
| AUTO | 맵 로드 시 자동 발동 | 오프닝 컷씬, 자동 대화 |

#### 3.14.3 EventTrigger 컴포넌트

맵 내에 배치되는 트리거 영역. Flame에서는 `ShapeHitbox` 기반 충돌 감지로 구현한다.

| 속성 | 타입 | 설명 |
|------|------|------|
| trigger_id | String | 고유 식별자 |
| one_shot | bool | true: 한 번만 실행, false: 반복 실행 |
| requires_interaction | bool | true: 확인 입력 필요, false: 진입 시 자동 발동 |
| required_flags | List<String> | 이 플래그들이 모두 설정되어야 발동 |
| blocked_flags | List<String> | 이 플래그 중 하나라도 설정되면 발동 차단 |
| event_type | String | Dialogue, Battle, MapTransition, Custom |

#### 3.14.4 이벤트 큐 처리

이벤트는 큐에 추가되어 순차 처리된다. 대화/전투 등 `await`가 필요한 이벤트는 완료까지 대기 후 다음 이벤트를 실행한다.

```
queue_event(event_data)
    |
    +-- event_queue에 추가
    +-- 현재 처리 중?
        +-- YES: 대기 (큐에 남김)
        +-- NO: execute_event() 시작
            |
            +-- event_started 시그널 발생
            +-- 타입별 핸들러 실행 (await)
            +-- event_completed 시그널 발생
            +-- 큐에 다음 이벤트 있으면 재귀 실행
```

#### 3.14.5 시그널/이벤트

| 시그널 | 페이로드 | 발생 시점 |
|--------|---------|----------|
| event_started | event_data | 이벤트 실행 시작 |
| event_completed | event_data | 이벤트 실행 완료 |
| trigger_activated | trigger_id | 트리거 활성화 시 |

### 3.15 맵 관리 시스템

원본 구현체: `godot/scripts/map/map_manager.gd`, `map_data.gd`

#### 3.15.1 MapData 리소스

| 속성 | 타입 | 설명 |
|------|------|------|
| map_id | String | 맵 고유 식별자 |
| map_name | String | 맵 표시 이름 |
| chapter | int | 소속 챕터 번호 |
| map_width | int | 맵 가로 크기 (기본 1280) |
| map_height | int | 맵 세로 크기 (기본 800) |
| bgm_path | String | 배경음악 경로 |
| map_type | String | Field, Dungeon, Town, Boss |
| connections | Map | 출구별 연결 맵 정보 `{"exit_name": {"map": "path", "spawn": "point"}}` |
| entry_events | List<String> | 맵 진입 시 실행할 이벤트 |
| enemy_waves | List<Map> | 적 웨이브 정의 |
| enemy_spawns | List<Map> | 일반 적 스폰 `[{"enemy_id": "goblin", "position": [100, 200], "count": 3}]` |
| boss_spawn | Map | 보스 스폰 `{"enemy_id": "goblin_chief", "position": [640, 400]}` |
| spawn_points | Map | 플레이어 스폰 위치 `{"default": [100, 100], "from_forest": [50, 300]}` |

#### 3.15.2 MapManager

| 기능 | 메서드 | 설명 |
|------|--------|------|
| 맵 로드 | `loadMap(mapPath, spawnPoint)` | 기존 맵 정리 후 새 맵 로드, 플레이어 스폰 |
| ID로 로드 | `loadMapById(chapter, mapId, spawnPoint)` | 챕터/맵 ID 기반 로드 |
| 맵 전환 | `transitionToMap(mapPath, spawnPoint, fadeDuration)` | 페이드 효과 포함 전환 |
| 적 스폰 | `spawnEnemies()` | 현재 맵의 enemy_spawns 기반 적 생성 |
| 맵 경계 | `getMapBounds()` | 현재 맵의 Rect 반환 |

#### 3.15.3 충돌 레이어

| CollisionLayer | 값 | 용도 |
|---------------|-----|------|
| WORLD | 1 | 벽, 지형 |
| PLAYER | 2 | 플레이어 유닛 |
| ENEMY | 4 | 적 유닛 |
| TRIGGER | 8 | 이벤트 트리거 |
| PROJECTILE | 16 | 투사체 |

Flame에서는 `CollisionType`과 커스텀 `collisionGroup` 속성으로 동일한 레이어 시스템을 구현한다.

#### 3.15.4 맵 전환 흐름

```
transitionToMap(target, spawn)
    |
    +-- map_transition_started 시그널
    |
    +-- 페이드 아웃 (0.5초 기본)
    |   +-- 검은 ColorFilter alpha 0 --> 1
    |
    +-- loadMap(target, spawn)
    |   +-- 기존 맵 씬 해제
    |   +-- 새 맵 씬 로드/인스턴스화
    |   +-- MapData 참조 획득
    |   +-- 스폰 포인트로 플레이어 유닛 이동 (유닛 간격 50px)
    |   +-- ProgressionSystem에 맵 변경 알림
    |
    +-- 페이드 인 (0.5초)
    |   +-- 검은 ColorFilter alpha 1 --> 0
    |
    +-- map_transition_completed 시그널
```

#### 3.15.5 시그널/이벤트

| 시그널 | 페이로드 | 발생 시점 |
|--------|---------|----------|
| map_loading_started | map_name | 맵 로딩 시작 |
| map_loaded | map_name | 맵 로딩 완료 |
| map_transition_started | from_map, to_map | 맵 전환 시작 |
| map_transition_completed | to_map | 맵 전환 완료 |
| spawn_point_reached | spawn_id | 스폰 포인트 도착 |

#### 3.15.6 Flame Tiled 연동

맵 에디터는 Tiled Map Editor를 사용하고, `flame_tiled` 패키지로 로드한다.

```dart
class MapComponent extends Component with HasGameRef<FQ4Game> {
  late TiledComponent tiledMap;

  Future<void> loadMap(String mapPath) async {
    tiledMap = await TiledComponent.load(mapPath, Vector2.all(32));
    add(tiledMap);

    // 오브젝트 레이어에서 스폰 포인트, 트리거 영역 파싱
    final objectLayer = tiledMap.tileMap.getLayer<ObjectGroup>('triggers');
    // ...
  }
}
```

---

## 4. 스토리/시나리오

### 4.1 세계관

무대는 로그리스 대륙. 바르시아 제국이 마물의 힘을 얻어 대륙을 침공한다. 변경의 전사 아레스가 동료들을 이끌고 제국에 맞서 싸운다.

### 4.2 주요 캐릭터

| 캐릭터 | 역할 | 클래스 | 성격(AI) | 설명 |
|--------|------|--------|---------|------|
| 아레스 | 주인공/리더 | 전사 | - (직접 조작 기본) | 변경의 젊은 전사, 정의감이 강함 |
| 아레인 | 히로인 | 마법사 | BALANCED | 아레스의 소꿉친구, 회복/지원 마법 |
| 시누세 | 동료 | 검사 | AGGRESSIVE | 검의 달인, 과묵하고 충직 |
| 소토카 | 동료 | 기사 | DEFENSIVE | 아레스의 측근, 방어 전문 |
| 타로 | 동료 | 마법사 | BALANCED | 공격 마법 전문, 호기심 많음 |

### 4.3 적 세력

| 캐릭터 | 직위 | 역할 |
|--------|------|------|
| 쿠가이아 | 지의 장군 | 바르시아 제국 전략가 |
| 모르드레드 | 화의 장군 | 바르시아 제국 맹장 |

### 4.4 챕터 구조 (10개)

| 챕터 | 제목 | 주요 이벤트 | 보스 |
|------|------|-----------|------|
| 1 | 마을의 습격 | 바르시아 병사 침공, 부대 편성 튜토리얼 | - |
| 2 | 숲의 시련 | 시누세 합류, 대형 시스템 해금 | - |
| 3 | 성채 탈환 | 소토카 합류, 장비 시스템 | 하급 장군 |
| 4 | 사막 횡단 | 환경 시스템 (FIRE/COLD), 타로 합류 | - |
| 5 | 항구 도시 | 상점 시스템, 해상 전투 | 해적 두목 |
| 6 | 마법의 탑 | 마법 시스템 확장, 퍼즐 | 마법사 |
| 7 | 제국 변경 | 쿠가이아 첫 대결, 대규모 전투 | 쿠가이아 (1차) |
| 8 | 제국 수도 | 모르드레드 대결, 배신 이벤트 | 모르드레드 |
| 9 | 마계의 문 | 쿠가이아 최종 대결, 마물 등장 | 쿠가이아 (최종) |
| 10 | 최종 결전 | 마왕 대결, 엔딩 분기 | 마왕 (3페이즈) |

---

## 5. 그래픽/아트 설계

### 5.1 Rive 기반 아트 스타일

원본의 픽셀아트를 완전히 대체하는 Rive 벡터 애니메이션 기반 아트 스타일.

| 요소 | 방식 | 상세 |
|------|------|------|
| 캐릭터 | Rive Artboard + State Machine | 유닛별 .riv 파일 |
| 배경 | 정적 벡터 + 패럴랙스 레이어 | 맵별 배경 세트 |
| UI | Rive 인터랙티브 위젯 | 버튼, 게이지, 전환 효과 |
| 이펙트 | Rive 파티클 + Flutter CustomPaint | 마법/타격/사망 |
| 초상화 | 고해상도 일러스트 (정적) | 대화/UI용 |

### 5.2 캐릭터 애니메이션 State Machine

```
Rive State Machine: Unit
    |
    +-- Idle (기본 대기)
    |   +-- idle_normal
    |   +-- idle_tired (피로도 TIRED)
    |   +-- idle_exhausted (피로도 EXHAUSTED)
    |
    +-- Walk
    |   +-- walk_normal
    |   +-- walk_tired
    |   +-- walk_exhausted
    |
    +-- Attack
    |   +-- attack_melee
    |   +-- attack_ranged
    |   +-- attack_critical (크리티컬)
    |
    +-- Spell
    |   +-- spell_cast_start
    |   +-- spell_cast_end
    |
    +-- Damage
    |   +-- hit_normal
    |   +-- hit_critical
    |
    +-- Death
    |   +-- death_normal
    |
    +-- Status Effects (오버레이)
        +-- poison_overlay (녹색 기포)
        +-- burn_overlay (불꽃)
        +-- stun_overlay (별)
        +-- freeze_overlay (얼음)
        +-- slow_overlay (파란 기운)
        +-- blind_overlay (어두운 안개)
```

### 5.3 Rive Input/Number 연동

```dart
// Rive State Machine과 게임 시스템 연동
class UnitRiveController {
  late StateMachineController _controller;

  // Inputs (Rive State Machine Triggers/Booleans)
  late SMITrigger _attackTrigger;
  late SMITrigger _hitTrigger;
  late SMITrigger _deathTrigger;
  late SMIBool _isMoving;
  late SMIBool _isPoisoned;
  late SMIBool _isBurning;

  // Numbers (0.0 ~ 1.0)
  late SMINumber _fatigueLevel;     // 피로도 단계 (0=NORMAL, 1=TIRED, 2=EXHAUSTED, 3=COLLAPSED)
  late SMINumber _hpRatio;          // HP 비율
  late SMINumber _directionX;       // 이동 방향 X (-1 ~ 1)

  void updateFromUnit(UnitModel unit) {
    _fatigueLevel.value = unit.fatigueLevel.index.toDouble();
    _hpRatio.value = unit.currentHp / unit.maxHp;
    _isMoving.value = unit.state == UnitState.moving;
    _isPoisoned.value = unit.hasStatusEffect(StatusEffectType.poison);
    _isBurning.value = unit.hasStatusEffect(StatusEffectType.burn);
  }
}
```

### 5.4 화면 해상도 대응

| 플랫폼 | 기준 해상도 | 스케일 방식 |
|--------|-----------|-----------|
| 모바일 세로 | 1080x1920 | 게임 영역 상단, HUD 하단 |
| 모바일 가로 | 1920x1080 | 전체 화면 게임 + 오버레이 HUD |
| 태블릿 | 2048x1536 | 가로 모드 + 확장 UI |
| PC/Web | 1920x1080 | 전체 화면, 창 모드 지원 |

---

## 6. UI/UX 설계

### 6.1 화면 구성

```
+-------------------------------------------------------------------+
|  타이틀 화면                                                       |
|  - 새 게임 / 이어하기 / New Game+ / 설정 / 크레딧                  |
+-------------------------------------------------------------------+
         |
         v
+-------------------------------------------------------------------+
|  메인 게임 화면                                                    |
|  +-------------------------------------------------------------+  |
|  |                                                             |  |
|  |  [게임 월드]  (Flame GameWidget)                             |  |
|  |  - 맵, 유닛, 이펙트 렌더링                                  |  |
|  |  - 카메라: 조작 유닛 추적                                   |  |
|  |                                                             |  |
|  +-------------------------------------------------------------+  |
|  |  [HUD 오버레이]  (Flutter Overlay)                          |  |
|  |  +----------+ +----------+ +------+ +------+ +----------+  |  |
|  |  | 유닛 패널 | | 미니맵   | | 명령 | | 마법 | | 일시정지 |  |  |
|  |  +----------+ +----------+ +------+ +------+ +----------+  |  |
|  +-------------------------------------------------------------+  |
+-------------------------------------------------------------------+
```

### 6.2 화면 목록

| 화면 | 타입 | 설명 |
|------|------|------|
| 타이틀 | Flutter Screen | 새 게임, 이어하기, NG+, 설정, 크레딧 |
| 메인 게임 | Flame GameWidget + Flutter Overlay | 게임 월드 + HUD |
| 유닛 패널 | Flutter Overlay | 초상화, HP/MP/피로도 바, 부대 그리드 (18칸) |
| 전투 HUD | Flutter Overlay | 전투 로그, 타겟 정보, 데미지 팝업 |
| 인벤토리 | Flutter Screen | 50슬롯 그리드, 아이템 상세, 장비 비교 |
| 일시정지 | Flutter Dialog | 재개, 인벤토리, 옵션, 저장, 로드, 타이틀 |
| 상점 | Flutter Screen | 구매/판매 탭, 가격 표시, 재고 |
| 대화 | Flutter Overlay | 초상화 + 텍스트 박스, 선택지 |
| 그래픽 설정 | Flutter Screen | 품질, 이펙트 토글, 접근성 |
| 업적 | Flutter Screen | 카테고리별 목록, 진행률, 잠금/해금 |
| 크레딧 | Flutter Screen | 스크롤 크레딧 |

### 6.3 터치 조작 설계

```
+-------------------------------------------------------------------+
|  터치 입력 매핑                                                    |
+-------------------------------------------------------------------+
|                                                                   |
|  [이동]                                                           |
|  - 빈 영역 탭: 해당 위치로 이동                                   |
|  - 빈 영역 길게 누르기 + 드래그: 연속 이동 (조이스틱)             |
|                                                                   |
|  [공격]                                                           |
|  - 적 유닛 탭: 타겟 설정 + 이동/공격                              |
|  - 적 유닛 더블 탭: 즉시 공격 (사거리 내)                         |
|                                                                   |
|  [유닛 전환]                                                      |
|  - 아군 유닛 탭: 해당 유닛으로 조작 전환                          |
|  - HUD 초상화 좌/우 스와이프: 부대 내 유닛 전환                   |
|  - HUD 초상화 상/하 스와이프: 부대 전환                           |
|                                                                   |
|  [마법]                                                           |
|  - 마법 버튼 탭: 마법 선택 팝업                                   |
|  - 마법 선택 후 타겟 탭: 시전                                     |
|                                                                   |
|  [부대 명령]                                                      |
|  - 명령 버튼 탭: 명령 선택 팝업 (5종)                             |
|  - 두 손가락 핀치: 카메라 줌                                      |
|                                                                   |
+-------------------------------------------------------------------+
```

### 6.4 키보드/게임패드 매핑

| 입력 | 키보드 | 게임패드 | 터치 |
|------|--------|---------|------|
| 이동 | WASD / 방향키 | 좌스틱 | 탭/드래그 |
| 공격 | Space | A 버튼 | 적 탭 |
| 유닛 전환 (부대 내) | Q/E | L1/R1 | 초상화 좌우 스와이프 |
| 부대 전환 | Tab / Shift+Tab | L2/R2 | 초상화 상하 스와이프 |
| 마법 | 1-8 | X 버튼 + 방향 | 마법 버튼 |
| 명령 | F1-F5 | Y 버튼 + 방향 | 명령 버튼 |
| 인벤토리 | I | Select | UI 버튼 |
| 일시정지 | ESC | Start | UI 버튼 |
| 대형 변경 | Shift+1~5 | D-pad | UI 드롭다운 |
| 카메라 줌 | +/- | 우스틱 | 핀치 |

---

## 7. 다국어/접근성

### 7.1 지원 언어

| 언어 | 코드 | 우선순위 |
|------|------|---------|
| 일본어 | ja | 1 (원본 언어) |
| 한국어 | ko | 2 |
| 영어 | en | 3 |

### 7.2 로컬라이제이션 구조

```dart
// Flutter 내장 l10n 사용
// lib/l10n/
//   app_ja.arb  (일본어)
//   app_ko.arb  (한국어)
//   app_en.arb  (영어)

// 사용 예:
Text(AppLocalizations.of(context)!.menuNewGame)
```

| 범위 | 다국어 대상 |
|------|-----------|
| UI 텍스트 | 모든 메뉴, 버튼, 레이블 |
| 대화 텍스트 | 800개 메시지 (원본 FQ4MES 기반) |
| 아이템/장비 이름 | 전체 |
| 마법 이름/설명 | 전체 |
| 업적 이름/설명 | 전체 |
| 시스템 메시지 | 전투 로그, 알림 |

### 7.3 접근성

| 기능 | 설정 | 기본값 |
|------|------|--------|
| 색맹 모드 | NONE / PROTANOPIA / DEUTERANOPIA / TRITANOPIA | NONE |
| 폰트 스케일 | 0.8 ~ 1.5 (슬라이더) | 1.0 |
| 고대비 모드 | ON / OFF | OFF |
| 화면 흔들림 | ON / OFF | ON |
| 플래시 효과 | ON / OFF | ON |
| 자막 | ON / OFF | ON |
| 자막 배경 | ON / OFF | ON |

```dart
// 색맹 모드 구현 (ColorFilter)
enum ColorBlindMode { none, protanopia, deuteranopia, tritanopia }

ColorFilter getColorFilter(ColorBlindMode mode) {
  switch (mode) {
    case ColorBlindMode.protanopia:
      return ColorFilter.matrix(protanopiaMatrix);
    case ColorBlindMode.deuteranopia:
      return ColorFilter.matrix(deuteranopiaMatrix);
    case ColorBlindMode.tritanopia:
      return ColorFilter.matrix(tritanopiaMatrix);
    default:
      return ColorFilter.mode(Colors.transparent, BlendMode.multiply);
  }
}
```

---

## 8. 기술 아키텍처

### 8.1 전체 구조

```
+-------------------------------------------------------------------+
|                        Flutter App                                |
+-------------------------------------------------------------------+
|                                                                   |
|  +---------------------+  +-----------------------------------+   |
|  |   Flutter UI Layer  |  |     Flame Game Layer              |   |
|  |                     |  |                                   |   |
|  |  - Screens          |  |  +-----------------------------+  |   |
|  |  - Widgets          |  |  |   FQ4Game (FlameGame)       |  |   |
|  |  - Dialogs          |  |  |                             |  |   |
|  |  - Overlays         |  |  |   +--- GameWorld            |  |   |
|  |                     |  |  |   |    +-- Map              |  |   |
|  +----------+----------+  |  |   |    +-- Units[]          |  |   |
|             |              |  |   |    +-- Effects[]        |  |   |
|             |              |  |   |                         |  |   |
|  +----------v----------+  |  |   +--- Systems              |  |   |
|  |   Riverpod          |  |  |   |    +-- CombatSystem     |  |   |
|  |   State Management  |  |  |   |    +-- FatigueSystem    |  |   |
|  |                     |  |  |   |    +-- MagicSystem      |  |   |
|  |  - GameState        |<-+->|   |    +-- AISystem         |  |   |
|  |  - UnitStates       |  |  |   |    +-- SquadSystem      |  |   |
|  |  - UIState          |  |  |   |    +-- SpatialHash      |  |   |
|  |  - SettingsState    |  |  |   |    +-- ...              |  |   |
|  |                     |  |  |   |                         |  |   |
|  +----------+----------+  |  |   +--- Camera               |  |   |
|             |              |  |        +-- follow unit      |  |   |
|             |              |  +-----------------------------+  |   |
|  +----------v----------+  +-----------------------------------+   |
|  |   Data Layer        |                                          |
|  |                     |                                          |
|  |  - Isar Database    |                                          |
|  |  - SharedPreferences|                                          |
|  |  - JSON Assets      |                                          |
|  +---------------------+                                          |
+-------------------------------------------------------------------+
```

### 8.2 게임 루프

```dart
class FQ4Game extends FlameGame with HasCollisionDetection {
  // 시스템 참조
  late final CombatSystem combatSystem;
  late final FatigueSystem fatigueSystem;
  late final MagicSystem magicSystem;
  late final AISystem aiSystem;
  late final SquadSystem squadSystem;
  late final SpatialHashSystem spatialHash;
  late final StatusEffectSystem statusEffectSystem;
  late final EnvironmentSystem environmentSystem;

  @override
  Future<void> onLoad() async {
    // 시스템 초기화
    combatSystem = CombatSystem();
    fatigueSystem = FatigueSystem();
    magicSystem = MagicSystem(combatSystem: combatSystem);
    aiSystem = AISystem();
    squadSystem = SquadSystem();
    spatialHash = SpatialHashSystem(cellSize: 100.0);
    statusEffectSystem = StatusEffectSystem();
    environmentSystem = EnvironmentSystem(statusEffectSystem);

    // 맵 로드
    // 유닛 스폰
    // 카메라 설정
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 시스템 업데이트 순서 (중요!)
    // 1. 입력 처리 (Flutter/Flame 이벤트)
    // 2. AI 판단 (aiSystem - 0.3/0.4초 간격)
    // 3. 상태이상 tick (statusEffectSystem)
    // 4. 환경 효과 (environmentSystem)
    // 5. 이동/충돌 (Flame physics)
    // 6. 전투 처리 (combatSystem)
    // 7. 피로도 갱신 (fatigueSystem)
    // 8. Spatial Hash 업데이트
    // 9. UI 동기화 (Riverpod state update)
  }
}
```

### 8.3 상태 관리 (Riverpod)

```dart
// 핵심 Provider 구조

// 게임 상태
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);

enum GameState { menu, battle, paused, gameOver, victory }

// 현재 조작 유닛
final controlledUnitProvider = StateProvider<UnitModel?>((ref) => null);

// 부대 정보
final squadProvider = StateNotifierProvider<SquadNotifier, Map<int, List<UnitModel>>>(
  (ref) => SquadNotifier(),
);

// 인벤토리
final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(),
);

// 설정
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

// 업적
final achievementProvider = StateNotifierProvider<AchievementNotifier, AchievementState>(
  (ref) => AchievementNotifier(),
);
```

### 8.4 Flame-Flutter 브릿지

```
+-------------------------------------------------------------------+
|  Flame <--> Flutter 통신                                          |
+-------------------------------------------------------------------+
|                                                                   |
|  Flame --> Flutter:                                               |
|  - GameRef.overlays.add('hud')    // HUD 오버레이 표시            |
|  - ref.read(provider).update()    // Riverpod 상태 갱신           |
|  - GameWidget.overlayBuilderMap   // 오버레이 위젯 등록           |
|                                                                   |
|  Flutter --> Flame:                                               |
|  - gameRef.squadSystem.issueCommand()  // 부대 명령               |
|  - gameRef.onTapUnit(unit)             // 유닛 선택               |
|  - gameRef.magicSystem.castSpell()     // 마법 시전               |
|                                                                   |
+-------------------------------------------------------------------+
```

### 8.5 세이브/로드 (Isar)

```dart
@Collection()
class SaveData {
  Id id = Isar.autoIncrement;

  int slotIndex;            // 세이브 슬롯 (0-2)
  String saveName;          // "자동 저장" / "슬롯 1" 등
  DateTime savedAt;

  // 게임 진행
  int currentChapter;
  String currentMap;
  double playTimeSeconds;
  Map<String, bool> flags;

  // 유닛 데이터
  List<UnitSaveData> playerUnits;

  // 인벤토리
  Map<String, int> items;   // item_id -> quantity
  int gold;

  // 업적
  Map<String, int> achievements;  // achievement_id -> unlock_timestamp
  Map<String, int> progress;

  // NG+ 데이터
  int ngPlusCount;
}
```

### 8.6 시그널/이벤트 흐름 (Godot Signal to Dart Stream/Riverpod)

Godot의 Signal 기반 아키텍처를 Flutter에서는 Dart Stream과 Riverpod Provider로 변환한다.

#### 8.6.1 핵심 시그널 매핑

| Godot Signal | Flutter 대응 | 타입 |
|-------------|-------------|------|
| `Unit.unit_died(unit)` | `Stream<UnitDiedEvent>` | EventBus (StreamController) |
| `GameManager.state_changed(new_state)` | `gameStateProvider` | StateNotifierProvider |
| `GameManager.squad_changed(squad_id)` | `squadProvider` | StateNotifierProvider |
| `GameManager.controlled_unit_changed(unit)` | `controlledUnitProvider` | StateProvider |
| `CombatSystem.damage_dealt(attacker, target, damage)` | `Stream<DamageEvent>` | EventBus |
| `CombatSystem.unit_killed(killer, victim)` | `Stream<UnitKilledEvent>` | EventBus |
| `DialogueSystem.dialogue_started(id)` | `Stream<DialogueStartEvent>` | EventBus |
| `DialogueSystem.dialogue_ended(id)` | `Stream<DialogueEndEvent>` | EventBus |
| `MapManager.map_loaded(name)` | `Stream<MapLoadedEvent>` | EventBus |
| `MapManager.map_transition_completed(name)` | `Stream<MapTransitionEvent>` | EventBus |
| `EventSystem.event_started(data)` | `Stream<GameEvent>` | EventBus |
| `EventSystem.event_completed(data)` | `Stream<GameEvent>` | EventBus |

#### 8.6.2 EventBus 구현

```dart
class GameEventBus {
  // 전투 이벤트
  final _damageController = StreamController<DamageEvent>.broadcast();
  final _unitKilledController = StreamController<UnitKilledEvent>.broadcast();
  final _unitDiedController = StreamController<UnitDiedEvent>.broadcast();

  // 대화 이벤트
  final _dialogueStartController = StreamController<DialogueStartEvent>.broadcast();
  final _dialogueEndController = StreamController<DialogueEndEvent>.broadcast();

  // 맵 이벤트
  final _mapLoadedController = StreamController<MapLoadedEvent>.broadcast();
  final _mapTransitionController = StreamController<MapTransitionEvent>.broadcast();

  // 게임 이벤트
  final _gameEventController = StreamController<GameEvent>.broadcast();

  // Getters
  Stream<DamageEvent> get onDamageDealt => _damageController.stream;
  Stream<UnitDiedEvent> get onUnitDied => _unitDiedController.stream;
  // ...
}

// Riverpod Provider로 등록
final gameEventBusProvider = Provider<GameEventBus>((ref) => GameEventBus());
```

#### 8.6.3 상태 변경 흐름

```
유닛 사망 시:
    Unit.die()
    --> gameEventBus.emitUnitDied(unit)
    --> GameManager.unregisterUnit(unit)
        --> 조작 유닛이면: controlledUnitProvider 갱신 (자동 전환)
        --> squadProvider 갱신
        --> _checkGameOver()
            --> gameStateProvider를 GAME_OVER 또는 VICTORY로 변경

전투 데미지 시:
    CombatSystem.executeAttack(attacker, target)
    --> gameEventBus.emitDamageDealt(attacker, target, damage)
    --> UI: DamagePopup 위젯 표시 (Stream 구독)
    --> 사망 시: ExperienceSystem 경험치 처리
```

---

## 9. 성능 목표

### 9.1 목표 사양

| 지표 | 목표 | 측정 조건 |
|------|------|----------|
| FPS | 60 FPS | 100 유닛 동시 전투 |
| 메모리 | < 200 MB | 게임 플레이 중 |
| 앱 시작 | < 3초 | 콜드 스타트 |
| 씬 전환 | < 1초 | 챕터/맵 전환 |
| 배터리 | 4시간+ | 모바일 연속 플레이 |
| APK 크기 | < 100 MB | 초기 설치 (에셋 별도 다운로드 가능) |

### 9.2 Spatial Hash

100 유닛 동시 전투 시 적 탐색 성능을 보장하기 위한 공간 분할 시스템.

```dart
class SpatialHash {
  final double cellSize;  // 기본 100.0
  final Map<Vector2i, List<Component>> cells = {};

  void insert(Component obj, Vector2 position);
  void remove(Component obj, Vector2 position);
  void update(Component obj, Vector2 oldPos, Vector2 newPos);

  List<Component> queryRange(Vector2 center, double radius);
  Component? queryNearest(Vector2 center, double radius, bool Function(Component) filter);
}
```

| 연산 | 기존 (전체 순회) | Spatial Hash |
|------|-----------------|-------------|
| 범위 검색 | O(n) | O(k) (k = 셀 내 유닛) |
| 최근접 탐색 | O(n) | O(k) |
| 위치 갱신 | - | O(1) (셀 변경 시만) |

셀 변경 감지: 위치 변화 > 1px 일 때만 업데이트.

### 9.3 오브젝트 풀링

```dart
class ObjectPool<T extends Component> {
  final T Function() factory;
  final Queue<T> _pool = Queue();
  final int initialSize;

  ObjectPool({required this.factory, this.initialSize = 20}) {
    // 초기 풀 생성
    for (int i = 0; i < initialSize; i++) {
      _pool.add(factory());
    }
  }

  T acquire() {
    if (_pool.isEmpty) return factory();
    return _pool.removeFirst();
  }

  void release(T obj) {
    // 리셋 후 반환
    _pool.add(obj);
  }
}

// 등록 예시:
// effectPool = ObjectPool(factory: () => HitEffect(), initialSize: 30);
// arrowPool = ObjectPool(factory: () => ArrowProjectile(), initialSize: 20);
```

### 9.4 렌더링 최적화

| 기법 | 설명 |
|------|------|
| 뷰포트 컬링 | 카메라 밖 유닛은 렌더링 스킵 |
| Rive LOD | 거리에 따라 애니메이션 복잡도 조절 |
| 배치 렌더링 | 같은 Rive 파일의 유닛은 배치 처리 |
| AI tick 분산 | 100 유닛의 AI를 프레임별 분산 처리 |
| 상태 diff | Riverpod 상태 변경 시에만 UI 리빌드 |

### 9.5 비기능 요구사항

| 항목 | 목표 | 측정 방식 |
|------|------|----------|
| 크래시율 | < 0.1% | Firebase Crashlytics 또는 Sentry |
| ANR 비율 | < 0.5% | Android Vitals |
| 세이브 데이터 무결성 | 100% | 저장 후 로드 비교 검증, 체크섬 |
| 오프라인 동작 | 100% | 네트워크 없이 모든 기능 정상 동작 |
| 콜드 스타트 | < 3초 | 기준 기기(iPhone 11, Galaxy S10)에서 측정 |
| 핫 리로드 복구 | < 0.5초 | 일시정지 후 복귀 시 상태 보존 |

---

## 10. 개발 로드맵

### 10.1 페이즈 개요

```
Phase 0       Phase 1        Phase 2       Phase 3       Phase 4
Pre-prod      Foundation     Core Systems  Content       Polish
(6주)         (8주)          (12주)        (10주)        (6주)
|             |              |             |             |
v             v              v             v             v
기획/설계     엔진 기반      Gocha-Kyara   챕터 4-10     성능 최적화
아트 설계     유닛 시스템     전투/마법     보스/엔딩     다국어
프로토타입    챕터 1-3       AI/부대       NG+/업적     접근성
              기본 UI        환경/상태     상점/장비     QA/버그픽스

                                                        |
                                                        v
                                                    Phase 5
                                                    Release (4주)
                                                    스토어 심사
                                                    베타 테스트
                                                    출시
```

### 10.2 페이즈별 상세

#### Phase 0: Pre-production (6주)

| 주차 | 작업 | 산출물 |
|------|------|--------|
| 1-2 | Flutter/Flame 프로젝트 설정, 아키텍처 확정 | 프로젝트 스캐폴드 |
| 2-3 | Rive 아트 스타일 확정, 캐릭터 1체 프로토타입 | 아트 스타일 가이드 |
| 3-4 | 게임 루프 프로토타입 (이동/공격/카메라), **100 Rive 인스턴스 60FPS 성능 게이트** | 기술 프로토타입 |
| 4 | 성능 게이트 판정: 100개 Rive 인스턴스 60FPS 달성 여부. 실패 시 전략 B(Sprite Sheet) 전환 결정 | Go/No-Go 판정 |
| 5-6 | 터치 입력 프로토타입, UI 와이어프레임 | UX 프로토타입 |

#### Phase 1: Foundation (8주)

| 주차 | 작업 | 시스템 |
|------|------|--------|
| 1-2 | Unit 컴포넌트 계층 (Unit/AIUnit/PlayerUnit/EnemyUnit) | 유닛 시스템 |
| 3-4 | CombatSystem, FatigueSystem | 전투/피로도 |
| 5-6 | GameManager (부대 관리, 유닛 전환) | Gocha-Kyara 기반 |
| 7-8 | 챕터 1-3 맵, 기본 HUD, 타이틀 화면 | 콘텐츠/UI |

#### Phase 2: Core Systems (12주)

| 주차 | 작업 | 시스템 |
|------|------|--------|
| 1-2 | AISystem (9개 AIState 상태머신) | Gocha-Kyara AI |
| 3-4 | 성격/대형/부대 명령 시스템 | Gocha-Kyara 확장 |
| 5-6 | MagicSystem (8종 마법, 시전 흐름) | 마법 시스템 |
| 7-8 | StatusEffectSystem (6종), EnvironmentSystem (6종 지형) | 상태이상/환경 |
| 9-10 | EquipmentSystem, InventorySystem, ShopSystem | 장비/인벤토리/상점 |
| 11-12 | ExperienceSystem, StatsSystem, 대화 시스템 | 경험치/스탯/대화 |

#### Phase 3: Content (10주)

| 주차 | 작업 | 시스템 |
|------|------|--------|
| 1-3 | 챕터 4-7 맵/이벤트/대화 | 콘텐츠 |
| 4-5 | BossUnit (3페이즈, 광폭화, 미니언 소환) | 보스 시스템 |
| 6-7 | 챕터 8-10, EndingSystem (GOOD/NORMAL/BAD) | 엔딩 |
| 8-9 | NewGamePlusSystem, AchievementSystem (28개) | NG+/업적 |
| 10 | 세이브/로드, 설정 화면 | 시스템 |

#### Phase 4: Polish (6주)

| 주차 | 작업 | 영역 |
|------|------|------|
| 1-2 | 성능 최적화 (Spatial Hash, Object Pool, 100 유닛 60FPS) | 성능 |
| 3-4 | 다국어 (ja/ko/en), 접근성 (색맹, 폰트, 고대비) | 다국어/접근성 |
| 5-6 | QA, 버그 수정, 밸런스 조정, 사운드 통합 | 품질 |

#### Phase 5: Release (4주)

| 주차 | 작업 | 영역 |
|------|------|------|
| 1 | 앱스토어 심사 제출 (iOS/Android) | 배포 |
| 2-3 | 베타 테스트 (TestFlight/내부 테스트) | 테스트 |
| 4 | 최종 수정, 출시 | 릴리즈 |

### 10.3 총 일정

| 페이즈 | 기간 | 누적 |
|--------|------|------|
| Phase 0 | 6주 | 6주 |
| Phase 1 | 8주 | 14주 |
| Phase 2 | 12주 | 26주 |
| Phase 3 | 10주 | 36주 |
| Phase 4 | 6주 | 42주 |
| Phase 5 | 4주 | 46주 (약 11개월) |

---

## 11. 리스크/제약사항

### 11.1 기술 리스크

| 리스크 | 영향도 | 확률 | 대응 |
|--------|--------|------|------|
| 100 유닛 Rive 애니메이션 성능 | HIGH | 중 | LOD, 뷰포트 컬링, 심플 스프라이트 대체 |
| Flame + Rive 통합 안정성 | HIGH | 중 | Rive는 UI만, 인게임은 Flame SpriteBatch |
| 모바일 터치 조작 UX | HIGH | 고 | 프로토타입 단계 UX 테스트, 반복 개선 |
| Flame 대규모 유닛 렌더링 | MEDIUM | 중 | Spatial Hash, Object Pool, 배치 렌더링 |
| Isar 세이브 데이터 마이그레이션 | LOW | 저 | 스키마 버전 관리 |
| Isar 4.0 Web 지원 제한 | MEDIUM | 중 | Web 타겟 시 shared_preferences 또는 Hive로 대체. Native 빌드(iOS/Android/Desktop)는 Isar 유지 |

### 11.2 콘텐츠 리스크

| 리스크 | 영향도 | 확률 | 대응 |
|--------|--------|------|------|
| Rive 에셋 제작 분량 | HIGH | 고 | 캐릭터 리깅 템플릿화, 공통 State Machine |
| 10개 챕터 맵 제작 | MEDIUM | 중 | Tiled 에디터 활용, 타일셋 재사용 |
| 800개 대화 번역 | MEDIUM | 중 | 원본 일본어 기반, 한/영 번역 외주 |
| BGM/SFX 제작 | MEDIUM | 중 | 프리랜서 작곡, SFX 라이브러리 활용 |

### 11.3 사업 리스크

| 리스크 | 영향도 | 확률 | 대응 |
|--------|--------|------|------|
| 원본 IP 라이선스 | CRITICAL | 미확인 | Kure Software Koubou 연락 필요 |
| 앱스토어 심사 거부 | MEDIUM | 저 | 심사 가이드라인 준수, 사전 확인 |
| 수익화 모델 미정 | MEDIUM | 중 | 유료 앱 vs F2P 결정 필요 |

### 11.4 제약사항

| 제약 | 내용 |
|------|------|
| 원본 에셋 사용 불가 | 모든 에셋 신규 제작 (IP 이슈) |
| 네트워크 기능 없음 | 오프라인 싱글 플레이 전용 |
| 컨트롤러 지원 범위 | Xbox/PlayStation 공식 컨트롤러만 보장 |
| 최소 OS | iOS 15+, Android 8.0+ |
| 최소 기기 | iPhone 11 / Galaxy S10 이상 권장 |

### 11.5 Rive vs Sprite 대안 전략

100 유닛 Rive 동시 렌더링이 성능 병목이 될 경우의 대안:

```
전략 A (권장): Hybrid 방식
  - 조작 유닛 + 근접 유닛: Rive 풀 애니메이션
  - 원거리 유닛: Rive 심플 모드 (State Machine 비활성화)
  - 화면 밖 유닛: 렌더링 스킵

전략 B (대안): Sprite 대체
  - Rive에서 Sprite Sheet 사전 렌더링
  - 인게임은 Flame SpriteBatch로 렌더링
  - UI/대화/메뉴만 Rive 유지

전략 C (최악): 유닛 수 제한
  - 동시 유닛 수를 50으로 제한
  - 원본보다 적지만 모바일 최적화
```

### 11.6 팀 구성

| 역할 | 최소 인원 | 담당 영역 |
|------|----------|----------|
| 프로그래머 (Flutter/Flame) | 1-2 | 게임 시스템, UI, 빌드, 테스트 |
| Rive 아티스트 | 1 | 캐릭터/UI/이펙트 애니메이션 제작 |
| 사운드 디자이너 | 1 (외주 가능) | BGM 작곡, SFX 제작 |
| QA | 0.5 (겸임 가능) | 테스트, 밸런스 검증 |

예상 풀타임 인력: 2-3명. 1인 개발 시 아트/사운드 외주 필수.

### 11.7 KPI / 성공 지표

| 지표 | 목표 | 측정 시점 |
|------|------|----------|
| 다운로드 수 (출시 1개월) | 10,000+ | 출시 후 30일 |
| DAU | 500+ | 출시 후 안정기 |
| D7 리텐션 | 25%+ | 출시 후 측정 |
| D30 리텐션 | 10%+ | 출시 후 측정 |
| 크래시율 | < 0.1% | 상시 모니터링 |
| 앱 평점 | 4.0+ | 앱스토어 리뷰 |
| 챕터 10 클리어율 | 15%+ | 전체 플레이어 대비 |
| 평균 플레이 시간 | 8시간+ | 전체 사용자 평균 |

---

## 12. GDScript to Dart 마이그레이션 전략

기존 Godot 4.4 구현체를 Flutter/Flame으로 이식할 때의 체계적 변환 규칙.

### 12.1 언어 매핑

| GDScript | Dart | 비고 |
|----------|------|------|
| `var` (동적 타이핑) | 명시적 타입 (`int`, `String`, `UnitModel`) | Dart는 정적 타이핑. 모든 변수에 타입 명시 |
| `Dictionary` | `Map<String, dynamic>` 또는 freezed 모델 | 가능한 한 freezed 모델로 변환 |
| `Array` | `List<T>` | 제네릭 타입 명시 |
| `enum` | `enum` | 동일 |
| `extends Resource` | `@freezed class` | 불변 데이터 모델 |
| `extends Node` | `class extends Component` 또는 일반 클래스 | Flame Component 또는 서비스 클래스 |
| `class_name X` | `class X` | Dart는 파일당 여러 클래스 가능 |
| `@export var` | `final` 필드 (freezed) 또는 `late` 필드 | 에디터 노출 불필요 |
| `push_error()` | `throw Exception()` 또는 `log.severe()` | 에러 처리 |
| `push_warning()` | `log.warning()` | 경고 |

### 12.2 노드/컴포넌트 매핑

| Godot | Flame/Flutter | 비고 |
|-------|-------------|------|
| `CharacterBody2D` | `PositionComponent` + `HasCollisionDetection` | Flame 컴포넌트 |
| `Area2D` | `ShapeHitbox` (CircleHitbox, RectangleHitbox) | 충돌 감지 |
| `CollisionShape2D` | `CircleHitbox` / `RectangleHitbox` | Flame hitbox |
| `CanvasLayer` | Flutter `Overlay` 또는 `Stack` 위젯 | UI 레이어 |
| `Sprite2D` | `SpriteComponent` | 스프라이트 |
| `AnimatedSprite2D` | `SpriteAnimationComponent` 또는 `RiveComponent` | 애니메이션 |
| `TileMapLayer` | `TiledComponent` (flame_tiled) | 타일맵 |
| `Camera2D` | `CameraComponent` | 카메라 |
| `Marker2D` | 좌표값 (`Vector2`) | 위치 마커 |

### 12.3 생명주기 매핑

| Godot | Flame | 호출 시점 |
|-------|-------|----------|
| `_ready()` | `onLoad()` | 컴포넌트 로드 완료 |
| `_process(delta)` | `update(double dt)` | 매 프레임 |
| `_physics_process(delta)` | `update(double dt)` | Flame은 물리/일반 구분 없음 |
| `_input(event)` | `onTapDown()`, `onKeyEvent()` 등 Mixin | 입력 처리 |
| `_enter_tree()` | `onMount()` | 트리 진입 |
| `_exit_tree()` | `onRemove()` | 트리 이탈 |
| `queue_free()` | `removeFromParent()` | 노드/컴포넌트 제거 |

### 12.4 시그널 to Stream/Provider 매핑

| Godot Signal 패턴 | Dart 대응 | 사용 시점 |
|-------------------|----------|----------|
| `signal X` (선언) | `StreamController<XEvent>.broadcast()` | 이벤트 버스 |
| `X.emit(args)` | `_controller.add(XEvent(args))` | 이벤트 발생 |
| `X.connect(callable)` | `stream.listen((event) => ...)` | 이벤트 구독 |
| `await signal_name` | `await stream.first` | 시그널 대기 |
| 상태 변경 시그널 | `StateNotifierProvider` (Riverpod) | UI 반응형 상태 |

### 12.5 Autoload to Riverpod Provider 변환

| Godot Autoload | Riverpod Provider | 타입 |
|---------------|------------------|------|
| `GameManager` | `gameManagerProvider` | `Provider<GameManager>` |
| `SaveSystem` | `saveSystemProvider` | `Provider<SaveSystem>` |
| `GraphicsManager` | `settingsProvider` | `StateNotifierProvider<SettingsNotifier, SettingsState>` |
| `ProgressionSystem` | `progressionProvider` | `StateNotifierProvider` |
| `ChapterManager` | `chapterManagerProvider` | `Provider<ChapterManager>` |
| `EventSystem` | `eventSystemProvider` | `Provider<EventSystem>` |
| `AudioManager` | `audioManagerProvider` | `Provider<AudioManager>` |
| `PoolManager` | `ObjectPool<T>` (Flame 내부) | 게임 내부 관리 |
| `AchievementSystem` | `achievementProvider` | `StateNotifierProvider` |

Autoload 싱글톤은 Riverpod의 `Provider`로 변환하여 의존성 주입과 테스트 용이성을 확보한다.

### 12.6 주요 변환 예시

```dart
// --- GDScript 원본 ---
// func _physics_process(delta: float) -> void:
//     if current_state == UnitState.MOVING:
//         velocity = direction * move_speed
//         move_and_slide()

// --- Dart/Flame 변환 ---
class UnitComponent extends PositionComponent
    with HasGameRef<FQ4Game>, CollisionCallbacks {

  UnitState currentState = UnitState.idle;
  Vector2 direction = Vector2.zero();
  double moveSpeed = 100.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (currentState == UnitState.moving) {
      position += direction * moveSpeed * dt;
    }
  }
}
```

### 12.7 마이그레이션 체크리스트

| 단계 | 작업 | 검증 |
|------|------|------|
| 1 | 데이터 모델 변환 (Resource -> freezed) | 직렬화/역직렬화 테스트 |
| 2 | Autoload -> Provider 변환 | 의존성 그래프 검증 |
| 3 | Signal -> Stream/Provider 변환 | 이벤트 흐름 테스트 |
| 4 | Unit 클래스 계층 변환 | 상태머신 동작 테스트 |
| 5 | 시스템 변환 (Combat, Fatigue 등) | 공식/상수 단위 테스트 |
| 6 | UI 변환 (Godot Node -> Flutter Widget) | 위젯 테스트 |
| 7 | 맵/이벤트 변환 | 통합 테스트 |

---

## 13. 테스트 전략

### 13.1 테스트 피라미드

```
              +--------+
             /  E2E    \        5% - 시나리오 테스트
            /  Tests    \
           +-----------+
          / Integration  \      15% - 시스템 간 상호작용
         /    Tests       \
        +-----------------+
       /   Widget Tests     \    30% - UI 컴포넌트
      /                       \
     +-------------------------+
    /      Unit Tests            \   50% - 핵심 로직
   +-------------------------------+
```

### 13.2 단위 테스트

핵심 시스템의 공식과 로직을 검증한다.

| 대상 시스템 | 테스트 항목 | 커버리지 목표 |
|------------|-----------|-------------|
| CombatSystem | 데미지 공식, 크리티컬 판정, 명중/회피, 최소 데미지 | 95% |
| FatigueSystem | 피로도 증감, 단계 판정, 패널티 배율 | 95% |
| AISystem | 상태 전이, 성격별 파라미터, 대형 오프셋 계산 | 90% |
| MagicSystem | MP 소모, 쿨다운, 타겟 결정, 효과 적용 | 90% |
| ExperienceSystem | 경험치 공식, 레벨업 스탯 성장, 타입 배율 | 95% |
| StatusEffectSystem | 상태이상 적용/해제, tick 데미지, 중복 처리 | 90% |
| EquipmentSystem | 장비 장착/해제, 스탯 반영 | 85% |
| InventorySystem | 아이템 추가/제거, 스택, 최대 슬롯 | 85% |
| ShopSystem | 구매/판매 가격 계산, 재고 관리 | 85% |
| EndingSystem | 엔딩 조건 판정 (GOOD/NORMAL/BAD) | 100% |
| SaveSystem | 직렬화/역직렬화, 데이터 무결성 | 95% |

### 13.3 위젯 테스트

| 대상 위젯 | 테스트 항목 |
|----------|-----------|
| HUD | HP/MP/피로도 바 표시, 유닛 전환 UI |
| 대화 UI | 텍스트 표시, 타이핑 효과, 선택지 버튼, 초상화 |
| 인벤토리 UI | 그리드 표시, 아이템 드래그, 장비 비교 |
| 상점 UI | 가격 표시, 구매/판매, 재고 |
| 업적 UI | 카테고리 표시, 진행률, 잠금/해금 상태 |
| 일시정지 메뉴 | 메뉴 항목, 저장/로드 |

### 13.4 통합 테스트

Flame 게임 루프와 시스템 간 상호작용을 검증한다.

| 시나리오 | 검증 내용 |
|---------|----------|
| 전투 흐름 | 공격 -> 데미지 -> 피로도 증가 -> 사망 -> 경험치 지급 |
| AI 행동 | 유닛 스폰 -> AI tick -> 상태 전이 -> 이동/공격 |
| 마법 시전 | 마법 선택 -> MP 소모 -> 쿨다운 -> 효과 적용 -> 피로도 증가 |
| 대화 시스템 | 이벤트 트리거 -> 대화 시작 -> 선택지 -> 플래그 설정 -> 대화 종료 |
| 맵 전환 | 트리거 진입 -> 페이드 -> 맵 로드 -> 스폰 -> 페이드 인 |
| 세이브/로드 | 게임 상태 저장 -> 앱 종료 -> 복원 -> 상태 일치 확인 |

### 13.5 E2E 시나리오 테스트

| 시나리오 | 설명 | 예상 시간 |
|---------|------|----------|
| 챕터 1 클리어 | 타이틀 -> 새 게임 -> 튜토리얼 -> 첫 전투 -> 챕터 1 클리어 | 자동 5분 |
| 풀 플레이 스루 | 챕터 1-10 자동 전투 (AI 전원 자동) | 자동 30분 |
| 세이브/로드 사이클 | 저장 -> 종료 -> 재시작 -> 로드 -> 이전 상태 확인 | 자동 2분 |
| NG+ 사이클 | 클리어 -> NG+ 시작 -> 스케일링 확인 | 자동 10분 |

### 13.6 밸런스 테스트

100 유닛 전투 시뮬레이션으로 밸런스를 검증한다.

```dart
// 자동 밸런스 시뮬레이터
class BalanceSimulator {
  /// 지정된 조합으로 N회 전투를 시뮬레이션하고 통계를 반환
  SimulationResult simulate({
    required List<UnitConfig> playerTeam,
    required List<UnitConfig> enemyTeam,
    int iterations = 1000,
  });
}

// 검증 항목:
// - 아군 승률이 40-70% 범위인지
// - 평균 전투 시간이 30초-5분 범위인지
// - 특정 유닛/마법이 지배적이지 않은지
// - 레벨 차이에 따른 경험치 보정이 적절한지
```

### 13.7 성능 테스트

| 테스트 | 조건 | 합격 기준 |
|--------|------|----------|
| 100 유닛 FPS | 50 아군 + 50 적, 전투 중 | 60 FPS 이상 (기준 기기) |
| 메모리 사용량 | 1시간 연속 플레이 | < 200 MB, 누수 없음 |
| 맵 전환 시간 | 챕터 간 전환 | < 1초 |
| 콜드 스타트 | 앱 설치 후 첫 실행 | < 3초 |
| Rive 렌더링 | 100 Rive 인스턴스 동시 | 60 FPS 이상 |

### 13.8 커버리지 목표

| 영역 | 목표 커버리지 |
|------|-------------|
| 핵심 시스템 (Combat, AI, Fatigue, Magic) | 90%+ |
| 데이터 모델 (freezed) | 85%+ |
| UI 위젯 | 70%+ |
| 전체 프로젝트 | 80%+ |

---

## 14. 용어 사전

### 14.1 핵심 게임 용어

| 용어 | 원본 일본어 | 영어 | 설명 |
|------|-----------|------|------|
| Gocha-Kyara | ゴチャキャラ | Gocha-Kyara | First Queen 시리즈의 핵심 시스템. 다수 유닛을 AI가 자동 제어 |
| 부대 | 部隊 | Squad | 리더 1명과 동료 유닛들로 구성된 그룹 |
| 대형 | 陣形 | Formation | 부대원의 배치 패턴 (V_SHAPE, LINE, CIRCLE, WEDGE, SCATTERED) |
| 부대 명령 | 部隊命令 | SquadCommand | 리더가 부대에 내리는 전술 명령 (NONE, GATHER, SCATTER, ATTACK_ALL, DEFEND_ALL, RETREAT_ALL) |
| 피로도 | 疲労度 | Fatigue | 행동에 따라 누적되는 피로. 4단계 (NORMAL, TIRED, EXHAUSTED, COLLAPSED) |

### 14.2 AI 시스템 용어

| 용어 | 설명 |
|------|------|
| AIState | AI 유닛의 현재 행동 상태. 9종: IDLE, FOLLOW, PATROL, CHASE, ATTACK, RETREAT, DEFEND, SUPPORT, REST |
| Personality | AI의 성격 유형. 3종: AGGRESSIVE (공격적), DEFENSIVE (방어적), BALANCED (균형) |
| AI tick | AI 판단 주기. 아군 0.3초, 적 0.4초 간격으로 상태를 평가 |
| 감지 범위 | AI 유닛이 적을 인식하는 최대 거리. 성격에 따라 배율 적용 |
| 추종 거리 | FOLLOW 상태에서 리더와 유지하는 거리. 기본 80px |

### 14.3 전투 시스템 용어

| 용어 | 설명 |
|------|------|
| 데미지 분산 | 최종 데미지에 적용되는 랜덤 편차. 기본 +/-10% |
| 크리티컬 | 기본 5% 확률로 발생. 데미지 2배 |
| 최소 데미지 | 방어력 초과 시에도 보장되는 최소 데미지. 항상 1 |
| 광폭화 | 보스 HP 20% 이하 시 발동. ATK 1.5배, SPD 1.3배 |

### 14.4 시스템 용어

| 용어 | 영어 | 설명 |
|------|------|------|
| Spatial Hash | Spatial Hash | 공간 분할 해시맵. O(n) 탐색을 O(k)로 최적화 |
| Object Pool | Object Pool | 오브젝트 재사용 풀. 메모리 할당 최소화 |
| EventTrigger | Event Trigger | 맵 내 이벤트 발동 영역. Area2D/ShapeHitbox 기반 |
| 플래그 | Flag | 게임 진행 상태를 나타내는 불리언 값 (ProgressionSystem 관리) |
| 스폰 포인트 | Spawn Point | 유닛이 생성되는 맵 내 위치 |

### 14.5 기술 용어

| 용어 | 설명 |
|------|------|
| Flame | Flutter 기반 2D 게임 엔진. 게임 루프, 물리, 카메라 제공 |
| Rive | 벡터 애니메이션 도구/런타임. State Machine 기반 인터랙티브 애니메이션 |
| Riverpod | Flutter 상태 관리 라이브러리. Provider 기반 의존성 주입 |
| Isar | Flutter 로컬 데이터베이스. 세이브/설정 저장 |
| freezed | Dart 코드 생성 패키지. 불변 데이터 모델 자동 생성 |
| Tiled | 2D 타일맵 에디터. flame_tiled로 Flame에서 로드 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-08 | 초안 작성 |
| 1.1.0 | 2026-02-08 | 검토 반영: 대화/이벤트/맵 시스템 추가 (3.13-3.15), 좌표계 정책 (1.5), 시그널 흐름 (8.6), GDScript to Dart 마이그레이션 전략 (12), 테스트 전략 (13), 용어 사전 (14), 비기능 요구사항 (9.5), 팀 구성 (11.6), KPI (11.7), SquadCommand NONE 추가, Phase 0 성능 게이트 추가, flame_riverpod 검증 메모, Isar Web 리스크 추가 |
