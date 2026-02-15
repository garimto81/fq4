# PRD-0005: 전략 전투 시스템 POC

**Version**: 1.0.0 | **Date**: 2026-02-15 | **Author**: Aiden Kim | **Status**: Draft

**기반 문서**: POC-GAMEPLAY-VERIFICATION.md (채택), GDD-0001, PRD-0002

---

## 1. 개요

### 1.1 문서 목적

본 문서는 First Queen 4 HD Renewal의 전투 시스템에 전략적 깊이를 부여하기 위한 POC 계획서다. 기존 POC가 검증한 "자동전투 기본 + 직접 개입" 체감에 이어, 전투 자체의 전술적 의미를 검증한다.

대상 독자: 개발 담당자, 기획 검토자

### 1.2 핵심 검증 목표

| 번호 | 목표 | 질문 |
|:----:|------|------|
| 1 | 대규모 전투 | 20-40 유닛이 동시에 전투해도 60 FPS를 유지하는가? |
| 2 | 지능적 AI | 각 유닛이 단순 돌진이 아닌 전술적 판단으로 행동하는가? |
| 3 | 전략적 깊이 | 방향, 사거리, 상성, 진형이 전투 결과에 실질적 영향을 주는가? |

### 1.3 관련 문서

| 문서 | 관계 |
|------|------|
| POC-GAMEPLAY-VERIFICATION.md | 현재 채택된 설계 방향. Phase 0 검증 완료 전제 |
| GDD-0001 | 게임성 설계. 180개 재미 요소 정의. 단, "직접 조작이 기본"이라는 방향은 POC-GAMEPLAY-VERIFICATION에서 "자동전투 기본 + 직접 개입"으로 변경됨 |
| PRD-0002 | Flutter 갱신 기획. 기술 스택 정의 |
| FQ4_INTEGRATED_GDD.md | Godot 통합 GDD. 원작 파라미터 참조 |

---

## 2. 배경 및 동기

### 2.1 기존 POC의 한계

현재까지 구현된 6개 POC는 기술 기반과 핵심 체감을 검증했다.

| POC | 검증 내용 | 결과 |
|-----|----------|------|
| POC-1 | Rive 렌더링 통합 | Windows segfault, fallback 사용 |
| POC-2 | AI 자동전투 기초 | 상태머신 동작 확인 |
| POC-3 | 레이아웃 | 가로 모드 전환 |
| POC-4 | 배속 시스템 | 동작 확인 |
| POC-5 | 통합 전투 | 기본 파이프라인 확인 |
| POC-T0 | 자동/수동 전환 | HybridUnitComponent 동작 확인 |

모든 POC의 전투 로직은 동일하다: **가장 가까운 적에게 이동하고 사거리 내에 들어오면 공격한다.** 방향 개념이 없고, 무기 사거리 차이가 없으며, 상성도 없다. 이 수준의 AI로는 원작 First Queen 4의 전투 경험을 재현할 수 없다.

### 2.2 원작의 전투 특징

First Queen 4의 전투는 단순 액션이 아니다.

- **수십 명의 난전**: 아군 부대와 적 부대가 뒤엉켜 싸우는 대규모 전투
- **진형의 의미**: 보병이 전방에서 적을 고정하고, 궁수가 후방에서 사격하는 역할 분담
- **위치의 중요성**: 측면이나 후방에서 공격하면 유리하고, 포위당하면 불리함
- **무기 유형별 교전 거리**: 검사는 접근해서, 창병은 중거리에서, 궁수는 원거리에서 전투

이런 전술적 깊이가 Gocha-Kyara 시스템의 "관전 재미"와 "개입 가치"를 만든다. AI가 단순하면 관전이 지루하고, 전술 요소가 없으면 개입할 이유가 없다.

### 2.3 이 POC가 프로젝트의 성패를 결정하는 이유

POC-GAMEPLAY-VERIFICATION에서 정의한 핵심 감정은 **"AI만으로는 부족하지만, 내가 개입하면 달라진다"**다.

이 감정이 성립하려면 두 가지가 필요하다:

1. **AI가 충분히 똑똑해야 한다** - 멍청한 AI를 보는 건 재미가 아니라 짜증이다
2. **전투에 전략적 판단 여지가 있어야 한다** - "아무 유닛이나 때리면 되는" 전투에서는 개입 가치가 없다

방향성 공격, 사거리 체계, 상성 관계가 없으면 플레이어의 전술적 개입은 "더 빨리 클릭하는 것" 이상의 의미를 가지지 못한다. 본 POC는 전투 시스템에 이 전략적 레이어를 추가하고, 그것이 실제로 재미로 이어지는지 검증한다.

---

## 3. 전투 메커니즘 설계

### 3.1 방향성 전투 시스템

#### 유닛의 facing direction

각 유닛은 facing direction을 가진다. 결정 규칙:

| 우선순위 | 조건 | 방향 결정 |
|:--------:|------|----------|
| 1 | 공격 대상 존재 | 대상을 향하는 방향 |
| 2 | 이동 중 | 이동 방향 벡터 |
| 3 | 정지 상태 | 마지막 facing 유지 |

facing은 radian 단위로 저장하며, 렌더링 시 4방향 또는 8방향으로 양자화하여 표시한다.

#### 공격 방향 판정

공격자의 위치와 대상의 facing 벡터 간 각도를 계산하여 공격 방향을 판정한다.

```
공격자 위치에서 대상 위치로의 벡터: attackVector
대상의 facing 벡터: facingVector

angle = acos(dot(attackVector.normalized, facingVector.normalized))
```

| 방향 | 각도 범위 | 데미지 배율 | 전략적 의미 |
|------|----------|:-----------:|-----------|
| 정면 | 0 ~ 45도 | 1.0x | 기본 교전. 방어력 온전 |
| 측면 | 45 ~ 135도 | 1.3x | 진형 돌파. 방어 진형의 약점 공략 |
| 후면 | 135 ~ 180도 | 1.5x | 기습. 원거리 유닛 후방 습격에 결정적 |

#### 전략적 함의

- 일직선 돌진은 정면 교전만 발생시킨다 (1.0x)
- 진형을 유지하면 후면 노출을 방지할 수 있다
- 기동력 높은 유닛으로 측면/후면을 노리는 플레이가 보상받는다
- 플레이어가 직접 제어하여 후면 기습을 성공시키면 1.5x 데미지로 전세를 뒤집을 수 있다

### 3.2 사거리 체계

세 가지 사거리 타입으로 무기와 유닛 역할을 분류한다.

| 타입 | 사거리 | 대표 무기 | DPS | 방어력 | 이동속도 | 전투 특성 |
|------|:------:|----------|:---:|:-----:|:-------:|----------|
| 근거리 | 0-60px | 검, 도끼, 단검 | 높음 | 높음 | 보통 | 접근 후 연타. 정면 교전에 강함 |
| 중거리 | 60-150px | 창, 할버드, 투창 | 중간 | 중간 | 보통 | 전방 우선 공격. 관통 판정 가능 |
| 원거리 | 150-300px | 활, 석궁, 마법 | 낮음 | 낮음 | 빠름 | 투사체 기반. 거리 유지가 생존 핵심 |

#### 사거리별 교전 패턴

**근거리 유닛**: 적에게 접근하여 밀착 공격. 높은 DPS와 방어력으로 정면 전투의 주력. 접근까지의 피해가 약점.

**중거리 유닛**: 근거리 유닛보다 먼저 공격 개시 가능. 창의 리치로 근거리 유닛 접근 전에 피해를 축적. 원거리 유닛에게는 사거리에서 밀림.

**원거리 유닛**: 최대 거리를 유지하며 일방적 공격. HP와 방어력이 낮아 근거리 유닛 접근 시 즉시 위험. 아군 근거리 유닛의 보호가 필수.

### 3.3 상성 관계

사거리 타입 간 상성이 존재한다. 단, 절대적이지 않고 방향 보너스로 뒤집을 수 있다.

```
근거리 ──유리──> 원거리 (접근 성공 시 압도, 1.3x)
  ^                        |
  |                        |
불리                      유리
  |                        |
중거리 <──유리── 원거리 (사거리 차이로 일방 공격, 1.2x)
  |
  └──유리──> 근거리 (적정 거리 유지 + 리치 우위, 1.2x)
```

| 공격자 | 대상 | 배율 | 조건 |
|--------|------|:----:|------|
| 근거리 | 원거리 | 1.3x | 60px 이내 접근 성공 시 |
| 중거리 | 근거리 | 1.2x | 60-150px 거리 유지 시 |
| 원거리 | 중거리 | 1.2x | 150px 이상 거리에서 사격 시 |

#### 상성 역전 조건

방향 보너스가 상성 불이익을 상쇄할 수 있다.

- 상성 불리 (0.8x) + 후면 공격 (1.5x) = 최종 1.2x (유리로 역전)
- 상성 불리 (0.8x) + 측면 공격 (1.3x) = 최종 1.04x (거의 동등)

이것이 진형과 기동의 중요성을 만든다. 상성이 불리해도 후방에서 기습하면 이길 수 있다.

### 3.4 진형 시스템

기존 `Formation` enum의 5가지 진형을 전술적 수치와 함께 구체화한다.

| 진형 | 전술적 성격 | 정면 방어 | 측면 노출 | 후면 보호 | 적합 상황 |
|------|-----------|:---------:|:---------:|:---------:|----------|
| V_SHAPE | 공격적 돌파 | 중간 | 높음 | 낮음 | 적 진형 쐐기 삽입 |
| LINE | 균형 방어 | 높음 | 중간 | 중간 | 정면 교전 |
| CIRCLE | 전방위 방어 | 중간 | 낮음 | 낮음 | 포위 대응, 원거리 보호 |
| WEDGE | 선두 돌격 | 낮음 (선두 집중) | 높음 | 높음 | 돌파 후 분산 |
| SCATTERED | 범위 회피 | 낮음 | 낮음 | 낮음 | 범위 공격 대응, 집중 방지 |

#### 진형 유지 로직

각 유닛은 리더 기준 상대 위치 offset을 가진다. AI는 전투 중에도 이 offset을 기준으로 위치를 보정한다.

```dart
// 진형 offset 예시 (V_SHAPE, 리더 기준)
// slot 0: leader (0, 0)
// slot 1: (-40, -30)  slot 2: (40, -30)
// slot 3: (-80, -60)  slot 4: (80, -60)
```

- 진형 이탈 거리가 offset + 30px 초과 시 복귀 시도
- 전투 중에는 진형 유지 우선순위가 낮아짐 (교전 > 진형)
- 교전 종료 후 자동 재정렬

---

## 4. AI 설계

### 4.1 개별 유닛 AI (전술 수준)

기존 AIBrain의 상태머신 위에 전술 판단 레이어를 추가한다. 기존 9개 AIState는 그대로 유지하고, 상태 전이 조건에 전략적 요소를 반영한다.

#### 위협 평가

```dart
double evaluateThreat(UnitComponent self, UnitComponent enemy) {
  double threat = 0;

  // 거리 위협 (가까울수록 높음)
  threat += (1.0 - distance / maxDetectionRange) * 30;

  // 방향 위협 (내 후면에 있으면 높음)
  if (getAttackDirection(enemy, self) == AttackDirection.back) threat += 40;
  if (getAttackDirection(enemy, self) == AttackDirection.side) threat += 20;

  // 수적 위협 (나를 타겟하는 적 수)
  threat += targetingMeCount * 15;

  // 상성 위협 (불리한 상성이면 높음)
  if (hasDisadvantage(self.weaponRange, enemy.weaponRange)) threat += 25;

  return threat;
}
```

#### 거리 관리

무기 타입에 따라 최적 교전 거리가 다르다.

| 무기 타입 | 최적 거리 | 행동 패턴 |
|----------|:---------:|----------|
| 근거리 | 0-40px | 접근 돌진. 적에게 밀착 시도 |
| 중거리 | 80-120px | 적정 거리 유지. 적이 접근하면 후퇴, 멀어지면 접근 |
| 원거리 | 200-280px | 최대 거리 유지. 아군 전위 뒤에 위치 |

#### 타겟 우선순위

AI가 공격 대상을 선택하는 우선순위:

| 우선순위 | 조건 | 가중치 | 근거 |
|:--------:|------|:------:|------|
| 1 | 체력 낮은 적 (HP 30% 이하) | +50 | 처치 확정으로 수적 우위 확보 |
| 2 | 위험한 적 (원거리 딜러) | +35 | 지속 피해 차단 |
| 3 | 후면이 노출된 적 | +30 | 1.5x 보너스 활용 |
| 4 | 상성 유리한 적 | +20 | 효율적 교전 |
| 5 | 가장 가까운 적 | +10 | 기본 |

#### 위치 최적화

- 근거리 유닛: 적의 측면/후면으로 우회 기동 시도 (직선 돌진이 아닌 호 형태 접근)
- 중거리 유닛: 적 전방에서 리치 우위 유지, 근거리 적 접근 시 후퇴
- 원거리 유닛: 아군 전위 유닛 뒤에 위치, 사격선 확보

#### 회피 판단

| 상황 | 판정 | 행동 |
|------|------|------|
| 후면에 적 1명 이상 | 후면 노출 위험 | 회전하여 적을 정면에 배치 |
| 3명 이상에게 포위 | 포위 위험 | 아군 방향으로 탈출 |
| HP 30% 이하 + 적 접근 | 사망 위험 | 즉시 후퇴, 아군 보호 하에 복귀 |

### 4.2 부대 AI (전략 수준)

개별 유닛 AI 위에 부대 단위의 협동 로직을 추가한다.

#### 핀서 공격

2개 이상 부대가 적을 양면에서 공격하는 전술.

```
아군 부대A ──정면──> 적 부대 <──후면── 아군 부대B
```

- 발동 조건: 2개 이상 아군 부대가 같은 적 부대를 타겟
- 부대B는 적 부대의 반대편으로 이동 후 공격 개시
- 적 부대의 후면이 노출되어 1.5x 보너스 적용

#### 앵커 & 플랭크

근거리 부대가 적을 정면에서 고정하고, 기동 부대가 측면으로 이동하는 전술.

| 역할 | 부대 유형 | 행동 |
|------|----------|------|
| 앵커 | 근거리 주력 | 적 정면에서 교전 유지. LINE 진형 |
| 플랭커 | 기동 부대 | 적 측면으로 이동 후 공격. V_SHAPE 진형 |

- 앵커 부대가 적을 3초 이상 고정하면 플랭크 지시 발동
- 플랭커는 적 부대의 90도 방향으로 우회 이동

#### 집중 사격

원거리 유닛들이 동일 타겟을 지정하여 화력을 집중하는 전술.

- 발동 조건: 원거리 유닛 3명 이상 같은 부대에 소속
- 타겟 선정: 적 부대 중 가장 위협적인 유닛 (위협 평가 최고점)
- 효과: 고위협 적 빠른 제거

#### 후퇴 트리거

| 조건 | 판정 | 행동 |
|------|------|------|
| 부대 생존율 50% 이하 | 자동 | 부대 전체 후퇴, CIRCLE 진형 전환 |
| 리더 HP 30% 이하 | 자동 | 부대 방어 모드, 리더 보호 우선 |
| 플레이어 후퇴 명령 | 수동 | 즉시 후퇴 |

#### 전투 상황별 진형 자동 전환

| 상황 | 현재 진형 | 전환 대상 | 사유 |
|------|----------|----------|------|
| 포위당함 | LINE/V_SHAPE | CIRCLE | 전방위 방어 |
| 적 퇴각 | LINE | V_SHAPE | 추격 가속 |
| 아군 합류 | SCATTERED | LINE | 전력 집중 |
| 범위 공격 감지 | LINE/CIRCLE | SCATTERED | 피해 분산 |

### 4.3 성격별 AI 분화

기존 3가지 Personality에 전략적 행동 패턴을 추가한다.

#### AGGRESSIVE

| 항목 | 값 | 행동 |
|------|-----|------|
| 추적 범위 배율 | 1.5x | 더 멀리서 적 감지, 추적 |
| 후퇴 HP 배율 | 0.7x | HP 21%까지 버팀 |
| 측면/후면 기동 | 적극적 | 30% 확률로 우회 기동 시도 |
| 타겟 고정 | 끈질김 | 한번 타겟 지정하면 처치까지 유지 |
| 상성 무시 | 일부 | 불리한 상성도 HP 여유 있으면 돌진 |

#### DEFENSIVE

| 항목 | 값 | 행동 |
|------|-----|------|
| 추적 범위 배율 | 0.7x | 가까운 적만 교전 |
| 후퇴 HP 배율 | 1.3x | HP 39%에서 후퇴 |
| 진형 유지 | 최우선 | 진형 이탈 최소화 |
| 아군 보호 | 적극적 | HP 낮은 아군 근처에서 방어 |
| 원거리 우선 제거 | 활성 | 원거리 적 타겟 우선순위 상향 |

#### BALANCED

| 항목 | 값 | 행동 |
|------|-----|------|
| 추적 범위 배율 | 1.0x | 기본 범위 |
| 후퇴 HP 배율 | 1.0x | HP 30%에서 후퇴 |
| 상황 적응 | 높음 | 적 구성에 따라 행동 변경 |
| 부대 명령 이행 | 충실 | 부대 명령 우선순위 최상위 |
| 위치 최적화 | 중간 | 무기 타입에 맞는 적정 거리 유지 |

---

## 5. 대규모 전투 성능

### 5.1 목표

| 지표 | 목표값 | 측정 조건 |
|------|:------:|----------|
| FPS | 60 이상 | 40 유닛 (20v20) 동시 전투, Windows 데스크톱 |
| AI tick 처리 시간 | 5ms 미만 | 40 유닛 전체 AI 판단 1 cycle |
| SpatialHash query | 프레임당 80회 미만 | 유닛당 평균 2회 (타겟 탐색 + 위협 평가) |
| 메모리 사용량 | 200MB 미만 | 40 유닛 + 투사체 + UI |

### 5.2 최적화 전략

#### SpatialHash 셀 크기 조정

현재 기본 셀 크기 100px. 최대 사거리가 300px이므로 300px 기반으로 조정하면 query 효율 향상.

```dart
// 현재
SpatialHash(cellSize: 100) // 300px 범위 query 시 49셀 탐색 (7x7)

// 최적화
SpatialHash(cellSize: 150) // 300px 범위 query 시 25셀 탐색 (5x5)
```

셀 크기가 크면 query 범위 내 셀 수는 줄지만 셀 당 유닛 수가 증가한다. 40 유닛 기준 150px이 최적 밸런스.

#### LOD AI

화면 밖 유닛은 간소화된 AI로 처리한다.

| 구분 | 화면 내 | 화면 밖 |
|------|--------|--------|
| AI tick 간격 | 0.3초 | 1.0초 |
| 위협 평가 | 전체 (거리, 방향, 상성, 수) | 거리만 |
| 진형 유지 | 활성 | 비활성 (리더 추종만) |
| 방향 판정 | 정밀 (각도 계산) | 간소 (정면/후면만) |
| 시각 효과 | 전체 | 없음 |

#### AI tick 동적 조정

프레임 드롭 감지 시 AI tick 간격을 자동 확대한다.

```
FPS >= 55: tick 0.3초 (기본)
FPS 45-54: tick 0.4초
FPS 35-44: tick 0.5초
FPS < 35:  tick 0.7초 + LOD 강제 적용
```

#### 투사체 풀링

원거리 유닛의 투사체는 ObjectPool을 활용하여 생성/파괴 비용을 제거한다. 풀 크기: 원거리 유닛 수 x 3 (동시 비행 최대 3발).

#### 배치 렌더링

같은 유닛 타입별 텍스처 아틀라스를 사용하여 draw call을 최소화한다. Flame의 `SpriteBatch`는 컴포넌트 트리와의 통합 비용이 높으므로, 먼저 아틀라스 기반 최적화로 시작하고 부족 시 별도 검토한다.

### 5.3 성능 측정 지표

POC 내에 성능 모니터 HUD를 구현하여 실시간 측정한다.

| 지표 | 표시 위치 | 갱신 주기 |
|------|----------|:---------:|
| FPS (현재/최소/평균) | 좌상단 | 매 프레임 |
| AI tick 처리 시간 (ms) | 좌상단 | 매 tick |
| 생존 유닛 수 (아군/적) | 우상단 | 매 초 |
| SpatialHash query 횟수 | 좌하단 | 매 초 |
| 메모리 사용량 (MB) | 좌하단 | 5초 |

---

## 6. POC 구현 계획

### 6.1 POC-S1: 방향성 전투

**목적**: 방향별 데미지 차이가 정확히 적용되고, AI가 측면/후면 기동을 시도하는지 검증한다.

| 항목 | 내용 |
|------|------|
| 유닛 수 | 8 (아군 4 vs 적 4), 전원 근거리 |
| 전장 크기 | 800x600px |
| 시각화 | facing 방향 화살표, 공격 시 방향 판정 텍스트 (FRONT/SIDE/BACK), 데미지 배율 표시 |

**테스트 시나리오:**

시나리오 A: 방향 판정 정확성
- 4명의 적을 고정 배치 (각각 상하좌우를 facing)
- 아군 1명을 수동 조작하여 각 방향에서 공격
- 10회씩 총 40회 공격. 방향 판정 정확도 측정

시나리오 B: AI 기동 관찰
- 전원 AI 자동전투 10회
- AI가 측면/후면 기동을 시도하는 횟수 기록
- AGGRESSIVE 성격 유닛의 우회 빈도 측정

| 측정 항목 | PASS 기준 |
|-----------|-----------|
| 방향 판정 정확도 | 40회 중 38회 이상 정확 (95%) |
| 후면 공격 데미지 | 정면 대비 정확히 1.5x (오차 +-2%) |
| 측면 공격 데미지 | 정면 대비 정확히 1.3x (오차 +-2%) |
| AI 측면 기동 시도 | AGGRESSIVE 유닛이 10회 중 5회 이상 시도 |

**FAIL 시 대응:**

| 실패 유형 | 대응 |
|-----------|------|
| 방향 판정 오류 | 각도 계산 로직 디버그. atan2 좌표계 확인 |
| AI가 기동 안 함 | 우회 기동 가중치 상향. AGGRESSIVE chaseRangeMult 조정 |
| 데미지 배율 불일치 | calculateDamage 파이프라인에서 방향 배율 적용 순서 확인 |

### 6.2 POC-S2: 사거리 상성

**목적**: 세 가지 사거리 타입 간 상성이 통계적으로 유효한지 검증한다.

| 항목 | 내용 |
|------|------|
| 유닛 수 | 12 (근거리 4 vs 중거리 4 vs 원거리 4) |
| 유닛 스탯 | 기본 스탯 동일 (ATK 20, DEF 10, SPD 80, LCK 5) |
| 차이점 | 무기 타입에 따른 사거리, DPS, 방어력, 이동속도만 다름 |
| 전장 크기 | 1200x800px |

**테스트 시나리오:**

3가지 1:1 매치업을 각 100회 시뮬레이션한다. 배속 x10으로 자동 실행.

| 매치업 | 예상 유리 측 | 목표 승률 |
|--------|:-----------:|:--------:|
| 근거리 4 vs 원거리 4 | 근거리 | 60-70% |
| 중거리 4 vs 근거리 4 | 중거리 | 60-70% |
| 원거리 4 vs 중거리 4 | 원거리 | 60-70% |

- 승률이 55% 미만이면 상성이 무의미 (FAIL)
- 승률이 75% 초과이면 상성이 너무 극단적 (FAIL)
- 3:3 혼합 편성 (각 타입 1명씩) 대전 100회도 추가 실행

| 측정 항목 | PASS 기준 |
|-----------|-----------|
| 상성 유리 승률 | 60-70% (3개 매치업 모두) |
| 혼합 대전 승패 | 40-60% (편향 없음) |
| 평균 전투 시간 | 15-60초 |
| 전투당 사상자 | 양측 모두 1명 이상 |

**FAIL 시 대응:**

| 실패 유형 | 대응 |
|-----------|------|
| 승률 편향 | DPS/방어력/이동속도 파라미터 조정 후 재시뮬레이션 |
| 원거리가 너무 강함 | 원거리 유닛 HP 하향 또는 근거리 이동속도 상향 |
| 전투가 너무 빨리 끝남 | 전체 HP 상향 또는 DPS 하향 |

### 6.3 POC-S3: 대규모 AI 전투

**목적**: 40 유닛 대규모 전투에서 성능과 전투 자연스러움을 동시에 검증한다.

| 항목 | 내용 |
|------|------|
| 유닛 수 | 40 (아군 20 vs 적 20) |
| 유닛 구성 | 근거리 8, 중거리 6, 원거리 6 (양측 동일) |
| 부대 구성 | 아군 3개 부대 (근7+중3, 중3+원3, 근1+원3), 적 3개 부대 |
| 전장 크기 | 1600x1000px |
| 부대 AI | 핀서, 앵커&플랭크, 집중 사격 활성화 |

**테스트 시나리오:**

시나리오 A: 성능 측정
- 40 유닛 전투 10회 실행
- 매 프레임 FPS, AI tick 시간 기록
- 최소 FPS, 평균 FPS, 99th percentile AI tick 시간 집계

시나리오 B: 전투 자연스러움
- 10회 전투를 관전
- 진형 유지 여부, 부대 협동 발생 여부, 전투 흐름 관찰
- 전투 시간, 사상자 수 기록

| 측정 항목 | PASS 기준 |
|-----------|-----------|
| 평균 FPS | 60 이상 |
| 최소 FPS | 45 이상 |
| AI tick 시간 (99th) | 5ms 이하 |
| 전투 시간 | 30-120초 |
| 양측 사상자 | 양측 모두 5명 이상 전사 |
| 진형 유지 | 부대 3개 중 2개 이상이 전투 초반 10초간 진형 유지 |
| 부대 협동 | 10회 중 5회 이상 핀서 또는 플랭크 발동 |

**FAIL 시 대응:**

| 실패 유형 | 대응 |
|-----------|------|
| FPS 45 미만 | LOD AI 적용 범위 확대, AI tick 0.5초로 상향 |
| AI tick 5ms 초과 | 위협 평가 간소화, SpatialHash 셀 크기 최적화 |
| 전투 너무 짧음 | 전체 HP 상향, DPS 하향 |
| 진형 무시 | 진형 복귀 우선순위 상향 |
| 협동 미발동 | 부대 AI 발동 조건 완화 |

### 6.4 POC-S4: 전략적 개입

**목적**: 플레이어의 직접 개입이 전투 결과를 유의미하게 변화시키는지 검증한다.

| 항목 | 내용 |
|------|------|
| 유닛 수 | 40 (20v20), POC-S3과 동일 편성 |
| 통합 대상 | HybridUnitComponent 활용 |
| 입력 | WASD 이동, Space 공격, Q/E 유닛 전환, C 부대 명령 |

**테스트 시나리오:**

시나리오 A: 자동전투 기준선
- 플레이어 입력 없이 50회 전투 자동 실행
- 승률 기록 (양측 동일 스탯이므로 이론적 50%)

시나리오 B: 수동 개입
- 동일 편성으로 50회 전투
- 플레이어가 적극적으로 개입: 후면 기습, 위기 유닛 구출, 부대 명령 변경
- 승률 기록

시나리오 C: 전략적 개입 (방향+상성 활용)
- 50회 전투
- 플레이어가 전략적으로 개입: 원거리 유닛 직접 조작하여 적 후방 이동, 상성 유리한 타겟 집중
- 승률 기록

| 측정 항목 | PASS 기준 |
|-----------|-----------|
| 자동전투 승률 | 40-60% (기준선) |
| 수동 개입 승률 | 자동전투 대비 +15% 이상 |
| 전략적 개입 승률 | 수동 개입 대비 추가 +10% 이상 |
| 개입 체감 | 50회 전투 중 30회 이상에서 플레이어가 자발적으로 수동 모드 전환 (개입 가치를 느끼는 행동 지표) |
| 자동/수동 전환 | 전투 중 전환 시 끊김 없음 |

**FAIL 시 대응:**

| 실패 유형 | 대응 |
|-----------|------|
| 개입 효과 미미 | 방향 보너스 상향 (1.5x -> 1.8x), AI 의도적 약점 추가 |
| 개입 효과 과다 | AI 판단력 강화, 방향 보너스 하향 |
| 전략 개입과 단순 개입 차이 없음 | 상성 배율 상향, 거리 관리 중요도 증가 |
| 전환 끊김 | HybridUnitComponent 전환 로직 최적화 |

---

## 7. 데이터 구조

### 7.1 새로운 상수 및 Enum 정의

```dart
/// 무기 사거리 타입
enum WeaponRange {
  melee,     // 0-60px
  midRange,  // 60-150px
  longRange, // 150-300px
}

/// 공격 방향
enum AttackDirection {
  front,  // 정면: 0~45도
  side,   // 측면: 45~135도
  back,   // 후면: 135~180도
}
```

### 7.2 방향별 데미지 배율

```dart
/// combat_constants.dart에 추가
class DirectionalCombatConstants {
  DirectionalCombatConstants._();

  static const Map<AttackDirection, double> directionMultiplier = {
    AttackDirection.front: 1.0,
    AttackDirection.side: 1.3,
    AttackDirection.back: 1.5,
  };
}
```

### 7.3 상성 배율

```dart
/// combat_constants.dart에 추가
class RangeAdvantageConstants {
  RangeAdvantageConstants._();

  /// 상성 유리 배율 (공격자 무기, 대상 무기)
  static double getAdvantage(WeaponRange attacker, WeaponRange defender) {
    if (attacker == WeaponRange.melee && defender == WeaponRange.longRange) {
      return 1.3; // 근거리 > 원거리
    }
    if (attacker == WeaponRange.midRange && defender == WeaponRange.melee) {
      return 1.2; // 중거리 > 근거리
    }
    if (attacker == WeaponRange.longRange && defender == WeaponRange.midRange) {
      return 1.2; // 원거리 > 중거리
    }
    // 역상성 (불리)
    if (attacker == WeaponRange.longRange && defender == WeaponRange.melee) {
      return 0.8;
    }
    if (attacker == WeaponRange.melee && defender == WeaponRange.midRange) {
      return 0.8;
    }
    if (attacker == WeaponRange.midRange && defender == WeaponRange.longRange) {
      return 0.8;
    }
    return 1.0; // 동일 타입
  }
}
```

### 7.4 사거리별 유닛 프로파일

```dart
/// 사거리 타입별 기본 스탯 프로파일
class WeaponRangeProfile {
  final WeaponRange range;
  final double attackRange;    // 공격 사거리 (px)
  final double optimalRange;   // 최적 교전 거리 (px)
  final double dpsMultiplier;  // DPS 배율
  final double defenseBonus;   // 방어력 보정
  final double speedBonus;     // 이동속도 보정

  const WeaponRangeProfile._({
    required this.range,
    required this.attackRange,
    required this.optimalRange,
    required this.dpsMultiplier,
    required this.defenseBonus,
    required this.speedBonus,
  });

  static const melee = WeaponRangeProfile._(
    range: WeaponRange.melee,
    attackRange: 60,
    optimalRange: 30,
    dpsMultiplier: 1.4,
    defenseBonus: 1.3,
    speedBonus: 1.0,
  );

  static const midRange = WeaponRangeProfile._(
    range: WeaponRange.midRange,
    attackRange: 150,
    optimalRange: 100,
    dpsMultiplier: 1.0,
    defenseBonus: 1.0,
    speedBonus: 1.0,
  );

  static const longRange = WeaponRangeProfile._(
    range: WeaponRange.longRange,
    attackRange: 300,
    optimalRange: 240,
    dpsMultiplier: 0.7,
    defenseBonus: 0.7,
    speedBonus: 1.2,
  );
}
```

### 7.5 확장 UnitStats

기존 `UnitStats` 클래스를 확장하여 전략 전투 정보를 포함한다.

```dart
/// 전략 전투용 확장 스탯
class StrategicUnitStats extends UnitStats {
  final WeaponRange weaponRange;
  final double facingAngle;   // radian, 유닛이 바라보는 방향
  final double attackArc;     // radian, 공격 범위 각도 (기본 pi/2)
  final double optimalRange;  // 최적 교전 거리 (px)

  const StrategicUnitStats({
    required super.attack,
    required super.defense,
    required super.speed,
    required super.luck,
    super.fatigue,
    super.equipmentEvasion,
    super.equipmentCritBonus,
    required this.weaponRange,
    required this.facingAngle,
    this.attackArc = 1.5708, // pi/2 (90도)
    required this.optimalRange,
  });
}
```

---

## 8. 성공 기준 종합

| POC | 핵심 지표 | 목표 | 비고 |
|-----|----------|------|------|
| S1 | 방향 판정 정확도 | 95% 이상 | 40회 테스트 |
| S1 | 방향별 데미지 배율 | 정면 1.0x, 측면 1.3x, 후면 1.5x | 오차 +-2% |
| S1 | AI 측면 기동 | AGGRESSIVE 유닛 50% 이상 시도 | 10회 관찰 |
| S2 | 상성 승률 | 유리 측 60-70% | 100회 시뮬레이션 x3 |
| S2 | 혼합 대전 | 40-60% | 편향 없음 확인 |
| S3 | 평균 FPS | 60 이상 | 40 유닛 전투 |
| S3 | 최소 FPS | 45 이상 | |
| S3 | AI tick 시간 | 5ms 이하 (99th) | |
| S3 | 전투 시간 | 30-120초 | 자연스러운 전투 길이 |
| S3 | 양측 사상자 | 5명 이상 | 일방적이지 않은 전투 |
| S4 | 자동전투 승률 | 40-60% | 기준선 |
| S4 | 수동 개입 효과 | +15% 이상 | 개입 가치 검증 |
| S4 | 전략 개입 효과 | 수동 대비 +10% 이상 | 전략 깊이 검증 |

---

## 9. 리스크 및 대응

| 리스크 | 영향도 | 발생 확률 | 대응 |
|--------|:------:|:--------:|------|
| 40 유닛 시 FPS 저하 | 높음 | 중간 | LOD AI, AI tick 동적 조정, SpatialHash 셀 크기 최적화 |
| 상성 밸런스 붕괴 | 중간 | 높음 | 100회 시뮬레이션 통계 기반 파라미터 조정. 3회 이상 반복 |
| AI가 너무 똑똑함 | 중간 | 낮음 | AI 반응 지연 (0.3초 tick), 시야각 제한 (전방 120도), 의도적 판단 실수 (10%) |
| AI가 너무 멍청함 | 높음 | 중간 | 부대 AI 협동 강화, 위협 평가 가중치 조정, tick 간격 축소 (0.2초) |
| 방향 판정 부자연스러움 | 중간 | 중간 | facing 화살표, 공격 방향 표시기, 데미지 배율 팝업으로 시각적 피드백 |
| 투사체 성능 병목 | 낮음 | 낮음 | ObjectPool 풀 크기 확대, 투사체 수명 제한 (3초) |
| 진형 AI가 전투를 방해 | 중간 | 중간 | 교전 중 진형 우선순위 하향, 교전/진형 가중치 비율 조정 |

---

## 10. 일정

| 단계 | 내용 | 선행 조건 |
|------|------|----------|
| Phase 1 | 방향성 전투 구현 (POC-S1) | POC-T0 Phase 0 완료 |
| Phase 2 | 사거리 체계 + 상성 (POC-S2) | Phase 1 완료 |
| Phase 3 | 대규모 AI 전투 (POC-S3) | Phase 2 완료 |
| Phase 4 | 전략적 개입 통합 (POC-S4) | Phase 3 완료 |

각 Phase는 순차 실행. 이전 Phase PASS 확인 후 다음 Phase 진행.

---

## 11. 관련 문서

| 문서 | 내용 |
|------|------|
| PRD-0001 | Godot 리메이크 기획서. 원작 전투 시스템 참조 |
| PRD-0002 | Flutter 갱신 기획서. 기술 스택 정의 |
| POC-GAMEPLAY-VERIFICATION.md | 현재 채택된 설계 방향. "자동전투 기본 + 직접 개입" |
| FQ4_INTEGRATED_GDD.md | 통합 GDD. Gocha-Kyara 시스템 상세 |
| GDD-0001 | 게임성 설계서. 180개 재미 요소 카탈로그 |

---

## 12. 부록: 기존 시스템과의 통합 포인트

본 POC의 모든 시스템은 **기존 코드를 확장**한다. 기존 클래스의 인터페이스를 변경하지 않으며, 상속 또는 컴포지션으로 기능을 추가한다.

### 12.1 DirectionalCombat -> CombatSystem 확장

```
기존: CombatSystem.calculateDamage(attacker, target) -> DamageResult
확장: StrategicCombatSystem.calculateDamage(attacker, target, direction?) -> DamageResult
```

- `CombatSystem`을 상속하여 `StrategicCombatSystem` 생성
- `calculateDamage()`를 override하여 방향 배율과 상성 배율을 기존 데미지 파이프라인에 추가
- `direction` 파라미터가 없으면 기존 로직과 동일하게 동작 (하위 호환)
- 적용 순서: ATK x 크리티컬 x 분산 - DEF x 피로도 -> **x 방향배율 x 상성배율** -> 최종 데미지

**파일**: `lib/game/systems/strategic_combat_system.dart` (신규)
**의존**: `lib/game/systems/combat_system.dart` (기존, 수정 없음)

### 12.2 WeaponRange -> UnitStats 확장

```
기존: UnitStats(attack, defense, speed, luck, fatigue, ...)
확장: StrategicUnitStats extends UnitStats + weaponRange, facingAngle, optimalRange
```

- `UnitStats`를 상속하여 `StrategicUnitStats` 생성
- 기존 `UnitComponent.toUnitStats()`는 변경 없음
- 새로운 `StrategicUnitComponent`에서 `toStrategicUnitStats()` 추가

**파일**: `lib/game/systems/combat_system.dart` 하단에 `StrategicUnitStats` 추가, 또는 별도 파일
**의존**: `lib/game/systems/combat_system.dart` (기존 UnitStats, 수정 없음)

### 12.3 StrategicAI -> AIBrain 확장

```
기존: AIBrain.update(dt, AIContext) -> AIDecision?
확장: StrategicAIBrain extends AIBrain, AIContext -> StrategicAIContext
```

- `AIBrain`을 상속하여 `StrategicAIBrain` 생성
- 기존 9개 `AIState`는 그대로 유지
- `StrategicAIContext`에 위협 정보, 방향 정보, 무기 타입 추가
- 상태 전이 로직에 전략적 판단 레이어 추가 (위협 평가, 거리 관리, 타겟 우선순위)
- 기존 `_processChase`, `_processAttack` 등을 override하여 전술 행동 추가

**파일**: `lib/game/ai/strategic_ai_brain.dart` (신규)
**의존**: `lib/game/ai/ai_brain.dart` (기존, 수정 없음)

### 12.4 SquadTactics -> Formation/SquadCommand 확장

```
기존: Formation { vShape, line, circle, wedge, scattered }
확장: 기존 enum 유지 + SquadTactics 클래스 신규 (전술 로직 담당)
```

- 기존 `Formation` enum은 변경 없음
- `SquadTactics` 클래스가 진형별 offset 계산, 전투 상황별 자동 전환, 부대 협동 전술 관리
- 기존 `SquadCommand`에 `pincer`, `anchor`, `focusFire` 추가는 POC에서만 사용하고, 본개발 시 반영 결정

**파일**: `lib/game/ai/squad_tactics.dart` (신규)
**의존**: `lib/core/constants/ai_constants.dart` (기존 enum 참조, 수정 없음)

### 12.5 PerformanceMonitor -> SpatialHash 활용

```
기존: SpatialHash.queryRange(x, y, range) -> List<T>
확장: 그대로 활용 + PerformanceMonitor 추가
```

- `SpatialHash`는 수정 없이 그대로 사용
- 셀 크기만 생성 시 파라미터로 조정 (100 -> 150)
- `PerformanceMonitor`가 FPS, AI tick 시간, query 횟수를 측정하는 독립 컴포넌트

**파일**: `lib/game/systems/performance_monitor.dart` (신규)
**의존**: `lib/game/systems/spatial_hash.dart` (기존, 수정 없음)

### 12.6 통합 컴포넌트 계층

```
기존 계층:
UnitComponent -> AIUnitComponent -> HybridUnitComponent

확장 계층:
UnitComponent -> AIUnitComponent -> HybridUnitComponent (기존 유지)
                                 -> StrategicAIUnitComponent (신규, 전략 AI 탑재)
                                    -> StrategicHybridUnitComponent (신규, 전략 AI + 수동 전환)
```

- 기존 컴포넌트 체인은 완전히 보존
- POC-S1~S3은 `StrategicAIUnitComponent` 사용
- POC-S4는 `StrategicHybridUnitComponent` 사용
- 본개발 시 기존 체인과 전략 체인을 통합할지는 POC 결과에 따라 결정

### 12.7 신규 파일 목록 (예상)

| 파일 | 역할 | 의존 대상 |
|------|------|----------|
| `lib/game/systems/strategic_combat_system.dart` | 방향+상성 전투 | combat_system.dart |
| `lib/game/ai/strategic_ai_brain.dart` | 전략 AI | ai_brain.dart |
| `lib/game/ai/squad_tactics.dart` | 부대 전술 | ai_constants.dart |
| `lib/game/ai/threat_evaluator.dart` | 위협 평가 | strategic_combat_system.dart |
| `lib/game/components/units/strategic_unit_component.dart` | 전략 유닛 | unit_component.dart, ai_unit_component.dart |
| `lib/game/systems/performance_monitor.dart` | 성능 측정 | spatial_hash.dart |
| `lib/core/constants/strategic_combat_constants.dart` | 방향/상성 상수 | combat_constants.dart |
| `lib/game/components/projectile_component.dart` | 투사체 | combat_system.dart, PoolManager |
| `lib/poc/poc_s1_direction.dart` | POC-S1 | strategic_combat_system.dart |
| `lib/poc/poc_s2_range_rps.dart` | POC-S2 | strategic_combat_system.dart |
| `lib/poc/poc_s3_mass_battle.dart` | POC-S3 | strategic_ai_brain.dart, squad_tactics.dart |
| `lib/poc/poc_s4_intervention.dart` | POC-S4 | strategic_unit_component.dart, hybrid |

### 12.8 BattleController 통합

```
기존: BattleController.findNearestEnemy(position, range) -> Component?
기존: BattleController.findWoundedAlly(position, range) -> Component?
```

- `BattleController`는 수정 없이 그대로 사용
- `StrategicAIUnitComponent`는 `AIUnitComponent`를 상속하므로 기존 `battleController` 참조를 자동 유지
- 추가적인 전략 탐색 (위협 평가, 타겟 우선순위)은 `ThreatEvaluator`에서 `BattleController`의 유닛 목록을 활용

**의존**: `lib/game/systems/battle_controller.dart` (기존, 수정 없음)

### 12.9 투사체 컴포넌트

원거리 유닛의 투사체는 신규 컴포넌트로 구현한다.

```dart
// 투사체: PositionComponent, 직선 이동, 충돌 시 데미지 적용 후 풀 반환
class ProjectileComponent extends PositionComponent with CollisionCallbacks { ... }
```

- `ObjectPool` (기존 PoolManager)을 활용하여 생성/파괴 비용 제거
- 풀 크기: 원거리 유닛 수 x 3

**파일**: `lib/game/components/projectile_component.dart` (신규)
**의존**: `lib/game/systems/combat_system.dart`, PoolManager

### 12.10 attackRange 변경 사항

기존 `AIUnitComponent._buildContext()`에서 `attackRange: 40.0`으로 하드코딩되어 있음. 전략 전투에서는 `WeaponRangeProfile` 기반 동적 값을 사용:

| 기존 | 근거리 | 중거리 | 원거리 |
|:----:|:-----:|:-----:|:-----:|
| 40px | 60px | 150px | 300px |

`StrategicAIUnitComponent`에서 `_buildContext()` override로 동적 `attackRange` 적용.

### 12.11 단위 테스트 계획

기존 193개 테스트를 보존하며, 신규 시스템에 대한 단위 테스트를 추가한다.

| 테스트 대상 | 파일 | 최소 테스트 수 |
|------------|------|:------------:|
| 방향 판정 각도 계산 | `test/game/systems/directional_combat_test.dart` | 12 |
| 상성 배율 반환값 | `test/game/systems/range_advantage_test.dart` | 9 |
| 위협 평가 점수 | `test/game/ai/threat_evaluator_test.dart` | 8 |
| 진형 offset 계산 | `test/game/ai/squad_tactics_test.dart` | 10 |
| 전략 AI 상태 전이 | `test/game/ai/strategic_ai_brain_test.dart` | 15 |
| 투사체 이동/충돌 | `test/game/components/projectile_test.dart` | 6 |

**원칙**: 기존 파일 수정 0건. 모든 변경은 신규 파일에서 상속/컴포지션으로 구현.
