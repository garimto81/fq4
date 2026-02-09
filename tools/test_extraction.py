#!/usr/bin/env python3
"""
Test script for FQ4 Graphics Extractor
Demonstrates complete extraction workflow
"""

import subprocess
import sys
from pathlib import Path


def run_command(cmd, description):
    """Run command and print results"""
    print(f"\n{'='*60}")
    print(f"TEST: {description}")
    print(f"{'='*60}")
    print(f"Command: {' '.join(cmd)}")
    print()

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.stdout:
        print(result.stdout)

    if result.returncode != 0:
        print(f"ERROR: Command failed with code {result.returncode}")
        if result.stderr:
            print(result.stderr)
        return False

    return True


def main():
    """Run extraction tests"""
    print("FQ4 Graphics Extractor - Test Suite")
    print("=" * 60)

    tests = [
        # Test 1: Parse palette
        (
            ["python", "tools/fq4_extractor.py", "palette", "GAME/FQ4.RGB", "--output", "output"],
            "Palette Parsing (FQ4.RGB)"
        ),
        # Test 2: Decode first image
        (
            ["python", "tools/fq4_extractor.py", "decode", "GAME/FQOP_01", "--output", "output"],
            "RGBE Decoding (FQOP_01)"
        ),
        # Test 3: Decode second image
        (
            ["python", "tools/fq4_extractor.py", "decode", "GAME/FQOP_02", "--output", "output"],
            "RGBE Decoding (FQOP_02)"
        ),
        # Test 4: Decode third image
        (
            ["python", "tools/fq4_extractor.py", "decode", "GAME/FQOP_03", "--output", "output"],
            "RGBE Decoding (FQOP_03)"
        ),
    ]

    passed = 0
    failed = 0

    for cmd, description in tests:
        if run_command(cmd, description):
            passed += 1
        else:
            failed += 1

    # Verify output files
    print(f"\n{'='*60}")
    print("VERIFICATION: Output Files")
    print(f"{'='*60}")

    expected_files = [
        "output/palette.png",
        "output/FQOP_01.png",
        "output/FQOP_02.png",
        "output/FQOP_03.png",
    ]

    for filepath in expected_files:
        path = Path(filepath)
        if path.exists():
            size = path.stat().st_size
            print(f"[OK] {filepath}: {size:,} bytes")
        else:
            print(f"[FAIL] {filepath}: NOT FOUND")
            failed += 1

    # Summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"{'='*60}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print()

    if failed == 0:
        print("[SUCCESS] ALL TESTS PASSED")
        return 0
    else:
        print("[FAILURE] SOME TESTS FAILED")
        return 1


if __name__ == '__main__':
    sys.exit(main())
