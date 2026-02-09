#!/usr/bin/env python3
"""
FQ4 Comprehensive Asset Extractor
Extracts all asset types from First Queen 4 (DOS game):
- RGBE compressed images (palette + 4-plane graphics)
- CHR sprite files (4bpp planar tiles)
- Bank files (compressed asset banks)
- Text/message files

Author: POC Implementation
Date: 2026-01-30
"""

import struct
import sys
from pathlib import Path
from typing import List, Tuple, Optional, Dict
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
    """Decoder for RGBE compressed plane files (First Queen 4 format)

    File Format Analysis:
    - Type 9 (B_, G_): 6-byte header + 1024-byte flag table + compressed data
    - Type 7 (R_, E_): RLE compressed with different header structure

    Header Structure (Type 9):
        00-01: Compression type (0x0009)
        02-03: Unknown (0x0000)
        04-05: Flag table size (0x0400 = 1024)
        06+:   Flag table followed by compressed data

    Header Structure (Type 7):
        00-01: Compression type (0x0007)
        02+:   RLE compressed data
    """

    def __init__(self, base_path: str):
        """Initialize decoder with base path (e.g., "FQOP_01")"""
        self.base_path = Path(base_path)
        self.width = 320   # Standard VGA width
        self.height = 200  # Standard VGA height
        self.plane_size = self.width * self.height // 8  # 8000 bytes per plane

    def decompress_type7_rle(self, data: bytes, skip: int = 2) -> bytes:
        """
        Decompress Type 7 RLE format (used by R_ and E_ files)

        Format:
        - control >= 0x80: Repeat next byte (control - 0x7F) times
        - control < 0x80: Copy (control + 1) literal bytes
        """
        result = bytearray()
        i = skip  # Skip header bytes

        while i < len(data) and len(result) < self.plane_size:
            control = data[i]
            i += 1

            if control >= 0x80:
                count = control - 0x7F
                if i < len(data):
                    value = data[i]
                    i += 1
                    result.extend([value] * count)
            else:
                count = control + 1
                if i + count <= len(data):
                    result.extend(data[i:i+count])
                    i += count
                else:
                    break

        return bytes(result)

    def decompress_type9(self, data: bytes) -> bytes:
        """
        Decompress Type 9 format (used by B_ and G_ files)

        Structure:
        - 6-byte header (type, unknown, table_size)
        - 1024-byte flag/symbol table
        - Compressed data (9-bit codes referencing symbol table)

        Symbol table entries (16-bit words):
        - 0x00XX: Literal byte (output XX)
        - 0xFFXX: Special command (XX=0xFF is end marker, else RLE)
        - Other: Metadata or tree nodes (Entry[0] is metadata)

        NOTE: This decoder is incomplete. The compression algorithm appears to
        be a Huffman/LZ hybrid that requires reverse engineering of MAIN.EXE.
        For reliable asset extraction, use DOSBox capture workflow instead:

            python tools/dosbox_capture_workflow.py full

        Current implementation attempts 9-bit symbol table lookup but produces
        noisy output due to unknown bit-stream interpretation algorithm.
        """
        if len(data) < 6:
            return data

        # Parse header
        table_size = struct.unpack('<H', data[4:6])[0]

        # Skip header and read flag table
        flag_table = data[6:6 + table_size]
        data_start = 6 + table_size
        if data_start >= len(data):
            return data

        compressed = data[data_start:]

        # Parse symbol table entries
        entries = []
        for i in range(0, min(1024, len(flag_table)), 2):
            if i + 1 < len(flag_table):
                word = struct.unpack('<H', flag_table[i:i + 2])[0]
                entries.append(word)

        # 9-bit code reader
        result = bytearray()
        bit_pos = 0
        byte_idx = 0

        def read_9bits():
            nonlocal bit_pos, byte_idx
            if byte_idx >= len(compressed):
                return None
            val = 0
            for i in range(9):
                if byte_idx >= len(compressed):
                    return None
                byte = compressed[byte_idx]
                bit = (byte >> bit_pos) & 1
                val |= (bit << i)
                bit_pos += 1
                if bit_pos >= 8:
                    bit_pos = 0
                    byte_idx += 1
            return val

        # Decode using symbol table
        while len(result) < self.plane_size:
            code = read_9bits()
            if code is None:
                break

            # Skip Entry[0] (metadata)
            if code == 0:
                continue

            if code >= len(entries):
                break

            entry = entries[code]
            hi = (entry >> 8) & 0xFF
            lo = entry & 0xFF

            if hi == 0x00:
                # Literal byte
                result.append(lo)
            elif hi == 0xFF:
                if lo == 0xFF:
                    # End marker
                    break
                elif lo == 0x00:
                    # Single zero byte (special case - 0 is not in literal table)
                    result.append(0)
                else:
                    # RLE: repeat previous byte (lo + 3) times
                    repeat_count = lo + 3
                    if len(result) > 0:
                        result.extend([result[-1]] * repeat_count)
                    else:
                        result.extend([0] * repeat_count)
            else:
                # Unknown entry type - output lo byte as fallback
                result.append(lo)

        return bytes(result)

    def load_plane(self, filepath: Path) -> Optional[bytes]:
        """Load and decompress a single plane file"""
        if not filepath.exists():
            print(f"Warning: Plane file not found: {filepath}")
            return None

        with open(filepath, 'rb') as f:
            data = f.read()

        if len(data) < 2:
            return None

        comp_type = struct.unpack('<H', data[0:2])[0]
        print(f"  {filepath.name}: {len(data)} bytes, type={comp_type}")

        if comp_type == 9:
            decompressed = self.decompress_type9(data)
        elif comp_type == 7:
            decompressed = self.decompress_type7_rle(data, skip=2)
        else:
            # Unknown type, try as raw planar data
            decompressed = data[2:]

        print(f"    Decompressed: {len(decompressed)} bytes (expected: {self.plane_size})")

        # Pad or truncate to expected size
        if len(decompressed) < self.plane_size:
            decompressed = decompressed + bytes(self.plane_size - len(decompressed))
        elif len(decompressed) > self.plane_size:
            decompressed = decompressed[:self.plane_size]

        return decompressed

    def load_planes(self) -> Optional[bytes]:
        """Load and decompress all 4 RGBE plane files"""
        # BGRE order for proper 4-bit pixel assembly
        plane_extensions = ['B_', 'G_', 'R_', 'E_']
        plane_files = [
            self.base_path.parent / f"{self.base_path.stem}.{ext}"
            for ext in plane_extensions
        ]

        print(f"Loading planes for {self.base_path.stem}:")
        planes = []
        for pf in plane_files:
            plane = self.load_plane(pf)
            if plane is None:
                return None
            planes.append(plane)

        # Combine planes to create indexed image
        return self.combine_planes(planes)

    def combine_planes(self, planes: List[bytes]) -> bytes:
        """
        Combine 4 bitplanes into indexed color image

        VGA planar format: each plane byte contains 8 horizontal pixels
        Planes are combined bit-by-bit:
        - B plane: bit 3 (MSB)
        - G plane: bit 2
        - R plane: bit 1
        - E plane: bit 0 (LSB)

        Result: 4-bit pixel values (0-15)
        """
        total_pixels = self.width * self.height
        result = bytearray(total_pixels)

        # Each byte in plane data represents 8 horizontal pixels
        bytes_per_row = self.width // 8  # 40 bytes per row

        for y in range(self.height):
            for x_byte in range(bytes_per_row):
                byte_offset = y * bytes_per_row + x_byte

                if byte_offset >= len(planes[0]):
                    continue

                # Get bytes from each plane
                b_byte = planes[0][byte_offset] if byte_offset < len(planes[0]) else 0
                g_byte = planes[1][byte_offset] if byte_offset < len(planes[1]) else 0
                r_byte = planes[2][byte_offset] if byte_offset < len(planes[2]) else 0
                e_byte = planes[3][byte_offset] if byte_offset < len(planes[3]) else 0

                # Extract 8 pixels from these bytes
                for bit in range(8):
                    pixel_x = x_byte * 8 + (7 - bit)  # MSB first
                    pixel_idx = y * self.width + pixel_x

                    if pixel_idx >= total_pixels:
                        continue

                    # Combine bits from each plane
                    b_bit = (b_byte >> bit) & 1
                    g_bit = (g_byte >> bit) & 1
                    r_bit = (r_byte >> bit) & 1
                    e_bit = (e_byte >> bit) & 1

                    # B=bit3, G=bit2, R=bit1, E=bit0
                    pixel = (b_bit << 3) | (g_bit << 2) | (r_bit << 1) | e_bit
                    result[pixel_idx] = pixel

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


class CHRDecoder:
    """Decoder for CHR sprite files (4bpp planar format)"""

    def __init__(self, filepath: Path, tile_width: int = 8, tile_height: int = 8):
        """
        Initialize CHR decoder

        Args:
            filepath: Path to CHR file
            tile_width: Width of each tile in pixels (default 8)
            tile_height: Height of each tile in pixels (default 8)
        """
        self.filepath = filepath
        self.tile_width = tile_width
        self.tile_height = tile_height
        self.data = None

    def load(self) -> bytes:
        """Load CHR file data"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        return self.data

    def decode_tile(self, offset: int) -> List[int]:
        """
        Decode a single 4bpp planar tile

        4bpp planar format:
        - 4 bitplanes, each plane is tile_width * tile_height / 8 bytes
        - Each bitplane contributes 1 bit per pixel
        - Total: 4 * (tile_width * tile_height / 8) bytes per tile

        For 8x8 tile: 4 * 8 = 32 bytes per tile

        Args:
            offset: Byte offset in CHR file

        Returns:
            List of pixel values (0-15)
        """
        pixels_per_tile = self.tile_width * self.tile_height
        bytes_per_plane = pixels_per_tile // 8
        bytes_per_tile = bytes_per_plane * 4

        if offset + bytes_per_tile > len(self.data):
            return [0] * pixels_per_tile

        # Extract 4 bitplanes
        planes = []
        for plane_idx in range(4):
            plane_offset = offset + (plane_idx * bytes_per_plane)
            plane_data = self.data[plane_offset:plane_offset + bytes_per_plane]
            planes.append(plane_data)

        # Combine bitplanes to pixels
        pixels = []
        for pixel_idx in range(pixels_per_tile):
            byte_idx = pixel_idx // 8
            bit_idx = 7 - (pixel_idx % 8)

            pixel_value = 0
            for plane_num, plane in enumerate(planes):
                if byte_idx < len(plane):
                    byte_val = plane[byte_idx]
                    bit = (byte_val >> bit_idx) & 1
                    pixel_value |= (bit << plane_num)

            pixels.append(pixel_value)

        return pixels

    def extract_all_tiles(self) -> List[Image.Image]:
        """
        Extract all tiles from CHR file

        Returns:
            List of PIL Images (one per tile)
        """
        if self.data is None:
            self.load()

        pixels_per_tile = self.tile_width * self.tile_height
        bytes_per_plane = pixels_per_tile // 8
        bytes_per_tile = bytes_per_plane * 4

        num_tiles = len(self.data) // bytes_per_tile
        print(f"Extracting {num_tiles} tiles from {self.filepath.name}")

        tiles = []
        for tile_idx in range(num_tiles):
            offset = tile_idx * bytes_per_tile
            pixels = self.decode_tile(offset)

            # Create indexed image
            tile_img = Image.new('P', (self.tile_width, self.tile_height))
            tile_img.putdata(pixels)
            tiles.append(tile_img)

        return tiles

    def create_sprite_sheet(self, tiles: List[Image.Image], cols: int = 16) -> Image.Image:
        """
        Arrange tiles in a sprite sheet

        Args:
            tiles: List of tile images
            cols: Number of columns in sprite sheet

        Returns:
            Combined sprite sheet image
        """
        if not tiles:
            return Image.new('P', (1, 1))

        rows = (len(tiles) + cols - 1) // cols
        sheet_width = cols * self.tile_width
        sheet_height = rows * self.tile_height

        sheet = Image.new('P', (sheet_width, sheet_height))

        for idx, tile in enumerate(tiles):
            col = idx % cols
            row = idx // cols
            x = col * self.tile_width
            y = row * self.tile_height
            sheet.paste(tile, (x, y))

        return sheet


class BankDecoder:
    """Decoder for Bank files (offset table + compressed data)"""

    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.data = None
        self.offsets = []

    def load(self) -> bytes:
        """Load Bank file"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        return self.data

    def parse_offset_table(self) -> List[int]:
        """
        Parse offset table at beginning of Bank file

        Bank format analysis:
        - CHRBANK first bytes: 37 0D C1 0C 09 0B 29 0C...
        - These are 16-bit little-endian offsets
        - 0x0D37 = 3383, 0x0CC1 = 3265, 0x0B09 = 2825...
        - Offsets are NOT in ascending order (they jump around)
        - Need different strategy: read until offset points into offset table itself

        Returns:
            List of byte offsets
        """
        if self.data is None:
            self.load()

        offsets = []
        idx = 0

        # Strategy: Read offsets until we hit one that points back to offset table
        # The first data entry can't start before the offset table ends
        while idx + 2 <= len(self.data):
            offset = struct.unpack('<H', self.data[idx:idx+2])[0]

            # If offset points into current offset table area, we've gone too far
            if offset <= idx + 2:
                break

            # If offset is way beyond file size, probably not valid
            if offset >= len(self.data):
                # But don't break immediately - might be padding
                if len(offsets) > 0:
                    break

            offsets.append(offset)
            idx += 2

            # Safety limit
            if len(offsets) > 10000:
                break

        self.offsets = offsets
        return offsets

    def extract_entry(self, entry_idx: int) -> Optional[bytes]:
        """
        Extract data for specific entry

        Args:
            entry_idx: Index in offset table

        Returns:
            Raw data bytes or None
        """
        if entry_idx >= len(self.offsets):
            return None

        start_offset = self.offsets[entry_idx]

        # Determine end offset
        if entry_idx + 1 < len(self.offsets):
            end_offset = self.offsets[entry_idx + 1]
        else:
            end_offset = len(self.data)

        return self.data[start_offset:end_offset]

    def extract_all_entries(self, output_dir: Path):
        """
        Extract all entries to files

        Args:
            output_dir: Directory to save entries
        """
        if not self.offsets:
            self.parse_offset_table()

        output_dir.mkdir(parents=True, exist_ok=True)

        print(f"Extracting {len(self.offsets)} entries from {self.filepath.name}")

        for idx in range(len(self.offsets)):
            data = self.extract_entry(idx)
            if data:
                output_file = output_dir / f"entry_{idx:04d}.bin"
                with open(output_file, 'wb') as f:
                    f.write(data)
                print(f"  Entry {idx:4d}: {len(data):6d} bytes -> {output_file.name}")


class TextDecoder:
    """Decoder for FQ4MES text file"""

    def __init__(self, filepath: Path, encoding: str = 'shift_jis'):
        self.filepath = filepath
        self.encoding = encoding
        self.data = None
        self.offsets = []

    def load(self) -> bytes:
        """Load text file"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        return self.data

    def parse_offset_table(self) -> List[int]:
        """
        Parse message offset table

        Format appears to be:
        - 16-bit offsets at start
        - Each offset points to a text string
        - Strings likely null-terminated or length-prefixed

        Returns:
            List of byte offsets
        """
        if self.data is None:
            self.load()

        offsets = []
        idx = 0

        # Read offsets until we hit data or invalid offset
        while idx + 2 <= len(self.data):
            offset = struct.unpack('<H', self.data[idx:idx+2])[0]

            # Stop if offset looks invalid
            if offset >= len(self.data) or (offsets and offset < idx):
                break

            offsets.append(offset)
            idx += 2

            # Safety check: stop if we've read too many
            if len(offsets) > 1000:
                break

        self.offsets = offsets
        return offsets

    def extract_string(self, start_offset: int, end_offset: Optional[int] = None) -> str:
        """
        Extract text string from offset

        Args:
            start_offset: Start byte offset
            end_offset: End offset (or None to auto-detect)

        Returns:
            Decoded string
        """
        if end_offset is None:
            # Find null terminator
            end_offset = start_offset
            while end_offset < len(self.data) and self.data[end_offset] != 0:
                end_offset += 1

        raw_bytes = self.data[start_offset:end_offset]

        # Try decoding
        try:
            return raw_bytes.decode(self.encoding, errors='replace')
        except:
            # Fallback: ASCII representation
            return raw_bytes.hex()

    def extract_all_strings(self, output_file: Path):
        """
        Extract all text strings to file

        Args:
            output_file: Output text file path
        """
        if not self.offsets:
            self.parse_offset_table()

        output_file.parent.mkdir(parents=True, exist_ok=True)

        print(f"Extracting {len(self.offsets)} strings from {self.filepath.name}")

        with open(output_file, 'w', encoding='utf-8') as f:
            for idx in range(len(self.offsets)):
                start = self.offsets[idx]
                end = self.offsets[idx + 1] if idx + 1 < len(self.offsets) else None

                text = self.extract_string(start, end)
                f.write(f"[{idx:04d}] {text}\n")

                # Safe console output (avoid encoding errors)
                try:
                    preview = text[:60] if len(text) > 60 else text
                    print(f"  String {idx:4d}: {preview}...")
                except UnicodeEncodeError:
                    print(f"  String {idx:4d}: [binary data]")


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


def cmd_decode_all(args):
    """Handle 'decode-all' subcommand - decode all RGBE images"""
    game_dir = Path(args.game_dir) if args.game_dir else Path("C:/claude/Fq4/GAME")
    output_dir = Path(args.output) if args.output else Path("C:/claude/Fq4/output/images")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find palette
    palette_path = game_dir / "FQ4.RGB"
    if not palette_path.exists():
        print(f"Error: Palette not found at {palette_path}")
        return 1

    # Parse palette
    parser = FQ4PaletteParser(palette_path)
    palette = parser.parse()
    print(f"Loaded {len(palette)} colors from palette\n")

    # List of RGBE image sets to extract
    rgbe_sets = [
        "FQOP_01", "FQOP_02", "FQOP_03", "FQOP_04", "FQOP_05",
        "FQOP_06", "FQOP_07", "FQOP_08", "FQOP_09", "FQOP_10",
        "FQ4G16", "FQ4GLOGO",
        "SUEMI_A1", "SUEMI_A2", "SUEMI_A3"
    ]

    success_count = 0
    for base_name in rgbe_sets:
        base_path = game_dir / base_name
        print(f"Processing {base_name}...")

        # Check if all plane files exist
        plane_files = [f"{base_name}.{ext}" for ext in ['B_', 'R_', 'G_', 'E_']]
        if not all((game_dir / pf).exists() for pf in plane_files):
            print(f"  Skipped: Missing plane files\n")
            continue

        try:
            decoder = RGBEDecoder(str(base_path))
            img = decoder.decode_to_image(palette)

            if img:
                output_path = output_dir / f"{base_name}.png"
                img.save(output_path)
                print(f"  Saved: {output_path} ({img.width}x{img.height})\n")
                success_count += 1
            else:
                print(f"  Failed to decode\n")

        except Exception as e:
            print(f"  Error: {e}\n")

    print(f"Successfully extracted {success_count}/{len(rgbe_sets)} images")
    return 0


def cmd_chr(args):
    """Handle 'chr' subcommand - extract CHR sprite file"""
    chr_file = Path(args.chr_file)
    if not chr_file.exists():
        print(f"Error: CHR file not found: {chr_file}")
        return 1

    output_dir = Path(args.output) if args.output else Path("C:/claude/Fq4/output/sprites") / chr_file.stem
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find palette
    palette_path = Path(args.palette) if args.palette else Path("C:/claude/Fq4/GAME/FQ4.RGB")
    if palette_path.exists():
        parser = FQ4PaletteParser(palette_path)
        palette = parser.parse()
    else:
        # Use default grayscale palette
        palette = [(i * 17, i * 17, i * 17) for i in range(16)]

    # Decode CHR file
    decoder = CHRDecoder(chr_file, tile_width=8, tile_height=8)
    tiles = decoder.extract_all_tiles()

    if not tiles:
        print("No tiles extracted")
        return 1

    # Create sprite sheet
    sprite_sheet = decoder.create_sprite_sheet(tiles, cols=16)

    # Apply palette
    pal_data = []
    for r, g, b in palette:
        pal_data.extend([r, g, b])
    while len(pal_data) < 768:
        pal_data.append(0)
    sprite_sheet.putpalette(pal_data)

    # Save sprite sheet
    output_path = output_dir / f"{chr_file.stem}_sheet.png"
    sprite_sheet.save(output_path)
    print(f"Sprite sheet saved: {output_path}")
    print(f"Total tiles: {len(tiles)}")
    print(f"Sheet size: {sprite_sheet.width}x{sprite_sheet.height}")

    # Optionally save individual tiles
    if args.individual:
        tiles_dir = output_dir / "tiles"
        tiles_dir.mkdir(exist_ok=True)
        for idx, tile in enumerate(tiles):
            tile.putpalette(pal_data)
            tile_path = tiles_dir / f"tile_{idx:04d}.png"
            tile.save(tile_path)
        print(f"Individual tiles saved to: {tiles_dir}")

    return 0


def cmd_bank(args):
    """Handle 'bank' subcommand - extract Bank file"""
    bank_file = Path(args.bank_file)
    if not bank_file.exists():
        print(f"Error: Bank file not found: {bank_file}")
        return 1

    output_dir = Path(args.output) if args.output else Path("C:/claude/Fq4/output/bank") / bank_file.stem
    output_dir.mkdir(parents=True, exist_ok=True)

    decoder = BankDecoder(bank_file)
    offsets = decoder.parse_offset_table()

    print(f"Found {len(offsets)} entries in {bank_file.name}")
    print(f"Offset table: {offsets[:10]}{'...' if len(offsets) > 10 else ''}")

    decoder.extract_all_entries(output_dir)

    print(f"\nAll entries saved to: {output_dir}")
    return 0


def cmd_text(args):
    """Handle 'text' subcommand - extract text file"""
    text_file = Path(args.text_file)
    if not text_file.exists():
        print(f"Error: Text file not found: {text_file}")
        return 1

    output_file = Path(args.output) if args.output else Path("C:/claude/Fq4/output/text/messages.txt")
    output_file.parent.mkdir(parents=True, exist_ok=True)

    encoding = args.encoding if args.encoding else 'shift_jis'

    decoder = TextDecoder(text_file, encoding=encoding)
    offsets = decoder.parse_offset_table()

    print(f"Found {len(offsets)} strings in {text_file.name}")
    decoder.extract_all_strings(output_file)

    print(f"\nAll strings saved to: {output_file}")
    return 0


def cmd_extract_all(args):
    """Handle 'extract-all' subcommand - extract everything"""
    game_dir = Path(args.game_dir) if args.game_dir else Path("C:/claude/Fq4/GAME")
    output_base = Path(args.output) if args.output else Path("C:/claude/Fq4/output")

    print("=" * 60)
    print("FQ4 COMPREHENSIVE ASSET EXTRACTION")
    print("=" * 60)

    # 1. Extract palette
    print("\n[1/5] Extracting palette...")
    palette_path = game_dir / "FQ4.RGB"
    if palette_path.exists():
        parser = FQ4PaletteParser(palette_path)
        palette = parser.parse()

        swatch_dir = output_base
        swatch_dir.mkdir(parents=True, exist_ok=True)
        swatch = Image.new('RGB', (16 * 32, 32))
        for i, (r, g, b) in enumerate(palette):
            for y in range(32):
                for x in range(32):
                    swatch.putpixel((i * 32 + x, y), (r, g, b))
        swatch.save(swatch_dir / "palette.png")
        print(f"  Palette saved: {swatch_dir / 'palette.png'}")
    else:
        print("  Palette not found, using default grayscale")
        palette = [(i * 17, i * 17, i * 17) for i in range(16)]

    # 2. Extract all RGBE images
    print("\n[2/5] Extracting RGBE images...")
    rgbe_output = output_base / "images"
    rgbe_output.mkdir(parents=True, exist_ok=True)

    rgbe_sets = [
        "FQOP_01", "FQOP_02", "FQOP_03", "FQOP_04", "FQOP_05",
        "FQOP_06", "FQOP_07", "FQOP_08", "FQOP_09", "FQOP_10",
        "FQ4G16", "FQ4GLOGO",
        "SUEMI_A1", "SUEMI_A2", "SUEMI_A3"
    ]

    rgbe_count = 0
    for base_name in rgbe_sets:
        base_path = game_dir / base_name
        plane_files = [f"{base_name}.{ext}" for ext in ['B_', 'R_', 'G_', 'E_']]
        if all((game_dir / pf).exists() for pf in plane_files):
            try:
                decoder = RGBEDecoder(str(base_path))
                img = decoder.decode_to_image(palette)
                if img:
                    img.save(rgbe_output / f"{base_name}.png")
                    rgbe_count += 1
                    print(f"  {base_name}.png")
            except Exception as e:
                print(f"  {base_name}: Error - {e}")

    print(f"  Total: {rgbe_count} images")

    # 3. Extract all CHR files
    print("\n[3/5] Extracting CHR sprite files...")
    chr_files = list(game_dir.glob("*.CHR"))
    chr_output = output_base / "sprites"

    for chr_file in chr_files:
        try:
            decoder = CHRDecoder(chr_file, tile_width=8, tile_height=8)
            tiles = decoder.extract_all_tiles()
            if tiles:
                chr_dir = chr_output / chr_file.stem
                chr_dir.mkdir(parents=True, exist_ok=True)

                sprite_sheet = decoder.create_sprite_sheet(tiles, cols=16)
                pal_data = []
                for r, g, b in palette:
                    pal_data.extend([r, g, b])
                while len(pal_data) < 768:
                    pal_data.append(0)
                sprite_sheet.putpalette(pal_data)

                sprite_sheet.save(chr_dir / f"{chr_file.stem}_sheet.png")
                print(f"  {chr_file.name}: {len(tiles)} tiles")
        except Exception as e:
            print(f"  {chr_file.name}: Error - {e}")

    # 4. Extract Bank files
    print("\n[4/5] Extracting Bank files...")
    bank_files = [f for f in game_dir.iterdir() if 'BANK' in f.name.upper()]
    bank_output = output_base / "bank"

    for bank_file in bank_files:
        try:
            decoder = BankDecoder(bank_file)
            offsets = decoder.parse_offset_table()
            bank_dir = bank_output / bank_file.stem
            decoder.extract_all_entries(bank_dir)
            print(f"  {bank_file.name}: {len(offsets)} entries")
        except Exception as e:
            print(f"  {bank_file.name}: Error - {e}")

    # 5. Extract text
    print("\n[5/5] Extracting text files...")
    text_file = game_dir / "FQ4MES"
    if text_file.exists():
        try:
            decoder = TextDecoder(text_file, encoding='shift_jis')
            offsets = decoder.parse_offset_table()
            text_output = output_base / "text" / "messages.txt"
            decoder.extract_all_strings(text_output)
            print(f"  FQ4MES: {len(offsets)} strings")
        except Exception as e:
            print(f"  FQ4MES: Error - {e}")

    print("\n" + "=" * 60)
    print(f"EXTRACTION COMPLETE: {output_base}")
    print("=" * 60)

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="FQ4 Comprehensive Asset Extractor",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Extract everything
  python fq4_extractor.py extract-all --output C:/claude/Fq4/output

  # Extract all RGBE images
  python fq4_extractor.py decode-all --output C:/claude/Fq4/output/images

  # Extract CHR sprite file
  python fq4_extractor.py chr C:/claude/Fq4/GAME/FQ4.CHR --output C:/claude/Fq4/output/sprites

  # Extract Bank file
  python fq4_extractor.py bank C:/claude/Fq4/GAME/CHRBANK --output C:/claude/Fq4/output/chrbank

  # Extract text
  python fq4_extractor.py text C:/claude/Fq4/GAME/FQ4MES --output C:/claude/Fq4/output/text/messages.txt

  # Parse palette file
  python fq4_extractor.py palette C:/claude/Fq4/GAME/FQ4.RGB

  # Decode single RGBE image
  python fq4_extractor.py decode C:/claude/Fq4/GAME/FQOP_01 --output C:/claude/Fq4/output
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Extract-all command (NEW)
    extract_all_parser = subparsers.add_parser('extract-all', help='Extract all assets (images, sprites, banks, text)')
    extract_all_parser.add_argument('--game-dir', '-g', help='Game directory (default: C:/claude/Fq4/GAME)')
    extract_all_parser.add_argument('--output', '-o', help='Output directory (default: C:/claude/Fq4/output)')

    # Decode-all command (NEW)
    decode_all_parser = subparsers.add_parser('decode-all', help='Decode all RGBE images')
    decode_all_parser.add_argument('--game-dir', '-g', help='Game directory (default: C:/claude/Fq4/GAME)')
    decode_all_parser.add_argument('--output', '-o', help='Output directory (default: C:/claude/Fq4/output/images)')

    # CHR command (NEW)
    chr_parser = subparsers.add_parser('chr', help='Extract CHR sprite file')
    chr_parser.add_argument('chr_file', help='Path to CHR file')
    chr_parser.add_argument('--palette', '-p', help='Path to palette file (default: FQ4.RGB)')
    chr_parser.add_argument('--output', '-o', help='Output directory (default: output/sprites/)')
    chr_parser.add_argument('--individual', action='store_true', help='Save individual tiles')

    # Bank command (NEW)
    bank_parser = subparsers.add_parser('bank', help='Extract Bank file')
    bank_parser.add_argument('bank_file', help='Path to Bank file')
    bank_parser.add_argument('--output', '-o', help='Output directory (default: output/bank/)')

    # Text command (NEW)
    text_parser = subparsers.add_parser('text', help='Extract text file')
    text_parser.add_argument('text_file', help='Path to text file (e.g., FQ4MES)')
    text_parser.add_argument('--output', '-o', help='Output file (default: output/text/messages.txt)')
    text_parser.add_argument('--encoding', '-e', help='Text encoding (default: shift_jis)')

    # Palette command
    palette_parser = subparsers.add_parser('palette', help='Parse palette file')
    palette_parser.add_argument('palette_file', help='Path to FQ4.RGB palette file')
    palette_parser.add_argument('--output', '-o', help='Output directory for palette swatch')

    # Decode command
    decode_parser = subparsers.add_parser('decode', help='Decode single RGBE image')
    decode_parser.add_argument('base_name', help='Base path to RGBE files (e.g., FQOP_01 without extension)')
    decode_parser.add_argument('--palette', '-p', help='Path to palette file (default: FQ4.RGB)')
    decode_parser.add_argument('--output', '-o', help='Output directory (default: output/)')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    # Route to command handlers
    command_map = {
        'extract-all': cmd_extract_all,
        'decode-all': cmd_decode_all,
        'chr': cmd_chr,
        'bank': cmd_bank,
        'text': cmd_text,
        'palette': cmd_palette,
        'decode': cmd_decode,
    }

    handler = command_map.get(args.command)
    if handler:
        return handler(args)
    else:
        parser.print_help()
        return 1


if __name__ == '__main__':
    sys.exit(main())
