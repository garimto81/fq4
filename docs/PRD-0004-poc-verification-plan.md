# PRD-0004: First Queen 4 HD Renewal - POC 검증 계획서

**Version**: 1.0.0 | **Date**: 2026-02-15 | **Status**: Draft
**기반 문서**: GDD-0001 (채택), PRD-0003 (폐기)

---

## 1. 문서 목적 및 방향 선언

본 문서는 GDD-0001에 정의된 180개 재미 요소를 본개발 이전에 체계적으로 검증하기 위한 POC 계획서다. 각 재미 요소에 대해 POC 검증 필요 여부를 판단하고, 필요한 경우 구체적인 테스트 시나리오와 PASS/FAIL 기준을 정의한다.

**방향 선언:**

- **GDD-0001 채택**: 실시간 직접 조작 전술 RPG. 플레이어가 주인공 아레스를 WASD/게임패드로 직접 조작하고, 부대원은 AI가 자동 제어하는 Gocha-Kyara 시스템을 핵심으로 한다.
- **PRD-0003 폐기**: 방치형 자동전투 방향 전면 폐기. `is_player_controlled = false` 전제, 세로 모드, 오프라인 보상, 소탕/스킵 등 방치형 전용 시스템은 모두 제거한다.
- **기존 자동전투 코드**: 게임의 핵심이 아닌 "편의 옵션"으로 유지. 레벨링/반복 전투 시 선택적 사용.

### 1.1 방향 전환 요약

| 항목 | PRD-0003 (폐기) | 본 PRD (채택) |
|------|----------------|--------------|
| 게임 정체성 | 방치형 자동전투 RPG | 직접 조작 전술 RPG |
| 핵심 입력 | 편성만 (20% 조작) | WASD 직접 조작 (80% 조작) |
| 주인공 직접 제어 | false (`is_player_controlled = false`) | true (기본 수동 조작) |
| 화면 방향 | 세로 (800x1280) | 가로 (1280x800) |
| 전투 진행 | 완전 자동 + 배속/스킵 | 실시간 직접 전투 |
| 방치 시스템 | 오프라인 보상/소탕/자동루프 | 없음 (순수 게임) |
| POC 초점 | Rive + 자동전투 기술 검증 | 조작감 + 전투 재미 검증 |

### 1.2 사전 결정 사항 (Critic 피드백 반영)

| 결정 사항 | 내용 | 근거 |
|-----------|------|------|
| **화면 모드** | 가로(1280x800) 고정 | 모든 POC를 가로 모드로 수행. 세로 모드 적응은 본개발에서 처리 |
| **Rive 전략** | Windows에서 Custom Paint/fallback 사용 | Rive 네이티브 플러그인이 Windows에서 segfault 유발. Rive 통합은 Android에서 별도 검증 (POC-T3-01) |
| **POC 구현 위치** | 기존 `fq4_game.dart` 수정 방식 | poc1~poc5는 레거시로 유지하되 수정하지 않음. 새 POC는 `fq4_game.dart` + 전용 씬(`lib/game/scenes/poc/`)에 구현 |
| **히트스톱 구현** | 개별 유닛 레벨 `hitStopTimer` 패턴 | Flame 게임 루프 비파괴. `FlameGame.paused` 대신 유닛별 타이머로 정지 |

### 1.3 기존 코드 자산 평가

#### 기존 POC 재사용 가치

| POC | 파일 | 검증 내용 | 재사용 가치 | 사유 |
|-----|------|----------|:-----------:|------|
| POC-1 | `poc1_rive_test.dart` | Rive + Flame 통합 | 낮음 | Rive 비활성화 상태, fallback 렌더러만 동작 |
| POC-2 | `poc2_autobattle_test.dart` | AI 자동전투 | 중간 | AI 상태머신 검증 완료, 직접 조작 모드로 전환 필요 |
| POC-3 | `poc3_layout_test.dart` | 세로 모드 레이아웃 | 낮음 | 가로 모드로 전환 |
| POC-4 | `poc4_speed_test.dart` | 배속 시스템 | 중간 | 자동전투 편의 옵션으로 활용 가능 |
| POC-5 | `poc5_integrated_battle.dart` | 통합 전투 | 중간 | 전투 파이프라인은 유지, 입력 체계만 전환 |

#### 재사용 가능한 시스템 파일 (14개, 전체 193/193 테스트 통과)

| 파일 | 용도 | 테스트 상태 |
|------|------|:----------:|
| `ai_brain.dart` | AI 상태머신 9개 + 성격 3종 + 부대 명령 | PASS |
| `combat_system.dart` | 데미지/명중/회피 공식 | PASS |
| `fatigue_system.dart` | 피로도 4단계 | PASS |
| `magic_system.dart` | 마법 8종 | PASS |
| `status_effect_system.dart` | 상태이상 6종 | PASS |
| `environment_system.dart` | 환경 지형 6종 | PASS |
| `experience_system.dart` | 경험치/레벨업 | PASS |
| `equipment_system.dart` | 장비 시스템 | PASS |
| `inventory_system.dart` | 인벤토리 | PASS |
| `shop_system.dart` | 상점 | PASS |
| `achievement_system.dart` | 업적 28개 | PASS |
| `ending_system.dart` | 엔딩 3종 | PASS |
| `newgame_plus_system.dart` | NG+ | PASS |
| `spatial_hash.dart` | 공간 분할 해시맵 | PASS |

### 1.4 Rive 제약

Rive 네이티브 C++ 라이브러리(`rive_common`)가 현재 Windows 환경에서 segmentation fault를 유발한다. `pubspec.yaml`에서 `rive`/`flame_rive` 패키지를 주석 처리한 상태이며, `rive_unit_renderer.dart`의 fallback 렌더러(Custom Paint 원형)를 사용한다. 모든 POC는 이 fallback 렌더러 기반으로 진행하고, Rive 실제 통합은 Android 환경에서 POC-T3-01로 별도 검증한다.

---

## 2. 180개 재미 요소 - POC 매핑 전체표

### 카테고리 커버리지 요약

| 카테고리 | 코드 | 총 요소 | POC 검증 | POC 불필요 | 커버율 |
|---------|------|:-------:|:--------:|:----------:|:------:|
| A. 직접 조작 | ACT | 30 | 20 | 10 | 67% |
| B. 부대 지휘 | CMD | 28 | 18 | 10 | 64% |
| C. 전투 역학 | BTL | 32 | 18 | 14 | 56% |
| D. RPG 성장 | RPG | 30 | 8 | 22 | 27% |
| E. 탐색/스토리 | ADV | 25 | 4 | 21 | 16% |
| F. 감각/연출 | SEN | 20 | 7 | 13 | 35% |
| G. 시스템/편의 | SYS | 15 | 1 | 14 | 7% |
| **합계** | | **180** | **76** | **104** | **42%** |

**POC 불필요 104개 근거 분류:**

| 분류 | 수량 | 설명 |
|------|:----:|------|
| 기존 코드 테스트 통과 | 38 | 시스템 레벨 로직이 193/193 테스트에서 검증 완료 |
| UI/위젯 (게임플레이 무관) | 24 | HUD, 아이콘, 메뉴 등 시각 요소는 본개발에서 구현 |
| 콘텐츠/데이터 (기술 리스크 없음) | 22 | 스토리 텍스트, 챕터 데이터, 번역 등 데이터 입력 작업 |
| 상위 POC에서 간접 검증 | 12 | 예: ACT-04 이동공격은 ACT-01(이동) + ACT-02(공격) 조합 |
| 표준 엔진 기능 | 8 | 세이브/로드, 일시정지, 설정 등 Flame/Flutter 기본 기능 |

### 2.1 A. 직접 조작 (ACT: 30개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| ACT-01 | 이동 반응성 | POC-T0-01 | WASD 입력 지연 50ms 측정 |
| ACT-02 | 공격 타격감 | POC-T0-02 | A/B/C 비교 (기본/중간/풀) |
| ACT-03 | 공격 후 경직 | POC-T0-02 | 경직 0.3초 리듬감 확인 |
| ACT-04 | 이동 공격 | POC 불필요 | ACT-01 + ACT-02 기반 확장 |
| ACT-05 | 대시/회피 | POC 불필요 | 본개발 액션 확장 |
| ACT-06 | 마법 시전 | POC-T2-01 | 화염구 직접 시전 테스트 |
| ACT-07 | 아이템 사용 | POC 불필요 | inventory_system 테스트 통과 |
| ACT-08 | 조작감 일관성 | POC-T0-01 | 게임패드/키보드 지연 비교 |
| ACT-09 | 부대원 전환 | POC-T1-01 | Q/E 키 부대내 전환 |
| ACT-10 | 부대 전환 | POC-T1-01 | Tab 키 부대간 전환 |
| ACT-11 | 전환 즉시성 | POC-T1-01 | 전환 후 0.3초 내 조작 가능 |
| ACT-12 | 전환 전략 | POC 불필요 | T1-01 전환 기능 기반 응용 |
| ACT-13 | 리더 효과 | POC-T1-01 | 조작 유닛 변경 시 FOLLOW 유지 |
| ACT-14 | 멀티 부대 전환 | POC 불필요 | T1-01 부대 전환 기반 응용 |
| ACT-15 | 가상 조이스틱 | POC-T2-02 | Flame JoystickComponent |
| ACT-16 | 공격 버튼 | POC-T2-02 | 터치 공격 버튼 |
| ACT-17 | 스킬 버튼 | POC 불필요 | UI 위젯 (게임플레이 무관) |
| ACT-18 | 탭 타겟팅 | POC-T2-02 | 적 유닛 탭으로 타겟 지정 |
| ACT-19 | 핀치 줌 | POC 불필요 | 표준 Flutter 제스처 |
| ACT-20 | 드래그 카메라 | POC 불필요 | 표준 Flutter 제스처 |
| ACT-21 | 부대 전환 스와이프 | POC-T2-02 | 스와이프로 유닛 전환 |
| ACT-22 | 명령 휠 | POC-T2-02 | 길게 누르기 방사형 메뉴 |
| ACT-23 | 키보드+마우스 | POC 불필요 | 표준 입력, T0-01에서 간접 검증 |
| ACT-24 | 게임패드 | POC-T0-01 | 좌스틱 이동, A 공격 |
| ACT-25 | 입력 자동 감지 | POC 불필요 | Flutter 표준 기능 |
| ACT-26 | 버튼 프롬프트 | POC 불필요 | UI 위젯 |
| ACT-27 | 키 리매핑 | POC 불필요 | 설정 UI |
| ACT-28 | 자동전투 토글 | POC-T1-04 | AUTO 버튼 ON/OFF |
| ACT-29 | 자동전투 중 개입 | POC-T1-04 | WASD 입력으로 즉시 수동 복귀 |
| ACT-30 | 배속 (자동전투 전용) | POC 불필요 | POC-4에서 검증 완료 |

### 2.2 B. 부대 지휘 (CMD: 28개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| CMD-01 | V자 대형 | POC-T1-02 | 4v4 전투 관찰 |
| CMD-02 | LINE 횡대 | POC-T1-02 | 4v4 전투 관찰 |
| CMD-03 | CIRCLE 원형 | POC-T1-02 | 4v4 전투 관찰 |
| CMD-04 | WEDGE 쐐기 | POC-T1-02 | 4v4 전투 관찰 |
| CMD-05 | SCATTERED 분산 | POC-T1-02 | 4v4 전투 관찰 |
| CMD-06 | 대형 전환 즉시성 | POC-T1-02 | 전환 후 2초 내 재배치 |
| CMD-07 | 대형 유지력 | POC-T1-02 | 이동 중 대형 유지 관찰 (부가 기록) |
| CMD-08 | 대형 시각 표시 | POC 불필요 | UI 위젯 |
| CMD-09 | 추종 (FOLLOW) | POC-T1-03 | 명령 순환 테스트 |
| CMD-10 | 전원 공격 (ATTACK_ALL) | POC-T1-03 | 명령 순환 테스트 |
| CMD-11 | 위치 사수 (HOLD) | POC-T1-03 | 명령 순환 테스트 |
| CMD-12 | 전원 후퇴 (RETREAT) | POC-T1-03 | 명령 순환 테스트 |
| CMD-13 | 전원 휴식 (REST) | POC-T1-03 | 명령 순환 테스트 |
| CMD-14 | 분산 (SPREAD) | POC 불필요 | CMD-05 SCATTERED와 동일 |
| CMD-15 | 명령 즉시 반응 | POC-T1-03 | 명령 후 0.5초 내 행동 변경 |
| CMD-16 | 명령 아이콘 | POC 불필요 | UI 위젯 |
| CMD-17 | AGGRESSIVE 유닛 | POC-T0-03 | 3v3 관전 행동 차이 |
| CMD-18 | DEFENSIVE 유닛 | POC-T0-03 | 3v3 관전 행동 차이 |
| CMD-19 | BALANCED 유닛 | POC-T0-03 | 3v3 관전 행동 차이 |
| CMD-20 | 성격 시각 표시 | POC 불필요 | UI 위젯 |
| CMD-21 | 성격별 대사 | POC 불필요 | 콘텐츠 데이터 |
| CMD-22 | 부대 편성 | POC 불필요 | UI 화면 (게임플레이 무관) |
| CMD-23 | 부대 전환 | POC-T1-01 | Tab 키 부대간 전환 |
| CMD-24 | 다중 부대 작전 | POC 불필요 | T1-01 부대 전환 기반 응용 |
| CMD-25 | 부대 상태 HUD | POC 불필요 | UI 위젯 |
| CMD-26 | NPC 부대 | POC 불필요 | 콘텐츠 데이터 |
| CMD-27 | 부대 분리/합류 | POC 불필요 | game_manager 확장 |
| CMD-28 | 전투 후 부대 정리 | POC 불필요 | UI 화면 |

### 2.3 C. 전투 역학 (BTL: 32개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| BTL-01 | 실시간 긴장 | POC-T0-04 | 수동 vs 자동 승률 비교 |
| BTL-02 | 수적 우위/열세 | POC-T0-04 | 3 vs 5 수적 열세 전투 |
| BTL-03 | 시소 전투 | POC-T0-04 | HP 오가는 교전 관찰 |
| BTL-04 | 위기 탈출 | POC 불필요 | T0-04 전투에서 자연 발생 |
| BTL-05 | 적 증원 | POC 불필요 | 스폰 로직 단순 |
| BTL-06 | 아군 사망 | POC-T0-04 | 동료 사망 시 전력 약화 관찰 |
| BTL-07 | 주인공 사망 위기 | POC-T0-04 | 주인공 사망 = GAME OVER 처리 |
| BTL-08 | 보스 페이즈 전환 | POC 불필요 | boss_unit_component 구현 완료 |
| BTL-09 | 피로 누적 체감 | POC-T1-05 | 3연전 피로 누적 |
| BTL-10 | TIRED 상태 | POC-T1-05 | 속도 -20% 체감 |
| BTL-11 | EXHAUSTED 상태 | POC-T1-05 | 속도 -50% 체감 |
| BTL-12 | COLLAPSED 위기 | POC-T1-05 | 행동 정지 확인 |
| BTL-13 | 휴식 판단 | POC-T1-05 | 전투간 휴식 전략 |
| BTL-14 | 피로 회복 아이템 | POC 불필요 | fatigue_system 테스트 통과 |
| BTL-15 | 페어리 샘 | POC 불필요 | 콘텐츠 데이터 |
| BTL-16 | 피로 시각화 | POC-T1-05 | FT 바 색상 변화 |
| BTL-17 | 마법 시전 | POC-T2-01 | 화염구 직접 시전 |
| BTL-18 | MP 관리 | POC 불필요 | magic_system 테스트 통과 |
| BTL-19 | 화염구 | POC-T2-01 | 범위 60px 전원 데미지 |
| BTL-20 | 힐 | POC-T2-01 | AI 자동 치유 |
| BTL-21 | 버프/디버프 | POC 불필요 | status_effect_system 테스트 통과 |
| BTL-22 | AI 자동 마법 | POC-T2-01 | 힐러 AI 자동 치유 관찰 |
| BTL-23 | 마법 이펙트 | POC 불필요 | 시각 연출, 본개발 |
| BTL-24 | 독 | POC 불필요 | status_effect_system 테스트 통과 |
| BTL-25 | 화상 | POC 불필요 | status_effect_system 테스트 통과 |
| BTL-26 | 스턴 | POC-T2-03 | 3초 행동 불가 검증 |
| BTL-27 | 동결 | POC 불필요 | status_effect_system 테스트 통과 |
| BTL-28 | 물 지형 | POC 불필요 | environment_system 테스트 통과 |
| BTL-29 | 독 지형 | POC 불필요 | environment_system 테스트 통과 |
| BTL-30 | 어둠 지형 | POC-T2-03 | 감지 범위 50% 감소 검증 |
| BTL-31 | 지형 활용 전략 | POC 불필요 | T2-03에서 간접 검증 |
| BTL-32 | 보스 특수 공격 | POC 불필요 | boss_unit_component 구현 완료 |

### 2.4 D. RPG 성장 (RPG: 30개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| RPG-01 | 경험치 획득 | POC-T2-04 | 적 처치 후 EXP 획득 |
| RPG-02 | 레벨업 | POC-T2-04 | EXP 충족 후 레벨 UP |
| RPG-03 | 레벨업 연출 | POC 불필요 | 시각 연출, 본개발 |
| RPG-04 | 스탯 성장 표시 | POC-T2-04 | HP+15, ATK+2 표시 |
| RPG-05 | 레벨 격차 체감 | POC-T2-04 | Lv1/3/5 DPS 비교 |
| RPG-06 | 스킬 습득 | POC 불필요 | experience_system 확장 |
| RPG-07 | 부대원 성장 | POC-T2-04 | 부대원 EXP 획득 확인 |
| RPG-08 | 무기 교체 | POC-T2-05 | 강화무기 데미지 비교 |
| RPG-09 | 방어구 교체 | POC 불필요 | equipment_system 테스트 통과 |
| RPG-10 | 액세서리 | POC 불필요 | equipment_system 테스트 통과 |
| RPG-11 | 장비 비교 | POC 불필요 | UI 화면 |
| RPG-12 | 전투 중 아이템 | POC-T2-05 | HP 포션 사용 + 회복 팝업 |
| RPG-13 | 보물 상자 | POC 불필요 | 콘텐츠 데이터 |
| RPG-14 | 상점 | POC 불필요 | shop_system 테스트 통과 |
| RPG-15 | 골드 경제 | POC 불필요 | shop_system 테스트 통과 |
| RPG-16 | 마법 습득 | POC 불필요 | 콘텐츠 데이터 |
| RPG-17 | 마법 슬롯 | POC 불필요 | UI 위젯 |
| RPG-18 | 마법 선택 전략 | POC 불필요 | T2-01에서 간접 검증 |
| RPG-19 | 엔딩 분기 | POC 불필요 | ending_system 구현+테스트 완료 |
| RPG-20 | NG+ | POC 불필요 | newgame_plus_system 구현+테스트 완료 |
| RPG-21 | 업적 28개 | POC 불필요 | achievement_system 구현+테스트 완료 |
| RPG-22 | 숨겨진 보스 | POC 불필요 | 콘텐츠 데이터 |
| RPG-23 | 도전 모드 | POC 불필요 | 콘텐츠 데이터 |
| RPG-24 | 전투력 상한 | POC 불필요 | experience_system 수치 검증 |
| RPG-25 | 레벨별 능력치 곡선 | POC 불필요 | experience_system 테스트 통과 |
| RPG-26 | 적 레벨 스케일링 | POC 불필요 | 밸런스 데이터 |
| RPG-27 | 전투 보상 골드 | POC 불필요 | combat_system 테스트 통과 |
| RPG-28 | 장비 강화 | POC 불필요 | equipment_system 확장 |
| RPG-29 | 아이템 드롭 | POC 불필요 | 콘텐츠 데이터 |
| RPG-30 | 인벤토리 관리 | POC 불필요 | inventory_system 테스트 통과 |

### 2.5 E. 탐색/스토리 (ADV: 25개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| ADV-01 | 자유 이동 | POC-T2-06 | Tiled 맵에서 자유 이동 |
| ADV-02 | 비밀 통로 | POC 불필요 | 콘텐츠 데이터 |
| ADV-03 | 보물 발견 | POC 불필요 | 콘텐츠 데이터 |
| ADV-04 | NPC 대화 | POC 불필요 | dialogue_system 구현 완료 |
| ADV-05 | 지형 다양성 | POC 불필요 | 콘텐츠 데이터 |
| ADV-06 | 미니맵 | POC-T2-06 | 미니맵 렌더링 + 유닛 표시 |
| ADV-07 | 맵 전환 | POC 불필요 | chapter_manager 구현 완료 |
| ADV-08 | 메인 스토리 | POC 불필요 | 콘텐츠 데이터 |
| ADV-09 | 대화 시스템 | POC-T3-02 | 텍스트 박스 + 초상화 + 타이핑 |
| ADV-10 | 대화 선택지 | POC 불필요 | dialogue_system 확장 |
| ADV-11 | 이벤트 트리거 | POC 불필요 | event_system 구현 완료 |
| ADV-12 | 동료 합류 | POC 불필요 | 콘텐츠 데이터 |
| ADV-13 | 챕터 전환 연출 | POC 불필요 | 시각 연출, 본개발 |
| ADV-14 | 수비 전투 | POC 불필요 | 콘텐츠 데이터 |
| ADV-15 | 돌파 전투 | POC 불필요 | 콘텐츠 데이터 |
| ADV-16 | 매복 전투 | POC 불필요 | 콘텐츠 데이터 |
| ADV-17 | 보스 전투 | POC 불필요 | boss_unit_component 구현 완료 |
| ADV-18 | 부대 합류 전투 | POC 불필요 | game_manager 확장 |
| ADV-19 | 로그리스 대륙 | POC 불필요 | 콘텐츠 데이터 |
| ADV-20 | 왕국/세력 | POC 불필요 | 콘텐츠 데이터 |
| ADV-21 | 캐릭터 관계 | POC 불필요 | dialogue_data 구현 완료 |
| ADV-22 | 적대 인물 | POC 불필요 | 콘텐츠 데이터 |
| ADV-23 | 엔딩 감동 | POC 불필요 | 콘텐츠 데이터 |
| ADV-24 | 메시지 799개 | POC 불필요 | 콘텐츠 데이터 (복호화 완료) |
| ADV-25 | 다국어 | POC 불필요 | localization_manager 구현 완료 |

### 2.6 F. 감각/연출 (SEN: 20개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| SEN-01 | Rive 캐릭터 | POC-T3-01 | Android에서 Rive State Machine |
| SEN-02 | 캐릭터 모션 | POC-T3-01 | idle/walk/attack/hurt/die 전환 |
| SEN-03 | HD 배경 | POC 불필요 | 아트 에셋, 게임플레이 무관 |
| SEN-04 | 파티클 이펙트 | POC 불필요 | 시각 연출, 본개발 |
| SEN-05 | 날씨/조명 | POC 불필요 | 시각 연출, 본개발 |
| SEN-06 | 카메라 연출 | POC 불필요 | game_camera 확장 |
| SEN-07 | 히트 플래시 | POC-T3-03 | 피격 시 흰색 깜빡임 |
| SEN-08 | 히트스톱 | POC-T3-03 | 타격 순간 2프레임 정지 |
| SEN-09 | 넉백 | POC 불필요 | T0-02에서 간접 검증 |
| SEN-10 | 카메라 쉐이크 | POC 불필요 | T0-02에서 간접 검증 |
| SEN-11 | 데미지 팝업 | POC-T3-03 | 숫자 팝업 + 크리티컬 구분 |
| SEN-12 | 전투 BGM | POC 불필요 | 오디오 에셋, 게임플레이 무관 |
| SEN-13 | 타격음 | POC 불필요 | 오디오 에셋 |
| SEN-14 | 사망 효과음 | POC 불필요 | 오디오 에셋 |
| SEN-15 | UI 효과음 | POC 불필요 | 오디오 에셋 |
| SEN-16 | 환경음 | POC 불필요 | 오디오 에셋 |
| SEN-17 | HP 바 애니메이션 | POC-T3-03 | HP 바 부드러운 감소 (lerp) |
| SEN-18 | 레벨업 이펙트 | POC 불필요 | 시각 연출, 본개발 |
| SEN-19 | 전투 시작 연출 | POC 불필요 | 시각 연출, 본개발 |
| SEN-20 | 승리/패배 연출 | POC 불필요 | 시각 연출, 본개발 |

### 2.7 G. 시스템/편의 (SYS: 15개)

| ID | 요소 | POC ID | 검증 방법 |
|----|------|--------|----------|
| SYS-01 | 세이브/로드 | POC 불필요 | save_system 구현+테스트 완료 |
| SYS-02 | 설정 | POC 불필요 | 표준 Flutter 설정 UI |
| SYS-03 | 가로/세로 모드 | POC 불필요 | 가로 고정 결정 (1.2절), 세로 적응은 본개발 |
| SYS-04 | 일시정지 | POC 불필요 | 표준 Flame 기능 |
| SYS-05 | 미니맵 | POC 불필요 | minimap.dart 구현 완료 |
| SYS-06 | 튜토리얼 | POC 불필요 | 콘텐츠 데이터 |
| SYS-07 | 도감 | POC 불필요 | UI 화면 |
| SYS-08 | 전투 기록 | POC 불필요 | battle_controller 로그 구현 완료 |
| SYS-09 | 키 리매핑 | POC 불필요 | 설정 UI |
| SYS-10 | 색맹 모드 | POC 불필요 | accessibility_system 구현 완료 |
| SYS-11 | 폰트 크기 | POC 불필요 | accessibility_system 구현 완료 |
| SYS-12 | 게임 속도 | POC 불필요 | POC-4에서 검증 완료 |
| SYS-13 | 스크린샷 | POC 불필요 | 표준 플랫폼 기능 |
| SYS-14 | 클래식 모드 | POC 불필요 | 설정 옵션 |
| SYS-15 | 크로스 플랫폼 세이브 | POC 불필요 | 본개발 후반 |

---

## 3. POC 상세 정의

### Phase 0: 핵심 게임 필 (3일) - 실패 시 전체 재설계

Phase 0는 게임의 존재 이유를 검증한다. "내가 직접 해야 결과가 달라진다"라는 핵심 체감이 확인되지 않으면 전체 설계를 재검토한다.

---

#### POC-T0-01: 조작 반응성

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-01 (이동 반응성), ACT-08 (조작감 일관성), ACT-24 (게임패드) |
| **공수** | 0.5일 |
| **의존성** | 없음 |
| **Tier** | Tier 0 (핵심) |

**테스트 시나리오:**
- 가로 모드 1280x800에서 아레스를 WASD로 이동
- Space 키로 공격
- 게임패드 좌스틱 이동 + A 버튼 공격
- `Stopwatch` 기반 자동 측정: `KeyDownEvent` 수신 시각 ~ `position` 변경 시각 차이

**PASS 기준:**
- 이동 입력 후 50ms 이내 캐릭터 이동 시작
- 공격 버튼 후 100ms 이내 공격 모션 시작
- 방향 전환 즉각 반영 (30ms 이내)
- 게임패드와 키보드 반응 차이 10ms 이하

**FAIL 시 대응:**
- 입력 버퍼링 도입 (1프레임 선행 입력 저장)
- `RawKeyboardListener` 직접 사용 (Flutter 이벤트 우회)
- Flame `update()` 주기 최적화

**기술 접근:**
- `player_unit_component.dart` 수정: 게임패드 입력 통합
- `Stopwatch` 클래스로 입력~반응 시간 자동 로깅
- 측정 결과를 콘솔 출력 (100회 평균)

---

#### POC-T0-02: 공격 타격감

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-02 (공격 타격감), ACT-03 (공격 후 경직) |
| **공수** | 1일 |
| **의존성** | T0-01 |
| **Tier** | Tier 0 (핵심) |

**테스트 시나리오:**
A/B/C 3단계 비교:

| 단계 | 구성 | 기대 체감 |
|------|------|----------|
| (A) 기본 | 데미지 숫자만 표시 | 밋밋함 |
| (B) 중간 | + 히트 플래시(흰색 0.1초) + 넉백(5px) | 때리는 느낌 |
| (C) 풀 | + 히트스톱(2프레임, 개별 유닛 `hitStopTimer`) + 카메라 흔들림(2px, 0.1초) + 경직 0.3초 | 확실한 타격감 |

**PASS 기준:**
- (C) 단계에서 타격감이 확실히 체감됨
- 경직 0.3초 동안 이동 제한이 리듬감을 생성
- 60FPS 유지 (히트스톱이 프레임 드롭을 유발하지 않음)

**FAIL 시 대응:**
- 히트스톱 프레임 수 조정 (1~5프레임)
- 경직 시간 조정 (0.2~0.5초)
- 넉백 거리 조정 (3~10px)

**기술 접근:**
- `unit_component.dart`에 `attackLockout` (경직 타이머) 추가
- `unit_component.dart`에 `hitStopTimer` (개별 유닛 히트스톱) 추가
- `rive_unit_renderer.dart`에 `flashTimer` (히트 플래시) 추가
- `game_camera.dart`에 `shake()` 메서드 추가

**NOTE (Architect):** 배속(4x)과 히트스톱 상호작용 테스트 포함. 배속 시 히트스톱 지속 시간도 배속 역수로 축소되는지 확인.

---

#### POC-T0-03: AI 성격 행동 차이

| 항목 | 내용 |
|------|------|
| **검증 요소** | CMD-17 (AGGRESSIVE), CMD-18 (DEFENSIVE), CMD-19 (BALANCED) |
| **공수** | 0.5일 |
| **의존성** | 없음 |
| **Tier** | Tier 0 (핵심) |

**테스트 시나리오:**
- 3v3 관전 모드: AGGRESSIVE(빨강)/BALANCED(노랑)/DEFENSIVE(파랑) 아군 3체 vs 적 3체
- 플레이어 개입 없이 AI만으로 10회 관찰
- 각 유닛의 최초 교전 시점, 리더와의 평균 거리, 전투 적극성 기록

**PASS 기준:**
- 5초 관찰로 각 유닛의 성격을 맞출 수 있음
- AGGRESSIVE 유닛이 가장 먼저 교전 시작
- 최초 교전 시간차 AGGRESSIVE vs DEFENSIVE 2초 이상

**FAIL 시 대응:**
- 성격 파라미터 편차 확대 (`chase_range_mult`, `retreat_hp_mult` 조정)
- AGGRESSIVE의 공격 개시 거리 확대 (150px -> 250px)
- DEFENSIVE의 후퇴 HP 임계값 상향 (39% -> 50%)

**기술 접근:**
- `ai_brain.dart`의 기존 성격 시스템 활용 (수정 불필요)
- 색상 코드: AGGRESSIVE=빨강(0xFFFF4444), BALANCED=노랑(0xFFFFCC44), DEFENSIVE=파랑(0xFF4488FF)
- 콘솔에 교전 시점 로그 출력

---

#### POC-T0-04: 실시간 전투 긴장감

| 항목 | 내용 |
|------|------|
| **검증 요소** | BTL-01 (실시간 긴장), BTL-02 (수적 열세), BTL-03 (시소 전투), BTL-06 (아군 사망), BTL-07 (주인공 사망 위기) |
| **공수** | 1일 |
| **의존성** | T0-01, T0-02 |
| **Tier** | Tier 0 (핵심) |

**측정 프로토콜 (Critic 피드백 반영):**

고정 시나리오:
- 아군: 아레스 Lv5 (HP100, ATK25) + 타로 Lv3 (HP80, ATK20) + 엘레인 Lv3 (HP60, ATK15)
- 적: 고블린 5체 Lv3 (HP40, ATK12)
- 시드 고정: `Random(42)` 기반 적 배치/AI 랜덤

측정 방법:

| 모드 | 실행 | 메트릭 |
|------|------|--------|
| 자동전투 | 50회 시뮬레이션 (`is_player_controlled = false`) | 승률, 평균 사상자, 평균 전투시간 |
| 수동 조작 | 10회 직접 플레이 | 승률, 평균 사상자, 평균 전투시간 |

**PASS 기준:**
- 수동 승률 - 자동 승률 >= 20% **OR** 수동 평균 생존자 - 자동 평균 생존자 >= 1.0명
- 주인공(아레스) 사망 시 GAME OVER 처리 확인
- "내가 직접 해야 결과가 달라진다" 체감

**FAIL 시 대응:**
- 적 AI 파라미터 조정 (감지 범위, 공격 빈도)
- 직접 조작 유닛 미세 보너스 (회피+5%, 크리+3%)
- 수적 균형 재조정 (3v4 또는 4v5)

**기술 접근:**
- `fq4_game.dart` 수정: 고정 시나리오 스폰 함수
- `battle_controller.dart` 수정: 웨이브 통계 수집 (승패, 생존자 수, 전투 시간)
- 자동전투 시뮬레이션: 게임 루프 50회 반복 (headless 가능)
- 주인공 사망 감지: `game_manager.dart`에서 주인공 사망 시 `GameState.gameOver` 전환

---

### Phase 1: 전술 재미 (5.5일) - Gocha-Kyara 핵심

Phase 1은 "부대장으로서의 재미"를 검증한다. 대형, 명령, 전환, 피로도가 전투에 의미 있는 영향을 주지 않으면 전술 파라미터를 재설계한다.

---

#### POC-T1-01: 유닛/부대 전환

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-09 (부대원 전환), ACT-10 (부대 전환), ACT-11 (전환 즉시성), ACT-13 (리더 효과), CMD-23 (부대 전환) |
| **공수** | 1일 |
| **의존성** | T0-01 |
| **Tier** | Tier 1 (전술) |

**테스트 시나리오:**
- 2부대 구성:
  - 부대1: 아레스(전사) + 타로(마법사) + 엘레인(힐러)
  - 부대2: 시누세(전사) + 소토카(힐러) + 마키(궁수)
- Q/E: 같은 부대 내 유닛 전환
- Tab: 부대간 전환

**PASS 기준:**
- 전환 후 0.3초 이내 새 유닛 조작 가능
- 카메라 0.2초 lerp로 부드러운 전환
- 전환 중 게임 정지 없음 (전투 계속 진행)
- 전환된 유닛에서 이전 조작 유닛은 자동 AI 모드 전환
- FOLLOW 상태 유지 (전환 후 부대원이 새 리더를 추종)

**FAIL 시 대응:**
- 카메라 전환 속도 조정 (0.1~0.5초 lerp)
- AI 모드 전환 지연 제거 (즉시 전환)

**기술 접근:**
- `game_manager.dart` 수정: 유닛/부대 전환 고도화 (AI 모드 자동 전환)
- `game_camera.dart` 수정: `smoothFollow()` lerp 전환 (0.2초 목표)
- `game_input_handler.dart` 수정: Q/E/Tab 키 바인딩 연결

---

#### POC-T1-02: 대형 전투 영향

| 항목 | 내용 |
|------|------|
| **검증 요소** | CMD-01~06 (대형 5종 + 전환), CMD-07 (대형 유지력, 관찰 기록) |
| **공수** | 2일 (Architect 권고: 1.5일 -> 2일, `formation_calculator` 신규 작성) |
| **의존성** | T0-03 |
| **Tier** | Tier 1 (전술) |

**테스트 시나리오:**
- 4v4 전투, 각 대형 5회씩 총 25회
- 측정: 전투 시간, 사상자 수, 총 HP 소모량

| 대형 | 기대 양상 | 기대 특성 |
|------|----------|----------|
| V_SHAPE | 리더 앞, V자 배치 | 기본 범용, 빠른 격파 |
| LINE | 횡대 일렬 | 넓은 전선, 분산 피해 |
| CIRCLE | 원형 보호 | 느린 격파, 낮은 피해 |
| WEDGE | 쐐기 돌격 | 최단 전투, 높은 피해 |
| SCATTERED | 분산 배치 | 범위 공격 회피 |

**PASS 기준:**
- 대형별 전투 양상이 육안으로 구분 가능
- V자 = 최단 전투시간, 높은 피해
- CIRCLE = 낮은 피해 (V자 대비 30% 이상 감소)
- 대형 전환 명령 후 2초 이내 재배치 완료

**추가 관찰 (Critic 피드백):**
- CMD-07: 이동 중 대형 유지 여부 관찰 기록 (PASS/FAIL 기준에는 미포함, 관찰 데이터만 수집)

**FAIL 시 대응:**
- `formation_calculator` 오프셋 조정
- 대형별 보너스 도입 (V자: ATK+10%, CIRCLE: DEF+15%)

**기술 접근:**
- **신규** `formation_calculator.dart`: 대형별 위치 오프셋 계산
  - V_SHAPE: `offset = (cos(angle) * dist, sin(angle) * dist)` (angle = 30도 간격)
  - LINE: 횡 일렬 `(i * spacing, 0)`
  - CIRCLE: `(cos(2*PI*i/n) * radius, sin(2*PI*i/n) * radius)`
  - WEDGE: 역삼각형 배치
  - SCATTERED: 황금비 기반 분산 (GDD-0001 공식)
- `ai_unit_component.dart` 수정: formation 위치 추종 로직
- `ai_brain.dart` 수정: 대형 위치 반영 FOLLOW 행동

---

#### POC-T1-03: 부대 명령 체감

| 항목 | 내용 |
|------|------|
| **검증 요소** | CMD-09 (FOLLOW), CMD-10 (ATTACK_ALL), CMD-11 (HOLD), CMD-12 (RETREAT), CMD-13 (REST), CMD-15 (즉시 반응) |
| **공수** | 1일 |
| **의존성** | T1-02 |
| **Tier** | Tier 1 (전술) |

**테스트 시나리오:**
- 전투 중 명령 순환: FOLLOW -> ATTACK_ALL -> RETREAT -> HOLD -> REST
- 각 명령 발동 후 AI 행동 변화 관찰

**PASS 기준:**
- 각 명령 후 0.5초 이내 행동 변경 관찰 가능
- ATTACK_ALL: 전 부대원이 적극 전진/교전
- RETREAT: 교전 중인 유닛도 즉시 후퇴
- HOLD: 유닛이 지정 위치에서 이동하지 않음
- REST: 유닛이 제자리에서 피로 회복

**FAIL 시 대응:**
- AI 반응 속도 향상 (tick 간격 0.3초 -> 0.1초)
- 명령 우선순위 강화 (명령 수신 시 현재 상태 즉시 전환)

**기술 접근:**
- `game_input_handler.dart`의 `_issueCommand` 스텁 완성 (현재 비어 있음)
- `ai_brain.dart`의 `_processCommand` 연결: 각 부대원의 `aiBrain.currentCommand` 설정
- 키 바인딩: 1=GATHER, 2=SCATTER, 3=ATTACK_ALL, 4=DEFEND_ALL, 5=RETREAT_ALL

---

#### POC-T1-04: 자동전투 전환

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-28 (자동전투 토글), ACT-29 (자동전투 중 개입) |
| **공수** | 0.5일 |
| **의존성** | T0-04 |
| **Tier** | Tier 1 (전술) |

**테스트 시나리오:**
1. 수동 조작으로 전투 시작
2. AUTO 버튼(F 키) -> 주인공이 AI 제어로 전환
3. AI가 자동 전투 진행 (관전)
4. 위기 상황에서 WASD 입력 -> 즉시 수동 복귀

**PASS 기준:**
- AUTO 전환 시 조작감 단절 없음
- AI가 합리적 행동 (바보 같지 않게: 적에게 돌격, HP 낮으면 후퇴)
- 수동 복귀 시 0.1초 이내 조작 가능 (WASD 즉시 반응)

**FAIL 시 대응:**
- 전환 로직 개선 (전환 시 AI 상태 초기화)
- AI 행동 품질 향상 (성격 파라미터 튜닝)

**기술 접근:**
- **신규** `auto_battle_controller.dart`: 자동전투 ON/OFF 토글, `isPlayerControlled` 플래그 관리
- `player_unit_component.dart` 수정: `isPlayerControlled` 토글에 따른 입력/AI 전환

---

#### POC-T1-05: 피로도 체감

| 항목 | 내용 |
|------|------|
| **검증 요소** | BTL-09 (피로 누적), BTL-10 (TIRED), BTL-11 (EXHAUSTED), BTL-12 (COLLAPSED), BTL-13 (휴식 판단), BTL-16 (피로 시각화) |
| **공수** | 1일 |
| **의존성** | T0-04 |
| **Tier** | Tier 1 (전술) |

**테스트 시나리오:**
- 3연전 진행: 전투1(NORMAL) -> 전투2(TIRED) -> 전투3(EXHAUSTED)
- 전투간 피로도 유지 (리셋 없음)
- 동일 적 구성으로 전투 시간/사상자 비교

**PASS 기준:**
- 3전 전투시간이 1전 대비 50% 이상 증가
- TIRED 상태에서 속도 감소 육안 확인 가능
- COLLAPSED 상태에서 행동 정지 확인
- FT 바 색상 변화: 녹색(NORMAL) -> 황색(TIRED) -> 적색(EXHAUSTED) -> 점멸(COLLAPSED)

**추가 (Critic 피드백):**
- 피로 상태에서 직접 조작 체감 관찰: 느려져도 조작감이 유지되는가? (응답성은 유지하되 이동속도만 감소해야 함)

**FAIL 시 대응:**
- 피로 증가/감소량 조정 (FATIGUE_ATTACK 10 -> 15, FATIGUE_RECOVERY_REST 5 -> 3)
- 피로 단계 임계값 조정 (TIRED: 31% -> 25%)

**기술 접근:**
- `fatigue_system.dart` 활용 (수정 불필요)
- `battle_hud.dart` 수정: FT 바 추가 (HP 바 하단에 배치)
- `battle_controller.dart` 수정: 연전 간 피로 유지 로직

---

### Phase 2: 플랫폼/성장 검증 (5일)

Phase 2는 전투 시스템 확장과 플랫폼 호환성을 검증한다.

---

#### POC-T2-01: 마법 시스템

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-06 (마법 시전), BTL-17 (마법 시전), BTL-19 (화염구), BTL-20 (힐), BTL-22 (AI 자동 마법) |
| **공수** | 1.5일 |
| **의존성** | T0-04 |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- 엘레인(마법사) 직접 조작: 화염구 시전 (방향키 + M 키)
- 소토카(힐러) AI 자동 힐: HP 50% 이하 아군 자동 치유
- 마법 유무 승률 비교: 마법 사용 5회 vs 물리 공격만 5회

**PASS 기준:**
- 화염구: 범위 60px 내 적 전원 데미지 확인
- AI 힐러: HP 50% 이하 아군 발생 시 3초 이내 자동 치유
- 마법 사용 팀 승률이 물리 전용 팀 대비 15% 이상 높음

**NOTE (Architect):** 마법 -> 상태이상 연결 포함. 화염구 -> burn, ice_bolt -> slow 디버프가 `status_effect_system`에 정상 전달되는지 확인.

**FAIL 시 대응:**
- 마법 위력/범위 조정
- AI 힐러 반응 조건 조정 (HP 50% -> 60%)

**기술 접근:**
- `magic_system.dart` 활용 (수정 불필요, 테스트 통과 상태)
- `ai_brain.dart`의 SUPPORT 상태: `_processSupport()` 에서 `woundedAlly` 감지 -> 힐 판단
- 마법 -> 상태이상 연결: `status_effect_system.dart` 활용

---

#### POC-T2-02: 모바일 터치 조작

| 항목 | 내용 |
|------|------|
| **검증 요소** | ACT-15 (가상 조이스틱), ACT-16 (공격 버튼), ACT-18 (탭 타겟팅), ACT-21 (부대 전환 스와이프), ACT-22 (명령 휠) |
| **공수** | 1일 (Architect 권고: 1.5일 -> 1일, Flame `JoystickComponent` 빌트인) |
| **의존성** | T0-01, T1-03 |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- Android 기기에서 3v3 터치 전투
- 좌측 하단: 가상 조이스틱 (8방향 이동)
- 우측 하단: 공격 버튼 (연타 가능)
- 적 유닛 탭: 타겟 지정
- 좌우 스와이프: 유닛 전환
- 명령 영역 길게 누르기: 방사형 명령 메뉴 (5개 명령)

**PASS 기준:**
- 8방향 자유 이동 가능
- 연타 공격이 자연스러움
- 탭 타겟팅이 정확 (32x32 히트박스)
- 스와이프 전환 0.5초 이내
- 명령 휠에서 5개 명령 선택 가능

**FAIL 시 대응:**
- 터치 영역 확대 (히트박스 48dp)
- 자동 타겟팅 강화 (가장 가까운 적 자동 선택)
- 명령 버튼 단순화 (휠 -> 리스트)

**기술 접근:**
- **신규** `touch_input_handler.dart`: Flame `JoystickComponent` + 터치 버튼 오버레이
- `game_input_handler.dart` 수정: 터치/키보드 입력 통합

---

#### POC-T2-03: 상태이상/환경 체감

| 항목 | 내용 |
|------|------|
| **검증 요소** | BTL-26 (스턴), BTL-30 (어둠 지형) |
| **공수** | 0.5일 |
| **의존성** | T0-04, T2-01 (마법 -> 상태이상 의존성) |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- 스턴: 적에게 스턴 마법 시전 -> 3초간 행동 불가 확인
- 어둠 지형: DARK 타일 진입 -> 감지 범위 50% 감소 -> AI 교전 거리 축소 관찰

**PASS 기준:**
- 스턴: 3초간 이동/공격 불가, 스턴 종료 후 즉시 행동 재개
- 어둠: 감지 범위가 200px -> 100px로 감소, AI가 적을 늦게 발견

**FAIL 시 대응:**
- 상태이상 지속 시간 조정
- 환경 효과 수치 조정

**기술 접근:**
- `status_effect_system.dart` 활용 (수정 불필요)
- `environment_system.dart` 활용 (수정 불필요)

---

#### POC-T2-04: 성장 체감

| 항목 | 내용 |
|------|------|
| **검증 요소** | RPG-01 (경험치), RPG-02 (레벨업), RPG-04 (스탯 성장), RPG-05 (레벨 격차), RPG-07 (부대원 성장) |
| **공수** | 0.5일 |
| **의존성** | T0-04 |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- Lv1 아레스 vs 고블린 3체: 고전 (전투 시간 기록)
- Lv3 아레스 vs 고블린 3체: 여유 (전투 시간 기록)
- Lv5 아레스 vs 고블린 3체: 압도 (전투 시간 기록)
- EXP 획득 -> 레벨업 -> 스탯 성장 표시 확인
- 전투 참여 부대원도 EXP 획득 확인

**PASS 기준:**
- Lv+2에서 DPS 30% 이상 증가 체감
- Lv+4에서 전투 시간 50% 이상 단축
- 부대원이 전투 참여 시 EXP 획득

**FAIL 시 대응:**
- 레벨업 스탯 성장량 조정 (ATK+2 -> ATK+3)
- 경험치 곡선 조정

**기술 접근:**
- `experience_system.dart` 활용 (수정 불필요)
- `stats_system.dart` 활용 (수정 불필요)

---

#### POC-T2-05: 장비/아이템 체감

| 항목 | 내용 |
|------|------|
| **검증 요소** | RPG-08 (무기 교체), RPG-12 (전투 중 아이템) |
| **공수** | 0.5일 |
| **의존성** | T2-04 |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- 기본 무기(ATK+0) -> 강화 무기(ATK+10) 교체 후 데미지 비교
- 전투 중 HP 포션 사용: HP 50 회복 + 팝업 표시
- 아이템 사용 시 경직 0.5초

**PASS 기준:**
- 강화 무기 장착 후 데미지 증가 체감
- HP 포션 사용 시 HP 50 즉시 회복 + 팝업
- 아이템 사용 중 0.5초 경직 (남용 방지)

**FAIL 시 대응:**
- 장비 보너스 수치 조정
- 아이템 경직 시간 조정 (0.3~0.8초)

**기술 접근:**
- `equipment_system.dart` 활용 (수정 불필요)
- `inventory_system.dart` 활용 (수정 불필요)

---

#### POC-T2-06: 맵 탐색

| 항목 | 내용 |
|------|------|
| **검증 요소** | ADV-01 (자유 이동), ADV-06 (미니맵) |
| **공수** | 1.5일 (Architect 권고: 0.5일 -> 1.5일, 타일맵 코드 전무) |
| **의존성** | T0-01 |
| **Tier** | Tier 2 (플랫폼/성장) |

**테스트 시나리오:**
- Tiled 에디터로 제작한 테스트 맵에서 아레스 + 부대원 2체 이동
- 벽/장애물 충돌 처리
- 부대원 AI가 리더 추종
- 카메라 추적
- 미니맵 현재 위치 + 유닛 표시

**PASS 기준:**
- 타일맵 렌더링 60FPS
- 충돌 처리 정상 (벽 통과 불가)
- 부대원이 리더를 추종하며 이동
- 카메라가 주인공 추적
- 미니맵 동작

**FAIL 시 대응:**
- 타일맵 청크 렌더링 최적화
- 충돌 레이어 단순화

**기술 접근:**
- **신규** `map_renderer.dart`: `flame_tiled` 패키지 통합, 타일맵 렌더링
- `game_camera.dart`의 기존 `smoothFollow` 활용
- `minimap.dart`의 기존 구현 활용

---

### Phase 3: 연출/콘텐츠 검증 (2.5일 + 통합 0.5일)

Phase 3는 시각적 피드백과 콘텐츠 시스템을 검증한다.

---

#### POC-T3-01: Rive 캐릭터

| 항목 | 내용 |
|------|------|
| **검증 요소** | SEN-01 (Rive 캐릭터), SEN-02 (캐릭터 모션) |
| **공수** | 0.5일 |
| **의존성** | 없음 |
| **플랫폼** | **Android 전용** |
| **Tier** | Tier 3 (연출) |

**테스트 시나리오:**
- Android 기기에서 Rive `.riv` 파일 로드
- State Machine 전환: idle -> walk -> attack -> hurt -> die
- 6체 동시 렌더링 (아군 3 + 적 3)

**PASS 기준:**
- Rive 캐릭터 정상 렌더링 (Android)
- State Machine 전환 0.1초 이내
- 6체 동시 60FPS 유지
- fallback 렌더러와 동일 API 인터페이스

**FAIL 시 대응:**
- Sprite sheet 전환 결정 (Rive 포기)
- `rive_unit_renderer.dart`의 fallback을 sprite sheet 기반으로 교체

**기술 접근:**
- `pubspec.yaml`에서 `rive` 패키지 활성화 (Android 빌드만)
- `rive_unit_renderer.dart` 수정: Rive/fallback 분기 (플랫폼별)

---

#### POC-T3-02: 대화 시스템

| 항목 | 내용 |
|------|------|
| **검증 요소** | ADV-09 (대화 시스템) |
| **공수** | 0.5일 |
| **의존성** | 없음 |
| **Tier** | Tier 3 (연출) |

**테스트 시나리오:**
- 텍스트 박스 + 캐릭터 초상화(placeholder) + 타이핑 효과
- 탭/Enter로 대화 진행
- 대화 중 게임 정지

**PASS 기준:**
- 타이핑 효과 정상 동작 (문자별 표시)
- 탭/Enter로 즉시 표시 또는 다음 대사 진행
- 대화 중 게임 엔진 일시정지

**FAIL 시 대응:**
- 타이핑 속도 조정
- 대화 UI 레이아웃 변경

**기술 접근:**
- **신규** `dialogue_overlay.dart`: Flutter 오버레이 위젯 (Flame 위에 표시)
- `dialogue_system.dart`의 기존 데이터 구조 활용

---

#### POC-T3-03: 타격 피드백 폴리시

| 항목 | 내용 |
|------|------|
| **검증 요소** | SEN-07 (히트 플래시), SEN-08 (히트스톱), SEN-11 (데미지 팝업), SEN-17 (HP 바 애니메이션) |
| **공수** | 1일 |
| **의존성** | T0-02 |
| **Tier** | Tier 3 (연출) |

**테스트 시나리오:**
- T0-02에서 구현한 (C) 단계를 종합 폴리시:
  - 히트 플래시: 피격 시 흰색 깜빡임 (0.1초)
  - 히트스톱: 타격 순간 2프레임 정지 (개별 유닛 `hitStopTimer`)
  - 데미지 팝업: 숫자 위로 떠오르며 소멸 (크리티컬 = 빨강 큰 글자)
  - HP 바: lerp 기반 부드러운 감소 (0.3초)

**PASS 기준:**
- 모든 피드백이 육안으로 확인 가능
- 크리티컬과 일반 데미지 시각 구분
- HP 바가 단번에 줄지 않고 부드럽게 감소
- 60FPS 유지

**FAIL 시 대응:**
- 이펙트 파라미터 조정 (지속 시간, 크기, 색상)

**기술 접근:**
- `rive_unit_renderer.dart`의 기존 hurt flash 확장
- `damage_popup.dart`의 기존 구현 폴리시
- `battle_hud.dart` 수정: HP 바 lerp 애니메이션

---

#### POC-INT-01: 통합 시나리오 테스트 (Critic 피드백 추가)

| 항목 | 내용 |
|------|------|
| **검증 요소** | 전체 시스템 통합 동작 |
| **공수** | 0.5일 |
| **의존성** | Phase 0~2 전체 |
| **Tier** | 통합 검증 |

**테스트 시나리오:**
- 3분 연속 전투 플레이:
  1. 아레스 직접 조작으로 전투 시작 (1전)
  2. 피로 누적 확인 + 대형 V자 -> CIRCLE 변경
  3. 유닛 전환 (Q 키로 엘레인 전환)
  4. 엘레인으로 화염구 시전
  5. Tab으로 부대 전환 -> 2부대 지휘
  6. AUTO 전환 -> AI 관전 -> 위기시 WASD로 수동 복귀
  7. 2전, 3전 진행 (피로 누적)

**PASS 기준:**
- 모든 시스템이 충돌 없이 동시 작동
- 조작감 일관성 유지 (시스템 전환 시 끊김 없음)
- 60FPS 유지
- 크래시/hang 없음

**FAIL 시 대응:**
- 충돌 원인 분석 및 개별 시스템 수정
- 시스템 간 의존성 정리

---

## 4. 전체 일정 및 의존성

### 4.1 Phase별 일정 (총 18일)

```
Phase 0 (3일): 핵심 게임 필
  Day 1:  T0-01 (조작 0.5d) + T0-03 (성격 0.5d) [병렬]
  Day 2:  T0-02 (타격감 1d)
  Day 3:  T0-04 (전투 긴장감 1d)
  [GATE 0: 4개 중 1개라도 FAIL -> 전체 재설계]

Phase 1 (5.5일): 전술 재미
  Day 4:    T1-01 (유닛/부대 전환 1d)
  Day 5-6:  T1-02 (대형 2d)
  Day 7:    T1-03 (명령 1d) + T1-04 (자동전투 0.5d) [병렬]
  Day 8:    T1-05 (피로도 1d)
  [GATE 1: 대형/명령/피로가 전투에 영향 없음 -> 파라미터 재설계]

Phase 2 (5일): 플랫폼/성장
  Day 9-10:  T2-01 (마법 1.5d)
  Day 10:    T2-03 (상태이상 0.5d) [T2-01 이후 직렬]
  Day 11:    T2-02 (터치 1d)
  Day 12:    T2-04 (성장 0.5d) + T2-05 (장비 0.5d) [병렬]
  Day 13:    T2-06 (맵 탐색 1.5d 시작)
  [GATE 2: 터치 조작 실패 -> 터치 UI 재설계]

Phase 3 (2.5일 + 통합 0.5일 = 3일)
  Day 14:  T3-01 (Rive, Android 0.5d) + T3-02 (대화 0.5d) [병렬]
  Day 15:  T3-03 (타격 피드백 폴리시 1d)
  Day 16:  T2-06 완료(0.5d) + POC-INT-01 (통합 0.5d)
  [GATE 3: Rive 실패 -> sprite sheet 전환 결정]
```

NOTE: T2-06은 Day 13에 시작하여 Day 16에 완료 (총 1.5일, Phase 3과 겹침).

### 4.2 의존성 맵

```
T0-01 (조작) -----> T0-02 (타격) -----> T0-04 (전투) --+--> T1-04 (자동전투)
     |                                                   +--> T1-05 (피로도)
     |                                                   +--> T2-01 (마법) -----> T2-03 (상태이상)
     |                                                   +--> T2-04 (성장) -----> T2-05 (장비)
     |                                                   +--> POC-INT-01
     |
     +-----> T1-01 (전환) -----> T2-02 (터치) -----> POC-INT-01
     +-----> T2-06 (맵 탐색)

T0-03 (성격) -----> T1-02 (대형) -----> T1-03 (명령) -----> POC-INT-01

T0-01 -----> T3-01 (Rive)
T0-02 -----> T3-03 (피드백 폴리시)
(없음) -----> T3-02 (대화)
```

### 4.3 실패 시 버퍼 (Critic 피드백)

각 Gate에 2일 버퍼를 할당한다. 실패 시 파라미터 조정 또는 부분 재설계에 사용한다.

| Gate | 실패 조건 | 대응 | 버퍼 |
|------|----------|------|:----:|
| GATE 0 | 조작/타격/긴장감 미달 | 전체 재설계 | 2일 |
| GATE 1 | 전술 시스템 무의미 | 파라미터 재설계 | 2일 |
| GATE 2 | 터치 조작 불가 | 터치 UI 재설계 | 2일 |
| GATE 3 | Rive 실패 | sprite sheet 전환 | 2일 |

**총 일정:** 18일 (정상) + 최대 8일 (4 Gate x 2일 버퍼) = **최대 26일**

---

## 5. 신규/수정 파일

### 5.1 신규 파일 (6개)

| 파일 | 경로 | 용도 | 관련 POC |
|------|------|------|----------|
| `formation_calculator.dart` | `lib/game/systems/` | 대형별 위치 오프셋 계산 (5종) | T1-02 |
| `auto_battle_controller.dart` | `lib/game/systems/` | 자동전투 ON/OFF 토글, AI 전환 | T1-04 |
| `touch_input_handler.dart` | `lib/game/input/` | 모바일 터치 입력 (조이스틱, 버튼, 휠) | T2-02 |
| `map_renderer.dart` | `lib/game/components/map/` | Tiled 타일맵 렌더링 | T2-06 |
| `dialogue_overlay.dart` | `lib/presentation/widgets/` | 대화 UI 오버레이 (Flutter 레이어) | T3-02 |
| `hud_overlay.dart` | `lib/presentation/widgets/` | 전투 HUD 오버레이 (HP/FT/명령) | T0-04, T1-05 |

### 5.2 수정 파일 (10개)

| 파일 | 변경 내용 | 관련 POC |
|------|----------|----------|
| `fq4_game.dart` | 가로 모드 1280x800 확인, 고정 시나리오 스폰 | T0-01~T0-04 |
| `unit_component.dart` | `attackLockout` (경직 타이머), `hitStopTimer` (히트스톱) 추가 | T0-02 |
| `ai_unit_component.dart` | formation 위치 추종 로직, 대형별 오프셋 적용 | T1-02 |
| `player_unit_component.dart` | 게임패드 입력, `isPlayerControlled` 토글 | T0-01, T1-04 |
| `game_manager.dart` | 유닛/부대 전환 고도화, 주인공 사망 GAME OVER | T1-01, T0-04 |
| `game_camera.dart` | `smoothFollow` lerp 전환, `shake()` 메서드 | T0-02, T1-01 |
| `battle_controller.dart` | 웨이브 통계, 연전 피로 유지, 자동전투 시뮬 | T0-04, T1-05 |
| `game_input_handler.dart` | `_issueCommand` 스텁 완성, 부대 명령 연결 | T1-03 |
| `battle_hud.dart` | FT 바 추가, HP 바 lerp 애니메이션 | T1-05, T3-03 |
| `rive_unit_renderer.dart` | 히트 플래시 `flashTimer` 확장 | T0-02, T3-03 |

---

## 6. 커밋 전략

| Phase | 커밋 단위 | 커밋 메시지 형식 |
|-------|----------|-----------------|
| Phase 0 | POC 1개 = 커밋 1개 | `poc(T0-XX): description - PASS/FAIL` |
| Phase 1 | POC 1개 = 커밋 1개 | `poc(T1-XX): description - PASS/FAIL` |
| Phase 2 | POC 1~2개 = 커밋 1개 | `poc(T2-XX): description - PASS/FAIL` |
| Phase 3 | Phase 전체 = 커밋 1~2개 | `poc(T3): phase 3 verification - results` |
| Gate 실패 | 수정 1건 = 커밋 1개 | `fix(T0-XX): description` |
| 통합 | 통합 1건 = 커밋 1개 | `poc(INT-01): integration test - PASS/FAIL` |

예시:
```
poc(T0-01): WASD 조작 반응성 50ms 이하 확인 - PASS
poc(T0-02): A/B/C 타격감 비교, hitStopTimer 구현 - PASS
fix(T0-04): 수동 승률 차이 미달, 적 AI 감지범위 축소 조정
poc(T1-02): 5종 대형 전투 영향 검증 - PASS
poc(INT-01): 3분 통합 시나리오 전 시스템 동작 - PASS
```

---

## 7. 최종 PASS/FAIL 기준 요약표

| POC ID | Tier | PASS 핵심 지표 | FAIL 시 대응 |
|--------|:----:|---------------|-------------|
| T0-01 | 0 | 이동 50ms, 공격 100ms, 게임패드 차이 10ms | 입력 버퍼링, RawKeyboard |
| T0-02 | 0 | (C) 타격감 확실, 경직 동작, 60FPS | 히트스톱 1~5프레임, 경직 0.2~0.5초 |
| T0-03 | 0 | 5초 관찰로 성격 구분, 교전 시간차 2초+ | 성격 파라미터 편차 확대 |
| T0-04 | 0 | 수동-자동 승률차 20%+ OR 생존자차 1.0명+ | 적 AI 조정, 직접 조작 보너스 |
| T1-01 | 1 | 전환 0.3초 내 조작, 카메라 lerp, 게임 정지 없음 | 카메라/전환 로직 최적화 |
| T1-02 | 1 | 대형별 양상 구분, CIRCLE 피해 30%+ 감소 | 오프셋/보너스 조정 |
| T1-03 | 1 | 명령 후 0.5초 내 행동 변경, RETREAT 즉시 | AI 반응 속도 향상 |
| T1-04 | 1 | AUTO 전환 단절 없음, 수동 복귀 0.1초 | 전환 로직 개선 |
| T1-05 | 1 | 3전 전투시간 50%+ 증가, COLLAPSED 행동정지 | 피로 증감량 조정 |
| T2-01 | 2 | 화염구 범위 데미지, AI 힐 3초 내, 승률차 15%+ | 마법 위력/범위 조정 |
| T2-02 | 2 | 8방향 이동, 연타 공격, 스와이프 전환 0.5초 | 터치 영역 확대, 자동 타겟팅 |
| T2-03 | 2 | 스턴 3초 행동불가, 어둠 감지 50% 감소 | 지속시간/수치 조정 |
| T2-04 | 2 | Lv+2 DPS 30%+, Lv+4 전투시간 50%+ 단축 | 스탯 성장량 조정 |
| T2-05 | 2 | 데미지 증가 체감, HP 포션 50 회복+팝업 | 장비 보너스 조정 |
| T2-06 | 2 | 타일맵 60FPS, 충돌, 부대원 추종, 미니맵 | 청크 렌더링 최적화 |
| T3-01 | 3 | Rive 정상 렌더링(Android), 6체 60FPS | sprite sheet 전환 |
| T3-02 | 3 | 타이핑 효과, 탭 진행, 대화 중 게임 정지 | UI 레이아웃 변경 |
| T3-03 | 3 | 히트플래시+히트스톱+팝업+HP lerp, 60FPS | 이펙트 파라미터 조정 |
| INT-01 | 통합 | 전 시스템 동시 작동, 조작감 일관성, 60FPS | 개별 시스템 수정 |

---

## 8. POC 불필요 요소 상세 근거 (104개)

### 8.1 A. 직접 조작 (10개)

| ID | 요소 | 사유 |
|----|------|------|
| ACT-04 | 이동 공격 | ACT-01(이동) + ACT-02(공격) 조합으로 구현 가능. 별도 POC 불필요 |
| ACT-05 | 대시/회피 | 본개발 액션 확장. 기본 이동이 검증되면 파생 가능 |
| ACT-07 | 아이템 사용 | `inventory_system.dart` 테스트 통과 (소비 로직 검증 완료) |
| ACT-12 | 전환 전략 | T1-01 유닛 전환 기능 기반 응용. 전환 자체가 되면 전략은 플레이어 판단 |
| ACT-14 | 멀티 부대 전환 | T1-01 부대 전환 기반 응용 |
| ACT-17 | 스킬 버튼 | UI 위젯. 게임플레이 검증과 무관 |
| ACT-19 | 핀치 줌 | Flutter 표준 `GestureDetector` 기능 |
| ACT-20 | 드래그 카메라 | Flutter 표준 `GestureDetector` 기능 |
| ACT-25 | 입력 자동 감지 | Flutter `Gamepad` API 표준 기능 |
| ACT-26 | 버튼 프롬프트 | UI 위젯 |
| ACT-27 | 키 리매핑 | 설정 UI 화면 |
| ACT-30 | 배속 | POC-4에서 검증 완료. `speedMultiplier` 동작 확인됨 |

### 8.2 B. 부대 지휘 (10개)

| ID | 요소 | 사유 |
|----|------|------|
| CMD-07 | 대형 유지력 | T1-02에서 관찰 포함 (부가 기록). 별도 PASS/FAIL 불필요 |
| CMD-08 | 대형 시각 표시 | UI 위젯 |
| CMD-14 | 분산 | CMD-05 SCATTERED와 기능 동일 |
| CMD-16 | 명령 아이콘 | UI 위젯 |
| CMD-20 | 성격 시각 표시 | UI 위젯 |
| CMD-21 | 성격별 대사 | 콘텐츠 데이터 (대사 텍스트 입력) |
| CMD-22 | 부대 편성 | UI 화면 (드래그 배치). 게임플레이 무관 |
| CMD-24 | 다중 부대 작전 | T1-01 부대 전환 기반 응용 |
| CMD-25 | 부대 상태 HUD | UI 위젯 |
| CMD-26 | NPC 부대 | 콘텐츠 데이터 (스토리 합류 이벤트) |
| CMD-27 | 부대 분리/합류 | `game_manager.dart` 확장. 기존 부대 관리 로직 동작 확인됨 |
| CMD-28 | 전투 후 정리 | UI 화면 |

### 8.3 C. 전투 역학 (14개)

| ID | 요소 | 사유 |
|----|------|------|
| BTL-04 | 위기 탈출 | T0-04 전투에서 자연 발생하는 시나리오 |
| BTL-05 | 적 증원 | 스폰 로직 단순 (`world.add()` 호출) |
| BTL-08 | 보스 페이즈 전환 | `boss_unit_component.dart` 구현 완료 + 테스트 통과 |
| BTL-14 | 피로 회복 아이템 | `fatigue_system.dart` 테스트 통과 (FATIGUE_RECOVERY_ITEM=30) |
| BTL-15 | 페어리 샘 | 콘텐츠 데이터 (맵 오브젝트) |
| BTL-18 | MP 관리 | `magic_system.dart` 테스트 통과 (MP 소모/잔량 로직) |
| BTL-21 | 버프/디버프 | `status_effect_system.dart` 테스트 통과 (shield, haste, slow) |
| BTL-23 | 마법 이펙트 | 시각 연출. 게임플레이 검증과 무관 |
| BTL-24 | 독 | `status_effect_system.dart` 테스트 통과 (5dmg/s, 10s) |
| BTL-25 | 화상 | `status_effect_system.dart` 테스트 통과 (8dmg/s, 8s) |
| BTL-27 | 동결 | `status_effect_system.dart` 테스트 통과 (4s 행동불가) |
| BTL-28 | 물 지형 | `environment_system.dart` 테스트 통과 (speed*0.7) |
| BTL-29 | 독 지형 | `environment_system.dart` 테스트 통과 (poison 부여) |
| BTL-31 | 지형 활용 전략 | T2-03에서 간접 검증 (어둠 지형 체감) |
| BTL-32 | 보스 특수 공격 | `boss_unit_component.dart` 구현 완료 (3페이즈, 광폭화, 미니언) |

### 8.4 D. RPG 성장 (22개)

| ID | 요소 | 사유 |
|----|------|------|
| RPG-03 | 레벨업 연출 | 시각 연출, 본개발 |
| RPG-06 | 스킬 습득 | `experience_system.dart` 확장 |
| RPG-09 | 방어구 교체 | `equipment_system.dart` 테스트 통과 |
| RPG-10 | 액세서리 | `equipment_system.dart` 테스트 통과 |
| RPG-11 | 장비 비교 | UI 화면 |
| RPG-13 | 보물 상자 | 콘텐츠 데이터 |
| RPG-14 | 상점 | `shop_system.dart` 테스트 통과 |
| RPG-15 | 골드 경제 | `shop_system.dart` 테스트 통과 |
| RPG-16 | 마법 습득 | 콘텐츠 데이터 |
| RPG-17 | 마법 슬롯 | UI 위젯 |
| RPG-18 | 마법 선택 전략 | T2-01에서 간접 검증 |
| RPG-19 | 엔딩 분기 | `ending_system.dart` 구현+테스트 완료 (GOOD/NORMAL/BAD) |
| RPG-20 | NG+ | `newgame_plus_system.dart` 구현+테스트 완료 |
| RPG-21 | 업적 28개 | `achievement_system.dart` 구현+테스트 완료 |
| RPG-22 | 숨겨진 보스 | 콘텐츠 데이터 |
| RPG-23 | 도전 모드 | 콘텐츠 데이터 |
| RPG-24 | 전투력 상한 | `experience_system.dart` 수치 검증 |
| RPG-25 | 레벨별 능력치 곡선 | `experience_system.dart` 테스트 통과 |
| RPG-26 | 적 레벨 스케일링 | 밸런스 데이터 |
| RPG-27 | 전투 보상 골드 | `combat_system.dart` 테스트 통과 |
| RPG-28 | 장비 강화 | `equipment_system.dart` 확장 |
| RPG-29 | 아이템 드롭 | 콘텐츠 데이터 |
| RPG-30 | 인벤토리 관리 | `inventory_system.dart` 테스트 통과 |

### 8.5 E. 탐색/스토리 (21개)

| ID | 요소 | 사유 |
|----|------|------|
| ADV-02 | 비밀 통로 | 콘텐츠 데이터 (맵 설계) |
| ADV-03 | 보물 발견 | 콘텐츠 데이터 |
| ADV-04 | NPC 대화 | `dialogue_system.dart` 구현 완료 |
| ADV-05 | 지형 다양성 | 콘텐츠 데이터 (아트 에셋) |
| ADV-07 | 맵 전환 | `chapter_manager.dart` 구현 완료 |
| ADV-08 | 메인 스토리 | 콘텐츠 데이터 (799개 메시지 복호화 완료) |
| ADV-10 | 대화 선택지 | `dialogue_system.dart` 확장 |
| ADV-11 | 이벤트 트리거 | `event_system.dart` 구현 완료 |
| ADV-12 | 동료 합류 | 콘텐츠 데이터 |
| ADV-13 | 챕터 전환 연출 | 시각 연출, 본개발 |
| ADV-14 | 수비 전투 | 콘텐츠 데이터 |
| ADV-15 | 돌파 전투 | 콘텐츠 데이터 |
| ADV-16 | 매복 전투 | 콘텐츠 데이터 |
| ADV-17 | 보스 전투 | `boss_unit_component.dart` 구현 완료 |
| ADV-18 | 부대 합류 전투 | `game_manager.dart` 확장 |
| ADV-19 | 로그리스 대륙 | 콘텐츠 데이터 |
| ADV-20 | 왕국/세력 | 콘텐츠 데이터 |
| ADV-21 | 캐릭터 관계 | `dialogue_data.dart` 구현 완료 |
| ADV-22 | 적대 인물 | 콘텐츠 데이터 |
| ADV-23 | 엔딩 감동 | 콘텐츠 데이터 |
| ADV-24 | 메시지 799개 | 복호화 완료 (FQ4MES_FINAL_REPORT.md) |
| ADV-25 | 다국어 | `localization_manager.dart` 구현 완료 (ja/ko/en) |

### 8.6 F. 감각/연출 (13개)

| ID | 요소 | 사유 |
|----|------|------|
| SEN-03 | HD 배경 | 아트 에셋, 게임플레이 무관 |
| SEN-04 | 파티클 이펙트 | 시각 연출, 본개발 |
| SEN-05 | 날씨/조명 | 시각 연출, 본개발 |
| SEN-06 | 카메라 연출 | `game_camera.dart` 확장 |
| SEN-09 | 넉백 | T0-02(B)에서 5px 넉백 간접 검증 |
| SEN-10 | 카메라 쉐이크 | T0-02(C)에서 카메라 흔들림 간접 검증 |
| SEN-12 | 전투 BGM | 오디오 에셋, 게임플레이 무관 |
| SEN-13 | 타격음 | 오디오 에셋 |
| SEN-14 | 사망 효과음 | 오디오 에셋 |
| SEN-15 | UI 효과음 | 오디오 에셋 |
| SEN-16 | 환경음 | 오디오 에셋 |
| SEN-18 | 레벨업 이펙트 | 시각 연출, 본개발 |
| SEN-19 | 전투 시작 연출 | 시각 연출, 본개발 |
| SEN-20 | 승리/패배 연출 | 시각 연출, 본개발 |

### 8.7 G. 시스템/편의 (14개)

| ID | 요소 | 사유 |
|----|------|------|
| SYS-01 | 세이브/로드 | `save_system.dart` 구현+테스트 완료 |
| SYS-02 | 설정 | 표준 Flutter 설정 UI |
| SYS-03 | 가로/세로 모드 | 가로 고정 결정 (1.2절). 세로 적응은 본개발 |
| SYS-04 | 일시정지 | 표준 Flame `pauseEngine()`/`resumeEngine()` |
| SYS-05 | 미니맵 | `minimap.dart` 구현 완료 |
| SYS-06 | 튜토리얼 | 콘텐츠 데이터 |
| SYS-07 | 도감 | UI 화면 |
| SYS-08 | 전투 기록 | `battle_controller.dart` 로그 구현 완료 |
| SYS-09 | 키 리매핑 | 설정 UI |
| SYS-10 | 색맹 모드 | `accessibility_system.dart` 구현 완료 |
| SYS-11 | 폰트 크기 | `accessibility_system.dart` 구현 완료 |
| SYS-12 | 게임 속도 | POC-4에서 `speedMultiplier` 검증 완료 |
| SYS-13 | 스크린샷 | 표준 플랫폼 기능 |
| SYS-14 | 클래식 모드 | 설정 옵션 |
| SYS-15 | 크로스 플랫폼 세이브 | 본개발 후반 |

---

## 9. ralplan 합의 이력

### 9.1 Architect 검토 결과: 조건부 승인

| 항목 | 변경 내용 | 사유 |
|------|----------|------|
| T1-02 공수 | 1.5일 -> 2일 | `formation_calculator.dart` 신규 작성 필요. 5종 대형 오프셋 계산 + AI 추종 로직 |
| T2-06 공수 | 0.5일 -> 1.5일 | 타일맵 관련 코드 전무. `flame_tiled` 통합 + 충돌 레이어 + 카메라 연동 |
| T2-02 공수 | 1.5일 -> 1일 | Flame `JoystickComponent` 빌트인. 터치 버튼만 신규 |
| 히트스톱 패턴 | 확정 | 개별 유닛 `hitStopTimer` 패턴. Flame 게임 루프 비파괴 |
| T2-01 -> T2-03 | 의존성 추가 | 마법 -> 상태이상 연결 (화염구 -> burn, ice_bolt -> slow) |
| 배속-히트스톱 | T0-02에 포함 | 배속(4x) 시 히트스톱 지속 시간 축소 여부 확인 |

### 9.2 Critic 검토 결과: 8개 우려 반영

| 번호 | 우려 사항 | 반영 위치 |
|:----:|----------|----------|
| 1 | GDD-0001 채택 / PRD-0003 폐기 명시적 선언 필요 | 섹션 1 방향 선언에 명시 |
| 2 | T0-04 측정 프로토콜 불명확 | 고정 시나리오 + 시드 고정 + 50회 시뮬 + 대안 메트릭(생존자 수) |
| 3 | 가로 모드 선행 확정 필요 | 섹션 1.2 사전 결정 사항에 반영 |
| 4 | Rive fallback 전략 명시 필요 | 섹션 1.2 + 1.4에 반영 |
| 5 | POC 구현 위치 정의 필요 | 섹션 1.2에 반영 (기존 fq4_game.dart 수정 방식) |
| 6 | CMD-07 대형 유지력 누락 | T1-02에 관찰 기록으로 포함 |
| 7 | 통합 검증 POC 누락 | POC-INT-01 신규 추가 |
| 8 | 실패 버퍼 미할당 | 섹션 4.3에 Gate별 2일 버퍼 할당 |

---

## Document History

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-15 | 초기 작성 (ralplan 합의: Planner + Architect + Critic) |
