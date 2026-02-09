#!/usr/bin/env python3
"""
FQ4 AI Upscaler Setup
Downloads and configures Real-ESRGAN NCNN Vulkan executable

Usage:
    python tools/setup_ai_upscaler.py
    python tools/setup_ai_upscaler.py --check
"""

import argparse
import os
import sys
import zipfile
import shutil
from pathlib import Path
from urllib.request import urlretrieve
from urllib.error import URLError
import json

# Real-ESRGAN NCNN Vulkan releases
REALESRGAN_RELEASES = {
    'windows': {
        'url': 'https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan/releases/download/v0.2.0/realesrgan-ncnn-vulkan-v0.2.0-windows.zip',
        'exe': 'realesrgan-ncnn-vulkan.exe',
        'version': '0.2.0',
    },
}

# waifu2x NCNN Vulkan releases
WAIFU2X_RELEASES = {
    'windows': {
        'url': 'https://github.com/nihui/waifu2x-ncnn-vulkan/releases/download/20220728/waifu2x-ncnn-vulkan-20220728-windows.zip',
        'exe': 'waifu2x-ncnn-vulkan.exe',
        'version': '20220728',
    },
}

INSTALL_DIR = Path(__file__).parent / 'ai_backends'


def download_with_progress(url: str, dest: Path) -> bool:
    """Download file with progress indicator"""
    print(f"Downloading: {url}")
    print(f"Destination: {dest}")

    try:
        def progress_hook(count, block_size, total_size):
            percent = int(count * block_size * 100 / total_size) if total_size > 0 else 0
            print(f"\r  Progress: {percent}%", end='', flush=True)

        urlretrieve(url, dest, progress_hook)
        print()  # newline after progress
        return True
    except URLError as e:
        print(f"\n  Error: {e}")
        return False
    except Exception as e:
        print(f"\n  Error: {e}")
        return False


def extract_zip(zip_path: Path, dest_dir: Path) -> bool:
    """Extract zip file"""
    print(f"Extracting to: {dest_dir}")
    try:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            zf.extractall(dest_dir)
        return True
    except Exception as e:
        print(f"  Error: {e}")
        return False


def setup_realesrgan() -> bool:
    """Download and setup Real-ESRGAN NCNN Vulkan"""
    print("\n=== Setting up Real-ESRGAN NCNN Vulkan ===")

    platform = 'windows'  # TODO: detect platform
    if platform not in REALESRGAN_RELEASES:
        print(f"Error: Platform '{platform}' not supported")
        return False

    release = REALESRGAN_RELEASES[platform]
    install_path = INSTALL_DIR / 'realesrgan'
    exe_path = install_path / release['exe']

    # Check if already installed
    if exe_path.exists():
        print(f"Already installed: {exe_path}")
        return True

    # Create directory
    install_path.mkdir(parents=True, exist_ok=True)

    # Download
    zip_name = Path(release['url']).name
    zip_path = install_path / zip_name

    if not zip_path.exists():
        if not download_with_progress(release['url'], zip_path):
            return False

    # Extract
    if not extract_zip(zip_path, install_path):
        return False

    # Find executable in extracted folder
    for item in install_path.iterdir():
        if item.is_dir():
            nested_exe = item / release['exe']
            if nested_exe.exists():
                # Move contents to install_path
                for subitem in item.iterdir():
                    dest = install_path / subitem.name
                    if not dest.exists():
                        shutil.move(str(subitem), str(dest))
                item.rmdir()
                break

    # Verify
    if exe_path.exists():
        print(f"Installed: {exe_path}")

        # Clean up zip
        if zip_path.exists():
            zip_path.unlink()

        return True
    else:
        print(f"Error: Executable not found after extraction")
        return False


def setup_waifu2x() -> bool:
    """Download and setup waifu2x NCNN Vulkan"""
    print("\n=== Setting up waifu2x NCNN Vulkan ===")

    platform = 'windows'
    if platform not in WAIFU2X_RELEASES:
        print(f"Error: Platform '{platform}' not supported")
        return False

    release = WAIFU2X_RELEASES[platform]
    install_path = INSTALL_DIR / 'waifu2x'
    exe_path = install_path / release['exe']

    # Check if already installed
    if exe_path.exists():
        print(f"Already installed: {exe_path}")
        return True

    # Create directory
    install_path.mkdir(parents=True, exist_ok=True)

    # Download
    zip_name = Path(release['url']).name
    zip_path = install_path / zip_name

    if not zip_path.exists():
        if not download_with_progress(release['url'], zip_path):
            return False

    # Extract
    if not extract_zip(zip_path, install_path):
        return False

    # Find executable in extracted folder
    for item in install_path.iterdir():
        if item.is_dir():
            nested_exe = item / release['exe']
            if nested_exe.exists():
                for subitem in item.iterdir():
                    dest = install_path / subitem.name
                    if not dest.exists():
                        shutil.move(str(subitem), str(dest))
                item.rmdir()
                break

    # Verify
    if exe_path.exists():
        print(f"Installed: {exe_path}")
        if zip_path.exists():
            zip_path.unlink()
        return True
    else:
        print(f"Error: Executable not found after extraction")
        return False


def check_installation() -> dict:
    """Check installed backends"""
    result = {
        'realesrgan': None,
        'waifu2x': None,
    }

    # Check Real-ESRGAN
    realesrgan_exe = INSTALL_DIR / 'realesrgan' / 'realesrgan-ncnn-vulkan.exe'
    if realesrgan_exe.exists():
        result['realesrgan'] = str(realesrgan_exe)

    # Check waifu2x
    waifu2x_exe = INSTALL_DIR / 'waifu2x' / 'waifu2x-ncnn-vulkan.exe'
    if waifu2x_exe.exists():
        result['waifu2x'] = str(waifu2x_exe)

    return result


def update_upscale_ai_paths():
    """Update upscale_ai.py to use local backends"""
    config_path = INSTALL_DIR / 'config.json'

    installed = check_installation()

    config = {
        'realesrgan_path': installed.get('realesrgan'),
        'waifu2x_path': installed.get('waifu2x'),
    }

    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)

    print(f"\nConfiguration saved: {config_path}")


def main():
    parser = argparse.ArgumentParser(
        description='FQ4 AI Upscaler Setup - Download and configure AI backends'
    )
    parser.add_argument('--check', action='store_true',
                        help='Check installed backends only')
    parser.add_argument('--realesrgan-only', action='store_true',
                        help='Install only Real-ESRGAN')
    parser.add_argument('--waifu2x-only', action='store_true',
                        help='Install only waifu2x')

    args = parser.parse_args()

    if args.check:
        print("\n=== Checking AI Backend Installation ===")
        installed = check_installation()

        for name, path in installed.items():
            if path:
                print(f"  [OK] {name}: {path}")
            else:
                print(f"  [--] {name}: Not installed")

        return

    print("="*60)
    print("FQ4 AI Upscaler Setup")
    print("="*60)
    print(f"\nInstall directory: {INSTALL_DIR}")

    success_count = 0

    if args.realesrgan_only:
        if setup_realesrgan():
            success_count += 1
    elif args.waifu2x_only:
        if setup_waifu2x():
            success_count += 1
    else:
        # Install both
        if setup_realesrgan():
            success_count += 1
        if setup_waifu2x():
            success_count += 1

    # Update config
    update_upscale_ai_paths()

    print("\n" + "="*60)
    print(f"Setup complete. Installed: {success_count} backend(s)")

    # Show usage
    installed = check_installation()
    if installed.get('realesrgan'):
        print(f"\nReal-ESRGAN usage:")
        print(f"  python tools/upscale_ai.py realesrgan-ncnn -i input -o output")

    if installed.get('waifu2x'):
        print(f"\nwaifu2x usage:")
        print(f"  python tools/upscale_ai.py waifu2x -i input -o output")


if __name__ == '__main__':
    main()
