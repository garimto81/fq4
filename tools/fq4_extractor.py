#!/usr/bin/env python3
"""
FQ4 Graphics Asset Extractor
Extracts palette and RGBE compressed images from First Queen 4 (DOS game)

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


class FQ4PaletteParser:
    """Parser for FQ4.RGB palette file (88 bytes)"""

    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.palette = []

    def parse(self) -> List[Tuple[int, int, int]]:
        """
        Parse FQ4.RGB palette file

        Analysis:
        - 88 bytes total
        - Appears to be VGA 6-bit palette (0-63 range)
        - Need to convert to 8-bit (0-255)

        Returns:
            List of (R, G, B) tuples in 0-255 range
        """
        with open(self.filepath, 'rb') as f:
            data = f.read()

        if len(data) != 88:
            raise ValueError(f"Expected 88 bytes, got {len(data)}")

        # Try parsing as RGB triplets (88 / 3 = 29.33, so not exact RGB triplets)
        # Try parsing as 22 RGB entries with possible padding
        # Actually: 88 bytes could be 22 entries of 4 bytes each (RGBI format?)

        # Based on hex dump analysis, values are 0x00-0x3C (0-60 in decimal)
        # This suggests VGA 6-bit palette (0-63 range)

        # Try interpretation 1: Every 4th byte might be ignored
        palette = []
        if len(data) == 88:
            # Try reading as 22 RGBI entries (4 bytes each)
            for i in range(0, 88, 4):
                if i + 2 < len(data):
                    r = data[i]
                    g = data[i + 1] if i + 1 < len(data) else 0
                    b = data[i + 2] if i + 2 < len(data) else 0
                    # Convert 6-bit (0-63) to 8-bit (0-255)
                    r = (r * 255) // 63
                    g = (g * 255) // 63
                    b = (b * 255) // 63
                    palette.append((r, g, b))

        # If we don't have enough colors, pad with black
        while len(palette) < 16:
            palette.append((0, 0, 0))

        self.palette = palette[:16]  # Use first 16 colors
        return self.palette


class RGBEDecoder:
    """Decoder for RGBE compressed plane files"""

    def __init__(self, base_path: str):
        """
        Initialize decoder with base path (e.g., "FQOP_01")

        Args:
            base_path: Base filename without extension
        """
        self.base_path = Path(base_path)
        self.width = 0
        self.height = 0
        self.data = None

    def parse_header(self, filepath: Path) -> Tuple[int, int]:
        """
        Parse RGBE file header

        Header structure (first 16 bytes):
        00-01: Unknown (0x0009)
        04-05: Size/dimension? (0x0400 = 1024)
        06-07: Magic/checksum? (0x4711)

        Returns:
            (width, height) tuple
        """
        with open(filepath, 'rb') as f:
            header = f.read(16)

        if len(header) < 16:
            raise ValueError(f"Header too short: {len(header)} bytes")

        # Parse header fields
        field1 = struct.unpack('<H', header[0:2])[0]  # 0x0009
        field2 = struct.unpack('<H', header[4:6])[0]  # 0x0400
        magic = struct.unpack('<H', header[6:8])[0]   # 0x4711

        print(f"Header: field1=0x{field1:04X}, field2=0x{field2:04X}, magic=0x{magic:04X}")

        # Try to deduce dimensions
        # field2 = 0x0400 = 1024 could be total pixels / 256 = 4
        # Common DOS game resolutions: 320x200, 640x480, etc.
        # For now, try 320x200 (standard VGA)
        self.width = 320
        self.height = 200

        return self.width, self.height

    def decompress_rle(self, data: bytes) -> bytes:
        """
        Attempt RLE decompression (common in DOS games)

        Common RLE format:
        - If byte >= 0x80: Repeat next byte (count = byte - 0x80)
        - If byte < 0x80: Copy next 'byte' bytes literally
        """
        result = bytearray()
        i = 0

        while i < len(data):
            control = data[i]
            i += 1

            if control >= 0x80:
                # RLE run
                count = control - 0x80
                if i < len(data):
                    value = data[i]
                    i += 1
                    result.extend([value] * count)
            else:
                # Literal run
                count = control
                if i + count <= len(data):
                    result.extend(data[i:i+count])
                    i += count

        return bytes(result)

    def decompress_lzss(self, data: bytes) -> bytes:
        """
        Attempt LZSS decompression (simple version)
        """
        # Simplified LZSS - this is a placeholder
        # Real LZSS would need proper implementation
        return data

    def load_planes(self) -> Optional[bytes]:
        """
        Load and decompress all 4 RGBE plane files

        Returns:
            Decompressed indexed image data or None
        """
        plane_files = [
            self.base_path.parent / f"{self.base_path.stem}.B_",
            self.base_path.parent / f"{self.base_path.stem}.R_",
            self.base_path.parent / f"{self.base_path.stem}.G_",
            self.base_path.parent / f"{self.base_path.stem}.E_",
        ]

        planes = []
        for pf in plane_files:
            if not pf.exists():
                print(f"Warning: Plane file not found: {pf}")
                return None

            with open(pf, 'rb') as f:
                # Skip header (16 bytes)
                f.seek(16)
                plane_data = f.read()

            print(f"Loaded {pf.name}: {len(plane_data)} bytes")

            # Try decompression methods
            # Method 1: Try as raw data first
            decompressed = plane_data

            # Method 2: Try RLE decompression
            try:
                rle_result = self.decompress_rle(plane_data)
                if len(rle_result) == self.width * self.height:
                    decompressed = rle_result
                    print(f"  RLE decompression successful: {len(decompressed)} bytes")
            except Exception as e:
                print(f"  RLE decompression failed: {e}")

            planes.append(decompressed)

        # Parse header from first plane
        self.parse_header(plane_files[0])

        # Combine planes to create indexed image
        # RGBE typically means 4 bitplanes that combine to create 4-bit (16 color) pixels
        if len(planes) == 4:
            return self.combine_planes(planes)

        return None

    def combine_planes(self, planes: List[bytes]) -> bytes:
        """
        Combine 4 bitplanes into indexed color image

        Each plane contributes one bit per pixel:
        - E plane: bit 0 (LSB)
        - G plane: bit 1
        - R plane: bit 2
        - B plane: bit 3 (MSB)

        Result: 4-bit pixel values (0-15)
        """
        expected_size = self.width * self.height

        # Take minimum size across all planes
        min_size = min(len(p) for p in planes)
        actual_pixels = min(min_size, expected_size)

        result = bytearray(actual_pixels)

        for i in range(actual_pixels):
            # Get bit from each plane
            # Assume planar format: each byte contains 8 pixels
            byte_idx = i // 8
            bit_idx = 7 - (i % 8)

            pixel = 0
            for plane_num, plane in enumerate(planes):
                if byte_idx < len(plane):
                    byte_val = plane[byte_idx]
                    bit = (byte_val >> bit_idx) & 1
                    pixel |= (bit << plane_num)

            result[i] = pixel

        return bytes(result)

    def decode_to_image(self, palette: List[Tuple[int, int, int]]) -> Optional[Image.Image]:
        """
        Decode RGBE files and create PIL Image

        Args:
            palette: List of (R, G, B) tuples

        Returns:
            PIL Image or None on failure
        """
        data = self.load_planes()
        if data is None:
            return None

        # Create indexed color image
        img = Image.new('P', (self.width, self.height))

        # Set palette
        pal_data = []
        for r, g, b in palette:
            pal_data.extend([r, g, b])
        # Pad to 256 colors
        while len(pal_data) < 768:
            pal_data.append(0)
        img.putpalette(pal_data)

        # Put pixel data
        # Truncate or pad data to fit image
        pixel_data = bytearray(self.width * self.height)
        copy_len = min(len(data), len(pixel_data))
        pixel_data[:copy_len] = data[:copy_len]

        img.putdata(pixel_data)

        return img


def cmd_palette(args):
    """Handle 'palette' subcommand"""
    palette_path = Path(args.palette_file)

    if not palette_path.exists():
        print(f"Error: Palette file not found: {palette_path}")
        return 1

    parser = FQ4PaletteParser(palette_path)
    palette = parser.parse()

    print(f"Parsed {len(palette)} colors from {palette_path}")
    print("\nPalette colors (RGB):")
    for i, (r, g, b) in enumerate(palette):
        print(f"  Color {i:2d}: RGB({r:3d}, {g:3d}, {b:3d}) = #{r:02X}{g:02X}{b:02X}")

    # Save palette visualization
    if args.output:
        output_path = Path(args.output)
        output_path.mkdir(parents=True, exist_ok=True)

        # Create 16x16 palette swatch
        swatch = Image.new('RGB', (16 * 32, 32))
        for i, (r, g, b) in enumerate(palette):
            for y in range(32):
                for x in range(32):
                    swatch.putpixel((i * 32 + x, y), (r, g, b))

        swatch_path = output_path / "palette.png"
        swatch.save(swatch_path)
        print(f"\nPalette swatch saved to: {swatch_path}")

    return 0


def cmd_decode(args):
    """Handle 'decode' subcommand"""
    base_name = args.base_name

    # Find palette file
    palette_path = Path(args.palette) if args.palette else Path("C:/claude/Fq4/GAME/FQ4.RGB")

    if not palette_path.exists():
        print(f"Error: Palette file not found: {palette_path}")
        return 1

    # Parse palette
    parser = FQ4PaletteParser(palette_path)
    palette = parser.parse()
    print(f"Loaded {len(palette)} colors from palette")

    # Decode RGBE
    decoder = RGBEDecoder(base_name)
    img = decoder.decode_to_image(palette)

    if img is None:
        print("Error: Failed to decode RGBE image")
        return 1

    # Save output
    output_dir = Path(args.output) if args.output else Path("output")
    output_dir.mkdir(parents=True, exist_ok=True)

    base_filename = Path(base_name).stem
    output_path = output_dir / f"{base_filename}.png"

    img.save(output_path)
    print(f"\nImage saved to: {output_path}")
    print(f"Dimensions: {img.width}x{img.height}")

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="FQ4 Graphics Asset Extractor",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Parse palette file
  python fq4_extractor.py palette C:/claude/Fq4/GAME/FQ4.RGB

  # Decode RGBE image
  python fq4_extractor.py decode C:/claude/Fq4/GAME/FQOP_01 --output C:/claude/Fq4/output
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Palette command
    palette_parser = subparsers.add_parser('palette', help='Parse palette file')
    palette_parser.add_argument('palette_file', help='Path to FQ4.RGB palette file')
    palette_parser.add_argument('--output', '-o', help='Output directory for palette swatch')

    # Decode command
    decode_parser = subparsers.add_parser('decode', help='Decode RGBE image')
    decode_parser.add_argument('base_name', help='Base path to RGBE files (e.g., FQOP_01 without extension)')
    decode_parser.add_argument('--palette', '-p', help='Path to palette file (default: FQ4.RGB)')
    decode_parser.add_argument('--output', '-o', help='Output directory (default: output/)')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    if args.command == 'palette':
        return cmd_palette(args)
    elif args.command == 'decode':
        return cmd_decode(args)
    else:
        parser.print_help()
        return 1


if __name__ == '__main__':
    sys.exit(main())
