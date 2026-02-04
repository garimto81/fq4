#!/usr/bin/env python3
"""
FQ4 AI Upscale Tool
High-quality AI-powered upscaling for retro game assets

Supports multiple backends:
- Real-ESRGAN (best quality for anime/pixel art)
- Upscayl CLI (cross-platform, easy setup)
- waifu2x (excellent for pixel art preservation)

Usage:
    # Using Real-ESRGAN (recommended for quality)
    python tools/upscale_ai.py realesrgan --input output/images --output output/images_ai --scale 4

    # Using Upscayl CLI
    python tools/upscale_ai.py upscayl --input output/sprites --output output/sprites_ai

    # Check available backends
    python tools/upscale_ai.py check

    # Compare backends on sample image
    python tools/upscale_ai.py compare --input sample.png --output comparison/

Installation:
    # Real-ESRGAN (Python)
    pip install realesrgan basicsr

    # Or standalone executable (no Python needed)
    Download from: https://github.com/xinntao/Real-ESRGAN/releases

    # Upscayl (GUI + CLI)
    Download from: https://upscayl.org/
"""

import argparse
import subprocess
import sys
import shutil
from pathlib import Path
from typing import Optional, List, Tuple, Dict
from dataclasses import dataclass
from enum import Enum
import json

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


class Backend(Enum):
    REALESRGAN = "realesrgan"
    REALESRGAN_NCNN = "realesrgan-ncnn"
    UPSCAYL = "upscayl"
    WAIFU2X = "waifu2x"


@dataclass
class BackendInfo:
    name: str
    available: bool
    path: Optional[str]
    version: Optional[str]
    models: List[str]
    best_for: str


# Real-ESRGAN models optimized for different content types
# Model names must match the ncnn model files (without extension)
REALESRGAN_MODELS = {
    'anime': 'realesrgan-x4plus-anime',      # Best for anime/illustration
    'general': 'realesrgan-x4plus',          # General purpose
    'video': 'realesr-animevideov3',         # For video frames (supports x2, x3, x4)
}

# Upscayl models
UPSCAYL_MODELS = {
    'hfa2k': 'high-fidelity',      # High Fidelity by Helaman
    'remacri': 'remacri',          # by Foolhardy
    'ultramix': 'ultramix',        # Balanced
    'ultrasharp': 'ultrasharp',    # Maximum sharpness
}

# Local installation directory
INSTALL_DIR = Path(__file__).parent / 'ai_backends'
CONFIG_PATH = INSTALL_DIR / 'config.json'


def load_local_config() -> dict:
    """Load local backend configuration"""
    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH, 'r') as f:
                return json.load(f)
        except:
            pass
    return {}


def check_realesrgan_python() -> BackendInfo:
    """Check if Real-ESRGAN Python package is available"""
    try:
        from realesrgan import RealESRGANer
        from basicsr.archs.rrdbnet_arch import RRDBNet
        return BackendInfo(
            name="Real-ESRGAN (Python)",
            available=True,
            path="realesrgan (pip package)",
            version="installed",
            models=list(REALESRGAN_MODELS.keys()),
            best_for="Anime, illustrations, pixel art"
        )
    except ImportError:
        return BackendInfo(
            name="Real-ESRGAN (Python)",
            available=False,
            path=None,
            version=None,
            models=[],
            best_for="Anime, illustrations, pixel art"
        )


def check_realesrgan_ncnn() -> BackendInfo:
    """Check if Real-ESRGAN NCNN executable is available"""
    exe_names = ['realesrgan-ncnn-vulkan', 'realesrgan-ncnn-vulkan.exe']

    # Check local installation first
    config = load_local_config()
    if config.get('realesrgan_path'):
        local_exe = Path(config['realesrgan_path'])
        if local_exe.exists():
            return BackendInfo(
                name="Real-ESRGAN NCNN",
                available=True,
                path=str(local_exe),
                version="ncnn-vulkan (local install)",
                models=list(REALESRGAN_MODELS.keys()),
                best_for="Anime, illustrations (GPU accelerated)"
            )

    # Check in ai_backends directory
    local_install = INSTALL_DIR / 'realesrgan' / 'realesrgan-ncnn-vulkan.exe'
    if local_install.exists():
        return BackendInfo(
            name="Real-ESRGAN NCNN",
            available=True,
            path=str(local_install),
            version="ncnn-vulkan (local install)",
            models=list(REALESRGAN_MODELS.keys()),
            best_for="Anime, illustrations (GPU accelerated)"
        )

    # Check PATH
    for exe in exe_names:
        path = shutil.which(exe)
        if path:
            try:
                result = subprocess.run([path, '-h'], capture_output=True, text=True)
                return BackendInfo(
                    name="Real-ESRGAN NCNN",
                    available=True,
                    path=path,
                    version="ncnn-vulkan",
                    models=list(REALESRGAN_MODELS.keys()),
                    best_for="Anime, illustrations (GPU accelerated)"
                )
            except:
                pass

    # Check in current directory
    for exe in exe_names:
        local_path = Path(exe)
        if local_path.exists():
            return BackendInfo(
                name="Real-ESRGAN NCNN",
                available=True,
                path=str(local_path),
                version="ncnn-vulkan (local)",
                models=list(REALESRGAN_MODELS.keys()),
                best_for="Anime, illustrations (GPU accelerated)"
            )

    return BackendInfo(
        name="Real-ESRGAN NCNN",
        available=False,
        path=None,
        version=None,
        models=[],
        best_for="Anime, illustrations (GPU accelerated)"
    )


def check_upscayl() -> BackendInfo:
    """Check if Upscayl CLI is available"""
    exe_names = ['upscayl-bin', 'upscayl', 'upscayl.exe']

    for exe in exe_names:
        path = shutil.which(exe)
        if path:
            return BackendInfo(
                name="Upscayl",
                available=True,
                path=path,
                version="cli",
                models=list(UPSCAYL_MODELS.keys()),
                best_for="General images, photos"
            )

    return BackendInfo(
        name="Upscayl",
        available=False,
        path=None,
        version=None,
        models=[],
        best_for="General images, photos"
    )


def check_waifu2x() -> BackendInfo:
    """Check if waifu2x is available"""
    exe_names = ['waifu2x-ncnn-vulkan', 'waifu2x-ncnn-vulkan.exe', 'waifu2x']

    # Check local installation first
    config = load_local_config()
    if config.get('waifu2x_path'):
        local_exe = Path(config['waifu2x_path'])
        if local_exe.exists():
            return BackendInfo(
                name="waifu2x",
                available=True,
                path=str(local_exe),
                version="ncnn-vulkan (local install)",
                models=['anime', 'photo'],
                best_for="Pixel art preservation, anime"
            )

    # Check in ai_backends directory
    local_install = INSTALL_DIR / 'waifu2x' / 'waifu2x-ncnn-vulkan.exe'
    if local_install.exists():
        return BackendInfo(
            name="waifu2x",
            available=True,
            path=str(local_install),
            version="ncnn-vulkan (local install)",
            models=['anime', 'photo'],
            best_for="Pixel art preservation, anime"
        )

    # Check PATH
    for exe in exe_names:
        path = shutil.which(exe)
        if path:
            return BackendInfo(
                name="waifu2x",
                available=True,
                path=path,
                version="ncnn-vulkan",
                models=['anime', 'photo'],
                best_for="Pixel art preservation, anime"
            )

    return BackendInfo(
        name="waifu2x",
        available=False,
        path=None,
        version=None,
        models=[],
        best_for="Pixel art preservation, anime"
    )


def check_all_backends() -> Dict[str, BackendInfo]:
    """Check all available backends"""
    return {
        'realesrgan': check_realesrgan_python(),
        'realesrgan-ncnn': check_realesrgan_ncnn(),
        'upscayl': check_upscayl(),
        'waifu2x': check_waifu2x(),
    }


def upscale_realesrgan_python(
    input_path: Path,
    output_path: Path,
    scale: int = 4,
    model: str = 'anime',
    tile: int = 0,
    denoise: float = 0.5
) -> bool:
    """Upscale using Real-ESRGAN Python package"""
    try:
        import torch
        from basicsr.archs.rrdbnet_arch import RRDBNet
        from realesrgan import RealESRGANer
        from realesrgan.archs.srvgg_arch import SRVGGNetCompact
        import numpy as np
        import cv2
    except ImportError as e:
        print(f"Error: Missing dependency - {e}")
        print("Install with: pip install realesrgan basicsr torch torchvision")
        return False

    # Select model
    model_name = REALESRGAN_MODELS.get(model, REALESRGAN_MODELS['anime'])

    # Setup model architecture based on model name
    if 'anime' in model_name.lower():
        model_arch = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64,
                            num_block=6, num_grow_ch=32, scale=4)
    elif 'v3' in model_name.lower():
        model_arch = SRVGGNetCompact(num_in_ch=3, num_out_ch=3, num_feat=64,
                                     num_conv=32, upscale=4, act_type='prelu')
    else:
        model_arch = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64,
                            num_block=23, num_grow_ch=32, scale=4)

    # Determine device
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    if device == 'cpu':
        print("Warning: Running on CPU. GPU recommended for faster processing.")

    # Create upsampler
    upsampler = RealESRGANer(
        scale=4,
        model_path=None,  # Will download automatically
        dni_weight=denoise,
        model=model_arch,
        tile=tile,
        tile_pad=10,
        pre_pad=0,
        half=True if device == 'cuda' else False,
        device=device
    )

    # Read image
    img = cv2.imread(str(input_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        print(f"Error: Cannot read image {input_path}")
        return False

    # Upscale
    try:
        output, _ = upsampler.enhance(img, outscale=scale)

        # Save
        output_path.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), output)
        return True
    except Exception as e:
        print(f"Error during upscaling: {e}")
        return False


def upscale_realesrgan_ncnn(
    input_path: Path,
    output_path: Path,
    exe_path: str,
    scale: int = 4,
    model: str = 'anime'
) -> bool:
    """Upscale using Real-ESRGAN NCNN executable"""
    model_name = REALESRGAN_MODELS.get(model, REALESRGAN_MODELS['anime'])

    cmd = [
        exe_path,
        '-i', str(input_path),
        '-o', str(output_path),
        '-n', model_name,
        '-s', str(scale),
    ]

    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            if result.stderr:
                print(f"\n    stderr: {result.stderr.strip()}")
            if result.stdout:
                print(f"\n    stdout: {result.stdout.strip()}")
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False


def upscale_waifu2x(
    input_path: Path,
    output_path: Path,
    exe_path: str,
    scale: int = 2,
    noise_level: int = 1
) -> bool:
    """Upscale using waifu2x"""
    cmd = [
        exe_path,
        '-i', str(input_path),
        '-o', str(output_path),
        '-s', str(scale),
        '-n', str(noise_level),
    ]

    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False


def batch_upscale(
    input_path: Path,
    output_dir: Path,
    backend: str,
    scale: int = 4,
    model: str = 'anime',
    recursive: bool = True
) -> dict:
    """Batch upscale all images in directory or single file"""
    backends = check_all_backends()

    if backend not in backends or not backends[backend].available:
        print(f"Error: Backend '{backend}' not available")
        print("Available backends:")
        for name, info in backends.items():
            if info.available:
                print(f"  - {name}: {info.path}")
        return {'processed': 0, 'errors': 0}

    backend_info = backends[backend]
    output_dir.mkdir(parents=True, exist_ok=True)

    # Handle single file vs directory
    if input_path.is_file():
        png_files = [input_path]
        input_dir = input_path.parent
    else:
        input_dir = input_path
        pattern = '**/*.png' if recursive else '*.png'
        png_files = list(input_dir.glob(pattern))

    print(f"Found {len(png_files)} PNG files")
    print(f"Backend: {backend_info.name}")
    print(f"Scale: {scale}x")
    print(f"Model: {model}")
    print()

    stats = {'processed': 0, 'errors': 0, 'skipped': 0}

    for i, png in enumerate(png_files):
        relative = png.relative_to(input_dir)
        out_path = output_dir / relative.parent / f"{png.stem}_ai{scale}x.png"

        if out_path.exists():
            print(f"  [SKIP] {relative}")
            stats['skipped'] += 1
            continue

        print(f"  [{i+1}/{len(png_files)}] {relative}...", end=' ', flush=True)

        success = False

        if backend == 'realesrgan':
            success = upscale_realesrgan_python(png, out_path, scale, model)
        elif backend == 'realesrgan-ncnn':
            success = upscale_realesrgan_ncnn(png, out_path, backend_info.path, scale, model)
        elif backend == 'waifu2x':
            success = upscale_waifu2x(png, out_path, backend_info.path, scale)

        if success:
            print("OK")
            stats['processed'] += 1
        else:
            print("ERROR")
            stats['errors'] += 1

    return stats


def compare_backends(
    input_path: Path,
    output_dir: Path,
    scale: int = 4
) -> None:
    """Compare all available backends on a single image"""
    backends = check_all_backends()
    available = {k: v for k, v in backends.items() if v.available}

    if not available:
        print("No backends available!")
        return

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n=== Backend Comparison ===")
    print(f"Input: {input_path}")
    print(f"Scale: {scale}x")
    print()

    # Copy original
    original = Image.open(input_path)
    original.save(output_dir / f"00_original_{original.width}x{original.height}.png")

    # Nearest neighbor baseline
    nearest = original.resize(
        (original.width * scale, original.height * scale),
        Image.Resampling.NEAREST
    )
    nearest.save(output_dir / f"01_nearest_{nearest.width}x{nearest.height}.png")

    # Test each backend
    for i, (name, info) in enumerate(available.items(), start=2):
        print(f"Testing {info.name}...", end=' ', flush=True)

        out_path = output_dir / f"{i:02d}_{name}_{original.width*scale}x{original.height*scale}.png"

        success = False
        if name == 'realesrgan':
            success = upscale_realesrgan_python(input_path, out_path, scale)
        elif name == 'realesrgan-ncnn':
            success = upscale_realesrgan_ncnn(input_path, out_path, info.path, scale)
        elif name == 'waifu2x':
            success = upscale_waifu2x(input_path, out_path, info.path, min(scale, 2))

        print("OK" if success else "FAILED")

    print(f"\nResults saved to: {output_dir}")


def print_check_results(backends: Dict[str, BackendInfo]) -> None:
    """Print backend availability check results"""
    print("\n" + "="*60)
    print("FQ4 AI Upscale - Backend Availability")
    print("="*60)

    available_count = 0

    for name, info in backends.items():
        status = "[OK] Available" if info.available else "[--] Not found"
        print(f"\n[{name.upper()}] {status}")

        if info.available:
            available_count += 1
            print(f"  Path: {info.path}")
            print(f"  Version: {info.version}")
            print(f"  Models: {', '.join(info.models)}")

        print(f"  Best for: {info.best_for}")

    print("\n" + "="*60)
    print(f"Available backends: {available_count}/{len(backends)}")

    if available_count == 0:
        print("\n[!] No AI backends found!")
        print("\nInstallation options:")
        print("  1. Real-ESRGAN (Python): pip install realesrgan basicsr torch")
        print("  2. Real-ESRGAN NCNN: https://github.com/xinntao/Real-ESRGAN/releases")
        print("  3. Upscayl: https://upscayl.org/")
        print("  4. waifu2x: https://github.com/nihui/waifu2x-ncnn-vulkan/releases")

    print()


def main():
    parser = argparse.ArgumentParser(
        description='FQ4 AI Upscale Tool - High-quality AI-powered upscaling'
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Check command
    check_parser = subparsers.add_parser('check', help='Check available backends')

    # Batch upscale commands for each backend
    for backend in ['realesrgan', 'realesrgan-ncnn', 'upscayl', 'waifu2x']:
        bp = subparsers.add_parser(backend, help=f'Upscale using {backend}')
        bp.add_argument('--input', '-i', type=Path, required=True)
        bp.add_argument('--output', '-o', type=Path, required=True)
        bp.add_argument('--scale', '-s', type=int, default=4,
                        help='Scale factor (default: 4)')
        bp.add_argument('--model', '-m', type=str, default='anime',
                        choices=['anime', 'general', 'video', 'fast'],
                        help='Model type (default: anime)')
        bp.add_argument('--no-recursive', action='store_true')

    # Compare command
    compare_parser = subparsers.add_parser('compare', help='Compare backends')
    compare_parser.add_argument('--input', '-i', type=Path, required=True)
    compare_parser.add_argument('--output', '-o', type=Path, required=True)
    compare_parser.add_argument('--scale', '-s', type=int, default=4)

    # Auto command - use best available backend
    auto_parser = subparsers.add_parser('auto', help='Use best available backend')
    auto_parser.add_argument('--input', '-i', type=Path, required=True)
    auto_parser.add_argument('--output', '-o', type=Path, required=True)
    auto_parser.add_argument('--scale', '-s', type=int, default=4)
    auto_parser.add_argument('--model', '-m', type=str, default='anime')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if args.command == 'check':
        backends = check_all_backends()
        print_check_results(backends)

    elif args.command == 'compare':
        compare_backends(args.input, args.output, args.scale)

    elif args.command == 'auto':
        # Use best available backend
        backends = check_all_backends()

        # Priority: realesrgan > realesrgan-ncnn > waifu2x > upscayl
        priority = ['realesrgan', 'realesrgan-ncnn', 'waifu2x', 'upscayl']

        selected = None
        for backend in priority:
            if backends[backend].available:
                selected = backend
                break

        if not selected:
            print("Error: No AI backends available!")
            print("Run 'python tools/upscale_ai.py check' for installation instructions.")
            return

        print(f"Auto-selected backend: {selected}")
        stats = batch_upscale(
            args.input, args.output, selected,
            args.scale, args.model, True
        )
        print(f"\nProcessed: {stats['processed']}, Errors: {stats['errors']}, Skipped: {stats['skipped']}")

    elif args.command in ['realesrgan', 'realesrgan-ncnn', 'upscayl', 'waifu2x']:
        stats = batch_upscale(
            args.input, args.output, args.command,
            args.scale, args.model, not args.no_recursive
        )
        print(f"\nProcessed: {stats['processed']}, Errors: {stats['errors']}, Skipped: {stats['skipped']}")


if __name__ == '__main__':
    main()
