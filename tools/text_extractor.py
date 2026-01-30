#!/usr/bin/env python3
"""
FQ4 Text Extractor
Extracts game text/dialogue from FQ4MES file

File structure:
- Offset table: 16-bit little-endian pointers (799 entries)
- Text data: Shift-JIS encoded strings with 0x00 terminators
"""

import struct
from pathlib import Path
from typing import List, Tuple


class TextExtractor:
    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.messages: List[Tuple[int, str, str]] = []
        self.offsets: List[int] = []
        self.data: bytes = b""

    def analyze_structure(self) -> dict:
        """Analyze file structure and find string table"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()

        # Read offset table (16-bit little-endian pointers)
        i = 0
        while i < len(self.data) - 1:
            offset = struct.unpack('<H', self.data[i:i+2])[0]

            # Offset table ends when we reach data area
            # (offsets point to areas beyond the offset table itself)
            if offset >= len(self.data) or offset < 0x640:
                break

            self.offsets.append(offset)
            i += 2

        return {
            'file_size': len(self.data),
            'offset_table_size': i,
            'message_count': len(self.offsets),
            'first_offset': hex(self.offsets[0]) if self.offsets else None,
            'last_offset': hex(self.offsets[-1]) if self.offsets else None,
        }

    def extract_messages(self) -> int:
        """Extract all text messages from the file"""
        self.messages = []

        for idx, offset in enumerate(self.offsets):
            # Determine message end (next offset or end of file)
            if idx + 1 < len(self.offsets):
                end = self.offsets[idx + 1]
            else:
                end = len(self.data)

            # Extract raw message bytes
            raw_bytes = self.data[offset:end]

            # Split by null terminator (0x00)
            message_bytes = raw_bytes.split(b'\x00')[0]

            # Try to decode as Shift-JIS
            try:
                decoded = message_bytes.decode('shift_jis')
                # Remove common control characters
                decoded = decoded.replace('\x81A', '　')  # Full-width space
                decoded = decoded.strip()
            except UnicodeDecodeError:
                decoded = f"[DECODE ERROR]"

            self.messages.append((idx, message_bytes.hex(), decoded))

        return len(self.messages)

    def save_to_file(self, output_dir: str):
        """Save extracted messages to text files"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        # Save raw hex dump
        with open(output_path / 'messages.txt', 'w', encoding='utf-8') as f:
            f.write("FQ4MES Message Dump\n")
            f.write("=" * 80 + "\n")
            f.write(f"Total messages: {len(self.messages)}\n")
            f.write(f"Offset table: 0x0000 - 0x{len(self.offsets)*2:04X}\n")
            f.write("=" * 80 + "\n\n")

            for idx, raw_hex, decoded in self.messages:
                offset = self.offsets[idx]
                f.write(f"Message #{idx:03d} (Offset: 0x{offset:04X})\n")
                f.write(f"Hex: {raw_hex[:80]}{'...' if len(raw_hex) > 80 else ''}\n")
                f.write(f"Text: {decoded}\n")
                f.write("-" * 80 + "\n")

        # Save decoded text only
        with open(output_path / 'messages_decoded.txt', 'w', encoding='utf-8') as f:
            f.write("FQ4MES Decoded Messages\n")
            f.write("=" * 80 + "\n\n")

            for idx, _, decoded in self.messages:
                if decoded and decoded != "[DECODE ERROR]":
                    f.write(f"[{idx:03d}] {decoded}\n")

        print(f"[OK] Saved to {output_path}")
        print(f"  - messages.txt (full dump)")
        print(f"  - messages_decoded.txt (decoded only)")


def main():
    """Main CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description='Extract text from FQ4MES file',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python text_extractor.py GAME/FQ4MES
  python text_extractor.py GAME/FQ4MES -o output/custom
        """
    )
    parser.add_argument('input', help='Input FQ4MES file path')
    parser.add_argument('-o', '--output', default='output/text',
                        help='Output directory (default: output/text)')
    parser.add_argument('-a', '--analyze-only', action='store_true',
                        help='Only analyze structure, do not extract')

    args = parser.parse_args()

    # Initialize extractor
    print(f"Loading {args.input}...")
    extractor = TextExtractor(args.input)

    # Analyze structure
    print("Analyzing file structure...")
    info = extractor.analyze_structure()

    print(f"\nFile Information:")
    print(f"  File size: {info['file_size']:,} bytes")
    print(f"  Offset table: {info['offset_table_size']} bytes")
    print(f"  Message count: {info['message_count']}")
    print(f"  First offset: {info['first_offset']}")
    print(f"  Last offset: {info['last_offset']}")

    if args.analyze_only:
        return

    # Extract messages
    print("\nExtracting messages...")
    count = extractor.extract_messages()
    print(f"Extracted {count} messages")

    # Save to files
    print(f"\nSaving to {args.output}...")
    extractor.save_to_file(args.output)

    print("\n[OK] Extraction complete!")


if __name__ == '__main__':
    main()
