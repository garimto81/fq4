#!/usr/bin/env python3
"""
DOSBox Palette Capture Tool for First Queen 4

This script:
1. Launches DOSBox with FQ4
2. Takes screenshots at key moments
3. Extracts the VGA palette from screenshots
4. Saves the palette for sprite extraction

Usage:
    python capture_palette.py --auto     # Automated capture
    python capture_palette.py --manual   # Manual instructions
    python capture_palette.py --extract  # Extract from existing screenshots
"""

import os
import sys
import subprocess
import time
from pathlib import Path
from typing import List, Tuple, Optional

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow required. Install with: pip install Pillow")
    sys.exit(1)


# Paths
PROJECT_DIR = Path(__file__).parent.parent
DOSBOX_EXE = PROJECT_DIR / "DOSBox.exe"
DOSBOX_CONF = PROJECT_DIR / "dosbox.conf"
GAME_DIR = PROJECT_DIR / "GAME"
CAPTURE_DIR = PROJECT_DIR / "capture"
OUTPUT_DIR = PROJECT_DIR / "output" / "palettes"


def extract_palette_from_image(image_path: Path) -> List[Tuple[int, int, int]]:
    """
    Extract unique colors from a screenshot (up to 256 colors).
    For VGA mode, we expect 16 or 256 colors.
    """
    img = Image.open(image_path)

    # Convert to RGB if needed
    if img.mode != 'RGB':
        img = img.convert('RGB')

    # Get all unique colors
    colors = img.getcolors(maxcolors=65536)

    if colors is None:
        # Too many colors, use quantization
        img_quantized = img.quantize(colors=256)
        palette = img_quantized.getpalette()
        unique_colors = []
        for i in range(0, len(palette), 3):
            if i + 2 < len(palette):
                unique_colors.append((palette[i], palette[i+1], palette[i+2]))
        return unique_colors[:256]

    # Sort by frequency (most common first)
    colors_sorted = sorted(colors, key=lambda x: -x[0])

    # Extract RGB values
    palette = [color for count, color in colors_sorted]

    return palette


def analyze_vga_palette(colors: List[Tuple[int, int, int]]) -> dict:
    """
    Analyze extracted colors to identify VGA palette characteristics.
    """
    # Check for 6-bit color pattern (values divisible by 4)
    six_bit_count = sum(1 for r, g, b in colors
                        if r % 4 == 0 and g % 4 == 0 and b % 4 == 0)

    # Check for grayscale
    grayscale_count = sum(1 for r, g, b in colors if r == g == b)

    # Find color ranges
    r_range = (min(c[0] for c in colors), max(c[0] for c in colors))
    g_range = (min(c[1] for c in colors), max(c[1] for c in colors))
    b_range = (min(c[2] for c in colors), max(c[2] for c in colors))

    return {
        "total_colors": len(colors),
        "six_bit_pattern": six_bit_count / len(colors) if colors else 0,
        "grayscale_ratio": grayscale_count / len(colors) if colors else 0,
        "r_range": r_range,
        "g_range": g_range,
        "b_range": b_range,
    }


def select_sprite_palette(colors: List[Tuple[int, int, int]]) -> List[Tuple[int, int, int]]:
    """
    Select the best 16 colors for sprite rendering.
    Prioritizes skin tones, common RPG colors.
    """
    # Filter out near-black and near-white
    filtered = [c for c in colors if sum(c) > 30 and sum(c) < 720]

    # If we have less than 16 colors, use what we have
    if len(filtered) <= 16:
        palette_16 = filtered + [(0, 0, 0)] * (16 - len(filtered))
        return palette_16[:16]

    # Simple selection: take most distinct colors
    # Start with black
    selected = [(0, 0, 0)]
    remaining = [c for c in filtered if c != (0, 0, 0)]

    while len(selected) < 16 and remaining:
        # Find color most different from all selected
        best_color = None
        best_min_dist = -1

        for candidate in remaining:
            # Calculate minimum distance to any selected color
            min_dist = min(
                sum((a - b) ** 2 for a, b in zip(candidate, sel))
                for sel in selected
            )

            if min_dist > best_min_dist:
                best_min_dist = min_dist
                best_color = candidate

        if best_color:
            selected.append(best_color)
            remaining.remove(best_color)
        else:
            break

    # Pad with black if needed
    while len(selected) < 16:
        selected.append((0, 0, 0))

    return selected


def save_palette(palette: List[Tuple[int, int, int]], name: str) -> Path:
    """
    Save palette as PNG preview and Python module.
    """
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Save preview image
    preview_path = OUTPUT_DIR / f"{name}_preview.png"
    img = Image.new('RGB', (320, 64))

    color_width = 320 // len(palette)
    for i, (r, g, b) in enumerate(palette):
        for x in range(i * color_width, (i + 1) * color_width):
            for y in range(64):
                img.putpixel((x, y), (r, g, b))

    img.save(preview_path)
    print(f"Palette preview saved: {preview_path}")

    # Save as RGB file (same format as FQ4.RGB)
    rgb_path = OUTPUT_DIR / f"{name}.RGB"
    with open(rgb_path, 'wb') as f:
        for r, g, b in palette:
            # Convert to 6-bit values (0-63)
            f.write(bytes([r // 4, g // 4, b // 4]))
    print(f"RGB palette saved: {rgb_path}")

    # Save as Python dict
    py_path = OUTPUT_DIR / f"{name}_palette.py"
    with open(py_path, 'w') as f:
        f.write(f"# Extracted palette: {name}\n")
        f.write(f"# Generated by capture_palette.py\n\n")
        f.write(f"{name.upper()}_PALETTE = [\n")
        for i, (r, g, b) in enumerate(palette):
            f.write(f"    ({r:3d}, {g:3d}, {b:3d}),  # {i}\n")
        f.write("]\n")
    print(f"Python palette saved: {py_path}")

    return preview_path


def extract_from_captures():
    """
    Extract palettes from existing DOSBox screenshots.
    """
    CAPTURE_DIR.mkdir(parents=True, exist_ok=True)

    # Find all PNG files in capture directory
    screenshots = list(CAPTURE_DIR.glob("*.png"))

    if not screenshots:
        print(f"No screenshots found in {CAPTURE_DIR}")
        print("\nTo capture screenshots:")
        print("1. Run DOSBox with FQ4")
        print("2. Press Ctrl+F5 to take screenshots")
        print("3. Screenshots are saved to 'capture' folder")
        return None

    print(f"Found {len(screenshots)} screenshots:")
    for i, ss in enumerate(screenshots):
        print(f"  [{i}] {ss.name}")

    # Process each screenshot
    all_palettes = []

    for ss_path in screenshots:
        print(f"\nAnalyzing: {ss_path.name}")

        colors = extract_palette_from_image(ss_path)
        analysis = analyze_vga_palette(colors)

        print(f"  Total colors: {analysis['total_colors']}")
        print(f"  6-bit pattern: {analysis['six_bit_pattern']:.1%}")
        print(f"  Grayscale ratio: {analysis['grayscale_ratio']:.1%}")

        # Select best 16 colors for sprites
        palette_16 = select_sprite_palette(colors)
        all_palettes.append((ss_path.stem, palette_16, analysis))

    # Save the most colorful palette
    best_palette = min(all_palettes, key=lambda x: x[2]['grayscale_ratio'])
    name, palette, analysis = best_palette

    print(f"\nBest palette from: {name}")
    print(f"  Grayscale ratio: {analysis['grayscale_ratio']:.1%}")

    save_palette(palette, f"fq4_captured_{name}")

    # Also save combined palette from all screenshots
    all_colors = []
    for ss_path in screenshots:
        all_colors.extend(extract_palette_from_image(ss_path))

    combined_palette = select_sprite_palette(list(set(all_colors)))
    save_palette(combined_palette, "fq4_combined")

    return combined_palette


def create_dosbox_script():
    """
    Create DOSBox autoexec script to run game and capture.
    """
    script_content = f"""
@echo off
mount c "{GAME_DIR}"
c:
FQ4.BAT
"""
    script_path = PROJECT_DIR / "run_fq4.bat"
    with open(script_path, 'w') as f:
        f.write(script_content)
    return script_path


def print_manual_instructions():
    """
    Print instructions for manual palette capture.
    """
    print("""
╔══════════════════════════════════════════════════════════════════╗
║           First Queen 4 - Palette Capture Instructions            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  1. Launch DOSBox:                                                ║
║     > cd C:\\claude\\Fq4                                           ║
║     > DOSBox.exe -conf dosbox.conf                                ║
║                                                                   ║
║  2. In DOSBox, mount and run the game:                            ║
║     Z:\\> mount c GAME                                             ║
║     Z:\\> c:                                                       ║
║     C:\\> FQ4                                                      ║
║                                                                   ║
║  3. Take screenshots at these key moments:                        ║
║     - Title screen (character art)                                ║
║     - Battle scene (sprites visible)                              ║
║     - Status screen (UI colors)                                   ║
║     - Map screen (environment colors)                             ║
║                                                                   ║
║     Press Ctrl+F5 to capture screenshot                           ║
║                                                                   ║
║  4. Screenshots are saved to:                                     ║
║     C:\\claude\\Fq4\\capture\\                                       ║
║                                                                   ║
║  5. Run palette extraction:                                       ║
║     > python tools/capture_palette.py --extract                   ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
""")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="DOSBox Palette Capture for FQ4")
    parser.add_argument('--auto', action='store_true', help='Automated capture')
    parser.add_argument('--manual', action='store_true', help='Show manual instructions')
    parser.add_argument('--extract', action='store_true', help='Extract from existing screenshots')
    parser.add_argument('--launch', action='store_true', help='Launch DOSBox with game')

    args = parser.parse_args()

    if args.manual or (not args.auto and not args.extract and not args.launch):
        print_manual_instructions()
        return

    if args.launch:
        print("Launching DOSBox...")
        print("Press Ctrl+F5 in game to capture screenshots")
        print("Exit DOSBox when done, then run: python tools/capture_palette.py --extract")

        # Create capture directory
        CAPTURE_DIR.mkdir(parents=True, exist_ok=True)

        # Launch DOSBox
        subprocess.Popen([
            str(DOSBOX_EXE),
            "-conf", str(DOSBOX_CONF),
            str(GAME_DIR)
        ], cwd=str(PROJECT_DIR))
        return

    if args.extract:
        palette = extract_from_captures()

        if palette:
            print("\n" + "="*60)
            print("EXTRACTED PALETTE:")
            print("="*60)
            for i, (r, g, b) in enumerate(palette):
                print(f"  [{i:2d}] RGB({r:3d}, {g:3d}, {b:3d})")

            print("\nTo use this palette for sprite extraction:")
            print("  python tools/chr_extractor.py GAME/FQ4P.CHR \\")
            print("    --palette output/palettes/fq4_combined.RGB \\")
            print("    --output output/sprites/FQ4P_REAL \\")
            print("    --sheet")

    if args.auto:
        print("Automated capture not yet implemented.")
        print("Use --launch to open DOSBox, capture screenshots manually,")
        print("then use --extract to process them.")


if __name__ == '__main__':
    main()
