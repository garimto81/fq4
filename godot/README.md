# First Queen 4 Remake - Godot Project

First Queen 4의 HD 리메이크 프로젝트입니다. Godot 4.4 엔진을 사용합니다.

## 🚀 빠른 시작

### 방법 1: Godot 에디터에서 실행

```bash
# 프로젝트 폴더에서 Godot 실행
cd C:\claude\Fq4
.\Godot_v4.4-stable_win64.exe --path godot
```

또는:
1. Godot 4.4 에디터 실행
2. `C:\claude\Fq4\godot\project.godot` 열기
3. **F5** 또는 Play 버튼 클릭

### 방법 2: 직접 게임 실행

```bash
cd C:\claude\Fq4
.\Godot_v4.4-stable_win64.exe --path godot --main-loop
```

---

## 🎮 조작법

| 키 | 동작 |
|----|------|
| **WASD** | 유닛 이동 |
| **← →** | 부대 내 유닛 전환 |
| **↑ ↓** | 부대 전환 |
| **Space** | 공격 |
| **ESC** | 일시정지/메뉴 |
| **우클릭** | 해당 위치로 이동 명령 |

---

## 📁 테스트 씬

| 씬 | 경로 | 용도 |
|----|------|------|
| **메인 게임** | `scenes/game/main_game.tscn` | 실제 게임 플레이 (기본) |
| **AI 테스트** | `scenes/test/ai_test.tscn` | Gocha-Kyara AI 테스트 |
| **성능 테스트** | `scenes/test/performance_test.tscn` | 100 유닛 벤치마크 |

**씬 변경 방법:**
1. Godot 에디터에서 Project > Project Settings
2. Application > Run > Main Scene 변경

---

## 🏗️ 프로젝트 구조

```
godot/
├── project.godot              # Godot 프로젝트 설정
├── scenes/
│   ├── game/                  # 메인 게임 씬
│   │   └── main_game.tscn
│   ├── maps/chapter1/         # 챕터 1 맵
│   │   ├── castle_entrance.tscn
│   │   ├── forest_path.tscn
│   │   └── goblin_camp.tscn
│   ├── test/                  # 테스트 씬
│   ├── effects/               # 파티클 이펙트
│   └── ui/                    # UI 씬
├── scripts/
│   ├── autoload/              # 전역 매니저 (싱글톤)
│   │   ├── game_manager.gd
│   │   ├── save_system.gd
│   │   └── progression_system.gd
│   ├── units/                 # 유닛 스크립트
│   │   ├── unit.gd            # 기본 유닛
│   │   ├── ai_unit.gd         # Gocha-Kyara AI
│   │   └── enemy_unit.gd      # 적 AI
│   ├── systems/               # 게임 시스템
│   │   ├── stats_system.gd
│   │   ├── experience_system.gd
│   │   ├── equipment_system.gd
│   │   ├── inventory_system.gd
│   │   ├── fatigue_system.gd
│   │   └── combat_system.gd
│   ├── map/                   # 맵 시스템
│   ├── dialogue/              # 대화 시스템
│   └── game/                  # 게임 컨트롤러
├── resources/
│   ├── items/                 # 아이템 데이터
│   ├── equipment/             # 장비 데이터
│   ├── enemies/               # 적 데이터
│   └── levels/                # 레벨업 테이블
├── shaders/                   # 셰이더 (CRT, 픽셀, 아웃라인)
└── themes/                    # UI 테마
```

---

## 🎯 Gocha-Kyara 시스템

First Queen 4의 핵심인 Gocha-Kyara 시스템이 구현되어 있습니다.

### 핵심 규칙
1. **플레이어는 1명만 직접 제어** - 나머지는 AI가 자동 제어
2. **AI는 리더를 따라감** - V자 대형 유지
3. **가까운 적 자동 공격** - 감지 범위 내 적 추격
4. **피로도 기반 행동** - 피로도 높으면 자동 후퇴/휴식
5. **성격 시스템** - 공격적/방어적/균형

### AI 상태

| 상태 | 설명 |
|------|------|
| IDLE | 대기 |
| FOLLOW | 리더 따라가기 |
| CHASE | 적 추격 |
| ATTACK | 공격 |
| RETREAT | 후퇴 |
| REST | 휴식 |

---

## ⚡ 성능 벤치마크

| 유닛 수 | 평균 FPS | 상태 |
|:-------:|:--------:|:----:|
| 10 | 144.9 | ✅ EXCELLENT |
| 25 | 145.0 | ✅ EXCELLENT |
| 50 | 145.0 | ✅ EXCELLENT |
| 75 | 144.8 | ✅ EXCELLENT |
| 100 | 145.0 | ✅ EXCELLENT |

결과 파일: `C:\claude\Fq4\output\benchmark_results.txt`

---

## 📋 개발 현황

### Phase 0: Pre-production ✅
- [x] 에셋 추출 도구 (RGBE, CHR, Bank, Text)
- [x] Gocha-Kyara AI 프로토타입
- [x] 100 유닛 성능 테스트 통과

### Phase 1: MVP ✅
- [x] 코어 시스템 (스탯, 경험치, 장비, 인벤토리)
- [x] 챕터 1-3 맵/이벤트
- [x] Enhanced 그래픽 (셰이더, 파티클)
- [x] 대화 시스템
- [x] 세이브/로드 시스템
- [x] 테스트 가능 빌드

### Phase 2: Full Release (대기)
- [ ] 전체 스토리 (챕터 4-10)
- [ ] BGM 리마스터

### Phase 3: Expansion (대기)
- [ ] HD-2D 그래픽 DLC
- [ ] 신규 스토리 DLC

---

## 💻 시스템 요구사항

- **엔진**: Godot 4.4 이상
- **OS**: Windows 10/11 (64-bit)
- **권장**: 60 FPS @ 100 유닛

---

## 📜 라이선스

- POC 도구 코드: MIT License
- 원본 게임 에셋: © Kure Software Koubou
