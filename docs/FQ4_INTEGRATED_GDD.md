# First Queen 4 HD Remake - 통합 기획서

**Version**: 1.0.0
**Last Updated**: 2026-02-04
**Status**: Ralplan 합의 완료 (Critic 조건부 승인)

---

## 문서 범례

| 마크 | 의미 | 설명 |
|------|------|------|
| ✅ | 구현됨 | 코드 완성, 테스트 가능 |
| 🔨 | 부분구현 | 기본 구조만 존재, 로직 미완성 |
| ❌ | 미구현 | 코드 없음 |
| 🔵 확정 | 확정 데이터 | 복호화/코드 검증 완료 |
| 🟡 추정 | 추정 데이터 | 패턴 분석 기반, 검증 필요 |
| 🔴 가정 | 가정 데이터 | 기획 의도 기반, 원작 미확인 |

---

## 1. Executive Summary

### 1.1 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **타이틀** | First Queen 4 HD Remake |
| **원작** | First Queen 4 (DOS, 1994, Kure Software Koubou) |
| **장르** | 실시간 전술 RPG |
| **엔진** | Godot 4.4 (Forward+) |
| **해상도** | 1280×800 (원본 320×200의 4배) |
| **핵심 시스템** | Gocha-Kyara (AI 동료 자동 제어) |

### 1.2 프로젝트 목표

1. **Gocha-Kyara 시스템 완벽 재현**: 원작의 핵심인 AI 동료 자동 제어 시스템
2. **HD 그래픽**: AI 업스케일링(Real-ESRGAN)으로 픽셀아트 보존하며 고해상도화
3. **현대적 UX**: 키보드/마우스 지원, 직관적 UI

### 1.3 구현 현황 요약

| 시스템 | 상태 | 완성도 |
|--------|------|--------|
| Gocha-Kyara AI | ✅ 구현됨 | 95% |
| 피로도 시스템 | ✅ 구현됨 | 100% |
| 전투 시스템 | ✅ 구현됨 | 90% |
| 부대 관리 | ✅ 구현됨 | 85% |
| RPG 시스템 (레벨업) | 🔨 부분구현 | 40% |
| 장비/인벤토리 | 🔨 부분구현 | 30% |
| 마법 시스템 | ❌ 미구현 | 0% |
| 대화/이벤트 | 🔨 부분구현 | 50% |
| 오디오 | ❌ 미구현 | 0% |
| 세이브/로드 | ✅ 구현됨 | 80% |

---

## 2. Game Overview

### 2.1 게임 콘셉트

플레이어는 주인공 1명만 직접 조작하고, 나머지 부대원(최대 7명)은 AI가 자동 제어하는 **Gocha-Kyara** 시스템이 핵심. 각 캐릭터는 성격(Personality)에 따라 독립적으로 판단하고 행동하며, 플레이어는 전략적 명령만 내린다.

### 2.2 게임 루프

```
┌─────────────────────────────────────────────────────────┐
│                    메인 게임 루프                         │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ 탐색    │       │  전투   │       │  휴식   │
   │ (이동)  │──────▶│(Gocha)  │──────▶│ (회복)  │
   └─────────┘       └─────────┘       └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                    ┌─────────────┐
                    │ 이벤트/대화 │
                    └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  챕터 진행  │
                    └─────────────┘
```

### 2.3 게임 상태 (GameState)

| 상태 | 설명 | 전환 조건 |
|------|------|----------|
| `PLAYING` | 일반 플레이 | 기본 상태 |
| `BATTLE` | 전투 중 | 적 감지 시 |
| `PAUSED` | 일시정지 | ESC 키 |
| `VICTORY` | 승리 | 목표 달성 |
| `GAME_OVER` | 패배 | 주인공 사망 |

**구현 위치**: `godot/scripts/autoload/game_manager.gd:15-21`

---

## 3. Characters & Story

### 3.1 주요 캐릭터 🟡 추정

> ⚠️ **데이터 신뢰도 주의**: 캐릭터명은 FQ4MES 복호화 데이터 기반 추정. 88.59% 복호화율로 일부 오류 가능.

| 코드명 | 추정 이름 | 신뢰도 | 역할 | 등장 메시지 |
|--------|----------|--------|------|-------------|
| たぬけ | 🔵 Ares (アレス) | HIGH | 주인공 | #001, #050, #099 등 |
| うらな | 🟡 Elain (エレイン) | MEDIUM | 히로인 | #002, #051 등 |
| しぬせ | 🟡 Shinse | MEDIUM | 동료 | #003 등 |
| くらず | 🟡 Kraus | LOW | 적장/동료? | #100 등 |
| にらか | 🟡 Niraka | LOW | NPC | 제한적 등장 |

### 3.2 세력/왕국 🟡 추정

| 세력명 | 추정 번역 | 신뢰도 | 설명 |
|--------|----------|--------|------|
| カーリオン | 🔵 Carrion | HIGH | 주인공 세력 |
| バルシア | 🟡 Balcia | MEDIUM | 적대 세력 |
| ガルナジャ | 🟡 Garnaja | LOW | 제3세력 |

### 3.3 스토리 구조 🔴 가정

> ⚠️ **검증 필요**: 챕터 구조는 메시지 번호 패턴 기반 추정

| 챕터 | 메시지 범위 | 추정 내용 | 검증 상태 |
|------|------------|----------|----------|
| Chapter 1 | #001-#199 | 시작, Carrion 수호 | 🟡 부분 확인 |
| Chapter 2 | #200-#499 | Balcia 침공 | 🔴 미확인 |
| Chapter 3 | #500-#799 | 최종 결전 | 🔴 미확인 |

### 3.4 대화 시스템 구현 상태

| 기능 | 상태 | 파일 |
|------|------|------|
| 메시지 파싱 | ✅ 구현됨 | `tools/decode_fq4mes.py` |
| 대화 UI | 🔨 부분구현 | `godot/scenes/ui/dialogue_box.tscn` |
| 이벤트 트리거 | 🔨 부분구현 | `godot/scripts/autoload/event_system.gd` |
| 분기 대화 | ❌ 미구현 | - |

---

## 4. Core Systems - Gocha-Kyara

### 4.1 개요

**Gocha-Kyara**(ゴチャキャラ)는 "뒤죽박죽 캐릭터"라는 의미로, 다수의 캐릭터가 자율적으로 행동하는 First Queen 시리즈의 핵심 시스템.

**구현 파일**: `godot/scripts/units/ai_unit.gd` (539줄)

### 4.2 AI 상태 머신 (9개 상태) ✅ 구현됨

```
                    ┌─────────┐
                    │  IDLE   │◀──────────────────┐
                    └────┬────┘                   │
                         │ 리더 이동              │ 목표 없음
                         ▼                        │
                    ┌─────────┐                   │
              ┌────▶│ FOLLOW  │───────────────────┤
              │     └────┬────┘                   │
              │          │ 적 감지                │
              │          ▼                        │
              │     ┌─────────┐     ┌─────────┐   │
              │     │  CHASE  │────▶│ ATTACK  │───┤
              │     └────┬────┘     └────┬────┘   │
              │          │               │        │
              │          │ HP/피로 낮음  │        │
              │          ▼               ▼        │
              │     ┌─────────┐     ┌─────────┐   │
              │     │ RETREAT │────▶│  REST   │───┘
              │     └─────────┘     └─────────┘
              │
              │     ┌─────────┐     ┌─────────┐
              └─────│ DEFEND  │     │ SUPPORT │
                    └─────────┘     └─────────┘

                    ┌─────────┐
                    │ PATROL  │ (독립)
                    └─────────┘
```

**상태별 상세:**

| 상태 | 조건 | 행동 | 전환 |
|------|------|------|------|
| `IDLE` | 기본 상태 | 제자리 대기 | → FOLLOW (리더 이동) |
| `FOLLOW` | 리더 존재 | 대형 유지하며 추종 | → CHASE (적 감지) |
| `PATROL` | 명령 시 | 지정 경로 순찰 | → CHASE (적 감지) |
| `CHASE` | 적 감지 | 적에게 접근 | → ATTACK (사거리 내) |
| `ATTACK` | 사거리 내 적 | 공격 실행 | → CHASE (적 도주) |
| `RETREAT` | HP < 30% or 피로 > 70% | 후방 이동 | → REST (안전 지역) |
| `REST` | 후퇴 완료 | 회복 대기 | → IDLE (회복 완료) |
| `DEFEND` | 명령 시 | 위치 사수 | → ATTACK (적 접근) |
| `SUPPORT` | 명령 시 | 아군 보조 | → FOLLOW (보조 완료) |

**코드 상수** (`ai_unit.gd:67-77`):

```gdscript
var detection_range: float = 200.0      # 적 감지 범위
var attack_engage_range: float = 150.0  # 공격 시작 거리
var follow_distance: float = 80.0       # 리더 추종 거리
var retreat_distance: float = 200.0     # 후퇴 거리
var rest_hp_threshold: float = 0.3      # 휴식 HP 임계값 (30%)
var rest_fatigue_threshold: float = 70.0 # 휴식 피로도 임계값
```

### 4.3 성격 시스템 (Personality) ✅ 구현됨

3가지 성격이 AI 행동 패턴에 영향:

| 성격 | 감지 범위 | 후퇴 HP | 공격성 | 설명 |
|------|----------|---------|--------|------|
| `AGGRESSIVE` | ×1.3 (260) | 20% | HIGH | 적극적 교전, 위험 감수 |
| `BALANCED` | ×1.0 (200) | 30% | MEDIUM | 상황 판단 균형 |
| `DEFENSIVE` | ×0.8 (160) | 40% | LOW | 방어 우선, 리더 근처 유지 |

**코드 위치**: `ai_unit.gd:29-33`, `ai_unit.gd:191-220`

```gdscript
func _apply_personality_modifiers():
    match personality:
        Personality.AGGRESSIVE:
            detection_range *= 1.3
            rest_hp_threshold = 0.2
        Personality.DEFENSIVE:
            detection_range *= 0.8
            rest_hp_threshold = 0.4
```

### 4.4 대형 시스템 (Formation) ✅ 구현됨

5가지 대형으로 부대원 배치:

| 대형 | 형태 | 용도 | 위치 계산 |
|------|------|------|----------|
| `V_SHAPE` | V자 | 기본, 균형 | 45° 각도 배치 |
| `LINE` | 일렬 | 좁은 통로 | 직선 배치 |
| `CIRCLE` | 원형 | 방어, 포위 | 360° 균등 배치 |
| `WEDGE` | 쐐기 | 돌파 | 좁은 V자 |
| `SCATTERED` | 분산 | 범위 공격 회피 | 랜덤 오프셋 |

**코드 위치**: `ai_unit.gd:35-41`, `ai_unit.gd:290-350`

```gdscript
func _calculate_formation_position(index: int, total: int) -> Vector2:
    match current_formation:
        Formation.V_SHAPE:
            var angle = (index % 2 == 0) ? -45 : 45
            var distance = (index / 2 + 1) * follow_distance
            return Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * distance
        Formation.CIRCLE:
            var angle = (index * 360.0 / total)
            return Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * follow_distance
        # ... 기타 대형
```

### 4.5 부대 명령 (Squad Commands) ✅ 구현됨

| 명령 | 효과 | 코드 |
|------|------|------|
| `FOLLOW_ME` | 리더 추종 | 기본 상태 |
| `HOLD_POSITION` | 현 위치 사수 | → DEFEND |
| `ATTACK_ALL` | 전원 공격 | → CHASE/ATTACK |
| `RETREAT_ALL` | 전원 후퇴 | → RETREAT |
| `REST_ALL` | 전원 휴식 | → REST |
| `SPREAD_OUT` | 분산 | Formation.SCATTERED |

**GameManager API** (`game_manager.gd:180-210`):

```gdscript
func issue_current_squad_command(command: SquadCommand) -> void:
    for unit in current_squad.members:
        if unit is AIUnit:
            unit.receive_squad_command(command)

func set_current_squad_formation(formation: Formation) -> void:
    for unit in current_squad.members:
        if unit is AIUnit:
            unit.set_formation(formation)
```

---

## 5. Core Systems - Fatigue (피로도)

### 5.1 개요 ✅ 구현됨

피로도는 0%에서 시작하여 **누적**되는 방식. 행동할수록 증가하고, 휴식으로 감소.

> ⚠️ **수치 통일**: 본 문서는 "누적 기반" (0% = 완전 회복, 100% = 완전 피로) 사용

**구현 파일**: `godot/scripts/systems/fatigue_system.gd`

### 5.2 피로 레벨

| 레벨 | 피로도 범위 | 속도 배율 | 공격력 배율 | 효과 |
|------|------------|----------|------------|------|
| `NORMAL` | 0% ~ 30% | 100% | 100% | 정상 상태 |
| `TIRED` | 31% ~ 60% | 80% | 90% | 약간 둔화 |
| `EXHAUSTED` | 61% ~ 90% | 50% | 70% | 심각한 둔화 |
| `COLLAPSED` | 91% ~ 100% | 0% | 0% | 행동 불가 |

### 5.3 피로 증가 요인

| 행동 | 피로 증가량 | 코드 상수 |
|------|------------|----------|
| 일반 공격 | +10 | `FATIGUE_ATTACK = 10` |
| 스킬 사용 | +20 | `FATIGUE_SKILL = 20` |
| 이동 (10 유닛당) | +1 | `FATIGUE_MOVE_PER_10_UNITS = 1` |
| 피격 | +5 | `FATIGUE_DAMAGE_TAKEN = 5` |

### 5.4 피로 회복

| 상태 | 회복량 (초당) | 코드 상수 |
|------|-------------|----------|
| 대기 (IDLE) | -1 | `FATIGUE_RECOVERY_IDLE = 1` |
| 휴식 (REST) | -5 | `FATIGUE_RECOVERY_REST = 5` |
| 아이템 사용 | -30 | `FATIGUE_RECOVERY_ITEM = 30` |

### 5.5 피로도 ↔ AI 상호작용

```gdscript
# ai_unit.gd의 피로도 체크
func _should_retreat() -> bool:
    var fatigue_percent = FatigueSystem.get_fatigue_percent(self)
    return (hp_percent < rest_hp_threshold) or (fatigue_percent > rest_fatigue_threshold)

# 피로도에 따른 전투 배율
func _get_combat_multipliers() -> Dictionary:
    var level = FatigueSystem.get_fatigue_level(self)
    return {
        "speed": FATIGUE_SPEED_MULT[level],
        "attack": FATIGUE_ATTACK_MULT[level]
    }
```

---

## 6. Core Systems - Combat (전투)

### 6.1 개요 ✅ 구현됨

**구현 파일**: `godot/scripts/systems/combat_system.gd` (234줄)

### 6.2 데미지 공식

```
최종 데미지 = max(1, (ATK × 피로_배율 × 편차 × 크리티컬_배율) - DEF)
```

**코드 상수**:

| 상수 | 값 | 설명 |
|------|-----|------|
| `DAMAGE_VARIANCE` | 0.1 | ±10% 데미지 편차 |
| `CRITICAL_MULTIPLIER` | 2.0 | 크리티컬 시 2배 |
| `MIN_DAMAGE` | 1 | 최소 데미지 |

### 6.3 명중/회피 계산

**명중률**:
```
명중률 = BASE_HIT(95%) + (LCK × 1%)
최대 99%
```

**회피율**:
```
회피율 = BASE_EVASION(5%) + (SPD × 0.1%) + (LCK × 0.5%)
최대 50%
```

**최종 적중**:
```
적중 = 명중률 - 회피율
```

### 6.4 크리티컬

```
크리티컬 확률 = BASE_CRIT(5%) + (LCK × 0.5%) + unit.critical_chance
최대 50%
```

### 6.5 공격 속도

```gdscript
var attack_cooldown: float = 1.0  # 기본 1초
var actual_cooldown = attack_cooldown / (1 + SPD * 0.01)  # SPD가 높을수록 빠름
```

---

## 7. RPG Systems

### 7.1 스탯 시스템 🔨 부분구현

**구현 파일**: `godot/scripts/systems/stats_system.gd`

| 스탯 | 약어 | 효과 | 구현 상태 |
|------|------|------|----------|
| HP | - | 체력 | ✅ 구현됨 |
| MP | - | 마나 | 🔨 변수만 존재 |
| ATK | 공격력 | 물리 데미지 | ✅ 구현됨 |
| DEF | 방어력 | 데미지 감소 | ✅ 구현됨 |
| SPD | 속도 | 이동/공격 속도, 회피 | ✅ 구현됨 |
| LCK | 행운 | 명중, 회피, 크리티컬 | ✅ 구현됨 |
| ATTACK_RANGE | 사거리 | 공격 거리 | ✅ 구현됨 |
| CRITICAL_CHANCE | 치명타 | 추가 크리티컬 확률 | ✅ 구현됨 |
| EVASION | 회피 | 추가 회피 확률 | ✅ 구현됨 |

### 7.2 레벨업 시스템 🔨 부분구현

**구현 파일**: `godot/scripts/autoload/progression_system.gd`

| 기능 | 상태 | 설명 |
|------|------|------|
| 경험치 획득 | ✅ 구현됨 | 적 처치 시 EXP |
| 레벨업 판정 | ✅ 구현됨 | EXP 테이블 기반 |
| 스탯 증가 | 🔨 부분구현 | 기본값만 |
| 스킬 습득 | ❌ 미구현 | - |

**경험치 테이블** 🔴 가정:

```gdscript
const EXP_TABLE = [
    0,      # Lv 1
    100,    # Lv 2
    300,    # Lv 3
    600,    # Lv 4
    1000,   # Lv 5
    # ...
]
```

### 7.3 장비 시스템 🔨 부분구현

| 기능 | 상태 | 설명 |
|------|------|------|
| 장비 슬롯 | 🔨 부분구현 | 무기/방어구/악세서리 |
| 스탯 보너스 | 🔨 부분구현 | 기본 구조만 |
| 장비 교체 | ❌ 미구현 | - |
| 장비 제한 | ❌ 미구현 | 클래스별 제한 |

### 7.4 마법 시스템 ❌ 미구현

| 기능 | 상태 | 우선순위 |
|------|------|---------|
| 마법 시전 | ❌ 미구현 | HIGH |
| MP 소모 | ❌ 미구현 | HIGH |
| 마법 목록 | ❌ 미구현 | MEDIUM |
| 마법 이펙트 | ❌ 미구현 | LOW |

---

## 8. UI/UX Specification

### 8.1 화면 구성 🔨 부분구현

```
┌─────────────────────────────────────────────────────────┐
│ [상단 HUD]                                              │
│ HP ████████░░  MP ████░░░░░░  FT ██░░░░░░░░  Lv.15    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    [게임 뷰포트]                         │
│                     1280×600                            │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ [하단 패널]                                             │
│ 부대: █ █ █ █ ░ ░ ░ ░    명령: [F1]추종 [F2]공격      │
│ 대형: V자    조작: Ares                                 │
└─────────────────────────────────────────────────────────┘
```

### 8.2 UI 구성 요소

| 요소 | 상태 | 파일 |
|------|------|------|
| 상단 HUD | ✅ 구현됨 | `scenes/ui/hud.tscn` |
| 유닛 HP 바 | ✅ 구현됨 | `scenes/ui/unit_hp_bar.tscn` |
| 부대 패널 | 🔨 부분구현 | `scenes/ui/squad_panel.tscn` |
| 대화 박스 | 🔨 부분구현 | `scenes/ui/dialogue_box.tscn` |
| 인벤토리 | 🔨 부분구현 | `scenes/ui/inventory.tscn` |
| 메인 메뉴 | ❌ 미구현 | - |
| 설정 메뉴 | ❌ 미구현 | - |

### 8.3 조작 체계

| 입력 | 동작 | 구현 상태 |
|------|------|----------|
| WASD | 이동 | ✅ 구현됨 |
| ← → | 부대원 전환 | ✅ 구현됨 |
| ↑ ↓ | 부대 전환 | ✅ 구현됨 |
| Space | 공격 | ✅ 구현됨 |
| 우클릭 | 이동 명령 | ✅ 구현됨 |
| I | 인벤토리 | 🔨 부분구현 |
| ESC | 메뉴/일시정지 | 🔨 부분구현 |
| F1-F6 | 부대 명령 | ❌ 미구현 |

---

## 9. Technical Specification

### 9.1 Godot 프로젝트 구조

```
godot/
├── project.godot              # 프로젝트 설정
├── scripts/
│   ├── autoload/              # 7개 싱글톤
│   │   ├── game_manager.gd    # 핵심: 부대/유닛 관리
│   │   ├── save_system.gd     # 세이브/로드
│   │   ├── graphics_manager.gd # 그래픽 설정
│   │   ├── progression_system.gd # 레벨업
│   │   ├── chapter_manager.gd # 챕터/맵 전환
│   │   ├── audio_manager.gd   # 사운드 (미구현)
│   │   └── event_system.gd    # 이벤트 트리거
│   ├── units/
│   │   ├── unit.gd            # 기본 유닛
│   │   ├── ai_unit.gd         # Gocha-Kyara AI
│   │   ├── player_unit.gd     # 플레이어 유닛
│   │   └── enemy_unit.gd      # 적 유닛
│   └── systems/
│       ├── combat_system.gd   # 전투 로직
│       ├── fatigue_system.gd  # 피로도
│       └── stats_system.gd    # 스탯 계산
├── scenes/
│   ├── game/main_game.tscn    # 메인 씬
│   ├── maps/chapter1~3/       # 챕터별 맵
│   ├── ui/                    # UI 씬
│   └── test/                  # 테스트 씬
└── resources/
    ├── sprites/               # SpriteFrames
    ├── dialogues/             # 대화 리소스
    └── data/                  # 게임 데이터
```

### 9.2 Autoload 싱글톤

| 싱글톤 | 역할 | 상태 |
|--------|------|------|
| `GameManager` | 부대/유닛 관리, 게임 상태 | ✅ 구현됨 |
| `SaveSystem` | 세이브/로드 | ✅ 구현됨 |
| `GraphicsManager` | 그래픽 설정 | ✅ 구현됨 |
| `ProgressionSystem` | 레벨업, EXP | 🔨 부분구현 |
| `ChapterManager` | 챕터/맵 전환 | 🔨 부분구현 |
| `EventSystem` | 이벤트 트리거 | 🔨 부분구현 |
| `AudioManager` | 사운드/BGM | ❌ 미구현 |

### 9.3 시그널 흐름

```gdscript
# 유닛 사망 → 게임 상태 체크
Unit.unit_died → GameManager.unregister_unit() → _check_game_over()
                                              → controlled_unit_changed

# 부대 변경 → UI 업데이트
GameManager.squad_changed → UI.update_squad_display()
GameManager.state_changed → UI.update_game_state()

# 레벨업 → 스탯 갱신
ProgressionSystem.level_up → Unit.apply_level_bonus()
```

### 9.4 성능 목표

| 항목 | 목표 | 현재 |
|------|------|------|
| 유닛 수 | 50+ 동시 | ✅ 달성 |
| FPS | 60 FPS | ✅ 달성 |
| 로딩 | < 3초 | ✅ 달성 |
| 메모리 | < 500MB | ✅ 달성 |

---

## 10. Audio System ❌ 미구현

### 10.1 개요

> ⚠️ **현재 상태**: 오디오 시스템은 0% 구현. 싱글톤 껍데기만 존재.

**구현 파일**: `godot/scripts/autoload/audio_manager.gd`

### 10.2 계획된 구조

| 카테고리 | 내용 | 우선순위 |
|----------|------|---------|
| BGM | 챕터별 배경 음악 | HIGH |
| SFX | 공격, 피격, UI 효과음 | HIGH |
| 환경음 | 바람, 숲, 전투 함성 | LOW |
| 보이스 | 캐릭터 음성 (선택적) | LOW |

### 10.3 필요 리소스 🔴 가정

| 타입 | 예상 파일 수 | 포맷 |
|------|-------------|------|
| BGM | 10-15 | OGG |
| SFX | 30-50 | WAV |
| 환경음 | 5-10 | OGG |

### 10.4 구현 계획

```gdscript
# audio_manager.gd (계획)
extends Node

var bgm_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer]

func play_bgm(track_name: String) -> void:
    pass  # TODO

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
    pass  # TODO
```

---

## 11. Asset Pipeline

### 11.1 원본 에셋 포맷

| 포맷 | 파일 | 설명 | 추출 상태 |
|------|------|------|----------|
| RGBE | `.B_`, `.R_`, `.G_`, `.E_` | 4-plane 이미지 | 🔨 부분 (DOSBox 캡처 대체) |
| CHR | `.CHR` | 8x8 타일 스프라이트 | ✅ 완료 |
| Bank | `CHRBANK` 등 | 압축 엔트리 | ✅ 완료 |
| FQ4MES | 텍스트 | 799개 메시지 | ✅ 완료 (88.59%) |

### 11.2 HD 업스케일 파이프라인

```
원본 (320×200)
     │
     ▼
DOSBox 캡처 / CHR 추출
     │
     ▼
Real-ESRGAN (realesrgan-ncnn)
     │
     ▼
HD 에셋 (1280×800)
     │
     ▼
Godot SpriteFrames
```

### 11.3 도구

| 도구 | 명령 | 용도 |
|------|------|------|
| `fq4_extractor.py` | `python tools/fq4_extractor.py extract-all` | 전체 추출 |
| `upscale_ai.py` | `python tools/upscale_ai.py realesrgan-ncnn -s 4` | AI 업스케일 |
| `spriteframes_generator.py` | `python tools/spriteframes_generator.py` | Godot 리소스 생성 |

---

## 12. Development Roadmap

### 12.1 Phase 1: Core Systems (✅ 완료)

- [x] Gocha-Kyara AI 시스템
- [x] 피로도 시스템
- [x] 전투 시스템
- [x] 부대 관리
- [x] 기본 UI

### 12.2 Phase 2: RPG Systems (🔨 진행 중)

- [x] 스탯 시스템 기본
- [ ] 레벨업 시스템 완성
- [ ] 장비 시스템
- [ ] 마법 시스템

### 12.3 Phase 3: Content (⏳ 대기)

- [ ] 챕터 1 맵 완성
- [ ] 챕터 2 맵
- [ ] 챕터 3 맵
- [ ] 이벤트/대화 연결

### 12.4 Phase 4: Polish (⏳ 대기)

- [ ] 오디오 시스템
- [ ] UI/UX 개선
- [ ] 성능 최적화
- [ ] 버그 수정

### 12.5 예상 남은 작업량

| 영역 | 완성도 | 남은 작업 |
|------|--------|----------|
| Core Systems | 90% | 세부 밸런싱 |
| RPG Systems | 35% | 마법, 장비, 레벨업 완성 |
| Content | 20% | 맵 3개, 이벤트 800개 |
| Audio | 0% | 전체 구현 필요 |
| UI/UX | 50% | 메뉴, 설정, 개선 |

---

## Appendix A: 복호화 데이터 샘플

### A.1 확정 대화 (🔵 HIGH 신뢰도)

```
#001: カーリオン王国へようこそ
      (Carrion 왕국에 오신 것을 환영합니다)

#050: たぬけ「私が守る！」
      (Ares「내가 지킨다!」)

#099: 戦いは終わった...
      (전투가 끝났다...)
```

### A.2 추정 대화 (🟡 MEDIUM 신뢰도)

```
#200: バルシア軍が攻めてきた
      (Balcia 군이 쳐들어왔다) [추정: 챕터 2 시작]

#500: 最終決戦の時が来た
      (최종 결전의 때가 왔다) [추정: 챕터 3 시작]
```

---

## Appendix B: 코드 상수 총정리

### B.1 AI 상수 (ai_unit.gd)

```gdscript
# 감지/거리
var detection_range: float = 200.0
var attack_engage_range: float = 150.0
var follow_distance: float = 80.0
var retreat_distance: float = 200.0

# 임계값
var rest_hp_threshold: float = 0.3
var rest_fatigue_threshold: float = 70.0
```

### B.2 전투 상수 (combat_system.gd)

```gdscript
const BASE_HIT_CHANCE = 0.95
const BASE_EVASION = 0.05
const BASE_CRIT_CHANCE = 0.05
const CRITICAL_MULTIPLIER = 2.0
const DAMAGE_VARIANCE = 0.1
const MIN_DAMAGE = 1
```

### B.3 피로 상수 (fatigue_system.gd)

```gdscript
const FATIGUE_ATTACK = 10
const FATIGUE_SKILL = 20
const FATIGUE_MOVE_PER_10_UNITS = 1
const FATIGUE_DAMAGE_TAKEN = 5

const FATIGUE_RECOVERY_IDLE = 1
const FATIGUE_RECOVERY_REST = 5
const FATIGUE_RECOVERY_ITEM = 30

const FATIGUE_LEVELS = {
    "NORMAL": {"min": 0, "max": 30, "speed": 1.0, "attack": 1.0},
    "TIRED": {"min": 31, "max": 60, "speed": 0.8, "attack": 0.9},
    "EXHAUSTED": {"min": 61, "max": 90, "speed": 0.5, "attack": 0.7},
    "COLLAPSED": {"min": 91, "max": 100, "speed": 0.0, "attack": 0.0}
}
```

---

## Document History

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-04 | 초기 통합 기획서 (Ralplan 합의) |

---

*Generated by Ralplan Consensus (Planner + Architect + Analyst + Critic)*
