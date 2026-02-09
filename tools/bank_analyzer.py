#!/usr/bin/env python3
"""
FQ4 Bank File Analyzer
Analyzes and extracts data from CHRBANK, MAPBANK, BGMBANK files

Bank File Structure:
- Offset table at beginning (array of 16-bit little-endian values)
- Each offset points to an entry in the file
- Entries are variable length
- Last entry extends to end of file
"""

import struct
import sys
from pathlib import Path
from typing import List, Tuple


class BankAnalyzer:
    """Analyzes and extracts DOS game bank files"""

    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.data: bytes = b''
        self.offsets: List[int] = []
        self.entry_count: int = 0
        self.base_offset: int = 0

    def load(self) -> None:
        """Load bank file into memory"""
        with open(self.filepath, 'rb') as f:
            self.data = f.read()
        print(f"Loaded {self.filepath.name}: {len(self.data)} bytes")

    def detect_size_table(self) -> bool:
        """
        Detect size table structure.

        Bank file structure:
        - Pure size table starting at byte 0 (no header)
        - Each 16-bit LE word is the size of an entry
        - Size table continues until sizes would exceed file
        - Data immediately follows size table

        Algorithm:
        1. Read 16-bit sizes sequentially
        2. Stop when sizes account for entire file
        3. Calculate offsets by accumulating sizes
        """
        if len(self.data) < 4:
            return False

        sizes = []
        pos = 0
        total_data_size = 0

        # Read sizes until we account for the entire file
        max_entries = min(10000, len(self.data) // 2)  # Sanity limit

        for i in range(max_entries):
            if pos + 2 > len(self.data):
                break

            size = struct.unpack_from('<H', self.data, pos)[0]

            # Sanity checks
            if size == 0:
                # Zero marks end of size table
                pos += 2  # Skip the zero
                break
            if size > 50000:  # Unreasonably large for these files
                break

            sizes.append(size)
            total_data_size += size
            pos += 2

            # Check if we've accounted for the entire file
            # Size table includes all entries plus any terminator
            size_table_bytes = pos
            expected_file_size = size_table_bytes + total_data_size

            # Allow small variance (padding)
            if abs(expected_file_size - len(self.data)) <= 10:
                break

            # If we've gone over, we read too many
            if expected_file_size > len(self.data):
                # Remove last entry and stop
                sizes.pop()
                total_data_size -= size
                pos -= 2
                break

        if len(sizes) < 2:
            return False

        # Verify the calculation
        # pos now points after the last entry (or zero terminator)
        size_table_bytes = pos
        expected_file_size = size_table_bytes + total_data_size

        # Check if there's padding between size table and data
        # (e.g., MAPBANK has 52 bytes of padding)
        padding = 0
        if expected_file_size < len(self.data):
            # Check for zero padding
            potential_padding = len(self.data) - expected_file_size
            if potential_padding < 256:  # Reasonable padding size
                # Verify it's actually zeros
                padding_bytes = self.data[pos:pos + potential_padding]
                if all(b == 0 for b in padding_bytes):
                    padding = potential_padding
                    size_table_bytes = pos + padding

        expected_file_size = size_table_bytes + total_data_size

        if abs(expected_file_size - len(self.data)) > 10:
            return False

        # Calculate offsets from sizes
        current_offset = size_table_bytes
        calculated_offsets = []

        for size in sizes:
            calculated_offsets.append(current_offset)
            current_offset += size

        self.offsets = calculated_offsets
        self.entry_count = len(calculated_offsets)
        self.base_offset = size_table_bytes

        return True

    def detect_offset_table(self) -> bool:
        """Wrapper that tries size table detection"""
        return self.detect_size_table()

    def analyze(self) -> dict:
        """Analyze bank file structure and return metadata"""
        self.load()

        if not self.detect_offset_table():
            return {
                'status': 'error',
                'message': 'Could not detect offset table structure'
            }

        # Calculate entry sizes
        entry_info = []
        for i in range(self.entry_count):
            start = self.offsets[i]
            if i < self.entry_count - 1:
                end = self.offsets[i + 1]
            else:
                end = len(self.data)

            size = end - start
            entry_info.append({
                'index': i,
                'offset': start,
                'size': size
            })

        return {
            'status': 'success',
            'filename': self.filepath.name,
            'filesize': len(self.data),
            'entry_count': self.entry_count,
            'base_offset': self.base_offset,
            'offset_table_size': self.base_offset,
            'entries': entry_info,
            'avg_entry_size': sum(e['size'] for e in entry_info) / len(entry_info),
            'min_entry_size': min(e['size'] for e in entry_info),
            'max_entry_size': max(e['size'] for e in entry_info),
        }

    def extract_entries(self, output_dir: Path) -> int:
        """
        Extract all entries to output directory.

        Returns:
            Number of entries extracted
        """
        output_dir.mkdir(parents=True, exist_ok=True)

        base_name = self.filepath.stem
        extracted = 0

        for i in range(self.entry_count):
            start = self.offsets[i]
            if i < self.entry_count - 1:
                end = self.offsets[i + 1]
            else:
                end = len(self.data)

            entry_data = self.data[start:end]

            # Save with index and offset in filename
            output_file = output_dir / f"{base_name}_{i:04d}_0x{start:06X}.bin"
            with open(output_file, 'wb') as f:
                f.write(entry_data)

            extracted += 1

        return extracted

    def dump_header_info(self) -> str:
        """Return formatted header information"""
        lines = []
        lines.append(f"\n=== {self.filepath.name} Header Analysis ===")
        lines.append(f"File size: {len(self.data)} bytes")
        lines.append(f"\nFirst 64 bytes (hex):")

        for i in range(0, min(64, len(self.data)), 16):
            chunk = self.data[i:i+16]
            hex_str = ' '.join(f'{b:02X}' for b in chunk)
            ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
            lines.append(f"{i:04X}: {hex_str:<48} {ascii_str}")

        if self.offsets:
            lines.append(f"\nOffset table (first 10 entries):")
            for i, offset in enumerate(self.offsets[:10]):
                lines.append(f"  [{i:3d}] 0x{offset:06X} ({offset})")
            if len(self.offsets) > 10:
                lines.append(f"  ... ({len(self.offsets) - 10} more entries)")

        return '\n'.join(lines)


def analyze_all_banks(game_dir: Path, output_dir: Path):
    """Analyze all bank files in GAME directory"""

    bank_files = [
        'CHRBANK',
        'MAPBANK',
        'BGMBANK1',
        'BGMBANK2',
        'FQFBANK'
    ]

    results = []

    for bank_name in bank_files:
        bank_path = game_dir / bank_name
        if not bank_path.exists():
            print(f"Warning: {bank_name} not found")
            continue

        print(f"\n{'='*60}")
        analyzer = BankAnalyzer(str(bank_path))
        result = analyzer.analyze()

        if result['status'] == 'success':
            print(analyzer.dump_header_info())
            print(f"\n--- Analysis Results ---")
            print(f"Entry count: {result['entry_count']}")
            print(f"Offset table size: {result['offset_table_size']} bytes")
            print(f"Average entry size: {result['avg_entry_size']:.1f} bytes")
            print(f"Entry size range: {result['min_entry_size']} - {result['max_entry_size']} bytes")

            # Extract entries
            extract_dir = output_dir / bank_name.lower()
            extracted = analyzer.extract_entries(extract_dir)
            print(f"\nExtracted {extracted} entries to {extract_dir}")

            results.append(result)
        else:
            print(f"Error analyzing {bank_name}: {result['message']}")

    # Save summary report
    summary_path = output_dir / "bank_analysis_summary.txt"
    with open(summary_path, 'w') as f:
        f.write("FQ4 Bank File Analysis Summary\n")
        f.write("="*60 + "\n\n")

        for result in results:
            if result['status'] == 'success':
                f.write(f"{result['filename']}:\n")
                f.write(f"  File size: {result['filesize']:,} bytes\n")
                f.write(f"  Entries: {result['entry_count']}\n")
                f.write(f"  Avg entry size: {result['avg_entry_size']:.1f} bytes\n")
                f.write(f"  Size range: {result['min_entry_size']} - {result['max_entry_size']} bytes\n")
                f.write("\n")

    print(f"\nSummary saved to {summary_path}")


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: bank_analyzer.py <bank_file> [output_dir]")
        print("   or: bank_analyzer.py --all [game_dir] [output_dir]")
        print("\nAnalyzes FQ4 bank files and extracts entries")
        sys.exit(1)

    if sys.argv[1] == '--all':
        game_dir = Path(sys.argv[2] if len(sys.argv) > 2 else 'GAME')
        output_dir = Path(sys.argv[3] if len(sys.argv) > 3 else 'output/banks')
        analyze_all_banks(game_dir, output_dir)
    else:
        bank_path = Path(sys.argv[1])
        output_dir = Path(sys.argv[2] if len(sys.argv) > 2 else 'output/banks')

        analyzer = BankAnalyzer(str(bank_path))
        result = analyzer.analyze()

        if result['status'] == 'success':
            print(analyzer.dump_header_info())
            print(f"\n--- Analysis Results ---")
            print(f"Entry count: {result['entry_count']}")
            print(f"Offset table size: {result['offset_table_size']} bytes")
            print(f"Average entry size: {result['avg_entry_size']:.1f} bytes")

            # Extract
            extract_dir = output_dir / bank_path.stem.lower()
            extracted = analyzer.extract_entries(extract_dir)
            print(f"\nExtracted {extracted} entries to {extract_dir}")
        else:
            print(f"Error: {result['message']}")
            sys.exit(1)


if __name__ == '__main__':
    main()
