# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

First Queen 4 (DOS, 1994) HD 리메이크 프로젝트. 실시간 전술 RPG의 핵심 시스템인 "Gocha-Kyara"(AI 동료 자동 제어)를 Godot 4.4로 구현.

| 항목 | 내용 |
|------|------|
| 엔진 | Godot 4.4 (Forward+) |
| 언어 | GDScript (게임), Python (에셋 도구) |
| 해상도 | 1280x800 (원본 320x200의 4배 업스케일) |

## 빌드 및 실행

### Godot 게임

```powershell
# 에디터 열기
.\Godot_v4.4-stable_win64.exe --path godot --editor

# 게임 직접 실행
.\Godot_v4.4-stable_win64.exe --path godot

# 특정 씬 실행
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/ai_test.tscn

# Headless 벤치마크
.\Godot_v4.4-stable_win64.exe --path godot --headless --script res://scripts/test/headless_benchmark.gd
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
python tools/fq4_extractor.py bank GAME/CHRBANK --output output/chrbank

# 테스트
python tools/test_extraction.py

# SpriteFrames 리소스 생성 (Godot용)
python tools/spriteframes_generator.py --input output/sprites --output godot/resources/sprites
```

### AI 업스케일 (HD 에셋 생성)

```powershell
# 백엔드 확인
python tools/upscale_ai.py check

# 이미지 AI 업스케일 (권장: realesrgan-ncnn)
python tools/upscale_ai.py realesrgan-ncnn -i output/images -o output/images_ai -s 4 -m anime

# 스프라이트 AI 업스케일
python tools/upscale_ai.py realesrgan-ncnn -i output/sprites -o output/sprites_ai -s 4 -m anime

# 단일 파일 업스케일
python tools/upscale_ai.py realesrgan-ncnn -i output/images/FQOP_01.png -o output/test/FQOP_01_ai.png -s 4

# 기본 업스케일 (nearest-neighbor, 픽셀 보존)
python tools/upscale_basic.py batch -i output/images -o output/images_hd -s 4
```

**AI 업스케일 백엔드:**

| 백엔드 | 명령 | 설명 | 권장 용도 |
|--------|------|------|----------|
| `realesrgan-ncnn` | 로컬 실행 | GPU 가속, 네트워크 불필요 | **권장** - 모든 에셋 |
| `realesrgan` | Python 패키지 | 모델 다운로드 필요 (Error 400 가능) | 피하기 |
| `waifu2x` | 로컬 실행 | 픽셀아트 특화 | 스프라이트 |

**Error 400 해결:** `realesrgan` 대신 `realesrgan-ncnn` 사용. 로컬 NCNN 백엔드는 네트워크 요청 없이 동작.

## 아키텍처

### 핵심 디렉토리

```
Fq4/
├── godot/                      # Godot 4.4 프로젝트
│   ├── scripts/autoload/       # 7개 싱글톤
│   ├── scripts/units/          # 유닛 클래스 계층
│   ├── scripts/systems/        # 게임 시스템 (Combat, Fatigue, Stats 등)
│   ├── scenes/game/            # 메인 게임 씬
│   ├── scenes/maps/chapter1~3/ # 챕터별 맵
│   └── scenes/test/            # 테스트 씬
├── tools/                      # Python 에셋 도구
│   ├── fq4_extractor.py        # 메인 CLI (palette, decode, chr, bank, text)
│   ├── spriteframes_generator.py # Godot SpriteFrames 생성
│   └── upscale_ai.py           # AI 업스케일러 (Real-ESRGAN)
├── GAME/                       # 원본 게임 파일 (gitignore)
└── output/                     # 추출된 에셋 (gitignore)
```

### Godot Autoload 싱글톤

| 싱글톤 | 경로 | 역할 |
|--------|------|------|
| `GameManager` | autoload/game_manager.gd | Gocha-Kyara 핵심: 부대/유닛 관리, 조작 전환 |
| `SaveSystem` | autoload/save_system.gd | 세이브/로드 |
| `GraphicsManager` | autoload/graphics_manager.gd | 그래픽 설정, 셰이더 |
| `ProgressionSystem` | autoload/progression_system.gd | 레벨업, 경험치 |
| `ChapterManager` | autoload/chapter_manager.gd | 챕터/맵 전환 |
| `EventSystem` | events/event_system.gd | 이벤트 트리거 |
| `AudioManager` | autoload/audio_manager.gd | 사운드/BGM |

### Gocha-Kyara 시스템 (핵심)

플레이어는 1명만 직접 조작, 나머지 부대원은 AI가 자동 제어.

**클래스 계층:**
```
Unit (unit.gd)                    # 기본 속성: HP, MP, 피로도, 상태머신
├── AIUnit (ai_unit.gd)           # Gocha-Kyara AI: 9개 상태, 3개 성격, 5개 대형
│   └── PlayerUnit (player_unit.gd)
└── EnemyUnit (enemy_unit.gd)
```

**AIUnit.AIState (9개):**
- `IDLE` → `FOLLOW`: 리더 따라가기 (V자/원형/쐐기/일렬/분산 대형)
- `CHASE` → `ATTACK`: 적 감지 시 추격 후 공격
- `RETREAT` → `REST`: HP/피로도 낮으면 후퇴 후 휴식
- `DEFEND`, `SUPPORT`, `PATROL`

**Personality (성격별 행동 차이):**
| 성격 | 특징 |
|------|------|
| `AGGRESSIVE` | 넓은 감지 범위, 낮은 후퇴 임계값, 공격 우선 |
| `DEFENSIVE` | 좁은 감지 범위, 높은 후퇴 임계값, 리더 근처 유지 |
| `BALANCED` | 상황에 따라 유연하게 대응 |

**Formation (5개 대형):**
`V_SHAPE`(기본), `LINE`, `CIRCLE`, `WEDGE`, `SCATTERED`

**부대 명령 (GameManager → AIUnit):**
```gdscript
GameManager.issue_current_squad_command(SquadCommand.ATTACK_ALL)
GameManager.set_current_squad_formation(Formation.CIRCLE)
```

### 시그널 흐름

```
Unit.unit_died → GameManager.unregister_unit() → _check_game_over()
                                               → controlled_unit_changed (조작 유닛 사망 시)

GameManager.state_changed → UI 업데이트 (BATTLE, PAUSED, VICTORY, GAME_OVER)
GameManager.squad_changed → UI 부대 정보 갱신
```

### 피로도 시스템

| 상태 | 피로도 % | 속도 배율 |
|------|---------|----------|
| NORMAL | 0-30% | 100% |
| TIRED | 30-60% | 80% |
| EXHAUSTED | 60-90% | 50% |
| COLLAPSED | 90%+ | 0% (행동 불가) |

## 에셋 포맷

| 포맷 | 파일 | 설명 |
|------|------|------|
| RGBE | `.B_`, `.R_`, `.G_`, `.E_` | 4-plane 320x200 이미지, 4bpp |
| CHR | `.CHR` | 8x8 타일 스프라이트 (4bpp planar, 타일당 32B) |
| Bank | `CHRBANK`, `MAPBANK` 등 | 16-bit offset table + 압축 엔트리 |
| FQ4MES | 텍스트 | 799개 메시지, 치환 암호 (복호화 완료) |

### RGBE 포맷 상세 (분석 진행 중)

**파일 구조:**
- **Type 9** (B_, G_ 파일): 8바이트 헤더 + 1024바이트 플래그 테이블 + 압축 데이터
- **Type 7** (R_, E_ 파일): 2바이트 헤더 + RLE 압축 데이터

**압축 타입:**
```
Type 9 헤더: [09 00] [00 00] [00 04] [테이블...]
             타입    패딩    테이블크기(1024)

Type 7 헤더: [07 00] [압축데이터...]
             타입
```

**RLE 디코딩 (Type 7):**
- `ctrl >= 0x80`: (ctrl - 0x7F)회 반복
- `ctrl < 0x80`: (ctrl + 1)바이트 리터럴

**알려진 문제:**
- Type 9의 플래그 테이블 기반 압축 해제 알고리즘 미완성
- 디코딩 결과가 노이즈로 나타남 - 추가 리버스 엔지니어링 필요
- **해결책: DOSBox에서 게임 실행 후 스크린샷 캡처 (아래 참조)**

### DOSBox 스크린샷 캡처 (권장)

RGBE 디코딩 대신 DOSBox에서 직접 캡처한 스크린샷 사용:

```powershell
# DOSBox 실행 (프로젝트 폴더에 DOSBox.exe 포함)
.\DOSBox.exe -conf dosbox_capture.conf

# DOSBox 내에서:
# - Ctrl+F5: 스크린샷 캡처 (capture/ 폴더에 저장)
# - Alt+Enter: 전체화면 전환
# - Ctrl+F9: DOSBox 종료
```

**캡처된 스크린샷 위치:**
- 원본: `capture/fq4_dos_*.png` (640x400)
- HD 업스케일: `output/screenshots_dosbox_hd/` (2560x1600, 4x)

**AI 업스케일:**
```powershell
python tools/upscale_ai.py realesrgan-ncnn -i output/screenshots_dosbox -o output/screenshots_dosbox_hd -s 4 -m anime
```

## 테스트 씬

| 씬 | 경로 | 용도 |
|----|------|------|
| 메인 게임 | `scenes/game/main_game.tscn` | 기본 실행 (project.godot 메인) |
| AI 테스트 | `scenes/test/ai_test.tscn` | Gocha-Kyara 동작 확인 |
| 성능 테스트 | `scenes/test/performance_test.tscn` | 다수 유닛 벤치마크 |
| HD 에셋 테스트 | `scenes/test/hd_asset_test.tscn` | 업스케일 스프라이트 확인 |

## 조작법

| 키 | 동작 |
|----|------|
| WASD | 현재 유닛 이동 |
| ← → | 부대 내 캐릭터 전환 |
| ↑ ↓ | 부대 전환 |
| Space | 공격 |
| I | 인벤토리 토글 |
| 우클릭 | 이동 명령 |

## 문서

| 문서 | 내용 |
|------|------|
| `docs/PRD-0001-first-queen-4-remake.md` | 기획서 |
| `docs/FQ4MES_FINAL_REPORT.md` | 텍스트 복호화 결과 |
| `docs/FQ4_DIALOGUE_COLLECTION.md` | 800개 메시지 분석 |
| `docs/GAME_DESIGN_DOCUMENT.md` | 게임 설계 문서 |
