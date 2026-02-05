#!/usr/bin/env python3
"""
FQ4 Palette Tools
Palette correction, conversion, and multi-palette support

Usage:
    python tools/palette_tools.py brighten --input output/images --output output/images_bright --factor 1.5
    python tools/palette_tools.py extract --input output/sprites/FQ4/FQ4_sheet.png --output output/palette_extracted.png
    python tools/palette_tools.py apply --input output/sprites --palette palettes/bright.png --output output/sprites_corrected
"""

import argparse
import sys
from pathlib import Path
from typing import List, Tuple, Optional
from collections import Counter

try:
    from PIL import Image, ImageEnhance
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


# Original FQ4.RGB palette (16 colors, extracted from game)
ORIGINAL_PALETTE = [
    (0, 0, 0),       # 0: Black
    (32, 32, 32),    # 1: Dark gray
    (64, 64, 64),    # 2: Gray
    (96, 96, 96),    # 3: Light gray
    (16, 32, 48),    # 4: Dark blue
    (32, 64, 96),    # 5: Blue
    (64, 96, 128),   # 6: Light blue
    (96, 128, 160),  # 7: Sky blue
    (16, 48, 32),    # 8: Dark green
    (32, 96, 64),    # 9: Green
    (64, 128, 96),   # 10: Light green
    (96, 160, 128),  # 11: Mint
    (160, 160, 160), # 12: White-ish
    (128, 128, 128), # 13: Medium gray
    (128, 160, 192), # 14: Pale sky
    (0, 0, 0),       # 15: Black
]

# Bright palette (1.5x brightness)
BRIGHT_PALETTE = [
    (0, 0, 0),       # 0: Black
    (48, 48, 48),    # 1: Dark gray
    (96, 96, 96),    # 2: Gray
    (144, 144, 144), # 3: Light gray
    (24, 48, 72),    # 4: Dark blue
    (48, 96, 144),   # 5: Blue
    (96, 144, 192),  # 6: Light blue
    (144, 192, 240), # 7: Sky blue
    (24, 72, 48),    # 8: Dark green
    (48, 144, 96),   # 9: Green
    (96, 192, 144),  # 10: Light green
    (144, 240, 192), # 11: Mint
    (240, 240, 240), # 12: White
    (192, 192, 192), # 13: Medium gray
    (192, 240, 255), # 14: Pale sky
    (0, 0, 0),       # 15: Black
]

# Warm sunset palette
SUNSET_PALETTE = [
    (16, 8, 0),      # 0: Dark brown
    (48, 32, 16),    # 1: Brown
    (96, 64, 32),    # 2: Light brown
    (144, 96, 48),   # 3: Tan
    (48, 32, 64),    # 4: Purple tint
    (96, 64, 128),   # 5: Lavender
    (144, 96, 160),  # 6: Light lavender
    (192, 128, 192), # 7: Pink
    (64, 48, 16),    # 8: Olive dark
    (128, 96, 32),   # 9: Olive
    (160, 128, 64),  # 10: Light olive
    (192, 160, 96),  # 11: Gold
    (255, 224, 192), # 12: Cream
    (192, 160, 128), # 13: Beige
    (224, 192, 224), # 14: Pale pink
    (16, 8, 0),      # 15: Dark
]

# Night palette (blue shift)
NIGHT_PALETTE = [
    (0, 0, 16),      # 0: Dark blue-black
    (16, 16, 48),    # 1: Night blue
    (32, 32, 80),    # 2: Blue gray
    (48, 48, 112),   # 3: Light night
    (8, 24, 64),     # 4: Deep blue
    (16, 48, 96),    # 5: Blue
    (32, 72, 128),   # 6: Light blue
    (48, 96, 160),   # 7: Sky blue
    (8, 32, 48),     # 8: Teal dark
    (16, 64, 80),    # 9: Teal
    (32, 96, 112),   # 10: Light teal
    (48, 128, 144),  # 11: Cyan
    (128, 128, 176), # 12: Moonlight
    (80, 80, 128),   # 13: Dusk gray
    (96, 128, 192),  # 14: Night sky
    (0, 0, 16),      # 15: Dark
]

PALETTES = {
    'original': ORIGINAL_PALETTE,
    'bright': BRIGHT_PALETTE,
    'sunset': SUNSET_PALETTE,
    'night': NIGHT_PALETTE,
}


def create_palette_image(palette: List[Tuple[int, int, int]],
                         swatch_size: int = 32) -> Image.Image:
    """Create a visual palette swatch image"""
    width = len(palette) * swatch_size
    height = swatch_size

    img = Image.new('RGB', (width, height))

    for i, color in enumerate(palette):
        for x in range(swatch_size):
            for y in range(swatch_size):
                img.putpixel((i * swatch_size + x, y), color)

    return img


def extract_palette_from_image(img: Image.Image,
                               max_colors: int = 16) -> List[Tuple[int, int, int]]:
    """Extract dominant colors from an image"""
    if img.mode != 'RGB':
        img = img.convert('RGB')

    # Count all colors
    colors = Counter(img.getdata())

    # Get most common colors
    most_common = colors.most_common(max_colors)

    return [color for color, count in most_common]


def apply_palette(img: Image.Image,
                  palette: List[Tuple[int, int, int]]) -> Image.Image:
    """
    Apply a new palette to an indexed image.
    Maps each color to nearest palette color.
    """
    if img.mode not in ('P', 'RGB', 'RGBA'):
        img = img.convert('RGBA')

    has_alpha = img.mode == 'RGBA'

    if has_alpha:
        r, g, b, a = img.split()
        img_rgb = Image.merge('RGB', (r, g, b))
    else:
        img_rgb = img if img.mode == 'RGB' else img.convert('RGB')

    # Create new image with remapped colors
    result = Image.new('RGB', img.size)

    for y in range(img.height):
        for x in range(img.width):
            pixel = img_rgb.getpixel((x, y))
            nearest = find_nearest_color(pixel, palette)
            result.putpixel((x, y), nearest)

    if has_alpha:
        r, g, b = result.split()
        result = Image.merge('RGBA', (r, g, b, a))

    return result


def find_nearest_color(color: Tuple[int, int, int],
                       palette: List[Tuple[int, int, int]]) -> Tuple[int, int, int]:
    """Find nearest color in palette using Euclidean distance"""
    min_dist = float('inf')
    nearest = palette[0]

    for p_color in palette:
        dist = sum((a - b) ** 2 for a, b in zip(color, p_color))
        if dist < min_dist:
            min_dist = dist
            nearest = p_color

    return nearest


def brighten_palette(palette: List[Tuple[int, int, int]],
                     factor: float = 1.5) -> List[Tuple[int, int, int]]:
    """Brighten all colors in palette"""
    brightened = []
    for r, g, b in palette:
        r = min(255, int(r * factor))
        g = min(255, int(g * factor))
        b = min(255, int(b * factor))
        brightened.append((r, g, b))
    return brightened


def adjust_palette_contrast(palette: List[Tuple[int, int, int]],
                            factor: float = 1.2) -> List[Tuple[int, int, int]]:
    """Adjust contrast of palette colors"""
    adjusted = []
    for r, g, b in palette:
        # Center around 128 and scale
        r = min(255, max(0, int(128 + (r - 128) * factor)))
        g = min(255, max(0, int(128 + (g - 128) * factor)))
        b = min(255, max(0, int(128 + (b - 128) * factor)))
        adjusted.append((r, g, b))
    return adjusted


def batch_apply_brightness(input_dir: Path,
                           output_dir: Path,
                           factor: float = 1.5,
                           recursive: bool = True) -> dict:
    """Apply brightness correction to all images in directory"""
    output_dir.mkdir(parents=True, exist_ok=True)

    stats = {'processed': 0, 'errors': 0}

    pattern = '**/*.png' if recursive else '*.png'
    for png in input_dir.glob(pattern):
        try:
            relative = png.relative_to(input_dir)
            out_path = output_dir / relative
            out_path.parent.mkdir(parents=True, exist_ok=True)

            img = Image.open(png)

            if img.mode == 'RGBA':
                r, g, b, a = img.split()
                rgb = Image.merge('RGB', (r, g, b))
                enhancer = ImageEnhance.Brightness(rgb)
                brightened = enhancer.enhance(factor)
                r, g, b = brightened.split()
                result = Image.merge('RGBA', (r, g, b, a))
            else:
                rgb = img.convert('RGB')
                enhancer = ImageEnhance.Brightness(rgb)
                result = enhancer.enhance(factor)

            result.save(out_path, 'PNG')
            stats['processed'] += 1
            print(f"  [OK] {relative}")

        except Exception as e:
            stats['errors'] += 1
            print(f"  [ERROR] {png}: {e}")

    return stats


def create_palette_atlas(output_path: Path) -> Image.Image:
    """
    Create a multi-palette atlas for Godot shader use.
    Each row is a different palette variant.
    """
    swatch_size = 1  # 1 pixel per color for shader lookup
    width = 16 * swatch_size
    height = len(PALETTES) * swatch_size

    atlas = Image.new('RGB', (width, height))

    for row, (name, palette) in enumerate(PALETTES.items()):
        for col, color in enumerate(palette[:16]):
            atlas.putpixel((col, row), color)

    # Save with nearest-neighbor to avoid color blending
    atlas.save(output_path, 'PNG')

    # Also save a larger version for visual inspection
    large = atlas.resize((width * 16, height * 16), Image.Resampling.NEAREST)
    large_path = output_path.parent / f"{output_path.stem}_preview.png"
    large.save(large_path, 'PNG')

    return atlas


def main():
    parser = argparse.ArgumentParser(
        description='FQ4 Palette Tools - Palette correction and conversion'
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Brighten command
    brighten_parser = subparsers.add_parser('brighten', help='Brighten images')
    brighten_parser.add_argument('--input', '-i', type=Path, required=True)
    brighten_parser.add_argument('--output', '-o', type=Path, required=True)
    brighten_parser.add_argument('--factor', '-f', type=float, default=1.5,
                                 help='Brightness factor (default: 1.5)')
    brighten_parser.add_argument('--no-recursive', action='store_true')

    # Extract palette command
    extract_parser = subparsers.add_parser('extract', help='Extract palette from image')
    extract_parser.add_argument('--input', '-i', type=Path, required=True)
    extract_parser.add_argument('--output', '-o', type=Path, required=True)
    extract_parser.add_argument('--colors', '-c', type=int, default=16)

    # Apply palette command
    apply_parser = subparsers.add_parser('apply', help='Apply palette to images')
    apply_parser.add_argument('--input', '-i', type=Path, required=True)
    apply_parser.add_argument('--output', '-o', type=Path, required=True)
    apply_parser.add_argument('--palette', '-p', type=str, required=True,
                              choices=list(PALETTES.keys()) + ['file'],
                              help='Palette name or "file"')
    apply_parser.add_argument('--palette-file', type=Path,
                              help='Custom palette image (if --palette=file)')

    # Create swatches command
    swatch_parser = subparsers.add_parser('swatches', help='Create palette swatch images')
    swatch_parser.add_argument('--output', '-o', type=Path, required=True,
                               help='Output directory')

    # Create atlas command
    atlas_parser = subparsers.add_parser('atlas', help='Create palette atlas for shaders')
    atlas_parser.add_argument('--output', '-o', type=Path, required=True)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if args.command == 'brighten':
        print(f"\n=== Brightening images (factor: {args.factor}) ===")
        stats = batch_apply_brightness(
            args.input,
            args.output,
            args.factor,
            not args.no_recursive
        )
        print(f"\nProcessed: {stats['processed']}, Errors: {stats['errors']}")

    elif args.command == 'extract':
        print(f"Extracting palette from {args.input}")
        img = Image.open(args.input)
        palette = extract_palette_from_image(img, args.colors)

        # Create swatch image
        swatch = create_palette_image(palette, 32)
        swatch.save(args.output)

        print(f"Palette ({len(palette)} colors) saved to {args.output}")
        for i, color in enumerate(palette):
            print(f"  [{i:2d}] RGB{color}")

    elif args.command == 'apply':
        print(f"Applying palette '{args.palette}' to images")

        if args.palette == 'file':
            if not args.palette_file:
                print("Error: --palette-file required when using --palette=file")
                return
            pal_img = Image.open(args.palette_file)
            palette = extract_palette_from_image(pal_img, 16)
        else:
            palette = PALETTES[args.palette]

        args.output.mkdir(parents=True, exist_ok=True)

        for png in args.input.glob('**/*.png'):
            relative = png.relative_to(args.input)
            out_path = args.output / relative
            out_path.parent.mkdir(parents=True, exist_ok=True)

            img = Image.open(png)
            result = apply_palette(img, palette)
            result.save(out_path)
            print(f"  [OK] {relative}")

    elif args.command == 'swatches':
        print(f"Creating palette swatches in {args.output}")
        args.output.mkdir(parents=True, exist_ok=True)

        for name, palette in PALETTES.items():
            swatch = create_palette_image(palette, 32)
            swatch_path = args.output / f"palette_{name}.png"
            swatch.save(swatch_path)
            print(f"  Created: {swatch_path}")

    elif args.command == 'atlas':
        print(f"Creating palette atlas at {args.output}")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        atlas = create_palette_atlas(args.output)
        print(f"Atlas saved: {args.output} ({atlas.width}×{atlas.height})")
        print(f"Preview saved: {args.output.stem}_preview.png")


if __name__ == '__main__':
    main()
