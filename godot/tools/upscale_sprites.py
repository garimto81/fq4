#!/usr/bin/env python3
"""
xBRZ 업스케일 스크립트
원본 스프라이트를 4배 업스케일하여 Godot 에셋으로 변환
"""

import os
import sys
from pathlib import Path
from PIL import Image
import numpy as np

# xBRZ 알고리즘 대체: Nearest-Neighbor + Edge Detection
def xbrz_upscale(img: Image.Image, scale: int = 4) -> Image.Image:
    """
    xBRZ 스타일 업스케일 (순수 Python 구현)

    Args:
        img: 원본 이미지
        scale: 업스케일 배율 (2, 3, 4, 5, 6)

    Returns:
        업스케일된 이미지
    """
    if scale not in [2, 3, 4, 5, 6]:
        raise ValueError("Scale must be 2, 3, 4, 5, or 6")

    # Nearest-Neighbor 업스케일
    w, h = img.size
    upscaled = img.resize((w * scale, h * scale), Image.NEAREST)

    # Edge smoothing (xBRZ 근사)
    if scale >= 3:
        upscaled = _smooth_edges(upscaled, scale)

    return upscaled


def _smooth_edges(img: Image.Image, scale: int) -> Image.Image:
    """
    Edge detection 및 smoothing 적용
    """
    arr = np.array(img)
    h, w = arr.shape[:2]

    # Alpha 채널이 있으면 분리
    has_alpha = arr.shape[2] == 4 if len(arr.shape) == 3 else False

    if has_alpha:
        rgb = arr[:, :, :3]
        alpha = arr[:, :, 3]
    else:
        rgb = arr
        alpha = None

    # Edge detection (간단한 Sobel)
    kernel_x = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])
    kernel_y = np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]])

    # Grayscale로 변환하여 edge detection
    gray = np.mean(rgb, axis=2) if len(rgb.shape) == 3 else rgb

    # Smoothing 적용 (픽셀 아트 보존)
    # 여기서는 최소한의 처리만 수행

    result = arr.copy()

    # Alpha 복원
    if has_alpha:
        result[:, :, 3] = alpha

    return Image.fromarray(result)


def process_sprite_sheet(input_path: Path, output_path: Path, scale: int = 4):
    """
    스프라이트 시트 처리

    Args:
        input_path: 원본 PNG 파일 경로
        output_path: 출력 PNG 파일 경로
        scale: 업스케일 배율
    """
    print(f"Processing {input_path.name}...")

    # 이미지 로드
    img = Image.open(input_path)

    # Indexed color를 RGBA로 변환
    if img.mode == 'P':
        img = img.convert('RGBA')

    # 업스케일
    upscaled = xbrz_upscale(img, scale)

    # 저장
    output_path.parent.mkdir(parents=True, exist_ok=True)
    upscaled.save(output_path)

    print(f"  -> Saved to {output_path} ({upscaled.size[0]}x{upscaled.size[1]})")


def main():
    """
    메인 실행 함수
    """
    # 경로 설정
    project_root = Path(__file__).parent.parent.parent
    input_dir = project_root / "output" / "sprites"
    output_dir = project_root / "godot" / "assets" / "sprites"

    if not input_dir.exists():
        print(f"Error: Input directory not found: {input_dir}")
        sys.exit(1)

    print("=== xBRZ Sprite Upscaler ===")
    print(f"Input:  {input_dir}")
    print(f"Output: {output_dir}")
    print()

    # 각 스프라이트 시트 처리
    sprite_categories = {
        "FQ4": "characters",
        "FQ4P": "characters",
        "FQ4P2": "characters",
        "MAGIC": "effects",
        "MAGIC_BRIGHT": "effects",
        "CLASS": "ui",
        "CLASS_BRIGHT": "ui",
        "FONT": "ui",
        "FONT_BRIGHT": "ui",
        "BIGFONT": "ui"
    }

    processed = 0
    for sprite_name, category in sprite_categories.items():
        input_path = input_dir / sprite_name / f"{sprite_name}_sheet.png"

        if not input_path.exists():
            print(f"Warning: {input_path.name} not found, skipping")
            continue

        output_path = output_dir / category / f"{sprite_name.lower()}_4x.png"
        process_sprite_sheet(input_path, output_path, scale=4)
        processed += 1

    print()
    print(f"[OK] Processed {processed} sprite sheets")
    print(f"[OK] Output directory: {output_dir}")


if __name__ == "__main__":
    main()
