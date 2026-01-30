# FQ4 Graphics Extractor

Python tool for extracting graphics assets from First Queen 4 (DOS game, 1994).

## Requirements

```bash
pip install Pillow
```

## Usage

### Extract Palette

```bash
python fq4_extractor.py palette GAME/FQ4.RGB --output output/
```

This will:
- Parse the 88-byte FQ4.RGB palette file
- Display 16 VGA colors (converted from 6-bit to 8-bit)
- Save a palette swatch as `output/palette.png`

### Decode RGBE Images

```bash
python fq4_extractor.py decode GAME/FQOP_01 --output output/
```

This will:
- Load 4 plane files (.B_, .R_, .G_, .E_)
- Attempt decompression (RLE, raw)
- Combine bitplanes into indexed color image
- Apply palette and save as PNG

## File Format Analysis

### FQ4.RGB (Palette)

- **Size**: 88 bytes
- **Format**: 22 entries × 4 bytes (RGBI format suspected)
- **Color space**: VGA 6-bit (0-63), converted to 8-bit (0-255)
- **Colors used**: First 16 colors extracted

### RGBE Files (Images)

Four separate plane files per image:
- `.B_` - Blue/Bit 3 plane
- `.R_` - Red/Bit 2 plane
- `.G_` - Green/Bit 1 plane
- `.E_` - Extra/Bit 0 plane (LSB)

**Header Structure** (16 bytes):
```
Offset  Size  Description
------  ----  -----------
0x00    2     Unknown (0x0009)
0x04    2     Size/dimension hint (0x0400)
0x06    2     Magic number (0x4711)
```

**Image Properties**:
- Resolution: 320x200 (standard VGA)
- Color depth: 4-bit (16 colors)
- Compression: Appears to be compressed (file sizes vary: 10KB-17KB)

**Plane Combination**:
Each pixel is reconstructed by taking one bit from each plane:
```
Pixel value = (B << 3) | (R << 2) | (G << 1) | E
```

## Results

### Extracted Files

- `output/palette.png` - 16-color palette swatch
- `output/FQOP_01.png` - Decoded 320x200 image

### Palette Colors

The extracted palette shows 16 grayscale/blue-tinted colors ranging from black to near-white, typical of PC-98/VGA era games.

## Current Limitations

1. **Compression**: The exact compression format is not fully identified
   - RLE decompression attempted but may not be correct
   - Some images may appear garbled if compression is misidentified

2. **Dimensions**: Hardcoded to 320x200
   - Header fields may contain actual dimensions but not decoded yet

3. **Bitplane Order**: Assumed E/G/R/B ordering
   - Actual order may vary

## Next Steps

To improve extraction quality:

1. Analyze compressed data patterns to identify exact compression scheme
2. Parse header fields to extract actual image dimensions
3. Test with more FQOP_* files to verify consistency
4. Reverse-engineer actual game executable for format specifications

## License

POC implementation for archival/research purposes.
