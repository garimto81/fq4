#!/usr/bin/env python3
"""
DOSBox Capture Workflow Tool for First Queen 4 HD Remake

RGBE/CHR 디코더 우회를 위한 DOSBox 스크린샷 기반 에셋 파이프라인.
Type 9 압축 해제 알고리즘이 불완전하므로 DOSBox 캡처를 공식 에셋 소스로 사용.

Usage:
    python tools/dosbox_capture_workflow.py status          # 현재 에셋 상태 확인
    python tools/dosbox_capture_workflow.py upscale         # 캡처 → HD 업스케일
    python tools/dosbox_capture_workflow.py deploy          # HD 에셋 → Godot 배포
    python tools/dosbox_capture_workflow.py extract-sprites # 스프라이트 추출 (수동)
    python tools/dosbox_capture_workflow.py full            # 전체 파이프라인 실행
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 경로
PROJECT_ROOT = Path(__file__).parent.parent
CAPTURE_DIR = PROJECT_ROOT / "capture"
OUTPUT_DIR = PROJECT_ROOT / "output"
SCREENSHOTS_HD_DIR = OUTPUT_DIR / "screenshots_dosbox_hd"
GODOT_ASSETS_DIR = PROJECT_ROOT / "godot" / "assets"

# 에셋 카테고리 정의
ASSET_CATEGORIES = {
    "title": {
        "description": "타이틀 화면",
        "pattern": "*title*",
        "godot_path": "images/title",
        "required": True,
    },
    "gameplay": {
        "description": "게임플레이 씬",
        "pattern": "*dos*",
        "godot_path": "images/backgrounds",
        "required": True,
    },
    "ui": {
        "description": "UI 요소",
        "pattern": "*ui*",
        "godot_path": "images/ui",
        "required": False,
    },
    "sprites": {
        "description": "캐릭터 스프라이트",
        "pattern": "*sprite*",
        "godot_path": "sprites/characters",
        "required": False,
    },
}

# 필요한 씬 목록 (캡처 가이드용)
REQUIRED_SCENES = [
    {"name": "title_screen", "description": "First Queen IV 타이틀 화면", "captured": False},
    {"name": "chapter1_castle", "description": "Chapter 1 - 성 내부", "captured": False},
    {"name": "chapter1_field", "description": "Chapter 1 - 필드 맵", "captured": False},
    {"name": "battle_scene", "description": "전투 씬", "captured": False},
    {"name": "dialogue_scene", "description": "대화 씬", "captured": False},
    {"name": "inventory_ui", "description": "인벤토리 UI", "captured": False},
    {"name": "status_ui", "description": "스테이터스 UI", "captured": False},
    {"name": "world_map", "description": "월드 맵", "captured": False},
]


def get_capture_files():
    """캡처 디렉토리의 PNG 파일 목록"""
    if not CAPTURE_DIR.exists():
        return []
    return sorted(CAPTURE_DIR.glob("*.png"))


def get_hd_files():
    """HD 업스케일 디렉토리의 PNG 파일 목록"""
    if not SCREENSHOTS_HD_DIR.exists():
        return []
    return sorted(SCREENSHOTS_HD_DIR.glob("*.png"))


def check_upscaler():
    """AI 업스케일러 사용 가능 여부 확인"""
    upscale_script = PROJECT_ROOT / "tools" / "upscale_ai.py"
    if not upscale_script.exists():
        return False, "upscale_ai.py not found"

    # realesrgan-ncnn 확인
    try:
        result = subprocess.run(
            [sys.executable, str(upscale_script), "check"],
            capture_output=True,
            text=True,
            timeout=30
        )
        if "realesrgan-ncnn" in result.stdout.lower() or result.returncode == 0:
            return True, "realesrgan-ncnn available"
    except Exception as e:
        pass

    return False, "No AI upscaler available"


def cmd_status(args):
    """현재 에셋 상태 확인"""
    print("=" * 60)
    print("DOSBox Capture Asset Pipeline - Status")
    print("=" * 60)

    # 캡처 파일 상태
    captures = get_capture_files()
    print(f"\n[CAPTURES] {len(captures)} files")
    print(f"   Location: {CAPTURE_DIR}")
    for f in captures[:5]:
        print(f"   - {f.name}")
    if len(captures) > 5:
        print(f"   ... and {len(captures) - 5} more")

    # HD 업스케일 상태
    hd_files = get_hd_files()
    print(f"\n[HD UPSCALED] {len(hd_files)} files")
    print(f"   Location: {SCREENSHOTS_HD_DIR}")
    for f in hd_files[:5]:
        print(f"   - {f.name}")
    if len(hd_files) > 5:
        print(f"   ... and {len(hd_files) - 5} more")

    # 업스케일러 상태
    upscaler_ok, upscaler_msg = check_upscaler()
    print(f"\n[UPSCALER] {'[OK] ' + upscaler_msg if upscaler_ok else '[X] ' + upscaler_msg}")

    # 미캡처 씬 확인
    print(f"\n[REQUIRED SCENES]")
    for scene in REQUIRED_SCENES:
        status = "[OK]" if scene["captured"] else "[  ]"
        print(f"   {status} {scene['name']}: {scene['description']}")

    # Godot 에셋 상태
    print(f"\n[GODOT ASSETS]")
    for cat_name, cat_info in ASSET_CATEGORIES.items():
        godot_path = GODOT_ASSETS_DIR / cat_info["godot_path"]
        if godot_path.exists():
            files = list(godot_path.glob("*.png"))
            status = f"[OK] {len(files)} files"
        else:
            status = "[X] Not deployed"
        required = "(required)" if cat_info["required"] else "(optional)"
        print(f"   {cat_name}: {status} {required}")

    # 요약
    print("\n" + "=" * 60)
    if len(captures) == 0:
        print("[!] No captures found. Run DOSBox and capture scenes with Ctrl+F5")
    elif len(hd_files) == 0:
        print("[!] Captures exist but not upscaled. Run: python tools/dosbox_capture_workflow.py upscale")
    elif len(hd_files) < len(captures):
        print(f"[!] {len(captures) - len(hd_files)} captures not upscaled yet")
    else:
        print("[OK] Asset pipeline ready. Run 'deploy' to copy to Godot.")

    return 0


def cmd_upscale(args):
    """캡처 파일을 HD로 업스케일"""
    print("[UPSCALE] DOSBox Capture -> HD Upscale")
    print("=" * 60)

    captures = get_capture_files()
    if not captures:
        print("[X] No captures found in", CAPTURE_DIR)
        print("   Run DOSBox and capture scenes with Ctrl+F5")
        return 1

    upscaler_ok, upscaler_msg = check_upscaler()
    if not upscaler_ok:
        print(f"[X] Upscaler not available: {upscaler_msg}")
        print("   Install realesrgan-ncnn-vulkan from:")
        print("   https://github.com/xinntao/Real-ESRGAN/releases")
        return 1

    # 출력 디렉토리 생성
    SCREENSHOTS_HD_DIR.mkdir(parents=True, exist_ok=True)

    # 업스케일 실행
    upscale_script = PROJECT_ROOT / "tools" / "upscale_ai.py"
    cmd = [
        sys.executable, str(upscale_script),
        "realesrgan-ncnn",
        "-i", str(CAPTURE_DIR),
        "-o", str(SCREENSHOTS_HD_DIR),
        "-s", "4",
        "-m", "anime"
    ]

    print(f"Running: {' '.join(cmd)}")
    print()

    try:
        result = subprocess.run(cmd, cwd=PROJECT_ROOT)
        if result.returncode == 0:
            hd_files = get_hd_files()
            print()
            print(f"[OK] Upscaled {len(hd_files)} files to {SCREENSHOTS_HD_DIR}")
            return 0
        else:
            print(f"[X] Upscale failed with code {result.returncode}")
            return result.returncode
    except Exception as e:
        print(f"[X] Error running upscaler: {e}")
        return 1


def cmd_deploy(args):
    """HD 에셋을 Godot 프로젝트에 배포"""
    print("[DEPLOY] HD Assets to Godot")
    print("=" * 60)

    hd_files = get_hd_files()
    if not hd_files:
        print("[X] No HD files found. Run 'upscale' first.")
        return 1

    # 배포 디렉토리 생성
    deployed = 0

    # 배경 이미지 배포
    bg_dir = GODOT_ASSETS_DIR / "images" / "backgrounds" / "hd"
    bg_dir.mkdir(parents=True, exist_ok=True)

    for hd_file in hd_files:
        dest = bg_dir / hd_file.name
        if not dest.exists() or args.force:
            shutil.copy2(hd_file, dest)
            print(f"   Copied: {hd_file.name} → {dest.relative_to(PROJECT_ROOT)}")
            deployed += 1
        else:
            print(f"   Skipped (exists): {hd_file.name}")

    # 타이틀 이미지 별도 복사 (타이틀 화면용)
    title_dir = GODOT_ASSETS_DIR / "images" / "title"
    title_dir.mkdir(parents=True, exist_ok=True)

    for hd_file in hd_files:
        if "new_3" in hd_file.name.lower():  # 타이틀 화면으로 추정
            dest = title_dir / "title_screen_hd.png"
            shutil.copy2(hd_file, dest)
            print(f"   Title: {hd_file.name} → {dest.relative_to(PROJECT_ROOT)}")
            deployed += 1

    print()
    print(f"[OK] Deployed {deployed} files to Godot assets")
    print(f"   Background: {bg_dir.relative_to(PROJECT_ROOT)}")
    print(f"   Title: {title_dir.relative_to(PROJECT_ROOT)}")

    return 0


def cmd_extract_sprites(args):
    """스크린샷에서 스프라이트 추출 가이드"""
    print("[SPRITE] Extraction Guide")
    print("=" * 60)
    print()
    print("DOSBox 캡처에서 스프라이트를 수동 추출하는 방법:")
    print()
    print("1. 게임플레이 스크린샷에서 캐릭터 영역 식별")
    print("   - 캐릭터는 보통 16x16 또는 32x32 픽셀")
    print("   - 4방향 (down, left, right, up) 프레임 필요")
    print()
    print("2. 이미지 편집 도구로 스프라이트 시트 제작")
    print("   - GIMP, Photoshop, Aseprite 권장")
    print("   - 투명 배경으로 추출")
    print("   - 일관된 크기로 정렬")
    print()
    print("3. 스프라이트 시트 저장")
    print(f"   - 경로: {GODOT_ASSETS_DIR / 'sprites' / 'characters'}")
    print("   - 형식: PNG (투명 배경)")
    print("   - 이름: {character}_sheet.png")
    print()
    print("4. SpriteFrames 리소스 생성")
    print("   python tools/spriteframes_generator.py \\")
    print("     --input godot/assets/sprites/characters/hero_sheet.png \\")
    print("     --output godot/resources/sprites \\")
    print("     --tile-size 32 --directions 4")
    print()
    print("📌 참고: 현재 캡처에서 확인된 스프라이트:")

    # 캡처 파일 분석
    captures = get_capture_files()
    gameplay_captures = [f for f in captures if "dos_new_5" in f.name or "dos_new_6" in f.name]

    for cap in gameplay_captures:
        print(f"   - {cap.name}: 게임플레이 씬 (캐릭터 스프라이트 포함)")

    return 0


def cmd_full(args):
    """전체 파이프라인 실행"""
    print("[FULL] Pipeline Execution")
    print("=" * 60)

    # 1. 상태 확인
    print("\n[1/3] Checking status...")
    captures = get_capture_files()
    if not captures:
        print("[X] No captures found. Please run DOSBox first.")
        print("   DOSBox에서 Ctrl+F5로 스크린샷 캡처")
        return 1
    print(f"   Found {len(captures)} captures")

    # 2. 업스케일
    print("\n[2/3] Upscaling to HD...")
    result = cmd_upscale(args)
    if result != 0:
        return result

    # 3. 배포
    print("\n[3/3] Deploying to Godot...")
    args.force = True  # 강제 덮어쓰기
    result = cmd_deploy(args)
    if result != 0:
        return result

    print()
    print("=" * 60)
    print("[OK] Full pipeline completed successfully!")
    print()
    print("Next steps:")
    print("1. Godot에서 에셋 확인: godot/assets/images/")
    print("2. 테스트 씬 실행: scenes/test/hd_asset_test.tscn")
    print("3. 추가 씬 캡처가 필요하면 DOSBox 재실행")

    return 0


def cmd_capture_guide(args):
    """DOSBox 캡처 가이드"""
    print("[GUIDE] DOSBox Capture Guide")
    print("=" * 60)
    print()
    print("## DOSBox 실행 방법")
    print()
    print("1. DOSBox 설치 확인")
    print("   - Windows: https://www.dosbox.com/download.php")
    print("   - 또는 DOSBox-X: https://dosbox-x.com/")
    print()
    print("2. First Queen 4 실행")
    print("   dosbox.exe -c \"mount c C:\\claude\\Fq4\\GAME\" -c \"c:\" -c \"FQ4.EXE\"")
    print()
    print("3. 스크린샷 캡처")
    print("   - Ctrl+F5: 스크린샷 저장")
    print(f"   - 저장 위치: {CAPTURE_DIR}")
    print("   - Alt+Enter: 전체화면 전환")
    print("   - Ctrl+F9: DOSBox 종료")
    print()
    print("## 필요한 씬 목록")
    print()
    for i, scene in enumerate(REQUIRED_SCENES, 1):
        print(f"   {i}. {scene['description']}")
    print()
    print("## 캡처 팁")
    print()
    print("   - 각 챕터의 대표 배경 1-2장씩 캡처")
    print("   - UI 요소가 잘 보이는 상태로 캡처")
    print("   - 대화 씬은 캐릭터 초상화가 보이도록")
    print("   - 전투 씬은 여러 캐릭터가 보이도록")
    print()
    print(f"캡처 후 'python tools/dosbox_capture_workflow.py full' 실행")

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="DOSBox Capture Workflow for FQ4 HD Remake",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python tools/dosbox_capture_workflow.py status
  python tools/dosbox_capture_workflow.py upscale
  python tools/dosbox_capture_workflow.py deploy --force
  python tools/dosbox_capture_workflow.py full
  python tools/dosbox_capture_workflow.py guide
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # status
    sp_status = subparsers.add_parser("status", help="Check asset pipeline status")
    sp_status.set_defaults(func=cmd_status)

    # upscale
    sp_upscale = subparsers.add_parser("upscale", help="Upscale captures to HD")
    sp_upscale.set_defaults(func=cmd_upscale)

    # deploy
    sp_deploy = subparsers.add_parser("deploy", help="Deploy HD assets to Godot")
    sp_deploy.add_argument("--force", "-f", action="store_true", help="Overwrite existing files")
    sp_deploy.set_defaults(func=cmd_deploy)

    # extract-sprites
    sp_sprites = subparsers.add_parser("extract-sprites", help="Sprite extraction guide")
    sp_sprites.set_defaults(func=cmd_extract_sprites)

    # full
    sp_full = subparsers.add_parser("full", help="Run full pipeline")
    sp_full.set_defaults(func=cmd_full)

    # guide
    sp_guide = subparsers.add_parser("guide", help="DOSBox capture guide")
    sp_guide.set_defaults(func=cmd_capture_guide)

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
