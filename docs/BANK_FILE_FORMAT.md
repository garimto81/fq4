# FQ4 Bank File Format Documentation

## Overview

FQ4 uses "Bank" files to store game assets. These are custom archive formats that pack multiple data entries into single files.

## File List

| File | Size | Entries | Purpose |
|------|------|---------|---------|
| CHRBANK | 760,350 bytes | 255 | Character graphics/sprites |
| MAPBANK | 437,084 bytes | 73 | Map/level data |
| BGMBANK1 | 36,064 bytes | 41 | Background music (set 1) |
| BGMBANK2 | 34,441 bytes | 41 | Background music (set 2) |
| FQFBANK | 69,960 bytes | 75 | Unknown (fonts/SFX?) |

## Format Specification

### Structure

```
Offset  | Size      | Description
--------|-----------|------------------------------------------
0x0000  | N * 2     | Size table (16-bit LE words)
        | 0 or 2    | Optional: 0x0000 terminator
        | 0-256     | Optional: Zero padding
        | Variable  | Entry data (concatenated)
```

### Size Table Format

- **Element size**: 16-bit (2 bytes)
- **Endianness**: Little-endian
- **Value meaning**: Size in bytes of corresponding entry
- **Terminator**: Some files use 0x0000 to mark end
- **No count field**: Entry count is implicit

### Algorithm to Parse

```python
def parse_bank(data):
    # Read size table
    sizes = []
    pos = 0

    while pos + 2 <= len(data):
        size = struct.unpack_from('<H', data, pos)[0]
        if size == 0:
            pos += 2  # Skip terminator
            break
        sizes.append(size)
        pos += 2

    # Check for padding
    while pos < len(data) and data[pos] == 0:
        pos += 1

    # Extract entries
    entries = []
    for size in sizes:
        entry = data[pos:pos + size]
        entries.append(entry)
        pos += size

    return entries
```

### Verification

Total file size should equal:
```
file_size = size_table_bytes + padding_bytes + sum(all_entry_sizes)
```

## File-Specific Notes

### CHRBANK

- **255 entries**: Character/sprite graphics
- **No terminator**: Size table ends when entries account for file
- **No padding**: Data immediately follows size table
- **Entry sizes**: 39 - 11,064 bytes (avg 2,980 bytes)
- **Format hints**: Binary graphics data, likely planar format

### MAPBANK

- **73 entries**: Map/level definitions
- **Has terminator**: 0x0000 word after last size
- **Has padding**: 52 zero bytes between table and data
- **Entry sizes**: 1,931 - 11,293 bytes (avg 5,985 bytes)
- **Format hints**: Structured data with low byte values

### BGMBANK1 & BGMBANK2

- **41 entries each**: Music tracks
- **No terminator**: Size table ends naturally
- **No padding**: Data immediately follows
- **Entry sizes**: 75 - 1,711 bytes (avg 850-880 bytes)
- **Format hints**: Likely IMF (id Music Format) or RAW AdLib data
- **Note**: Entry 1 in both files is exactly 75 bytes (placeholder?)

### FQFBANK

- **75 entries**: Unknown purpose
- **No terminator**
- **No padding**
- **Entry sizes**: 10 - 2,646 bytes (avg 931 bytes)
- **Format hints**: Mixed data types, possibly fonts or sound effects

## Tools

### Extraction

```bash
# Extract all banks
python tools/bank_analyzer.py --all GAME output/banks

# Extract specific bank
python tools/bank_analyzer.py GAME/CHRBANK output/banks

# Analyze only (no extraction)
python tools/bank_analyzer.py GAME/CHRBANK
```

### Output

Extracted files are named: `{BANK}_{INDEX}_{OFFSET}.bin`

Example: `CHRBANK_0042_0x01A3F0.bin`
- From CHRBANK
- Entry index 42
- Located at offset 0x01A3F0 in original file

## Implementation Details

### Edge Cases

1. **Zero-sized entries**: Not present in FQ4 banks
2. **Terminator variation**: Only MAPBANK uses 0x0000 terminator
3. **Padding**: Only MAPBANK has padding (52 bytes)
4. **Size validation**: Entry sizes must sum to remaining file size

### Error Handling

- **Invalid size**: If size > 50,000 bytes, likely corrupt
- **Overflow**: If calculated file size exceeds actual, invalid parse
- **Underflow**: If data remains after all entries, check for padding

## Next Steps

### CHRBANK Analysis

Character graphics are likely in one of these formats:
- Planar EGA (4-bit, 16 colors)
- Planar VGA (8-bit, 256 colors)
- Custom compressed format

Analyze first entry dimensions and color depth.

### MAPBANK Analysis

Map data structure likely contains:
- Tile indices (references to CHRBANK)
- Collision data
- Entity placement
- Trigger zones

### BGMBANK Analysis

Music data is likely:
- AdLib IMF format (most common in DOS games)
- Raw OPL2 register writes
- Custom music format

Check for OPL2 register patterns (0xB0-0xBF for note on/off).

### FQFBANK Analysis

Unknown format. Possible contents:
- Font data (Chinese character glyphs)
- Sound effects (PC speaker or AdLib)
- Game scripts or text
- UI graphics

## References

- AdLib IMF format: http://www.shikadi.net/moddingwiki/IMF_Format
- EGA planar graphics: http://www.shikadi.net/moddingwiki/EGA_Planar
- VGA Mode 13h: http://www.shikadi.net/moddingwiki/VGA_Mode_13h

## Revision History

- 2026-01-30: Initial documentation based on extraction analysis
