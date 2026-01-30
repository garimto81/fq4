# FQ4 Graphics Extractor - Quick Start

## Installation

```bash
# Install Python dependencies
pip install Pillow

# Navigate to project directory
cd C:\claude\Fq4
```

## Quick Test

Run the complete test suite:

```bash
python tools/test_extraction.py
```

Expected output:
```
[SUCCESS] ALL TESTS PASSED
Passed: 4
Failed: 0
```

## Extract Graphics

### Extract Palette

```bash
python tools/fq4_extractor.py palette GAME/FQ4.RGB --output output
```

Output: `output/palette.png` (16-color swatch)

### Extract Single Image

```bash
python tools/fq4_extractor.py decode GAME/FQOP_01 --output output
```

Output: `output/FQOP_01.png` (320×200 indexed color image)

### Batch Extract All Images

```bash
# Windows PowerShell
1..10 | ForEach-Object {
    $num = "{0:D2}" -f $_
    python tools/fq4_extractor.py decode GAME/FQOP_$num --output output
}
```

```bash
# Linux/macOS
for i in {01..10}; do
    python tools/fq4_extractor.py decode GAME/FQOP_$i --output output
done
```

## View Results

```bash
# List extracted files
ls output/*.png

# View in default image viewer
start output/FQOP_01.png   # Windows
open output/FQOP_01.png    # macOS
xdg-open output/FQOP_01.png # Linux
```

## File Locations

```
C:\claude\Fq4\
├── GAME\              # Original game files
│   ├── FQ4.RGB       # Palette (88 bytes)
│   └── FQOP_*.B_/R_/G_/E_  # Image planes
├── tools\            # Extraction tools
│   ├── fq4_extractor.py    # Main extractor
│   ├── test_extraction.py  # Test suite
│   └── README.md           # Documentation
├── output\           # Extracted graphics
│   ├── palette.png
│   └── FQOP_*.png
└── QUICKSTART.md     # This file
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'PIL'"

Install Pillow:
```bash
pip install Pillow
```

### "File not found" errors

Ensure you're in the correct directory:
```bash
cd C:\claude\Fq4
```

Check that GAME folder exists:
```bash
ls GAME/FQ4.RGB
```

### Garbled/Strange Images

This is expected with current implementation. The compression format is not fully decoded yet. Images show recognizable patterns but may have artifacts.

## Next Steps

- See `tools/README.md` for detailed format documentation
- See `IMPLEMENTATION_SUMMARY.md` for technical details
- Visually inspect extracted images in `output/`
- Report findings or patterns observed

## Help

```bash
# Show help
python tools/fq4_extractor.py --help

# Show palette command help
python tools/fq4_extractor.py palette --help

# Show decode command help
python tools/fq4_extractor.py decode --help
```
