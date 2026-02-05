#!/usr/bin/env python3
"""
FQ4 Basic Upscale Tool
Nearest-neighbor upscaling for pixel art preservation

Usage:
    python tools/upscale_basic.py --input output/images --output output/images_hd --scale 4
    python tools/upscale_basic.py --input output/sprites --output output/sprites_hd --scale 4
"""

import argparse
import sys
from pathlib import Path
from typing import Optional, Tuple

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


def upscale_nearest(input_path: Path, output_path: Path, scale: int = 4) -> Image.Image:
    """
    Nearest-neighbor upscale (preserves pixel art)

    Args:
        input_path: Source image path
        output_path: Destination path
        scale: Scale factor (default 4x)

    Returns:
        Upscaled PIL Image
    """
    img = Image.open(input_path)

    # Convert to RGBA if needed (preserve transparency)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    new_size = (img.width * scale, img.height * scale)
    upscaled = img.resize(new_size, Image.Resampling.NEAREST)
    upscaled.save(output_path, 'PNG')

    return upscaled


def brighten_image(img: Image.Image, factor: float = 1.5) -> Image.Image:
    """
    Brighten image by factor

    Args:
        img: PIL Image
        factor: Brightness multiplier (1.0 = no change)

    Returns:
        Brightened PIL Image
    """
    from PIL import ImageEnhance

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Split alpha channel
    r, g, b, a = img.split()
    rgb = Image.merge('RGB', (r, g, b))

    # Enhance brightness
    enhancer = ImageEnhance.Brightness(rgb)
    brightened = enhancer.enhance(factor)

    # Restore alpha
    r, g, b = brightened.split()
    return Image.merge('RGBA', (r, g, b, a))


def batch_upscale(
    input_dir: Path,
    output_dir: Path,
    scale: int = 4,
    brighten: Optional[float] = None,
    recursive: bool = True
) -> dict:
    """
    Batch upscale all PNG files in directory

    Args:
        input_dir: Source directory
        output_dir: Destination directory
        scale: Scale factor
        brighten: Optional brightness factor
        recursive: Process subdirectories

    Returns:
        Statistics dict
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    stats = {
        'processed': 0,
        'skipped': 0,
        'errors': 0,
        'total_size_before': 0,
        'total_size_after': 0
    }

    # Find all PNG files
    pattern = '**/*.png' if recursive else '*.png'
    png_files = list(input_dir.glob(pattern))

    print(f"Found {len(png_files)} PNG files in {input_dir}")

    for png in png_files:
        try:
            # Preserve directory structure
            relative = png.relative_to(input_dir)
            out_path = output_dir / relative.parent / f"{png.stem}_x{scale}.png"
            out_path.parent.mkdir(parents=True, exist_ok=True)

            # Skip if already exists
            if out_path.exists():
                print(f"  [SKIP] {relative}")
                stats['skipped'] += 1
                continue

            # Read original
            stats['total_size_before'] += png.stat().st_size

            # Upscale
            img = Image.open(png)
            if img.mode != 'RGBA':
                img = img.convert('RGBA')

            # Apply brightness if requested
            if brighten and brighten != 1.0:
                img = brighten_image(img, brighten)

            # Upscale
            new_size = (img.width * scale, img.height * scale)
            upscaled = img.resize(new_size, Image.Resampling.NEAREST)
            upscaled.save(out_path, 'PNG')

            stats['total_size_after'] += out_path.stat().st_size
            stats['processed'] += 1

            print(f"  [OK] {relative} → {out_path.name} ({img.width}×{img.height} → {new_size[0]}×{new_size[1]})")

        except Exception as e:
            print(f"  [ERROR] {png}: {e}")
            stats['errors'] += 1

    return stats


def create_sprite_atlas(
    sprites_dir: Path,
    output_path: Path,
    tile_size: Tuple[int, int] = (32, 32),
    columns: int = 16
) -> Image.Image:
    """
    Create sprite atlas from individual tiles

    Args:
        sprites_dir: Directory with individual sprite PNGs
        output_path: Output atlas path
        tile_size: Size of each tile (after upscaling)
        columns: Number of columns in atlas

    Returns:
        Atlas PIL Image
    """
    sprites = sorted(sprites_dir.glob('*.png'))

    if not sprites:
        raise ValueError(f"No sprites found in {sprites_dir}")

    rows = (len(sprites) + columns - 1) // columns
    atlas_size = (columns * tile_size[0], rows * tile_size[1])

    atlas = Image.new('RGBA', atlas_size, (0, 0, 0, 0))

    for i, sprite_path in enumerate(sprites):
        sprite = Image.open(sprite_path)
        if sprite.mode != 'RGBA':
            sprite = sprite.convert('RGBA')

        # Resize to tile size if needed
        if sprite.size != tile_size:
            sprite = sprite.resize(tile_size, Image.Resampling.NEAREST)

        x = (i % columns) * tile_size[0]
        y = (i // columns) * tile_size[1]
        atlas.paste(sprite, (x, y))

    atlas.save(output_path, 'PNG')
    return atlas


def main():
    parser = argparse.ArgumentParser(
        description='FQ4 Basic Upscale Tool - Nearest-neighbor upscaling for pixel art'
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Batch upscale command
    batch_parser = subparsers.add_parser('batch', help='Batch upscale directory')
    batch_parser.add_argument('--input', '-i', type=Path, required=True,
                              help='Input directory')
    batch_parser.add_argument('--output', '-o', type=Path, required=True,
                              help='Output directory')
    batch_parser.add_argument('--scale', '-s', type=int, default=4,
                              help='Scale factor (default: 4)')
    batch_parser.add_argument('--brighten', '-b', type=float, default=None,
                              help='Brightness factor (e.g., 1.5 for 50% brighter)')
    batch_parser.add_argument('--no-recursive', action='store_true',
                              help='Do not process subdirectories')

    # Single file command
    single_parser = subparsers.add_parser('single', help='Upscale single file')
    single_parser.add_argument('--input', '-i', type=Path, required=True,
                               help='Input file')
    single_parser.add_argument('--output', '-o', type=Path, required=True,
                               help='Output file')
    single_parser.add_argument('--scale', '-s', type=int, default=4,
                               help='Scale factor (default: 4)')
    single_parser.add_argument('--brighten', '-b', type=float, default=None,
                               help='Brightness factor')

    # Atlas command
    atlas_parser = subparsers.add_parser('atlas', help='Create sprite atlas')
    atlas_parser.add_argument('--input', '-i', type=Path, required=True,
                              help='Input directory with sprites')
    atlas_parser.add_argument('--output', '-o', type=Path, required=True,
                              help='Output atlas file')
    atlas_parser.add_argument('--tile-size', type=int, nargs=2, default=[32, 32],
                              help='Tile size (width height)')
    atlas_parser.add_argument('--columns', '-c', type=int, default=16,
                              help='Number of columns')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if args.command == 'batch':
        print(f"\n=== FQ4 Batch Upscale ===")
        print(f"Input: {args.input}")
        print(f"Output: {args.output}")
        print(f"Scale: {args.scale}×")
        if args.brighten:
            print(f"Brighten: {args.brighten}×")
        print()

        stats = batch_upscale(
            args.input,
            args.output,
            args.scale,
            args.brighten,
            not args.no_recursive
        )

        print(f"\n=== Results ===")
        print(f"Processed: {stats['processed']}")
        print(f"Skipped: {stats['skipped']}")
        print(f"Errors: {stats['errors']}")
        if stats['total_size_before'] > 0:
            ratio = stats['total_size_after'] / stats['total_size_before']
            print(f"Size: {stats['total_size_before'] / 1024:.1f}KB → {stats['total_size_after'] / 1024:.1f}KB ({ratio:.1f}×)")

    elif args.command == 'single':
        print(f"Upscaling {args.input} → {args.output} ({args.scale}×)")

        img = Image.open(args.input)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        if args.brighten:
            img = brighten_image(img, args.brighten)

        new_size = (img.width * args.scale, img.height * args.scale)
        upscaled = img.resize(new_size, Image.Resampling.NEAREST)

        args.output.parent.mkdir(parents=True, exist_ok=True)
        upscaled.save(args.output, 'PNG')

        print(f"Done: {img.width}×{img.height} → {new_size[0]}×{new_size[1]}")

    elif args.command == 'atlas':
        print(f"Creating atlas from {args.input}")

        atlas = create_sprite_atlas(
            args.input,
            args.output,
            tuple(args.tile_size),
            args.columns
        )

        print(f"Atlas saved: {args.output} ({atlas.width}×{atlas.height})")


if __name__ == '__main__':
    main()
