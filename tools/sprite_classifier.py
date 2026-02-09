#!/usr/bin/env python3
"""
FQ4 Sprite Classifier
Automatic categorization of 27,005+ sprite tiles by visual characteristics

Usage:
    python tools/sprite_classifier.py analyze --input output/sprites --output output/classified
    python tools/sprite_classifier.py report --input output/sprites
    python tools/sprite_classifier.py extract-unique --input output/sprites --output output/unique_sprites
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from collections import defaultdict
from dataclasses import dataclass, asdict
import hashlib

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: PIL/Pillow and numpy are required.")
    print("Install with: pip install Pillow numpy")
    sys.exit(1)


@dataclass
class SpriteInfo:
    """Information about a single sprite tile"""
    path: str
    width: int
    height: int
    unique_colors: int
    transparency_ratio: float
    brightness: float
    category: str
    hash: str
    is_duplicate: bool = False
    duplicate_of: Optional[str] = None


@dataclass
class CategoryStats:
    """Statistics for a sprite category"""
    count: int
    unique_count: int
    avg_colors: float
    avg_brightness: float
    examples: List[str]


# Sprite category definitions based on visual characteristics
CATEGORIES = {
    'character': {
        'description': 'Character sprites (players, NPCs, enemies)',
        'color_range': (4, 16),
        'transparency_range': (0.1, 0.9),
        'brightness_range': (0.1, 0.8),
    },
    'terrain': {
        'description': 'Terrain tiles (ground, walls, etc.)',
        'color_range': (2, 8),
        'transparency_range': (0.0, 0.3),
        'brightness_range': (0.2, 0.7),
    },
    'ui': {
        'description': 'UI elements (borders, icons, text)',
        'color_range': (2, 6),
        'transparency_range': (0.0, 0.5),
        'brightness_range': (0.3, 1.0),
    },
    'effect': {
        'description': 'Visual effects (magic, explosions)',
        'color_range': (3, 12),
        'transparency_range': (0.3, 0.95),
        'brightness_range': (0.4, 1.0),
    },
    'empty': {
        'description': 'Empty or nearly empty tiles',
        'color_range': (1, 2),
        'transparency_range': (0.9, 1.0),
        'brightness_range': (0.0, 0.1),
    },
    'solid': {
        'description': 'Solid color tiles',
        'color_range': (1, 2),
        'transparency_range': (0.0, 0.1),
        'brightness_range': (0.0, 1.0),
    },
}


def compute_sprite_hash(img: Image.Image) -> str:
    """Compute perceptual hash of sprite for duplicate detection"""
    # Convert to grayscale and resize to 8x8
    gray = img.convert('L').resize((8, 8), Image.Resampling.NEAREST)
    pixels = list(gray.getdata())
    avg = sum(pixels) / len(pixels)

    # Generate hash based on pixel comparison to average
    bits = ''.join('1' if p > avg else '0' for p in pixels)
    return hex(int(bits, 2))[2:].zfill(16)


def analyze_sprite(img_path: Path) -> SpriteInfo:
    """Analyze a single sprite and extract characteristics"""
    img = Image.open(img_path)

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    pixels = list(img.getdata())
    width, height = img.size
    total_pixels = width * height

    # Count unique colors (excluding fully transparent)
    color_set: Set[Tuple[int, int, int]] = set()
    transparent_count = 0
    brightness_sum = 0

    for r, g, b, a in pixels:
        if a < 128:  # Consider as transparent
            transparent_count += 1
        else:
            color_set.add((r, g, b))
            brightness_sum += (r + g + b) / 3

    unique_colors = len(color_set)
    transparency_ratio = transparent_count / total_pixels if total_pixels > 0 else 0

    opaque_count = total_pixels - transparent_count
    brightness = (brightness_sum / opaque_count / 255) if opaque_count > 0 else 0

    # Determine category based on characteristics
    category = classify_sprite(unique_colors, transparency_ratio, brightness)

    # Compute hash for duplicate detection
    sprite_hash = compute_sprite_hash(img)

    return SpriteInfo(
        path=str(img_path),
        width=width,
        height=height,
        unique_colors=unique_colors,
        transparency_ratio=round(transparency_ratio, 3),
        brightness=round(brightness, 3),
        category=category,
        hash=sprite_hash,
    )


def classify_sprite(colors: int, transparency: float, brightness: float) -> str:
    """Classify sprite based on visual characteristics"""
    # Check for empty tiles first
    if colors <= 1 and transparency > 0.9:
        return 'empty'

    # Check for solid color tiles
    if colors <= 2 and transparency < 0.1:
        return 'solid'

    # Check for UI elements (high brightness, low color count)
    if colors <= 6 and brightness > 0.5 and transparency < 0.5:
        return 'ui'

    # Check for effects (high transparency, moderate colors)
    if transparency > 0.4 and colors >= 3:
        return 'effect'

    # Check for terrain (low transparency, moderate colors)
    if transparency < 0.3 and colors <= 8:
        return 'terrain'

    # Default to character
    return 'character'


def find_duplicates(sprites: List[SpriteInfo]) -> List[SpriteInfo]:
    """Find duplicate sprites based on perceptual hash"""
    hash_map: Dict[str, str] = {}  # hash -> first path

    for sprite in sprites:
        if sprite.hash in hash_map:
            sprite.is_duplicate = True
            sprite.duplicate_of = hash_map[sprite.hash]
        else:
            hash_map[sprite.hash] = sprite.path

    return sprites


def analyze_directory(input_dir: Path, recursive: bool = True) -> List[SpriteInfo]:
    """Analyze all sprites in a directory"""
    pattern = '**/*.png' if recursive else '*.png'
    png_files = list(input_dir.glob(pattern))

    print(f"Found {len(png_files)} PNG files in {input_dir}")

    sprites: List[SpriteInfo] = []

    for i, png in enumerate(png_files):
        if (i + 1) % 1000 == 0:
            print(f"  Analyzed {i + 1}/{len(png_files)} sprites...")

        try:
            info = analyze_sprite(png)
            sprites.append(info)
        except Exception as e:
            print(f"  [ERROR] {png}: {e}")

    # Find duplicates
    sprites = find_duplicates(sprites)

    return sprites


def generate_report(sprites: List[SpriteInfo]) -> Dict:
    """Generate classification report"""
    categories: Dict[str, List[SpriteInfo]] = defaultdict(list)

    for sprite in sprites:
        categories[sprite.category].append(sprite)

    report = {
        'total_sprites': len(sprites),
        'unique_sprites': sum(1 for s in sprites if not s.is_duplicate),
        'duplicate_sprites': sum(1 for s in sprites if s.is_duplicate),
        'categories': {},
    }

    for cat_name, cat_sprites in sorted(categories.items()):
        unique_in_cat = [s for s in cat_sprites if not s.is_duplicate]

        avg_colors = sum(s.unique_colors for s in cat_sprites) / len(cat_sprites)
        avg_brightness = sum(s.brightness for s in cat_sprites) / len(cat_sprites)

        # Get example paths (first 5)
        examples = [s.path for s in unique_in_cat[:5]]

        report['categories'][cat_name] = {
            'description': CATEGORIES.get(cat_name, {}).get('description', ''),
            'count': len(cat_sprites),
            'unique_count': len(unique_in_cat),
            'duplicate_count': len(cat_sprites) - len(unique_in_cat),
            'avg_colors': round(avg_colors, 1),
            'avg_brightness': round(avg_brightness, 3),
            'examples': examples,
        }

    return report


def organize_by_category(sprites: List[SpriteInfo], output_dir: Path,
                         copy_files: bool = True) -> Dict[str, int]:
    """Organize sprites into category folders"""
    import shutil

    output_dir.mkdir(parents=True, exist_ok=True)

    counts: Dict[str, int] = defaultdict(int)

    for sprite in sprites:
        if sprite.is_duplicate:
            continue  # Skip duplicates

        cat_dir = output_dir / sprite.category
        cat_dir.mkdir(exist_ok=True)

        src = Path(sprite.path)
        dst = cat_dir / src.name

        if copy_files:
            shutil.copy2(src, dst)

        counts[sprite.category] += 1

    return dict(counts)


def extract_unique_sprites(sprites: List[SpriteInfo], output_dir: Path) -> int:
    """Extract only unique sprites (no duplicates)"""
    import shutil

    output_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for sprite in sprites:
        if sprite.is_duplicate:
            continue

        src = Path(sprite.path)
        dst = output_dir / src.name

        shutil.copy2(src, dst)
        count += 1

    return count


def print_report(report: Dict):
    """Print classification report to console"""
    print(f"\n{'='*60}")
    print("FQ4 Sprite Classification Report")
    print(f"{'='*60}")
    print(f"Total Sprites: {report['total_sprites']:,}")
    print(f"Unique Sprites: {report['unique_sprites']:,}")
    print(f"Duplicate Sprites: {report['duplicate_sprites']:,}")
    print(f"Duplicate Ratio: {report['duplicate_sprites']/report['total_sprites']*100:.1f}%")
    print(f"\n{'='*60}")
    print("Categories:")
    print(f"{'='*60}")

    for cat_name, stats in report['categories'].items():
        print(f"\n[{cat_name.upper()}] {stats['description']}")
        print(f"  Count: {stats['count']:,} ({stats['unique_count']:,} unique)")
        print(f"  Avg Colors: {stats['avg_colors']}")
        print(f"  Avg Brightness: {stats['avg_brightness']}")
        if stats['examples']:
            print(f"  Examples:")
            for ex in stats['examples'][:3]:
                print(f"    - {Path(ex).name}")


def main():
    parser = argparse.ArgumentParser(
        description='FQ4 Sprite Classifier - Automatic sprite categorization'
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Analyze command
    analyze_parser = subparsers.add_parser('analyze', help='Analyze and classify sprites')
    analyze_parser.add_argument('--input', '-i', type=Path, required=True,
                                help='Input directory with sprites')
    analyze_parser.add_argument('--output', '-o', type=Path,
                                help='Output directory for classified sprites')
    analyze_parser.add_argument('--no-copy', action='store_true',
                                help='Skip copying files, only generate report')
    analyze_parser.add_argument('--report', '-r', type=Path,
                                help='Output path for JSON report')

    # Report command
    report_parser = subparsers.add_parser('report', help='Generate classification report')
    report_parser.add_argument('--input', '-i', type=Path, required=True,
                               help='Input directory with sprites')
    report_parser.add_argument('--output', '-o', type=Path,
                               help='Output path for JSON report')

    # Extract unique command
    unique_parser = subparsers.add_parser('extract-unique',
                                          help='Extract only unique sprites')
    unique_parser.add_argument('--input', '-i', type=Path, required=True,
                               help='Input directory with sprites')
    unique_parser.add_argument('--output', '-o', type=Path, required=True,
                               help='Output directory for unique sprites')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if args.command == 'analyze':
        print(f"\n=== FQ4 Sprite Classifier ===")
        print(f"Input: {args.input}")

        sprites = analyze_directory(args.input)
        report = generate_report(sprites)

        print_report(report)

        if args.output and not args.no_copy:
            print(f"\nOrganizing sprites into {args.output}...")
            counts = organize_by_category(sprites, args.output, copy_files=True)
            print("Category file counts:")
            for cat, count in sorted(counts.items()):
                print(f"  {cat}: {count}")

        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            with open(args.report, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, ensure_ascii=False)
            print(f"\nReport saved to: {args.report}")

    elif args.command == 'report':
        print(f"\n=== FQ4 Sprite Classification Report ===")

        sprites = analyze_directory(args.input)
        report = generate_report(sprites)

        print_report(report)

        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, ensure_ascii=False)
            print(f"\nReport saved to: {args.output}")

    elif args.command == 'extract-unique':
        print(f"\n=== Extracting Unique Sprites ===")
        print(f"Input: {args.input}")
        print(f"Output: {args.output}")

        sprites = analyze_directory(args.input)
        count = extract_unique_sprites(sprites, args.output)

        print(f"\nExtracted {count:,} unique sprites to {args.output}")


if __name__ == '__main__':
    main()
