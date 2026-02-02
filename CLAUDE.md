# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

First Queen 4 (DOS, 1994) HD 리메이크 프로젝트. 실시간 전술 RPG의 핵심 시스템인 "Gocha-Kyara"(AI 동료 자동 제어)를 Godot 4.4로 구현.

| 항목 | 내용 |
|------|------|
| 엔진 | Godot 4.4 (Forward+) |
| 언어 | GDScript (게임), Python (에셋 도구) |
| 해상도 | 1280x800 (원본 320x200 업스케일) |

## 빌드 및 실행

### Godot 게임

```powershell
# 에디터에서 실행
.\Godot_v4.4-stable_win64.exe --path godot

# 직접 게임 실행
.\Godot_v4.4-stable_win64.exe --path godot --main-loop

# 성능 벤치마크 (headless)
.\Godot_v4.4-stable_win64.exe --path godot --headless --script scripts/test/headless_benchmark.gd
```

### Python 에셋 도구

```powershell
# 의존성 설치
pip install Pillow

# 전체 에셋 추출
python tools/fq4_extractor.py extract-all --output output

# 개별 추출
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output
python tools/fq4_extractor.py decode GAME/FQOP_01 --output output
python tools/fq4_extractor.py chr GAME/FQ4.CHR --output output/sprites
python tools/fq4_extractor.py text GAME/FQ4MES --output output/text

# 테스트
python tools/test_extraction.py
```

## 아키텍처

### 디렉토리 구조

```
Fq4/
├── godot/                   # Godot 4.4 프로젝트
│   ├── scripts/autoload/    # 싱글톤 (GameManager, SaveSystem 등)
│   ├── scripts/units/       # 유닛 클래스 (Unit, AIUnit, EnemyUnit)
│   ├── scripts/systems/     # 게임 시스템 (Combat, Fatigue, Stats 등)
│   └── scenes/              # 씬 파일 (.tscn)
├── tools/                   # Python 에셋 추출기
│   └── fq4_extractor.py     # 메인 CLI 도구
├── GAME/                    # 원본 게임 파일 (gitignore)
└── output/                  # 추출된 에셋 (gitignore)
```

### Godot Autoload 싱글톤

| 싱글톤 | 역할 |
|--------|------|
| `GameManager` | 게임 상태, 유닛/부대 관리, Gocha-Kyara 컨트롤 |
| `SaveSystem` | 세이브/로드 |
| `GraphicsManager` | 그래픽 설정, 셰이더 관리 |
| `ProgressionSystem` | 레벨업, 경험치 |
| `ChapterManager` | 챕터/맵 전환 |
| `EventSystem` | 이벤트 트리거 |

### Gocha-Kyara 시스템 (핵심)

플레이어는 1명만 직접 조작, 나머지 부대원은 AI가 자동 제어.

**클래스 계층:**
```
Unit (unit.gd)
├── AIUnit (ai_unit.gd)     # Gocha-Kyara AI 유닛
│   └── PlayerUnit (player_unit.gd)
└── EnemyUnit (enemy_unit.gd)
```

**AI 상태 머신 (AIUnit.AIState):**
- `FOLLOW`: 리더 따라가기 (V자 대형)
- `CHASE` → `ATTACK`: 적 감지 시 추격 후 공격
- `RETREAT` → `REST`: 피로도/HP 낮으면 후퇴 후 휴식
- 성격(Personality)에 따라 행동 우선순위 변화

**피로도 시스템 (FatigueSystem):**
- 이동/공격 시 피로도 증가
- 단계별 페널티: NORMAL → TIRED(-20% 속도) → EXHAUSTED(-50%) → COLLAPSED(행동 불가)

### 에셋 포맷

| 포맷 | 파일 | 설명 |
|------|------|------|
| RGBE | `.B_`, `.R_`, `.G_`, `.E_` | 4-plane 320x200 이미지 |
| CHR | `.CHR` | 8x8 타일 스프라이트 (4bpp planar) |
| Bank | `*BANK*` | 압축 에셋 아카이브 |
| FQ4MES | 텍스트 | Shift-JIS + 치환 암호 (미해독) |

## 테스트 씬

| 씬 | 경로 | 용도 |
|----|------|------|
| 메인 게임 | `scenes/game/main_game.tscn` | 기본 실행 |
| AI 테스트 | `scenes/test/ai_test.tscn` | Gocha-Kyara 동작 확인 |
| 성능 테스트 | `scenes/test/performance_test.tscn` | 100 유닛 벤치마크 |

## 조작법

| 키 | 동작 |
|----|------|
| WASD | 유닛 이동 |
| ← → | 부대 내 캐릭터 전환 |
| ↑ ↓ | 부대 전환 |
| Space | 공격 |
| 우클릭 | 이동 명령 |
