# FQ4 AI Upscaler Guide

## 개요

레트로 게임 에셋을 고품질로 업스케일하기 위한 AI 도구 가이드.
픽셀 아트 특성을 보존하면서 해상도와 품질을 향상시킵니다.

## 무료 AI 업스케일러 비교

### 추천 순위

| 순위 | 도구 | 용도 | 장점 | 단점 |
|:----:|------|------|------|------|
| 1 | **Real-ESRGAN** | 애니메이션/일러스트 | 최고 품질, anime 모델 | GPU 필요 |
| 2 | **waifu2x** | 픽셀 아트 보존 | 원본 픽셀 관계 유지 | 최대 2x |
| 3 | **Upscayl** | 범용 | GUI 제공, 설치 쉬움 | 픽셀아트 약함 |
| 4 | **Video2X** | 비디오 프레임 | 다중 백엔드 지원 | 설정 복잡 |

### 픽셀 아트용 최적 선택

**waifu2x-ncnn-vulkan** - 픽셀 아트 무결성 보존에 최적

> "Waifu2x preserved every pixel's positional relationship. Each glyph scaled exactly with zero distortion."

- 8-bit/16-bit 픽셀 아트의 의도적 제약 존중
- 고정 팔레트, 디더링, 타일 기반 구성 유지
- 수동 후보정 작업 40% 감소

### 애니메이션/일러스트용 최적 선택

**Real-ESRGAN (RealESRGAN_x4plus_anime_6B)**

- 품질 점수: 9.2/10 (ESRGAN 7.5/10 대비)
- JPEG 아티팩트 복원 능력 우수
- 디테일 재구성 공격적

## 설치 방법

### 1. Real-ESRGAN (Python)

```bash
# 기본 설치
pip install realesrgan basicsr torch torchvision

# GPU 가속 (CUDA)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

### 2. Real-ESRGAN NCNN (실행 파일)

다운로드: https://github.com/xinntao/Real-ESRGAN/releases

```
realesrgan-ncnn-vulkan.exe
├── models/
│   ├── realesrgan-x4plus.bin
│   ├── realesrgan-x4plus.param
│   ├── realesrgan-x4plus-anime.bin
│   └── realesrgan-x4plus-anime.param
```

### 3. Upscayl (GUI + CLI)

다운로드: https://upscayl.org/

- Windows 10+ 지원
- Vulkan 호환 GPU 필요
- 통합 GPU는 대부분 미지원

### 4. waifu2x NCNN

다운로드: https://github.com/nihui/waifu2x-ncnn-vulkan/releases

## FQ4 프로젝트 도구 사용법

### 백엔드 확인

```bash
python tools/upscale_ai.py check
```

출력 예시:
```
[REALESRGAN] ✓ Available
  Path: realesrgan (pip package)
  Models: anime, general, video, fast
  Best for: Anime, illustrations, pixel art

[WAIFU2X] ✗ Not found
  Best for: Pixel art preservation, anime
```

### 자동 업스케일 (최적 백엔드 선택)

```bash
python tools/upscale_ai.py auto --input output/images --output output/images_ai --scale 4
```

### Real-ESRGAN 사용

```bash
# anime 모델 (권장)
python tools/upscale_ai.py realesrgan --input output/sprites --output output/sprites_ai -m anime -s 4

# general 모델 (사진/배경)
python tools/upscale_ai.py realesrgan --input output/images --output output/images_ai -m general -s 4
```

### 백엔드 비교

```bash
python tools/upscale_ai.py compare --input sample.png --output comparison/
```

결과:
```
comparison/
├── 00_original_320x200.png
├── 01_nearest_1280x800.png
├── 02_realesrgan_1280x800.png
└── 03_waifu2x_640x400.png
```

## 모델 선택 가이드

### Real-ESRGAN 모델

| 모델 | 용도 | 특징 |
|------|------|------|
| `anime` | 캐릭터 스프라이트 | 라인 보존, 색상 선명 |
| `general` | 배경 이미지 | 텍스처 디테일 강화 |
| `video` | 애니메이션 프레임 | 프레임 일관성 |
| `fast` | 빠른 처리 | 품질 약간 낮음 |

### FQ4 에셋별 권장 설정

| 에셋 유형 | 백엔드 | 모델 | 스케일 |
|-----------|--------|------|--------|
| 캐릭터 스프라이트 | Real-ESRGAN | anime | 4x |
| 배경 이미지 | Real-ESRGAN | general | 4x |
| UI 요소 | waifu2x | - | 2x×2 |
| 타이틀 화면 | Real-ESRGAN | anime | 4x |

## 파이프라인 통합

### 전체 리마스터 워크플로우

```bash
# 1. 팔레트 보정 (밝기)
python tools/palette_tools.py brighten --input output/images --output output/images_bright --factor 1.8

# 2. AI 업스케일 (4x)
python tools/upscale_ai.py realesrgan --input output/images_bright --output output/images_ai -s 4

# 3. (선택) 추가 후처리
python tools/palette_tools.py apply --input output/images_ai --palette bright --output output/images_final
```

### Python API 사용

```python
from tools.upscale_ai import upscale_realesrgan_python
from pathlib import Path

# 단일 이미지 업스케일
success = upscale_realesrgan_python(
    input_path=Path("input.png"),
    output_path=Path("output.png"),
    scale=4,
    model='anime'
)
```

## 품질 비교 결과

### Nearest Neighbor vs AI

| 방식 | 파일 크기 | 처리 시간 | 품질 |
|------|----------|----------|------|
| Nearest 4x | 작음 | 즉시 | 블록 유지 |
| Real-ESRGAN 4x | 큼 | 5-10초/장 | 디테일 추가 |
| waifu2x 2x×2 | 중간 | 2-5초/장 | 픽셀 보존 |

### 픽셀 아트 보존도

| 도구 | 라인 선명도 | 색상 정확도 | 픽셀 경계 |
|------|------------|------------|----------|
| Nearest | ★★★★★ | ★★★★★ | ★★★★★ |
| waifu2x | ★★★★☆ | ★★★★★ | ★★★★☆ |
| Real-ESRGAN | ★★★★☆ | ★★★★☆ | ★★★☆☆ |
| Upscayl | ★★★☆☆ | ★★★★☆ | ★★★☆☆ |

## 시스템 요구사항

### 최소 사양

- **CPU**: 4코어 이상
- **RAM**: 8GB (16GB 권장)
- **GPU**: Vulkan 호환 (NVIDIA/AMD)
- **VRAM**: 4GB 이상

### GPU 없이 사용

```bash
# CPU 전용 모드 (느림)
python tools/upscale_ai.py realesrgan --input img.png --output out.png
# Warning: Running on CPU. GPU recommended for faster processing.
```

## 참고 링크

- [Real-ESRGAN GitHub](https://github.com/xinntao/Real-ESRGAN)
- [Upscayl](https://upscayl.org/)
- [waifu2x-ncnn-vulkan](https://github.com/nihui/waifu2x-ncnn-vulkan)
- [OpenModelDB](https://openmodeldb.info/) - 커스텀 AI 모델
- [PixelScale](https://metimol.github.io/PixelScale/) - 온라인 픽셀아트 업스케일러

## Sources

- [Best Free Pixel Art Upscaler 2025](https://openart.ai/features/pixel-art-upscaler)
- [Real-ESRGAN Alternatives](https://alternativeto.net/software/real-esrgan/)
- [AI Image Upscaling Battle: ESRGAN vs Beyond 2025](https://apatero.com/blog/ai-image-upscaling-battle-esrgan-vs-beyond-2025)
- [Top 5 AI Image Upscalers for AI Art 2026](https://letsenhance.io/blog/all/best-upscalers-ai-art/)
- [Best Free AI Image Upscaler 2026](https://deepdreamgenerator.com/blog/best-free-ai-image-upscaler-2026)
- [6 Best Free Open Source Image Upscalers](https://www.aiarty.com/ai-upscale-image/open-source-image-upscaler-enhancer.htm)
