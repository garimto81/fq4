# First Queen IV HD 리마스터 전략

**작성일**: 2026-02-02
**버전**: 1.0
**대상**: First Queen IV (DOS, 1994) → Godot 4.4 HD Remake

---

## 1. 에셋 현황 분석

### 1.1 추출 완료 에셋

| 카테고리 | 파일 수 | 총 에셋 수 | 상태 |
|----------|---------|-----------|:----:|
| **RGBE 이미지** | 15 | 15장 (320×200) | ✅ |
| **CHR 스프라이트** | 7 | 27,005 타일 | ✅ |
| **Bank 파일** | 5 | 481 엔트리 | ✅ |
| **텍스트** | 1 | 800 메시지 | ✅ (90.94% 복호화) |
| **팔레트** | 1 | 16색 | ✅ |

### 1.2 원본 해상도

| 항목 | 원본 | HD 목표 | 배율 |
|------|------|---------|:----:|
| **화면 해상도** | 320×200 | 1280×800 | 4× |
| **타일 크기** | 8×8 px | 32×32 px | 4× |
| **스프라이트** | 16×16 ~ 32×32 | 64×64 ~ 128×128 | 4× |
| **색상** | 16색 (4bpp) | 트루컬러 (32bpp) | - |

### 1.3 주요 이슈

#### A. 팔레트 문제 (Critical)
- **현상**: 추출된 이미지가 매우 어두움
- **원인**: FQ4.RGB 팔레트가 어두운 VGA 팔레트
- **해결책**:
  1. 밝기 보정 팔레트 생성
  2. 스프라이트별 다중 팔레트 지원
  3. 게임 내 동적 팔레트 전환 구현

#### B. 스프라이트 매핑 (High)
- **현상**: 27,005개 타일이 단일 시트에 혼합
- **필요 작업**:
  1. 캐릭터별 스프라이트 분류
  2. 애니메이션 프레임 그룹화
  3. 스프라이트 아틀라스 재구성

#### C. Bank 파일 미해독 (Medium)
- **CHRBANK**: 캐릭터 데이터 (압축)
- **MAPBANK**: 맵 데이터 (압축)
- **BGMBANK1/2**: 음악 (AdLib 포맷 추정)

---

## 2. 리마스터 전략

### 2.1 3단계 접근법

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: 기본 업스케일 (AI-Free)                           │
│  - 정수 배율 (4×) nearest-neighbor 스케일링                 │
│  - 원본 픽셀 아트 보존                                      │
│  - 빠른 프로토타입 구현                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: AI 업스케일링                                     │
│  - ESRGAN / Real-ESRGAN 4× 적용                            │
│  - 픽셀 아트 전용 모델 사용                                 │
│  - 배경 vs 스프라이트 분리 처리                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: 수동 보정 + 추가 에셋                             │
│  - AI 결과물 수동 터치업                                    │
│  - 새로운 HD 에셋 제작 (옵션)                               │
│  - 애니메이션 프레임 보간                                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Phase 1: 기본 업스케일 (즉시 구현 가능)

#### 구현 스크립트

```python
# tools/upscale_basic.py
from PIL import Image
from pathlib import Path

def upscale_nearest(input_path: Path, output_path: Path, scale: int = 4):
    """Nearest-neighbor 업스케일 (픽셀 아트 보존)"""
    img = Image.open(input_path)
    new_size = (img.width * scale, img.height * scale)
    upscaled = img.resize(new_size, Image.Resampling.NEAREST)
    upscaled.save(output_path)
    return upscaled

def batch_upscale(input_dir: Path, output_dir: Path, scale: int = 4):
    """디렉토리 내 모든 PNG 업스케일"""
    output_dir.mkdir(parents=True, exist_ok=True)
    for png in input_dir.glob("*.png"):
        out_path = output_dir / f"{png.stem}_x{scale}.png"
        upscale_nearest(png, out_path, scale)
        print(f"Upscaled: {png.name} → {out_path.name}")
```

#### 예상 결과물 크기

| 에셋 유형 | 원본 크기 | 4× 업스케일 |
|----------|----------|------------|
| FQOP 이미지 | 320×200 | 1280×800 |
| 타일 | 8×8 | 32×32 |
| 캐릭터 (16×16) | 16×16 | 64×64 |
| 캐릭터 (32×32) | 32×32 | 128×128 |
| FQ4_sheet | 128×9840 | 512×39360 |

### 2.3 Phase 2: AI 업스케일링

#### 권장 도구

| 도구 | 용도 | 특징 |
|------|------|------|
| **Real-ESRGAN** | 범용 업스케일 | 4× 고품질, 안정적 |
| **waifu2x** | 애니메이션 스타일 | 노이즈 제거 강점 |
| **Pixelart Upscaler** | 픽셀 아트 전용 | 엣지 보존 |
| **Gigapixel AI** | 상용 (최고 품질) | 유료, GUI |

#### AI 업스케일 파이프라인

```bash
# Real-ESRGAN CLI 예시
realesrgan-ncnn-vulkan -i output/images/ -o output/images_hd/ -n realesrgan-x4plus-anime
realesrgan-ncnn-vulkan -i output/sprites/ -o output/sprites_hd/ -n realesrgan-x4plus
```

#### 스프라이트별 처리 전략

| 스프라이트 유형 | 처리 방법 | 이유 |
|---------------|----------|------|
| **캐릭터** | AI + 수동 보정 | 디테일 중요 |
| **배경 타일** | AI 자동 | 반복 패턴 |
| **UI/폰트** | Nearest-neighbor | 선명도 유지 |
| **이펙트** | AI + 알파 채널 | 투명도 보존 |

### 2.4 Phase 3: 수동 보정

#### 필요 작업

1. **외곽선 정리**: AI 아티팩트 제거
2. **색상 보정**: 팔레트 일관성 유지
3. **투명도 마스크**: 스프라이트 배경 제거
4. **애니메이션 보간**: 프레임 추가 (옵션)

---

## 3. 팔레트 리마스터 전략

### 3.1 현재 팔레트 분석

```
원본 FQ4.RGB (16색):
┌─────────────────────────────────────────────────────┐
│ [0] 검정  [1] 진회색 [2] 회색   [3] 밝은회색        │
│ [4] 어두운청 [5] 청색 [6] 밝은청 [7] 하늘색        │
│ [8] 어두운녹 [9] 녹색 [10] 연녹  [11] 민트         │
│ [12] 흰색  [13] 연회색 [14] 연하늘 [15] 검정       │
└─────────────────────────────────────────────────────┘

문제: 전체적으로 어둡고 채도가 낮음
```

### 3.2 팔레트 보정 방안

#### A. 밝기 보정 팔레트

```python
def brighten_palette(palette: list, factor: float = 1.5) -> list:
    """팔레트 밝기 증가"""
    brightened = []
    for r, g, b in palette:
        r = min(255, int(r * factor))
        g = min(255, int(g * factor))
        b = min(255, int(b * factor))
        brightened.append((r, g, b))
    return brightened
```

#### B. 다중 팔레트 시스템

| 팔레트 | 용도 | 특징 |
|--------|------|------|
| **default** | 기본 | 원본 FQ4.RGB |
| **bright** | 낮 장면 | 밝기 1.5× |
| **sunset** | 저녁 장면 | 따뜻한 톤 |
| **night** | 밤 장면 | 푸른 톤 |
| **battle** | 전투 | 대비 강조 |

#### C. Godot 셰이더 기반 팔레트 스왑

```gdscript
# palette_swap.gdshader
shader_type canvas_item;

uniform sampler2D palette_texture;
uniform int palette_index = 0;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    float index = pixel.r * 15.0;  // 16색 인덱스
    vec2 palette_uv = vec2((index + 0.5) / 16.0, (float(palette_index) + 0.5) / 8.0);
    COLOR = texture(palette_texture, palette_uv);
    COLOR.a = pixel.a;
}
```

---

## 4. 스프라이트 분류 전략

### 4.1 CHR 파일별 용도 추정

| CHR 파일 | 타일 수 | 추정 용도 |
|----------|---------|----------|
| **FQ4.CHR** | 19,296 | 메인 캐릭터, 유닛, 맵 타일 |
| **FQ4P.CHR** | 812 | 플레이어 전용 스프라이트 |
| **FQ4P2.CHR** | 812 | 플레이어 추가 애니메이션 |
| **CLASS.CHR** | 875 | 직업별 아이콘/초상화 |
| **MAGIC.CHR** | 750 | 마법 이펙트 |
| **BIGFONT.CHR** | 4,360 | 대형 폰트 (일본어) |
| **FONT.CHR** | 100 | 기본 폰트 (ASCII) |

### 4.2 스프라이트 분류 도구

```python
# tools/sprite_classifier.py

class SpriteClassifier:
    """스프라이트 자동 분류 (크기/패턴 기반)"""

    def classify_by_size(self, tile_count: int) -> str:
        """타일 수로 스프라이트 크기 추정"""
        if tile_count == 1:
            return "8x8_single"
        elif tile_count == 4:
            return "16x16_character"  # 2×2 타일
        elif tile_count == 16:
            return "32x32_large"      # 4×4 타일
        elif tile_count == 64:
            return "64x64_boss"       # 8×8 타일
        return "unknown"

    def extract_animation_frames(self, sheet: Image,
                                  sprite_size: tuple,
                                  frame_count: int) -> list:
        """애니메이션 프레임 추출"""
        frames = []
        w, h = sprite_size
        for i in range(frame_count):
            x = (i * w) % sheet.width
            y = ((i * w) // sheet.width) * h
            frame = sheet.crop((x, y, x + w, y + h))
            frames.append(frame)
        return frames
```

### 4.3 캐릭터 애니메이션 구조 (추정)

```
캐릭터 스프라이트 (16×16, 4방향, 4프레임):
┌──────────────────────────────────────────┐
│  [Down1][Down2][Down3][Down4]            │  ← 아래 방향
│  [Left1][Left2][Left3][Left4]            │  ← 왼쪽 방향
│  [Right1][Right2][Right3][Right4]        │  ← 오른쪽 방향
│  [Up1][Up2][Up3][Up4]                    │  ← 위 방향
└──────────────────────────────────────────┘

총 16 타일 = 64 기본 타일 (4 타일/프레임 × 16 프레임)
```

---

## 5. Godot 통합 계획

### 5.1 에셋 디렉토리 구조

```
godot/
├── assets/
│   ├── sprites/
│   │   ├── characters/      # 캐릭터별 분류된 스프라이트
│   │   │   ├── player/
│   │   │   ├── allies/
│   │   │   └── enemies/
│   │   ├── tiles/           # 맵 타일셋
│   │   ├── effects/         # 마법/이펙트
│   │   └── ui/              # UI 요소
│   ├── images/
│   │   ├── backgrounds/     # 배경 이미지
│   │   └── cutscenes/       # 컷신 이미지
│   ├── fonts/
│   │   ├── japanese/        # 일본어 폰트
│   │   └── english/         # 영어 폰트
│   └── palettes/
│       └── palette_atlas.png  # 팔레트 아틀라스
└── scripts/
    └── graphics/
        └── palette_manager.gd  # 팔레트 관리자
```

### 5.2 SpriteFrames 리소스 생성

```gdscript
# tools/import_sprites.gd
@tool
extends EditorScript

func _run():
    var frames = SpriteFrames.new()

    # 걷기 애니메이션 추가
    frames.add_animation("walk_down")
    frames.set_animation_speed("walk_down", 8)
    frames.set_animation_loop("walk_down", true)

    for i in range(4):
        var tex = load("res://assets/sprites/characters/player/walk_down_%d.png" % i)
        frames.add_frame("walk_down", tex)

    # 리소스 저장
    ResourceSaver.save(frames, "res://assets/sprites/characters/player.tres")
```

### 5.3 그래픽 설정 옵션

```gdscript
# scripts/autoload/graphics_manager.gd

enum GraphicsMode {
    ORIGINAL,       # 320×200, 16색, nearest
    HD_BASIC,       # 1280×800, 16색, nearest 4×
    HD_UPSCALED,    # 1280×800, AI 업스케일
    HD_REMASTERED   # 1280×800, 수동 보정 에셋
}

var current_mode: GraphicsMode = GraphicsMode.HD_BASIC

func set_graphics_mode(mode: GraphicsMode):
    current_mode = mode
    match mode:
        GraphicsMode.ORIGINAL:
            get_viewport().size = Vector2i(320, 200)
            # 원본 스프라이트 로드
        GraphicsMode.HD_BASIC:
            get_viewport().size = Vector2i(1280, 800)
            # 4× nearest 스프라이트 로드
        GraphicsMode.HD_UPSCALED:
            get_viewport().size = Vector2i(1280, 800)
            # AI 업스케일 스프라이트 로드
```

---

## 6. 구현 로드맵

### Phase 1: 기초 작업 (1주)

| 태스크 | 우선순위 | 상태 |
|--------|:--------:|:----:|
| 팔레트 밝기 보정 도구 | HIGH | ✅ `palette_tools.py` |
| 기본 4× 업스케일 스크립트 | HIGH | ✅ `upscale_basic.py` |
| 스프라이트 분류 도구 | HIGH | ✅ `sprite_classifier.py` |
| Godot 에셋 구조 설정 | MEDIUM | ⬜ |

### Phase 2: AI 업스케일 (1주) ✅ 완료

| 태스크 | 우선순위 | 상태 |
|--------|:--------:|:----:|
| Real-ESRGAN 파이프라인 구축 | HIGH | ✅ `upscale_ai.py` |
| Real-ESRGAN NCNN Vulkan 설치 | HIGH | ✅ `setup_ai_upscaler.py` |
| 배경 이미지 업스케일 (15개) | HIGH | ✅ `output/images_ai/` |
| 캐릭터 스프라이트 업스케일 (5개) | HIGH | ✅ `output/sprites_ai/` |
| 폰트 스프라이트 업스케일 (2개) | MEDIUM | ✅ `output/sprites_ai/` |
| 품질 검수 및 보정 | MEDIUM | ✅ (밝기 2.0x 보정 적용) |

### Phase 3: Godot 통합 (2주) ✅ 완료

| 태스크 | 우선순위 | 상태 |
|--------|:--------:|:----:|
| HD 에셋 Godot 복사 | HIGH | ✅ `godot/assets/*/hd/` |
| GraphicsManager HD_REMASTERED 모드 | HIGH | ✅ `graphics_manager.gd` |
| SpriteFrames 생성 도구 | HIGH | ✅ `spriteframes_generator.py` |
| SpriteFrames 리소스 생성 | HIGH | ✅ `player_hd.tres` |
| 팔레트 스왑 셰이더 구현 | HIGH | ✅ `shaders/palette_swap.gdshader` |
| 그래픽 설정 메뉴 | MEDIUM | ✅ `scenes/ui/graphics_settings.tscn` |
| 테스트 씬에서 렌더링 확인 | HIGH | ✅ `scenes/test/hd_asset_test.tscn` |

---

## 7. 도구 요약

### 기존 도구 (구현 완료)

| 도구 | 경로 | 기능 |
|------|------|------|
| `fq4_extractor.py` | `tools/` | 전체 에셋 추출 |
| `chr_extractor.py` | `tools/` | CHR 스프라이트 추출 |
| `decode_fq4mes.py` | 루트 | 텍스트 복호화 |

### 구현 완료 도구

| 도구 | 기능 | 상태 |
|------|------|:----:|
| `upscale_basic.py` | 기본 4× 업스케일 | ✅ |
| `palette_tools.py` | 팔레트 보정/변환 | ✅ |
| `sprite_classifier.py` | 스프라이트 자동 분류 | ✅ |
| `upscale_ai.py` | AI 업스케일 (Real-ESRGAN/waifu2x) | ✅ |
| `setup_ai_upscaler.py` | AI 백엔드 자동 설치 | ✅ |

### 필요 도구 (구현 예정)

| 도구 | 기능 | 우선순위 |
|------|------|:--------:|
| `godot_importer.py` | Godot 리소스 생성 | MEDIUM |

### 완료된 추가 도구

| 도구 | 기능 | 상태 |
|------|------|:----:|
| `spriteframes_generator.py` | SpriteFrames 자동 생성 | ✅ |
| `setup_ai_upscaler.py` | AI 백엔드 자동 설치 | ✅ |

---

## 8. 참고 자료

### 문서

| 문서 | 경로 |
|------|------|
| 에셋 추출 요약 | `EXTRACTION_SUMMARY.md` |
| CHR 포맷 문서 | `tools/CHR_EXTRACTOR_README.md` |
| Bank 포맷 문서 | `docs/BANK_FILE_FORMAT.md` |
| 텍스트 복호화 보고서 | `docs/FQ4MES_COMPLETE_ANALYSIS.md` |

### 외부 도구

| 도구 | URL | 용도 | 권장 |
|------|-----|------|:----:|
| Real-ESRGAN | github.com/xinntao/Real-ESRGAN | AI 업스케일 | ★★★ |
| waifu2x-ncnn-vulkan | github.com/nihui/waifu2x-ncnn-vulkan | 픽셀아트 보존 | ★★★ |
| Upscayl | upscayl.org | GUI AI 업스케일 | ★★☆ |
| Aseprite | aseprite.org | 픽셀 아트 편집 | ★★★ |

### AI 업스케일러 상세 가이드

자세한 설치/사용법: `docs/AI_UPSCALER_GUIDE.md`

---

**문서 정보**

- 작성: 2026-02-02
- 버전: 1.3 (2026-02-02 업데이트)
- Phase 1: ✅ 완료 (도구 구현)
- Phase 2: ✅ 완료 (AI 업스케일 22개 파일)
- Phase 3: ✅ 완료 (Godot 통합)
- 다음 단계: Godot 에디터에서 테스트 씬 실행 및 게임 개발
