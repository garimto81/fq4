# FQ4MES Text Format Analysis

## File Structure

| Component | Offset | Size | Description |
|-----------|--------|------|-------------|
| **Offset Table** | 0x0000 | 1,598 bytes | 799 entries × 2 bytes (little-endian) |
| **Text Data** | 0x0640 | ~64KB | Shift-JIS encoded strings |

## Offset Table Format

```
[WORD] Message 0 offset (usually 0x0640)
[WORD] Message 1 offset
[WORD] Message 2 offset
...
[WORD] Message 798 offset
```

**Example:**
```
0x0000: 40 06  → 0x0640 (Message 0)
0x0002: 40 06  → 0x0640 (Message 1, same as 0)
0x0004: 5D 06  → 0x065D (Message 2)
0x0006: BC 06  → 0x06BC (Message 3)
```

## Text Data Format

### Encoding
- **Character Set**: Shift-JIS (Japanese)
- **Terminator**: 0x00 (null byte)
- **Cipher**: Character substitution cipher suspected

### Message Structure

```
[Shift-JIS Text] 0x00
```

**Example Message #1:**
```
Offset: 0x0640
Hex:    81 41 81 41 81 41 81 41 81 41 81 41 92 DE 8C CF 90 8F 8E E1 81 41 94 F1 90 F4 8F 91 00
Decode: 、、、、、、釣狐随若、非洗書
```

## Character Substitution Cipher

The decoded text appears to use a **substitution cipher** where Shift-JIS characters are mapped to different meanings:

### Evidence

1. **Pattern Analysis**
   - `0x8141` (、) appears frequently → likely represents common particles or spaces
   - Messages decode as valid Shift-JIS but make no semantic sense
   - Character distribution matches natural Japanese text

2. **Common Patterns**
   ```
   、、、、、、  → Repeated full-width commas (spacing?)
   釣狐随若      → "Fishing fox follow young" (nonsensical)
   狛呼渚条若    → "Komainu call shore condition young" (nonsensical)
   ```

3. **Frequency Analysis Needed**
   - Map cipher characters to actual game text
   - Compare with known game dialogue (if available)
   - Analyze statistical patterns (particle frequency, etc.)

## Decryption Strategy

### Method 1: Frequency Analysis
1. Extract all messages
2. Count character frequency
3. Compare with typical Japanese text frequency
4. Map common characters (は, の, を, etc.)

### Method 2: Known-Plaintext Attack
1. Find screenshots or gameplay videos with visible text
2. Match on-screen text to message indices
3. Build character mapping table
4. Apply to remaining messages

### Method 3: Reverse Engineering
1. Disassemble FQ4.EXE
2. Find text rendering routine
3. Locate decryption/mapping function
4. Extract character table

## Extracted Data

### File Locations
- **Raw Dump**: `C:\claude\Fq4\output\text\messages.txt`
- **Decoded**: `C:\claude\Fq4\output\text\messages_decoded.txt`

### Statistics
- Total Messages: **799**
- Offset Table Size: **1,598 bytes**
- Text Data Size: **~63,896 bytes**
- Average Message Length: **~80 bytes**

### Sample Messages

```
[001] 、、、、、、釣狐随若、非洗書
[013] 、、、、、、狛呼渚条若、世書
[024] 、、、、、、、、釣狐随若、世書
[032] 、、、、、狛呼渚条若、或錘
[043] 、、、、、、、、、釣狐随若
```

## Next Steps

1. **Manual Mapping**
   - Play original game with debugger
   - Capture text display events
   - Build initial character mapping

2. **Statistical Analysis**
   - Run frequency analysis on all 799 messages
   - Compare with Japanese text corpus
   - Identify likely mappings for common characters

3. **Automation**
   - Implement cipher decryption in `text_extractor.py`
   - Add `--decrypt` flag with mapping table
   - Generate human-readable translations

## Technical Notes

### Shift-JIS Encoding
- 2-byte characters: 0x81-0x9F, 0xE0-0xEF (first byte)
- Full-width space: 0x8140
- Full-width comma: 0x8141
- Hiragana: 0x829F-0x82F1
- Katakana: 0x8340-0x8396

### Common Control Codes
- `0x00`: String terminator
- `0x81 0x41`: Full-width comma (used as padding?)
- `0x0D 0x0A`: Newline (if present)

## References

- Shift-JIS Table: [Wikipedia](https://en.wikipedia.org/wiki/Shift_JIS)
- Japanese Text Frequency: [NLTK Japanese Corpus](https://www.nltk.org/)
- DOS Game Text Encryption: [Gaming Alexandria](https://www.gamingalexandria.com/)
