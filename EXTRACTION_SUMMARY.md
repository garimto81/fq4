# FQ4 Asset Extraction Summary

**Date**: 2026-01-30
**Tool**: `fq4_extractor.py` v2.0 (Comprehensive)
**Status**: COMPLETE ✓

## Extraction Results

### 1. RGBE Images (15/15 extracted)

| Image | Size | Status |
|-------|------|--------|
| FQOP_01 ~ FQOP_10 | 320x200 | ✓ |
| FQ4G16 | 320x200 | ✓ |
| FQ4GLOGO | 320x200 | ✓ |
| SUEMI_A1 ~ A3 | 320x200 | ✓ |

**Format**: 4bpp indexed color (16 colors)
**Output**: `output/images/*.png`

### 2. CHR Sprites (7/7 extracted)

| File | Size | Tiles | Sheet Size |
|------|------|-------|-----------|
| FQ4.CHR | 615KB | 19,296 | 128x9840 px |
| BIGFONT.CHR | 139KB | 4,360 | 128x2176 px |
| FONT.CHR | 3.2KB | 100 | 128x56 px |
| CLASS.CHR | 28KB | 875 | 128x440 px |
| MAGIC.CHR | 24KB | 750 | 128x376 px |
| FQ4P.CHR | 26KB | 812 | 128x408 px |
| FQ4P2.CHR | 26KB | 812 | 128x408 px |

**Total tiles**: 27,005
**Format**: 4bpp planar, 8x8 tiles, 32 bytes per tile
**Output**: `output/sprites/*/` (sprite sheets + optional individual tiles)

### 3. Bank Files (5/5 extracted)

| Bank | Size | Entries | Output Dir |
|------|------|---------|-----------|
| CHRBANK | 743KB | 177 | `output/bank/CHRBANK/` |
| MAPBANK | 427KB | 189 | `output/bank/MAPBANK/` |
| BGMBANK1 | 36KB | 41 | `output/bank/BGMBANK1/` |
| BGMBANK2 | 34KB | 41 | `output/bank/BGMBANK2/` |
| FQFBANK | 69KB | 33 | `output/bank/FQFBANK/` |

**Total entries**: 481
**Format**: 16-bit offset table + compressed data
**Output**: `entry_XXXX.bin` per entry

### 4. Text File (1/1 extracted)

| File | Size | Strings | Encoding |
|------|------|---------|----------|
| FQ4MES | 64KB | 799 | Shift-JIS |

**Output**: `output/text/messages.txt`
**Note**: Character substitution cipher suspected (needs decryption)

## Technical Details

### File Formats Decoded

1. **RGBE (4-plane compressed graphics)**
   - 4 bitplanes: .B_, .R_, .G_, .E_
   - Each plane is 1bpp (bit per pixel)
   - Combined to 4bpp (16-color) indexed image
   - Resolution: 320x200 (VGA standard)

2. **CHR (4bpp planar tiles)**
   - Tile size: 8x8 pixels
   - 4 bitplanes per tile (32 bytes)
   - Planar order: plane0 (LSB), plane1, plane2, plane3 (MSB)
   - No header, raw tile data

3. **Bank (offset table + compressed entries)**
   - Header: 16-bit little-endian offsets
   - Offsets point to start of each compressed entry
   - Table ends when offset points back to header area
   - Entries: variable-length compressed data

4. **FQ4MES (text with offset table)**
   - Header: 16-bit offset table (799 entries)
   - Body: Shift-JIS encoded strings
   - Strings are null-terminated or bounded by next offset

### Palette

- File: `FQ4.RGB` (88 bytes)
- Format: 22 × 4-byte entries (RGBI?)
- Color depth: 6-bit VGA (0-63 range)
- Conversion: VGA 6-bit → 8-bit (multiply by 255/63)
- Extracted to: `output/palette.png` (16-color swatch)

## Usage

### Full extraction

```bash
cd C:\claude\Fq4
python tools/fq4_extractor.py extract-all --output output
```

### Individual commands

```bash
# Images
python tools/fq4_extractor.py decode-all --output output/images

# Sprites
python tools/fq4_extractor.py chr GAME/FQ4.CHR --output output/sprites

# Banks
python tools/fq4_extractor.py bank GAME/CHRBANK --output output/chrbank

# Text
python tools/fq4_extractor.py text GAME/FQ4MES --output output/text/messages.txt

# Palette
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output/
```

## Next Steps

1. **Decrypt FQ4MES text** - Character substitution analysis
2. **Decode Bank entries** - Identify compression algorithm
3. **Parse CHRBANK/MAPBANK** - Extract character/map data structures
4. **Analyze BGMBANK** - Music sequence format
5. **Tile mapping** - Create tile → sprite mapping table

## Statistics

| Asset Type | Files | Total Size | Extracted Size |
|-----------|-------|------------|----------------|
| RGBE Images | 15 | ~1.5MB | ~100KB (PNG) |
| CHR Sprites | 7 | ~850KB | ~500KB (PNG sheets) |
| Bank Entries | 481 | ~1.3MB | ~1.3MB (raw) |
| Text | 1 | 64KB | 64KB (UTF-8) |
| **Total** | **504** | **~3.7MB** | **~2MB** |

## Files Generated

```
output/
├── palette.png                    # Palette swatch
├── images/                        # 15 RGBE images
│   └── *.png (320x200 each)
├── sprites/                       # 7 CHR sprite sheets
│   └── */                         # One dir per CHR file
│       └── *_sheet.png            # Combined sprite sheet
├── bank/                          # 5 bank directories
│   └── */                         # One dir per bank
│       └── entry_*.bin            # Raw entries
└── text/
    └── messages.txt               # 799 game strings
```

## Tool Information

**Script**: `C:\claude\Fq4\tools\fq4_extractor.py`
**Lines of code**: ~1000
**Dependencies**: Pillow (PIL)
**Python version**: 3.x

### Classes Implemented

- `FQ4PaletteParser`: VGA 6-bit palette decoder
- `RGBEDecoder`: 4-plane RGBE image decoder
- `CHRDecoder`: 4bpp planar sprite decoder
- `BankDecoder`: Offset table + entry extractor
- `TextDecoder`: Shift-JIS text extractor

### Commands Available

- `extract-all`: Extract all assets (recommended)
- `decode-all`: Extract all RGBE images
- `chr`: Extract CHR sprite file
- `bank`: Extract Bank file
- `text`: Extract text file
- `palette`: Parse palette file
- `decode`: Decode single RGBE image

## License

- Tool code: MIT License
- Original game assets: Copyright Kure Software Koubou
