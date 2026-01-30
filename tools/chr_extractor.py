#!/usr/bin/env python3
"""
FQ4 CHR Sprite Extractor
Extracts sprite tiles from First Queen 4 CHR files

Author: POC Implementation
Date: 2026-01-30
"""

import struct
import sys
from pathlib import Path
from typing import List, Tuple, Optional
import argparse

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

# Import FQ4PaletteParser from existing fq4_extractor.py
sys.path.insert(0, str(Path(__file__).parent))
try:
    from fq4_extractor import FQ4PaletteParser
except ImportError:
    print("Error: Cannot import FQ4PaletteParser from fq4_extractor.py")
    sys.exit(1)


class CHRExtractor:
    """
    Extracts sprite tiles from CHR files

    CHR Format Analysis:
    - 4bpp planar format (4 bitplanes for 16 colors)
    - Each 8x8 tile = 32 bytes (8 rows × 4 planes)
    - Each 16x16 tile = 128 bytes (16 rows × 4 planes)
    - No header, raw tile data

    Planar format:
    - Plane 0: bits 0 (LSB)
    - Plane 1: bits 1
    - Plane 2: bits 2
    - Plane 3: bits 3 (MSB)
    - Result: 4-bit pixel values (0-15)
    """

    TILE_SIZE_8x8 = 32    # bytes per 8x8 tile
    TILE_SIZE_16x16 = 128  # bytes per 16x16 tile

    def __init__(self, filepath: Path, palette: List[Tuple[int, int, int]]):
        self.filepath = filepath
        self.palette = palette
        self.tiles = []
        self.tile_width = 8
        self.tile_height = 8

    def extract_tiles(self, tile_size: int = 8):
        """
        Extract tiles from CHR file

        Args:
            tile_size: Tile dimension (8 or 16)
        """
        self.tile_width = tile_size
        self.tile_height = tile_size

        bytes_per_tile = self.TILE_SIZE_8x8 if tile_size == 8 else self.TILE_SIZE_16x16

        with open(self.filepath, 'rb') as f:
            data = f.read()

        total_tiles = len(data) // bytes_per_tile
        print(f"File: {self.filepath.name}")
        print(f"Size: {len(data)} bytes")
        print(f"Tile size: {tile_size}x{tile_size}")
        print(f"Total tiles: {total_tiles}")

        self.tiles = []
        for tile_idx in range(total_tiles):
            offset = tile_idx * bytes_per_tile
            tile_data = data[offset:offset + bytes_per_tile]

            if len(tile_data) < bytes_per_tile:
                break

            pixels = self.decode_planar_tile(tile_data, tile_size, tile_size)
            self.tiles.append(pixels)

            # Debug: Show first non-empty tile
            if tile_idx < 10:
                non_zero = sum(1 for p in pixels if p != 0)
                if non_zero > 0:
                    print(f"  Tile {tile_idx}: {non_zero}/{len(pixels)} non-zero pixels, colors: {set(pixels)}")

        print(f"Extracted {len(self.tiles)} tiles")

    def decode_planar_tile(self, data: bytes, width: int, height: int) -> List[int]:
        """
        Decode 4bpp planar tile to indexed pixels

        Planar format for 8x8 tile (32 bytes):
        - Bytes 0-7: Plane 0 (bit 0, LSB)
        - Bytes 8-15: Plane 1 (bit 1)
        - Bytes 16-23: Plane 2 (bit 2)
        - Bytes 24-31: Plane 3 (bit 3, MSB)

        For 16x16 tiles (128 bytes):
        - Each row is 2 bytes (16 bits)
        - Plane size = height * (width // 8)

        Args:
            data: Raw tile data
            width: Tile width
            height: Tile height

        Returns:
            List of pixel indices (0-15)
        """
        pixels = []
        bytes_per_row = width // 8  # Number of bytes per row
        bytes_per_plane = height * bytes_per_row

        for row in range(height):
            for col in range(width):
                pixel = 0

                # Which byte in the row contains this column?
                byte_in_row = col // 8
                bit_in_byte = 7 - (col % 8)  # MSB first

                # Combine bits from all 4 planes
                for plane in range(4):
                    plane_offset = plane * bytes_per_plane
                    row_offset = row * bytes_per_row
                    byte_offset = plane_offset + row_offset + byte_in_row

                    if byte_offset < len(data):
                        byte_val = data[byte_offset]
                        bit = (byte_val >> bit_in_byte) & 1
                        pixel |= (bit << plane)

                pixels.append(pixel)

        return pixels

    def save_sprite_sheet(self, output_path: Path, columns: int = 16):
        """
        Save all tiles as sprite sheet

        Args:
            output_path: Output PNG path
            columns: Number of tiles per row
        """
        if not self.tiles:
            print("No tiles to save")
            return

        total_tiles = len(self.tiles)
        rows = (total_tiles + columns - 1) // columns

        sheet_width = columns * self.tile_width
        sheet_height = rows * self.tile_height

        # Create indexed color image
        img = Image.new('P', (sheet_width, sheet_height), color=0)

        # Set palette
        pal_data = []
        for r, g, b in self.palette:
            pal_data.extend([r, g, b])
        # Pad to 256 colors
        while len(pal_data) < 768:
            pal_data.append(0)
        img.putpalette(pal_data)

        # Draw tiles
        for tile_idx, pixels in enumerate(self.tiles):
            row = tile_idx // columns
            col = tile_idx % columns

            x_offset = col * self.tile_width
            y_offset = row * self.tile_height

            for y in range(self.tile_height):
                for x in range(self.tile_width):
                    pixel_idx = y * self.tile_width + x
                    if pixel_idx < len(pixels):
                        color_idx = pixels[pixel_idx]
                        img.putpixel((x_offset + x, y_offset + y), color_idx)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(output_path)
        print(f"Sprite sheet saved to: {output_path}")
        print(f"Dimensions: {sheet_width}x{sheet_height} ({columns}x{rows} tiles)")

    def save_individual_tiles(self, output_dir: Path):
        """
        Save each tile as individual PNG

        Args:
            output_dir: Output directory
        """
        if not self.tiles:
            print("No tiles to save")
            return

        output_dir.mkdir(parents=True, exist_ok=True)

        # Set palette
        pal_data = []
        for r, g, b in self.palette:
            pal_data.extend([r, g, b])
        while len(pal_data) < 768:
            pal_data.append(0)

        for tile_idx, pixels in enumerate(self.tiles):
            img = Image.new('P', (self.tile_width, self.tile_height), color=0)
            img.putpalette(pal_data)

            for y in range(self.tile_height):
                for x in range(self.tile_width):
                    pixel_idx = y * self.tile_width + x
                    if pixel_idx < len(pixels):
                        color_idx = pixels[pixel_idx]
                        img.putpixel((x, y), color_idx)

            output_path = output_dir / f"tile_{tile_idx:04d}.png"
            img.save(output_path)

        print(f"Saved {len(self.tiles)} individual tiles to: {output_dir}")


def main():
    parser = argparse.ArgumentParser(
        description="FQ4 CHR Sprite Extractor",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Extract 8x8 tiles from FONT.CHR
  python chr_extractor.py C:/claude/Fq4/GAME/FONT.CHR --tile-size 8 --output C:/claude/Fq4/output/sprites/FONT/

  # Extract 16x16 tiles from FQ4.CHR as sprite sheet
  python chr_extractor.py C:/claude/Fq4/GAME/FQ4.CHR --tile-size 16 --output C:/claude/Fq4/output/sprites/FQ4/ --sheet

  # Extract MAGIC.CHR with custom palette
  python chr_extractor.py C:/claude/Fq4/GAME/MAGIC.CHR --tile-size 8 --palette C:/claude/Fq4/GAME/FQ4.RGB --output C:/claude/Fq4/output/sprites/MAGIC/
        """
    )

    parser.add_argument('chr_file', help='Path to CHR file')
    parser.add_argument('--tile-size', type=int, choices=[8, 16], default=8,
                        help='Tile size (8x8 or 16x16, default: 8)')
    parser.add_argument('--palette', '-p',
                        help='Path to palette file (default: C:/claude/Fq4/GAME/FQ4.RGB)')
    parser.add_argument('--output', '-o', required=True,
                        help='Output directory')
    parser.add_argument('--sheet', action='store_true',
                        help='Save as sprite sheet instead of individual tiles')
    parser.add_argument('--columns', type=int, default=16,
                        help='Tiles per row in sprite sheet (default: 16)')
    parser.add_argument('--debug', action='store_true',
                        help='Debug mode: show first tile analysis')
    parser.add_argument('--bright-palette', action='store_true',
                        help='Use bright default palette instead of FQ4.RGB')

    args = parser.parse_args()

    # Validate CHR file
    chr_path = Path(args.chr_file)
    if not chr_path.exists():
        print(f"Error: CHR file not found: {chr_path}")
        return 1

    # Load palette
    if args.bright_palette:
        # Use bright default VGA palette
        palette = [
            (0, 0, 0), (0, 0, 170), (0, 170, 0), (0, 170, 170),
            (170, 0, 0), (170, 0, 170), (170, 85, 0), (170, 170, 170),
            (85, 85, 85), (85, 85, 255), (85, 255, 85), (85, 255, 255),
            (255, 85, 85), (255, 85, 255), (255, 255, 85), (255, 255, 255)
        ]
        print(f"Using bright default palette (16 colors)")
    else:
        palette_path = Path(args.palette) if args.palette else Path("C:/claude/Fq4/GAME/FQ4.RGB")
        if not palette_path.exists():
            print(f"Error: Palette file not found: {palette_path}")
            return 1

        palette_parser = FQ4PaletteParser(palette_path)
        palette = palette_parser.parse()
        print(f"Loaded {len(palette)} colors from palette")

    # Extract tiles
    extractor = CHRExtractor(chr_path, palette)
    extractor.extract_tiles(args.tile_size)

    if not extractor.tiles:
        print("Error: No tiles extracted")
        return 1

    # Save output
    output_dir = Path(args.output)

    if args.sheet:
        # Save as sprite sheet
        sheet_name = chr_path.stem + "_sheet.png"
        output_path = output_dir / sheet_name
        extractor.save_sprite_sheet(output_path, args.columns)
    else:
        # Save individual tiles
        extractor.save_individual_tiles(output_dir)

    return 0


if __name__ == '__main__':
    sys.exit(main())
