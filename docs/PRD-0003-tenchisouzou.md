# PRD-0003: 천지창조 (First Queen 4 Mobile Idle)

**Version**: 2.0.0 | **Date**: 2026-02-15 | **Status**: Draft

---

## 1. Executive Summary

### 1.1 프로젝트 비전

First Queen 4(1994, DOS)의 핵심 게임 시스템과 세계관을 계승하면서, Flutter/Flame/Rive 기반으로 현대 모바일에 최적화된 **방치형 전술 RPG**. 원작의 Gocha-Kyara AI 시스템, 피로도 관리, 부대 전술을 그대로 살리면서 **완전 자동전투 + 편성 전략 + 방치 진행**으로 재탄생시킨다.

| 항목 | 내용 |
|------|------|
| **타이틀** | 천지창조 (天地創造) |
| **부제** | Logris Chronicle |
| **원작 기반** | First Queen 4 (DOS, 1994, Kure Software Koubou) |
| **장르** | 방치형 전술 RPG |
| **엔진** | Flutter 3.24+ / Flame 1.18+ / Rive 0.13+ |
| **플랫폼** | iOS, Android, Web (PWA) |
| **화면 방향** | 세로 모드 기본 (방치형 표준) |
| **아트 스타일** | Rive 벡터 애니메이션 (신규 제작) |
| **핵심 시스템** | Gocha-Kyara (완전 자동전투 + 방치 진행) |
| **타겟 유저** | 방치형 게임 유저, 전술 RPG 팬, 캐주얼 모바일 게이머 |

### 1.2 프로젝트 목표

1. **완전 자동전투**: 주인공 포함 전원 AI 자동 제어 (`is_player_controlled = false`)
2. **편성/전략 중심 게임플레이**: 전투 전 부대 편성, 대형, 전술 프리셋으로 전투 결과 결정
3. **방치 진행 시스템**: 오프라인 보상, 소탕, 자동 루프 전투로 24시간 진행
4. **Rive 벡터 그래픽**: 해상도 무관한 벡터 애니메이션으로 모든 기기에서 선명한 비주얼
5. **크로스 플랫폼**: 하나의 코드베이스로 iOS, Android, Web 동시 지원
6. **클라우드 세이브**: 기기 간 진행도 동기화

### 1.3 왜 "천지창조"인가

"천지창조"는 로그리스 대륙의 파괴와 재건을 다루는 원작의 서사를 함축한다. 바르시아 제국의 침공으로 무너진 세계를 주인공 아레스가 동료들과 함께 다시 세워나가는 여정 - 그것이 곧 천지창조다. 파괴된 대지 위에 새로운 질서를 세우는 창조의 이야기.

### 1.4 v1.0 대비 핵심 변경

| 영역 | v1.0 | v2.0 방치형 |
|------|------|------------|
| 게임 루프 | 실시간 수동 조작 | **완전 자동전투 + 오프라인 진행** |
| 입력 | 조이스틱/탭 공격 (80% 조작) | **전투 전 편성만 (20% 조작)** |
| Gocha-Kyara | 주인공 1명 수동 + AI | **전원 AI 자동전투** |
| 화면 방향 | 가로 모드 | **세로 모드** |
| 게임 진행 | 챕터 클리어 순차 | **스테이지 기반 + 방치 보상 + 소탕** |

---

## 2. 세계관과 스토리

### 2.1 배경

로그리스 대륙. 수많은 왕국과 제국이 흥망을 거듭한 이 대륙에, 마법 강국 바르시아가 야욕의 손길을 뻗어온다. 칼리온 왕국의 젊은 전사 아레스는 동료들과 함께 대륙을 구하기 위한 여정을 시작한다.

```
+-------------------------------------------------------------------+
|                     로그리스 대륙                                    |
+-------------------------------------------------------------------+
|                                                                    |
|   [칼리온 왕국]        [중립 지대]         [바르시아 제국]            |
|   주인공 세력          여러 마을/도시       적대 세력                 |
|   아레스, 엘레인       동료 모집 지역       쿠가이아, 모르드레드       |
|                                                                    |
|   제1장: 깨어남                                                     |
|   제2장: 동맹 형성     제3장: 전쟁 발발                              |
|   제4장: 장군 대결     제5장: 최종 결전                               |
|                                                                    |
+-------------------------------------------------------------------+
```

### 2.2 주요 캐릭터

| 캐릭터 | 역할 | 성격 | AI Personality |
|--------|------|------|---------------|
| **아레스** | 주인공, 전사 | 용감하고 의지가 강함 | BALANCED |
| **엘레인** | 히로인, 마법사 | 지적이고 헌신적 | DEFENSIVE |
| **시누세** | 동료 전사 | 호탕하고 충직 | AGGRESSIVE |
| **소토카** | 치유사 | 온화하고 침착 | DEFENSIVE |
| **마키** | 궁수 | 민첩하고 날카로움 | BALANCED |
| **니키** | 도적 | 재치 있고 유연 | AGGRESSIVE |
| **사스우** | 기사 | 명예롭고 강직 | BALANCED |
| **타로모** | 현자/마법사 | 신비롭고 지혜로움 | DEFENSIVE |

### 2.3 적대 세력

| 캐릭터 | 직위 | 역할 |
|--------|------|------|
| **쿠가이아** | 바르시아 지의 장군 | 중반부 보스, 전략가 |
| **모르드레드** | 바르시아 화의 장군 | 후반부 보스, 전투광 |
| **마왕** | 바르시아 제국 지배자 | 최종 보스 |

### 2.4 챕터 구조

| 챕터 | 제목 | 주요 내용 | 스테이지 | 메시지 범위 |
|------|------|----------|---------|-----------|
| 1장 | 깨어난 전사 | 아레스의 시작, 칼리온 수호 | 1-10 | #001-#030 |
| 2장 | 초기 전투 | 부대 편성, 첫 전투 경험 | 11-20 | #031-#100 |
| 3장 | 여행과 동맹 | 대륙 탐방, 동료 모집 | 21-30 | #101-#200 |
| 4장 | 세력 확장 | 왕국 연합 형성 | 31-40 | #201-#300 |
| 5장 | 전쟁 발발 | 바르시아 본격 침공 | 41-50 | #301-#400 |
| 6장 | 지의 장군 | 쿠가이아와의 대결 | 51-60 | #401-#500 |
| 7장 | 반격 | 연합군 반격 개시 | 61-70 | #501-#600 |
| 8장 | 화의 장군 | 모르드레드와의 대결 | 71-80 | #601-#700 |
| 9장 | 최종 결전 | 바르시아 진격 | 81-90 | #701-#780 |
| 10장 | 천지창조 | 마왕 격퇴, 대륙 재건 | 91-100 | #781-#800 |

### 2.5 엔딩 시스템

| 엔딩 | 조건 | 연출 |
|------|------|------|
| **GOOD** (천지창조) | 전원 생존 + 전 챕터 클리어 | 대륙 재건 컷신, 모든 동료와의 후일담 |
| **NORMAL** (재건의 빛) | 2명 이상 생존 | 희생 끝의 평화, 남은 이들의 새 시작 |
| **BAD** (고독한 왕좌) | 주인공만 생존 | 홀로 살아남은 아레스의 비극 |

---

## 3. 핵심 게임 시스템

### 3.1 Gocha-Kyara: 완전 자동전투 시스템

#### 3.1.0 시스템 개요

모든 캐릭터(주인공 포함)가 AI에 의해 자동으로 전투한다. 플레이어의 역할은 **전투 전 편성과 전략 결정**이다.

```
+-------------------------------------------------------------------+
|                    Gocha-Kyara v2.0 (완전 자동전투)                  |
+-------------------------------------------------------------------+
|                                                                    |
|   [전투 전 - 플레이어 조작]         [전투 중 - 완전 자동]            |
|   - 부대 편성 (드래그 배치)         - 전원 AI 자동 제어              |
|   - 대형 선택 (5종)                - 상태머신 기반 행동              |
|   - 전술 프리셋 설정               - 성격별 자동 판단               |
|   - 배속 선택 (1x/2x/4x)          - 피로도 자동 관리               |
|                                                                    |
|   [관전 모드]                                                      |
|   - 배속 조절: 1x / 2x / 4x                                       |
|   - 스킵: 3성 클리어 스테이지 즉시 완료                              |
|   - 자동 루프: 현재 스테이지 반복 진행                               |
|                                                                    |
+-------------------------------------------------------------------+
```

핵심 특징:
- `is_player_controlled = false` (전원 AI, 예외 없음)
- 전투 전 편성 화면에서 부대 배치, 대형, 전술 프리셋 결정
- 전투는 자동 진행, 플레이어는 배속/스킵으로만 관여
- AI 상태머신 9개 + 성격 3종 + 대형 5종 = 방치형의 핵심 전략 요소

#### 3.1.1 AI 상태머신 (9개 상태)

```
                    +----------+
                    |   IDLE   |<-------------------+
                    +----+-----+                    |
                         | 리더 이동               | 목표 없음
                         v                         |
                    +----------+                    |
              +---->| FOLLOW   |--------------------+
              |     +----+-----+                    |
              |          | 적 감지                  |
              |          v                          |
              |     +----------+     +----------+   |
              |     |  CHASE   |---->| ATTACK   |---+
              |     +----+-----+     +----+-----+   |
              |          |                |          |
              |          | HP/피로 낮음   |          |
              |          v                v          |
              |     +----------+     +----------+   |
              |     | RETREAT  |---->|  REST    |---+
              |     +----------+     +----------+
              |
              |     +----------+     +----------+
              +-----|  DEFEND  |     | SUPPORT  |
                    +----------+     +----------+

                    +----------+
                    | PATROL   | (독립)
                    +----------+
```

| AIState | 설명 | 전환 조건 |
|---------|------|----------|
| `IDLE` | 대기 | 리더 있으면 FOLLOW, 적 감지하면 CHASE |
| `FOLLOW` | 리더 추종 | 대형에 따른 위치 유지 |
| `PATROL` | 순찰 | 적 감지 시 CHASE |
| `CHASE` | 적 추격 | 사거리 도달 시 ATTACK |
| `ATTACK` | 공격 | 적 사망 시 FOLLOW, 사거리 이탈 시 CHASE |
| `RETREAT` | 후퇴 | HP/피로도 회복 시 FOLLOW |
| `DEFEND` | 방어 | 리더 근처에서 적 견제 |
| `SUPPORT` | 지원 | 힐러/버퍼 전용, 부상 아군 마법 시전 |
| `REST` | 휴식 | 피로도 30% 이하 회복 시 FOLLOW |

#### 3.1.2 AI 핵심 파라미터

| 파라미터 | 아군 | 적 | 단위 |
|----------|------|-----|------|
| AI tick 간격 | 0.3 | 0.4 | 초 |
| 기본 감지 범위 | 200 | 180 | px (논리 좌표) |
| 추종 거리 | 80 | - | px |
| 분산 거리 | 40 | - | px |
| 공격 교전 거리 | 150 | - | px |
| 후퇴 HP 임계값 | 30% | 20% | HP 비율 |
| 피로도 후퇴 임계값 | 70% | - | 피로도 비율 |
| 피로도 강제 휴식 | 90% | - | 피로도 비율 |

#### 3.1.3 성격 시스템 (Personality)

| Personality | chase_range_mult | retreat_hp_mult | attack_priority | follow_priority |
|-------------|-----------------|-----------------|-----------------|-----------------|
| AGGRESSIVE | 1.5 | 0.7 | 1.0 | 0.5 |
| DEFENSIVE | 0.7 | 1.3 | 0.5 | 1.0 |
| BALANCED | 1.0 | 1.0 | 0.8 | 0.8 |

실제 적용 예시:
- AGGRESSIVE: 감지 범위 300px (200*1.5), 후퇴 HP 21% (30%*0.7)
- DEFENSIVE: 감지 범위 140px (200*0.7), 후퇴 HP 39% (30%*1.3)
- BALANCED: 감지 범위 200px, 후퇴 HP 30%

#### 3.1.4 대형 시스템 (Formation)

| Formation | 배치 방식 | 용도 |
|-----------|----------|------|
| V_SHAPE | 리더 뒤쪽 V자 (기본) | 범용, 전방 돌파 |
| LINE | 횡대 일렬 | 넓은 전선 유지 |
| CIRCLE | 원형 | 리더 보호, 집합 시 |
| WEDGE | 쐐기형 (역삼각) | 돌격, 돌파 |
| SCATTERED | 황금비 기반 분산 | 범위 공격 회피 |

분산 대형 오프셋 (황금비):
```
angle = fmod(seed * 0.618033988749, 1.0) * 2 * PI
distance = follow_distance * (1.0 + fmod(seed * 0.314159, 0.5))
offset = (cos(angle) * distance, sin(angle) * distance)
```

#### 3.1.5 부대 명령 시스템 (전투 전 프리셋)

전투 전 편성 화면에서 설정. AI가 전투 상황에 따라 자동 전환한다.

| SquadCommand | 효과 | 대형 변경 | 거리 변경 |
|-------------|------|----------|----------|
| NONE | 기본 상태 | 유지 | 유지 |
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
6. 최소 데미지: final_damage = max(1, final_damage)
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
| CRITICAL_HIT_CHANCE | 0.05 | 기본 크리티컬 5% |
| CRITICAL_HIT_MULTIPLIER | 2.0 | 크리티컬 배율 |
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
    +-- 명중 판정
    |   +-- MISS --> 피로도 +10, 팝업 표시
    |   +-- EVADE --> 피로도 +10, 팝업 표시
    |
    +-- 데미지 계산
    |   +-- 크리티컬 판정
    |   +-- 분산 적용
    |   +-- 방어력 적용
    |
    +-- 피로도 배율 적용
    +-- target.take_damage(final_damage)
    +-- 공격자 피로도 +10
    |
    +-- 사망 체크
        +-- 사망 시: 경험치 지급, 골드 보상
        +-- gold_amount = 5 + (enemy_max_hp / 20)
```

#### 3.2.5 오프라인 전투 시뮬레이션

타임스탬프 기반으로 오프라인 전투 결과를 계산한다.

```
offline_simulate(last_timestamp, current_timestamp)
    |
    +-- elapsed = current_timestamp - last_timestamp
    +-- max_offline = 8 hours (28800 seconds)
    +-- effective_time = min(elapsed, max_offline)
    |
    +-- battles_count = effective_time / avg_battle_duration
    +-- 각 전투: 현재 스테이지의 승률 기반 확률 계산
    |   +-- win_rate = calculate_win_rate(squad_power, stage_difficulty)
    |   +-- 승리 시: gold + exp + item_drop
    |   +-- 패배 시: gold * 0.3 + exp * 0.3
    |
    +-- 결과: total_gold, total_exp, item_list, battles_won/lost
```

#### 3.2.6 배속 시스템

| 배속 | 해금 조건 | 설명 |
|------|----------|------|
| 1x | 기본 | 일반 속도 |
| 2x | 스테이지 10 클리어 | 2배속 자동전투 |
| 4x | 스테이지 30 클리어 | 4배속 자동전투 |
| 스킵 | 3성 클리어한 스테이지 | 즉시 결과 (소탕권 소모) |

### 3.3 피로도 시스템

#### 3.3.1 피로도 증감

| 행동 | 피로도 변화 | 상수 |
|------|-----------|------|
| 일반 공격 | +10 | FATIGUE_ATTACK |
| 스킬/마법 | +20 | FATIGUE_SKILL |
| 이동 10px | +1 | FATIGUE_MOVE_PER_10_UNITS |
| 피격 | +5 | FATIGUE_DAMAGE_TAKEN |
| 대기 (IDLE) | -1/초 | FATIGUE_RECOVERY_IDLE |
| 휴식 (REST) | -5/초 | FATIGUE_RECOVERY_REST |
| 아이템 사용 | -30 | FATIGUE_RECOVERY_ITEM |
| **오프라인** | **-2%/분** | **FATIGUE_RECOVERY_OFFLINE** |

#### 3.3.2 피로도 단계별 패널티

| 단계 | 범위 | 이동속도 | 공격력 | 행동 가능 |
|------|------|---------|--------|----------|
| NORMAL | 0-30% | 100% | 100% | O |
| TIRED | 31-60% | 80% | 90% | O |
| EXHAUSTED | 61-90% | 50% | 70% | O |
| COLLAPSED | 91-100% | 0% | 0% | X (강제 휴식) |

### 3.4 마법 시스템 (8종)

| spell_id | 유형 | 속성 | MP | 위력 | 사거리 | 범위 | 쿨다운 | 시전시간 | 타겟 |
|----------|------|------|-----|------|--------|------|--------|---------|------|
| fire_ball | DAMAGE | FIRE | 15 | 30 | 250 | 60 | 4.0s | 0.8s | AREA |
| ice_bolt | DAMAGE | ICE | 10 | 25 | 200 | 50 | 2.0s | 0.5s | SINGLE_ENEMY |
| thunder | DAMAGE | LIGHTNING | 20 | 45 | 300 | 50 | 5.0s | 1.0s | SINGLE_ENEMY |
| heal | HEAL | HOLY | 12 | 40 | 150 | - | 3.0s | 0.6s | SINGLE_ALLY |
| mass_heal | HEAL | HOLY | 30 | 25 | 100 | 120 | 8.0s | 1.2s | AREA |
| shield | BUFF | NONE | 8 | - | 150 | - | 5.0s | 0.5s | SINGLE_ALLY |
| haste | BUFF | NONE | 10 | - | 150 | - | 6.0s | 0.5s | SINGLE_ALLY |
| slow | DEBUFF | ICE | 8 | - | 180 | - | 4.0s | 0.5s | SINGLE_ENEMY |

버프/디버프 상세:

| spell_id | 효과 스탯 | 변화량 | 지속 시간 |
|----------|----------|--------|----------|
| shield | DEF | +10 | 15.0s |
| haste | SPD | +30 | 12.0s |
| slow | SPD | -20 | 10.0s |

### 3.5 상태이상 시스템 (6종)

| 상태 | 지속시간 | tick 간격 | tick 데미지 | 속도 배율 | 행동 가능 | 감지 배율 |
|------|---------|----------|-----------|----------|----------|----------|
| poison | 10.0s | 1.0s | 5 | 1.0 | O | 1.0 |
| burn | 8.0s | 1.0s | 8 | 1.0 | O | 1.0 |
| stun | 3.0s | - | - | 1.0 | X | 1.0 |
| slow | 5.0s | - | - | 0.5 | O | 1.0 |
| freeze | 4.0s | - | - | 0.0 | X | 1.0 |
| blind | 6.0s | - | - | 1.0 | O | 0.2 |

카테고리:
- 지속 데미지: poison, burn
- 군중 제어: stun, freeze, slow
- 시야 방해: blind

### 3.6 환경 시스템 (6종 지형)

| TerrainType | 효과 | 상태이상 | 수치 |
|-------------|------|---------|------|
| NORMAL | 없음 | - | - |
| WATER | 이동속도 감소 | - | speed * 0.7 |
| COLD | 피로도 누적 증가 | - | fatigue * 1.5 |
| DARK | 감지 범위 감소 | - | detection * 0.5 |
| POISON | 독 부여 | poison | 10s, 5 dmg/s |
| FIRE | 화상 부여 | burn | 8s, 8 dmg/s |

### 3.7 RPG 시스템

#### 3.7.1 스탯

| 스탯 | 약어 | 효과 |
|------|------|------|
| HP | - | 체력 |
| MP | - | 마나 |
| ATK | 공격력 | 물리 데미지 |
| DEF | 방어력 | 데미지 감소 |
| SPD | 속도 | 이동/공격 속도, 회피 |
| LCK | 행운 | 명중, 회피, 크리티컬 |

#### 3.7.2 경험치 공식

```
exp_to_next_level(level) = 100 * (1.2 ^ (level - 2))

예시:
  Lv1 -> Lv2: 100
  Lv2 -> Lv3: 120
  Lv5 -> Lv6: 207
  Lv10 -> Lv11: 516
  Lv49 -> Lv50: 7,937,914
```

최대 레벨: 50

#### 3.7.3 레벨업 스탯 성장 (레벨당)

| 스탯 | 성장량 |
|------|--------|
| HP | +15 |
| MP | +5 |
| ATK | +2 |
| DEF | +1 |
| SPD | +1 |
| LCK | +1 |

#### 3.7.4 적 처치 경험치

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

#### 3.7.5 장비 슬롯

| 슬롯 | 장착 가능 유형 | 영향 스탯 |
|------|--------------|----------|
| WEAPON | 검, 창, 지팡이, 활 | ATK, ATTACK_RANGE, CRITICAL_CHANCE |
| ARMOR | 갑옷, 로브, 가죽 | DEF, HP, EVASION |
| ACCESSORY | 반지, 목걸이, 부적 | LCK, SPD, MP, 특수 효과 |

#### 3.7.6 인벤토리/상점

| 파라미터 | 값 |
|----------|-----|
| 최대 슬롯 | 50 |
| 아이템 스택 | item_data.max_stack (아이템별) |
| 구매가 | buy_price * shop.buy_price_multiplier |
| 판매가 | sell_price * shop.sell_price_multiplier (구매가의 50%) |
| 재고 | -1 = 무한, 양수 = 제한 |

### 3.8 보스 시스템

#### 3.8.1 멀티 페이즈

| 페이즈 | HP 임계값 | 전환 이벤트 |
|--------|----------|------------|
| Phase 1 | 100% - 66% | 초기 패턴 |
| Phase 2 | 66% - 33% | 패턴 변경, 미니언 소환 |
| Phase 3 | 33% - 0% | 최종 패턴, 미니언 소환 |

#### 3.8.2 광폭화

| 파라미터 | 값 |
|----------|-----|
| 발동 HP | 20% 이하 |
| ATK 배율 | 1.5배 |
| SPD 배율 | 1.3배 |

### 3.9 New Game+ 시스템

| 캐리오버 | 여부 |
|----------|:----:|
| 유닛 레벨 | O |
| 장비 | O |
| 골드 | O |
| 해금 마법 | O |
| 업적 | O |
| 스토리 진행 | X (리셋) |
| 맵 상태 | X (리셋) |

NG+ 스케일링:

| 항목 | 배율 |
|------|------|
| 적 HP/ATK/DEF | 1.5배 |
| 적 SPD | 최대 1.2배 |
| 경험치 | 0.8배 |
| 골드 | 1.2배 |

### 3.10 업적 시스템 (28개)

| 카테고리 | 수량 | 예시 |
|---------|------|------|
| 챕터 클리어 | 10개 | chapter_1_clear ~ chapter_10_clear |
| 보스 처치 | 4개 | boss_demon_general, boss_fallen_hero, boss_demon_king, boss_all |
| 레벨 | 3개 | level_novice(10), level_veteran(30), level_master(50) |
| 처치 수 | 3개 | kills_hunter(100), kills_slayer(500), kills_legend(1000) |
| 엔딩 | 3개 | ending_good, ending_normal, ending_bad |
| 특수 | 5개 | speed_run, no_death, ng_plus, formation_master, spell_master |

### 3.11 방치형 핵심 시스템

#### 3.11.1 오프라인 보상 엔진

```
접속 시 정산 흐름:
    last_logout_timestamp → current_timestamp
    |
    +-- elapsed = min(current - last, MAX_OFFLINE_HOURS * 3600)
    +-- MAX_OFFLINE_HOURS = 8
    |
    +-- 보상 계산:
    |   +-- gold = stage_gold_per_min * elapsed_min
    |   +-- exp = stage_exp_per_min * elapsed_min
    |   +-- items = random_drop(stage_drop_table, elapsed_min)
    |
    +-- 피로도: 전원 NORMAL로 회복
    +-- 결과: 접속 시 보상 팝업 표시
```

| 파라미터 | 값 |
|----------|-----|
| 최대 방치 시간 | 8시간 |
| 방치 골드 효율 | 실시간 전투의 60% |
| 방치 경험치 효율 | 실시간 전투의 50% |
| 방치 아이템 드롭율 | 실시간 전투의 40% |

#### 3.11.2 스테이지 시스템

각 챕터는 10개 스테이지로 구성. 총 100개 스테이지.

| 평가 | 조건 | 보상 배율 |
|------|------|----------|
| 3성 | 전원 생존 + 시간 내 클리어 | x1.5 + 소탕 해금 |
| 2성 | 1명 이하 사망 | x1.2 |
| 1성 | 클리어 | x1.0 |

#### 3.11.3 소탕 시스템

| 조건 | 내용 |
|------|------|
| 해금 | 해당 스테이지 3성 클리어 |
| 소모 | 소탕권 1장 / 회 |
| 결과 | 즉시 완료, 보상 동일 (3성 기준) |
| 소탕권 획득 | 일일 퀘스트, 업적, 스테이지 최초 클리어 |

#### 3.11.4 자동 루프 전투

현재 스테이지를 자동으로 반복 진행한다.

```
auto_loop:
    +-- 현재 스테이지 자동전투 시작
    +-- 승리 → 보상 획득 → 다시 시작
    +-- 패배 → 중단 (알림)
    +-- 인벤토리 풀 → 중단 (알림)
```

---

## 4. 모바일 UX 설계

### 4.1 방치형 인터페이스

#### 4.1.1 세로 모드 기본

```
+---------------------------+
| [메인 대시보드]            |
+---------------------------+
|                           |
|   오프라인 보상 요약       |
|   +골드 12,500            |
|   +경험치 8,200            |
|   +아이템 3개              |
|                           |
|   [현재 스테이지: 3-7]    |
|   [전투력: 12,450]        |
|                           |
|   [출전]  [소탕]  [편성]  |
|                           |
+---------------------------+
| [전투] [영웅] [장비] [설정]|
+---------------------------+
```

#### 4.1.2 전투 관전 화면 (세로)

```
+---------------------------+
| Stage 3-7  Wave 2/3       |
+---------------------------+
|                           |
|                           |
|     자동전투 뷰포트        |
|     (Flame 렌더링)        |
|                           |
|                           |
+---------------------------+
| [아레스] [엘레인] [시누세] |
| HP ███░░  HP ████░ HP ██░ |
+---------------------------+
| [1x] [2x] [4x]  [⏸][AUTO]|
+---------------------------+
```

#### 4.1.3 편성 화면

```
+---------------------------+
| 편성 - 부대 1              |
+---------------------------+
| 대형: [V자] [일렬] [원형] |
|       [쐐기] [산개]       |
+---------------------------+
|                           |
|   [아레스]  [엘레인]      |
|      [시누세]             |
|   [소토카]  [마키]        |
|                           |
|   (드래그로 위치 변경)     |
+---------------------------+
| 전술: [공격] [방어] [균형] |
+---------------------------+
| [저장]            [출전]  |
+---------------------------+
```

### 4.2 Flutter UI 화면 구조

| 화면 | 설명 | 라우팅 |
|------|------|--------|
| TitleScreen | 타이틀, 새 게임/불러오기 | `/` |
| MainDashboard | 메인 화면 (방치 보상, 스테이지 진행) | `/main` |
| StageSelectScreen | 스테이지 선택/소탕 | `/stages` |
| FormationScreen | 부대 편성 (드래그 배치, 대형, 전술) | `/formation` |
| BattleScreen | 자동전투 관전 (배속/스킵) | `/battle` |
| HeroManagementScreen | 영웅 관리 (레벨업, 장비, 돌파) | `/heroes` |
| InventoryScreen | 인벤토리/장비 관리 | `/inventory` |
| ShopScreen | 상점 (구매/판매) | `/shop` |
| DialogueOverlay | 대화 오버레이 (인게임) | 오버레이 |
| IdleRewardScreen | 접속 시 방치 보상 팝업 | 오버레이 |
| SettingsScreen | 설정 (사운드, 언어, 그래픽) | `/settings` |
| AchievementScreen | 업적 목록 | `/achievements` |
| SaveLoadScreen | 세이브/로드 슬롯 | `/save` |

---

## 5. 비주얼 설계

### 5.1 Rive 벡터 애니메이션

모든 캐릭터, 적, 이펙트, UI 요소를 Rive로 제작한다.

#### 5.1.1 캐릭터 Rive 파일 구조

| 파일 | 내용 | State Machine |
|------|------|--------------|
| `hero_ares.riv` | 아레스 (주인공) | auto_idle, walk, attack, cast, hurt, die |
| `hero_elain.riv` | 엘레인 (히로인) | auto_idle, walk, attack, cast, hurt, die |
| `hero_sinuse.riv` | 시누세 (전사) | auto_idle, walk, attack, hurt, die |
| `enemy_soldier.riv` | 일반 적병 | auto_idle, walk, attack, hurt, die |
| `enemy_elite.riv` | 엘리트 적 | auto_idle, walk, attack, hurt, die, special |
| `boss_kugaia.riv` | 쿠가이아 (보스) | phase1, phase2, phase3, enrage |
| `boss_mordred.riv` | 모르드레드 (보스) | phase1, phase2, phase3, enrage |
| `boss_final.riv` | 마왕 (최종 보스) | phase1, phase2, phase3, enrage |

State Machine에 `auto_idle` 추가: 방치형 대시보드에서 캐릭터가 자동으로 움직이는 대기 애니메이션.
배속 시 애니메이션 `playbackSpeed` 배율 반영 (2x = 2.0, 4x = 4.0).

#### 5.1.2 이펙트 Rive 파일

| 파일 | 내용 |
|------|------|
| `fx_fire.riv` | 화염 마법 이펙트 |
| `fx_ice.riv` | 빙결 이펙트 |
| `fx_thunder.riv` | 번개 이펙트 |
| `fx_heal.riv` | 치유 이펙트 |
| `fx_shield.riv` | 방패 버프 이펙트 |
| `fx_hit.riv` | 타격 이펙트 |
| `fx_critical.riv` | 크리티컬 이펙트 |
| `fx_levelup.riv` | 레벨업 연출 |
| `fx_status.riv` | 상태이상 아이콘 애니메이션 |

#### 5.1.3 UI Rive 파일

| 파일 | 내용 |
|------|------|
| `ui_hp_bar.riv` | HP/MP/FT 바 (동적) |
| `ui_title.riv` | 타이틀 화면 애니메이션 |
| `ui_victory.riv` | 승리 연출 |
| `ui_game_over.riv` | 게임 오버 연출 |
| `ui_chapter_intro.riv` | 챕터 시작 연출 |
| `ui_idle_reward.riv` | 방치 보상 팝업 연출 |

### 5.2 아트 스타일 가이드

| 요소 | 스타일 | 비고 |
|------|--------|------|
| 캐릭터 | 2.5등신 디포르메, 벡터 | 원작 8x8 스프라이트의 현대적 재해석 |
| 배경 | 세밀한 벡터 풍경 + 레이어 패럴랙스 | 스테이지별 배경 |
| UI | Material Design 3 기반 | 세로 모드 최적화, 반투명 패널 |
| 이펙트 | Rive 파티클 + Flame 파티클 혼합 | 화려하면서 성능 최적화 |
| 색감 | 따뜻한 판타지 톤 | 챕터별 색조 변화 |

### 5.3 해상도 정책

| 항목 | 내용 |
|------|------|
| 화면 방향 | 세로 모드 기본 (Portrait) |
| 기준 논리 해상도 | 800x1280 (세로) |
| 전투 뷰포트 | 상단 60% 영역 (800x768) |
| 렌더링 | Flame CameraComponent로 기기 해상도에 자동 스케일 |
| AI 파라미터 | 모든 거리는 논리 좌표 기준 (감지 200px 등) |

---

## 6. 기술 스택

### 6.1 핵심 프레임워크

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.24+ | UI 프레임워크, 크로스 플랫폼 |
| Dart | 3.5+ | 메인 언어 |
| Flame | 1.18+ | 2D 게임 엔진 (게임 루프, 물리, 카메라) |
| Rive | 0.13+ | 벡터 애니메이션 (캐릭터, UI, 이펙트) |
| Riverpod | 2.5+ | 상태 관리 |
| Isar | 4.0+ | 로컬 데이터베이스 (세이브/설정) |
| Audioplayers | 6.0+ | 사운드/BGM |
| Flame Tiled | 1.20+ | 타일맵 |

### 6.2 추가 패키지

| 패키지 | 용도 |
|--------|------|
| `freezed` + `json_serializable` | 불변 데이터 모델 |
| `go_router` | 화면 라우팅 |
| `flame_audio` | 게임 내 오디오 |
| `flutter_localizations` | 다국어 |
| `shared_preferences` | 설정 저장 |
| `path_provider` | 파일 경로 |
| `flutter_local_notifications` | 방치 보상 알림 |
| `workmanager` | 백그라운드 타이머 |
| `firebase_core` + `cloud_firestore` | 클라우드 세이브 (선택) |
| `google_sign_in` / `sign_in_with_apple` | 소셜 로그인 (선택) |

### 6.3 개발 도구

| 도구 | 용도 |
|------|------|
| Rive Editor | 캐릭터/UI 애니메이션 제작 |
| Tiled Map Editor | 맵 제작 |
| FL Studio / GarageBand | 사운드 편집 |
| Flutter DevTools | 성능 프로파일링 |
| Firebase Analytics | 사용자 분석 (선택) |

### 6.4 프로젝트 구조

```
tenchisouzou/
+-- lib/
|   +-- main.dart                    # 앱 엔트리포인트
|   +-- app.dart                     # MaterialApp, 라우팅
|   +-- core/
|   |   +-- constants/               # 게임 상수 (원본 파라미터 1:1)
|   |   |   +-- combat_constants.dart
|   |   |   +-- fatigue_constants.dart
|   |   |   +-- ai_constants.dart
|   |   |   +-- spell_constants.dart
|   |   |   +-- level_constants.dart
|   |   |   +-- idle_constants.dart       # 방치형 상수
|   |   +-- utils/
|   |   +-- extensions/
|   +-- data/
|   |   +-- models/                  # 데이터 모델 (freezed)
|   |   |   +-- unit_model.dart
|   |   |   +-- spell_model.dart
|   |   |   +-- item_model.dart
|   |   |   +-- equipment_model.dart
|   |   |   +-- chapter_model.dart
|   |   |   +-- stage_model.dart          # 스테이지 데이터
|   |   |   +-- save_model.dart
|   |   |   +-- idle_reward_model.dart    # 방치 보상 모델
|   |   +-- repositories/
|   |   +-- databases/               # Isar 스키마
|   +-- game/
|   |   +-- tenchisouzou_game.dart   # FlameGame 메인 클래스
|   |   +-- components/
|   |   |   +-- units/               # 유닛 컴포넌트
|   |   |   |   +-- unit_component.dart
|   |   |   |   +-- ai_unit_component.dart    # 전원 AI (주인공 포함)
|   |   |   |   +-- enemy_unit_component.dart
|   |   |   |   +-- boss_unit_component.dart
|   |   |   +-- map/                 # 맵 컴포넌트
|   |   |   +-- effects/             # 이펙트/파티클
|   |   |   +-- ui/                  # 인게임 HUD (Flame 레이어)
|   |   +-- systems/                 # 게임 시스템
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
|   |   |   +-- idle_reward_system.dart   # 오프라인 보상 엔진
|   |   |   +-- sweep_system.dart         # 소탕 시스템
|   |   |   +-- stage_system.dart         # 스테이지 진행
|   |   |   +-- auto_loop_system.dart     # 자동 루프 전투
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
|   |   |   +-- main_dashboard.dart       # 메인 대시보드
|   |   |   +-- stage_select_screen.dart  # 스테이지 선택
|   |   |   +-- formation_screen.dart     # 편성 화면
|   |   |   +-- battle_screen.dart        # 자동전투 관전
|   |   |   +-- hero_management_screen.dart # 영웅 관리
|   |   |   +-- inventory_screen.dart
|   |   |   +-- shop_screen.dart
|   |   |   +-- settings_screen.dart
|   |   |   +-- achievement_screen.dart
|   |   |   +-- save_load_screen.dart
|   |   +-- widgets/
|   |   |   +-- hud/
|   |   |   +-- dialogs/
|   |   |   +-- rive_widgets/
|   |   |   +-- idle_reward_popup.dart    # 방치 보상 팝업
|   |   +-- providers/               # Riverpod providers
|   +-- l10n/                        # 다국어 리소스
+-- assets/
|   +-- rive/                        # Rive 애니메이션 파일 (.riv)
|   |   +-- characters/
|   |   +-- enemies/
|   |   +-- bosses/
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
|   |   +-- stages.json              # 스테이지 데이터
|   |   +-- dialogues/
|   +-- fonts/
|   +-- images/
+-- test/
+-- integration_test/
```

---

## 7. 유지 vs 변경 원칙

```
+-------------------------------+-------------------------------+
|        100% 유지 (원본)       |      완전 변경 (v2.0)         |
+-------------------------------+-------------------------------+
| Gocha-Kyara AI 전 파라미터    | 게임 루프 (자동전투)           |
| AI 상태머신 9개               | 입력 체계 (편성 중심)          |
| 성격 3종 / 대형 5종           | 화면 방향 (세로 모드)          |
| 전투 공식 (데미지/명중/회피)   | 진행 방식 (스테이지+방치)      |
| 피로도 시스템 (4단계)          | UI/UX (방치형 대시보드)        |
| 마법 8종 (스탯/쿨다운)         | 모든 그래픽 에셋 (Rive 벡터)   |
| 상태이상 6종                   | 사운드/음악 (신규 작곡)        |
| 환경 지형 6종                  | 온보딩/튜토리얼               |
| 장비/인벤토리/상점             | 게임 타이틀/브랜딩             |
| 스토리/시나리오/캐릭터          | 클라우드 세이브                |
| 경험치/레벨업 공식             | 앱스토어 통합                  |
| 보스 시스템 (3페이즈)          | 이펙트 (Rive 파티클)          |
| 엔딩 조건 (GOOD/NORMAL/BAD)   |                               |
| NG+ 스케일링                   |                               |
| 업적 28개                      |                               |
+-------------------------------+-------------------------------+
|              신규 추가 (방치형)                                |
+-------------------------------+-------------------------------+
| 오프라인 보상 엔진             | 배속 시스템 (1x/2x/4x/스킵)  |
| 소탕 시스템                    | 자동 루프 전투                |
| 스테이지 시스템 (1-3성)        | 방치 대시보드                 |
+-------------------------------+-------------------------------+
```

---

## 8. 기능 요구사항

### 8.1 Must Have (MVP)

| ID | 기능 | 설명 | 우선순위 |
|:--:|------|------|:--------:|
| F-001 | **완전 자동전투** | 전원 AI 자동 제어, 9개 AIState | P0 |
| F-002 | **편성 시스템** | 부대 배치, 대형 5종, 전술 프리셋 | P0 |
| F-003 | **피로도 시스템** | 4단계 피로도 관리 + 오프라인 회복 | P0 |
| F-004 | **배속 시스템** | 1x / 2x / 4x / 스킵 | P0 |
| F-005 | **오프라인 보상** | 타임스탬프 기반, 8시간 상한 | P0 |
| F-006 | **스테이지 시스템** | 1-3성 평가, 100개 스테이지 | P0 |
| F-007 | **소탕** | 3성 클리어 스테이지 즉시 완료 | P0 |
| F-008 | **Rive 캐릭터** | 주요 캐릭터 8종 + 적 3종 | P0 |
| F-009 | **RPG 코어** | 레벨업, 장비, 아이템 | P0 |
| F-010 | **세이브/로드** | 로컬 세이브 + 자동 저장 | P0 |
| F-011 | **모바일 빌드** | iOS + Android | P0 |

### 8.2 Should Have (Full Release)

| ID | 기능 | 설명 |
|:--:|------|------|
| F-012 | **전체 스토리** | 챕터 4-10, 스테이지 31-100 |
| F-013 | **마법 시스템** | 8종 마법 + AI 자동 시전 |
| F-014 | **보스 시스템** | 멀티 페이즈 + 광폭화 |
| F-015 | **상태이상** | 6종 상태이상 |
| F-016 | **환경 시스템** | 6종 지형 효과 |
| F-017 | **자동 루프 전투** | 스테이지 반복 자동 진행 |
| F-018 | **BGM/SFX** | 신규 작곡 사운드트랙 |
| F-019 | **업적** | 28개 업적 시스템 |
| F-020 | **NG+** | New Game Plus |
| F-021 | **다국어** | 일본어, 한국어, 영어 |

### 8.3 Nice to Have (Post-Launch)

| ID | 기능 | 설명 |
|:--:|------|------|
| F-022 | **클라우드 세이브** | Firebase 기반 기기 간 동기화 |
| F-023 | **Web 빌드** | PWA 지원 |
| F-024 | **리더보드** | 스피드런/처치 수 순위 |
| F-025 | **스킨 시스템** | 캐릭터 외형 변경 |

### 8.4 Out of Scope

| 제외 항목 | 이유 |
|----------|------|
| MMO/온라인 PvP | 원본 싱글플레이어 정체성 유지 |
| 3D 풀 리메이크 | Gocha-Kyara 감성 상실 |
| 가챠 | 캐릭터는 스토리 진행으로 획득 |

---

## 9. 비기능 요구사항

### 9.1 성능

| 플랫폼 | 해상도 | FPS | 최대 유닛 | 로딩 | 메모리 |
|--------|--------|-----|----------|------|--------|
| 모바일 (최소) | 720x1280 | 30 | 20 | < 5초 | < 300MB |
| 모바일 (권장) | 1080x1920 | 60 | 30 | < 3초 | < 400MB |
| 태블릿 | 1536x2048 | 60 | 30 | < 3초 | < 500MB |
| Web | 1080x1920 | 60 | 30 | < 5초 | < 500MB |

### 9.2 모바일 최적화

| 항목 | 요구사항 |
|------|----------|
| 배터리 (전투 중) | 1시간 플레이 시 배터리 소모 15% 이하 |
| 배터리 (방치 모드) | 5% 이하/시간 |
| 발열 | 30분 연속 플레이 시 40도 이하 |
| APK 크기 | 100MB 이하 (최초 설치) |
| 오프라인 | 타임스탬프 기반 오프라인 진행 |
| 백그라운드 | 타임스탬프 기반 보상 계산 (앱 종료 OK) |

### 9.3 접근성

| 항목 | 요구사항 |
|------|----------|
| 색맹 모드 | 적녹/청황/회색 3가지 모드 |
| 자막 | 전체 대사 자막 |
| 폰트 크기 | 3단계 조절 (소/중/대) |
| 고대비 | 고대비 UI 모드 |
| 터치 크기 | 최소 48dp 터치 영역 |

### 9.4 다국어

| 우선순위 | 언어 | 용도 |
|:--------:|------|------|
| P0 | 일본어 (원본) | 원작 텍스트 기반 |
| P0 | 한국어 | 주요 타겟 시장 |
| P1 | 영어 | 글로벌 시장 |

---

## 10. 개발 로드맵

### POC: Proof of Concept (2주)

**목표**: 자동전투 + Rive 통합이 기술적으로 가능한지 검증

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| Flame + Rive 통합 | Rive 캐릭터가 Flame 월드에서 렌더링 | 1개 캐릭터 화면 출력 |
| 자동전투 프로토타입 | 2개 유닛이 AI로 서로 공격 | IDLE → CHASE → ATTACK 전환 확인 |
| 세로 모드 레이아웃 | 800x1280 기준 Flutter UI + Flame 뷰포트 | 상단 전투 + 하단 UI 분리 |
| 배속 시스템 | Flame `timeScale` 변경 | 1x/2x/4x 전환 동작 |

**산출물**: 기술 검증 보고서, 프로토타입 APK

---

### MVP: Minimum Viable Product (2개월)

**목표**: 자동전투 + 편성 + 스테이지 진행의 핵심 루프 완성

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| Unit 클래스 계층 | AIUnit 기반 전원 자동 제어 | 주인공 포함 전원 AI 동작 |
| AI 상태머신 | 9개 AIState 전체 구현 | 상태 전환 + 전투 자동 진행 |
| 성격 3종 | AGGRESSIVE/DEFENSIVE/BALANCED | 행동 차이 관찰 가능 |
| 전투 시스템 | 데미지/명중/회피 공식 | Appendix A 상수 1:1 일치 |
| 편성 화면 | 대형 5종 + 드래그 배치 | UI에서 편성 → 전투 적용 |
| 스테이지 1-10 | 챕터 1 전체 | 1-3성 평가 동작 |
| 배속/스킵 | 1x/2x/4x + 스킵 | 전투 속도 제어 |
| 기본 UI | 대시보드, 편성, 전투 관전 | 핵심 화면 3개 동작 |
| Rive 캐릭터 2종 | 아레스 + 적 1종 | auto_idle, walk, attack, hurt |

**산출물**: 내부 테스트 가능한 APK (챕터 1 플레이 가능)

---

### Phase 1: Core Systems (2개월)

**목표**: RPG 시스템 완성 + 방치형 핵심 기능

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| 피로도 시스템 | 4단계 + 오프라인 회복 | 전투 중 피로도 반영, 오프라인 회복 확인 |
| 경험치/레벨업 | 공식 + 스탯 성장 | Lv1→50 성장 곡선 검증 |
| 장비/인벤토리 | 3슬롯 장비 + 50칸 인벤토리 | 장착/해제/능력치 반영 |
| 상점 | 구매/판매 | 가격 배율 적용 |
| 오프라인 보상 | 타임스탬프 기반, 8시간 상한 | 접속 시 보상 팝업 |
| 소탕 시스템 | 3성 스테이지 즉시 완료 | 소탕권 소모 + 보상 지급 |
| 자동 루프 | 스테이지 반복 자동 진행 | 승리 → 재시작 → 패배 시 중단 |
| 세이브/로드 | 로컬 저장 + 자동 저장 | Isar 기반 데이터 영속성 |

**산출물**: 방치형 코어 루프 완성 빌드

---

### Phase 2: Content & Magic (3개월)

**목표**: 챕터 1-5 콘텐츠 + 전투 시스템 완성

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| 마법 시스템 | 8종 마법 + AI 자동 시전 | 마법사/힐러 AI 마법 활용 |
| 상태이상 | 6종 상태이상 | tick 데미지, CC 효과 적용 |
| 환경 시스템 | 6종 지형 효과 | 스테이지별 지형 반영 |
| SpatialHash | 공간 분할 최적화 | 30 유닛 60 FPS |
| 스테이지 11-50 | 챕터 2-5 | 맵/이벤트/대화 |
| 보스 시스템 | 쿠가이아 (챕터 6 보스) | 3페이즈 + 광폭화 |
| Rive 캐릭터 | 아군 4종 + 적 5종 추가 | 6종 캐릭터 + 6종 적 |
| 대화 시스템 | 스토리 대화 오버레이 | 메시지 #001-#400 |

**산출물**: 중간 콘텐츠 빌드 (챕터 1-5 플레이 가능)

---

### Phase 3: Full Content (3개월)

**목표**: 챕터 6-10 콘텐츠 완성 + 엔드게임

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| 스테이지 51-100 | 챕터 6-10 | 맵/이벤트/대화/보스 |
| 보스 완성 | 모르드레드 + 마왕 | 3페이즈 + 광폭화 |
| 엔딩 시스템 | GOOD/NORMAL/BAD | 조건 분기 + 컷신 |
| NG+ | New Game Plus | 1.5배 스케일링 |
| 업적 | 28개 전체 | 추적 + 보상 |
| Rive 캐릭터 완성 | 나머지 아군 + 적 + 보스 | 전체 캐릭터 |
| Rive 이펙트 | 마법/상태이상/UI 이펙트 | 9개 이펙트 파일 |
| 대화 완성 | 메시지 #401-#800 | 전체 스토리 |

**산출물**: 풀 콘텐츠 빌드 (전 챕터 플레이 가능)

---

### Phase 4: Polish & Audio (2개월)

**목표**: 비주얼/사운드 완성 + 품질 향상

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| BGM | 10-15곡 작곡 | 챕터별 BGM |
| SFX | 30-50개 | 공격/마법/UI 효과음 |
| UI/UX 폴리시 | Material Design 3 기반 | 일관된 디자인 시스템 |
| 방치 보상 연출 | Rive 팝업 애니메이션 | 접속 시 보상 연출 |
| 다국어 | ja/ko/en | 전체 텍스트 번역 |
| 접근성 | 색맹/폰트/고대비 | 3가지 모드 동작 |
| 알림 | 방치 보상 알림 | 로컬 푸시 알림 |

**산출물**: 비주얼/사운드 완성 빌드

---

### Final: QA & Launch (1개월)

**목표**: 품질 보증 + 앱스토어 출시

| 항목 | 내용 | 완료 기준 |
|------|------|----------|
| 성능 최적화 | 30 유닛 60 FPS (모바일) | 프로파일링 통과 |
| 배터리 테스트 | 방치 모드 5%/시간 이하 | 실기기 측정 |
| QA | 전 스테이지 플레이 테스트 | 크래시율 0.5% 이하 |
| 버그 수정 | QA 발견 이슈 전체 | Critical/Major 0건 |
| 앱스토어 등록 | iOS App Store + Google Play | 심사 통과 |
| Web 배포 | PWA 빌드 | 웹 접속 가능 |

**산출물**: 정식 출시 빌드

---

### 전체 일정 요약

```
POC      ██ (2W)
MVP      ████████ (2M)
Phase 1  ████████ (2M)
Phase 2  ████████████ (3M)
Phase 3  ████████████ (3M)
Phase 4  ████████ (2M)
Final    ████ (1M)
─────────────────────────
Total    약 13.5개월
```

| 단계 | 기간 | 누적 | 주요 마일스톤 |
|------|------|------|-------------|
| POC | 2주 | 2주 | 기술 검증 완료 |
| MVP | 2개월 | 2.5개월 | 자동전투 + 편성 + 챕터 1 |
| Phase 1 | 2개월 | 4.5개월 | 방치형 코어 루프 완성 |
| Phase 2 | 3개월 | 7.5개월 | 챕터 1-5 + 전투 시스템 완성 |
| Phase 3 | 3개월 | 10.5개월 | 전체 콘텐츠 완성 |
| Phase 4 | 2개월 | 12.5개월 | 비주얼/사운드/다국어 |
| Final | 1개월 | 13.5개월 | QA + 출시 |

---

## Appendix A: FQ4 원본 시스템 상수 총정리

### A.1 AI 상수

```dart
const double AI_TICK_INTERVAL = 0.3;       // 아군 AI tick
const double AI_TICK_INTERVAL_ENEMY = 0.4; // 적 AI tick
const double DETECTION_RANGE = 200.0;      // 기본 감지 범위
const double ATTACK_ENGAGE_RANGE = 150.0;  // 공격 시작 거리
const double FOLLOW_DISTANCE = 80.0;       // 리더 추종 거리
const double RETREAT_DISTANCE = 200.0;     // 후퇴 거리
const double REST_HP_THRESHOLD = 0.3;      // 휴식 HP 임계값
const double REST_FATIGUE_THRESHOLD = 70.0; // 휴식 피로도 임계값
```

### A.2 전투 상수

```dart
const double BASE_HIT_CHANCE = 0.95;
const double BASE_EVASION = 0.05;
const double BASE_CRIT_CHANCE = 0.05;
const double CRITICAL_MULTIPLIER = 2.0;
const double DAMAGE_VARIANCE = 0.1;
const int MIN_DAMAGE = 1;
const double ATTACK_COOLDOWN = 1.0;
```

### A.3 피로도 상수

```dart
const int FATIGUE_ATTACK = 10;
const int FATIGUE_SKILL = 20;
const int FATIGUE_MOVE_PER_10_UNITS = 1;
const int FATIGUE_DAMAGE_TAKEN = 5;
const int FATIGUE_RECOVERY_IDLE = 1;
const int FATIGUE_RECOVERY_REST = 5;
const int FATIGUE_RECOVERY_ITEM = 30;

const Map<String, Map<String, num>> FATIGUE_LEVELS = {
  'NORMAL': {'min': 0, 'max': 30, 'speed': 1.0, 'attack': 1.0},
  'TIRED': {'min': 31, 'max': 60, 'speed': 0.8, 'attack': 0.9},
  'EXHAUSTED': {'min': 61, 'max': 90, 'speed': 0.5, 'attack': 0.7},
  'COLLAPSED': {'min': 91, 'max': 100, 'speed': 0.0, 'attack': 0.0},
};
```

### A.4 경험치/레벨 상수

```dart
const int MAX_LEVEL = 50;
const int BASE_EXP = 100;
const double EXP_GROWTH_RATE = 1.2;

const Map<String, int> LEVEL_UP_STATS = {
  'hp': 15, 'mp': 5, 'atk': 2, 'def': 1, 'spd': 1, 'lck': 1,
};
```

---

## Document History

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-15 | 초기 PRD 작성 (실시간 전술 RPG) |
| 2.0.0 | 2026-02-15 | 방치형 자동전투 전면 재설계, 섹션 10+ 개발 로드맵으로 통합 |
