#!/usr/bin/env python3
"""
Custom Palettes for First Queen 4 Sprites

Since FQ4.RGB is a grayscale placeholder, we need actual color palettes
for character sprites. These are reconstructed based on:
- VGA standard palette conventions
- DOS RPG color schemes of the era
- First Queen series visual style

Usage:
    from custom_palettes import get_palette, PALETTES
    palette = get_palette('fantasy_rpg')
"""

from typing import List, Tuple

# Type alias for RGB tuple
RGB = Tuple[int, int, int]

# ============================================================
# PALETTE DEFINITIONS
# ============================================================

# Standard VGA 16-color palette (EGA compatible)
VGA_16 = [
    (0, 0, 0),       # 0: Black
    (0, 0, 170),     # 1: Dark Blue
    (0, 170, 0),     # 2: Dark Green
    (0, 170, 170),   # 3: Dark Cyan
    (170, 0, 0),     # 4: Dark Red
    (170, 0, 170),   # 5: Dark Magenta
    (170, 85, 0),    # 6: Brown/Orange
    (170, 170, 170), # 7: Light Gray
    (85, 85, 85),    # 8: Dark Gray
    (85, 85, 255),   # 9: Light Blue
    (85, 255, 85),   # 10: Light Green
    (85, 255, 255),  # 11: Light Cyan
    (255, 85, 85),   # 12: Light Red
    (255, 85, 255),  # 13: Light Magenta
    (255, 255, 85),  # 14: Yellow
    (255, 255, 255), # 15: White
]

# Fantasy RPG palette (skin tones, armor, nature)
FANTASY_RPG = [
    (0, 0, 0),       # 0: Transparent/Black
    (56, 56, 56),    # 1: Dark Shadow
    (96, 96, 96),    # 2: Shadow
    (144, 144, 144), # 3: Light Shadow
    (232, 184, 144), # 4: Skin Light
    (200, 144, 104), # 5: Skin Medium
    (152, 104, 72),  # 6: Skin Dark
    (104, 64, 40),   # 7: Skin Shadow
    (48, 80, 144),   # 8: Armor Blue
    (72, 112, 184),  # 9: Armor Blue Light
    (136, 64, 32),   # 10: Leather Brown
    (184, 96, 48),   # 11: Leather Light
    (64, 112, 48),   # 12: Forest Green
    (96, 160, 72),   # 13: Grass Green
    (192, 176, 48),  # 14: Gold/Yellow
    (255, 255, 255), # 15: White/Highlight
]

# Medieval Knight palette (metallic, heraldry)
KNIGHT_PALETTE = [
    (0, 0, 0),       # 0: Black
    (32, 32, 48),    # 1: Dark Steel
    (64, 64, 80),    # 2: Steel Shadow
    (112, 112, 128), # 3: Steel
    (160, 160, 176), # 4: Steel Highlight
    (208, 208, 216), # 5: Silver
    (144, 48, 48),   # 6: Heraldry Red
    (192, 80, 80),   # 7: Heraldry Red Light
    (48, 48, 144),   # 8: Heraldry Blue
    (80, 80, 192),   # 9: Heraldry Blue Light
    (232, 184, 144), # 10: Skin
    (200, 144, 104), # 11: Skin Shadow
    (96, 64, 32),    # 12: Leather
    (144, 96, 48),   # 13: Leather Light
    (224, 192, 64),  # 14: Gold
    (255, 255, 255), # 15: White
]

# Nature/Forest palette (for outdoor scenes)
NATURE_PALETTE = [
    (0, 0, 0),       # 0: Black
    (24, 40, 24),    # 1: Dark Forest
    (40, 64, 40),    # 2: Forest Shadow
    (64, 96, 48),    # 3: Forest
    (96, 144, 64),   # 4: Forest Light
    (128, 176, 80),  # 5: Grass
    (176, 208, 112), # 6: Grass Light
    (88, 64, 40),    # 7: Earth Dark
    (136, 104, 64),  # 8: Earth
    (176, 144, 96),  # 9: Earth Light
    (64, 112, 160),  # 10: Water Dark
    (96, 160, 208),  # 11: Water
    (144, 200, 232), # 12: Water Light
    (160, 128, 96),  # 13: Rock
    (200, 176, 144), # 14: Rock Light
    (255, 255, 255), # 15: White
]

# Fire/Magic palette
MAGIC_PALETTE = [
    (0, 0, 0),       # 0: Black
    (32, 0, 64),     # 1: Dark Purple
    (64, 0, 128),    # 2: Purple
    (128, 0, 192),   # 3: Bright Purple
    (192, 64, 224),  # 4: Light Purple
    (64, 0, 0),      # 5: Dark Red
    (128, 0, 0),     # 6: Red
    (192, 32, 0),    # 7: Orange Red
    (224, 96, 0),    # 8: Orange
    (255, 160, 0),   # 9: Yellow Orange
    (255, 224, 64),  # 10: Yellow
    (0, 64, 128),    # 11: Ice Blue Dark
    (0, 128, 192),   # 12: Ice Blue
    (64, 192, 255),  # 13: Ice Blue Light
    (192, 255, 255), # 14: Ice White
    (255, 255, 255), # 15: White
]

# Japanese RPG skin tone optimized
JRPG_PALETTE = [
    (0, 0, 0),       # 0: Transparent
    (40, 32, 48),    # 1: Outline Dark
    (72, 56, 80),    # 2: Outline
    (255, 224, 200), # 3: Skin Highlight
    (248, 200, 168), # 4: Skin Light
    (232, 168, 128), # 5: Skin
    (200, 128, 96),  # 6: Skin Shadow
    (152, 88, 64),   # 7: Skin Dark
    (64, 48, 112),   # 8: Hair Dark Blue
    (88, 72, 160),   # 9: Hair Blue
    (120, 104, 200), # 10: Hair Blue Light
    (80, 48, 32),    # 11: Hair Brown Dark
    (128, 80, 48),   # 12: Hair Brown
    (176, 120, 72),  # 13: Hair Brown Light
    (240, 216, 64),  # 14: Hair Blonde
    (255, 255, 255), # 15: White
]

# All palettes dictionary
PALETTES = {
    'vga_16': VGA_16,
    'fantasy_rpg': FANTASY_RPG,
    'knight': KNIGHT_PALETTE,
    'nature': NATURE_PALETTE,
    'magic': MAGIC_PALETTE,
    'jrpg': JRPG_PALETTE,
}

def get_palette(name: str) -> List[RGB]:
    """Get palette by name"""
    if name not in PALETTES:
        raise ValueError(f"Unknown palette: {name}. Available: {list(PALETTES.keys())}")
    return PALETTES[name]

def get_palette_bytes(name: str) -> bytes:
    """Get palette as flat byte array (for PIL putpalette)"""
    palette = get_palette(name)
    result = []
    for r, g, b in palette:
        result.extend([r, g, b])
    # Pad to 256 colors
    while len(result) < 768:
        result.append(0)
    return bytes(result)

def create_palette_preview(name: str, output_path: str) -> None:
    """Create a visual preview of the palette"""
    from PIL import Image

    palette = get_palette(name)

    # Create 16x1 image scaled up
    img = Image.new('RGB', (320, 64))

    for i, (r, g, b) in enumerate(palette):
        for x in range(i * 20, (i + 1) * 20):
            for y in range(64):
                img.putpixel((x, y), (r, g, b))

    img.save(output_path)
    print(f"Palette preview saved: {output_path}")


if __name__ == '__main__':
    import sys
    from pathlib import Path

    output_dir = Path('C:/claude/Fq4/output/palettes')
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Generating palette previews...")
    for name in PALETTES:
        output_path = output_dir / f"{name}_preview.png"
        create_palette_preview(name, str(output_path))

    print(f"\nAll palettes saved to: {output_dir}")
    print(f"Available palettes: {list(PALETTES.keys())}")
