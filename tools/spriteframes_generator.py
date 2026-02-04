"""
SpriteFrames Generator for Godot 4.x

AI 업스케일된 스프라이트 시트에서 Godot SpriteFrames 리소스(.tres)를 자동 생성하는 CLI 도구.
"""

import argparse
import sys
from pathlib import Path
from typing import List, Tuple


class SpriteFramesGenerator:
    """Godot SpriteFrames .tres 리소스 생성기"""

    def __init__(
        self,
        input_path: Path,
        output_dir: Path,
        tile_size: int = 32,
        frames: int = 4,
        directions: int = 4,
        name: str | None = None,
        fps: float = 8.0,
        include_idle: bool = False,
    ):
        self.input_path = input_path
        self.output_dir = output_dir
        self.tile_size = tile_size
        self.frames = frames
        self.directions = directions
        self.name = name or input_path.stem
        self.fps = fps
        self.include_idle = include_idle

        # 방향 매핑 (스프라이트 시트 행 순서)
        self.direction_names = ["down", "left", "right", "up"][:directions]

    def generate_atlas_frames(self, anim_name: str, row: int) -> List[dict]:
        """특정 애니메이션의 AtlasTexture 프레임 생성"""
        frames_data = []
        for col in range(self.frames):
            frame = {
                "texture": 'SubResource("AtlasTexture_{}_{}")'.format(row, col),
                "duration": 1.0,
            }
            frames_data.append(frame)
        return frames_data

    def generate_atlas_resources(self) -> List[str]:
        """AtlasTexture 서브리소스 생성"""
        resources = []
        resource_id = 1

        for row in range(self.directions):
            for col in range(self.frames):
                x = col * self.tile_size
                y = row * self.tile_size

                resource = f'''[sub_resource type="AtlasTexture" id="AtlasTexture_{row}_{col}"]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {self.tile_size}, {self.tile_size})
'''
                resources.append(resource)
                resource_id += 1

        return resources

    def generate_animations(self) -> List[str]:
        """애니메이션 데이터 생성"""
        animations = []

        # walk 애니메이션
        for row, direction in enumerate(self.direction_names):
            anim_name = f"walk_{direction}"
            frames_data = self.generate_atlas_frames(anim_name, row)

            frames_str = ", ".join(
                f'{{"duration": {f["duration"]}, "texture": {f["texture"]}}}'
                for f in frames_data
            )

            animation = f'''{{
"frames": [{frames_str}],
"loop": true,
"name": &"{anim_name}",
"speed": {self.fps}
}}'''
            animations.append(animation)

        # idle 애니메이션 (첫 프레임만 사용)
        if self.include_idle:
            for row, direction in enumerate(self.direction_names):
                anim_name = f"idle_{direction}"
                frame = {
                    "texture": 'SubResource("AtlasTexture_{}_{}")'.format(row, 0),
                    "duration": 1.0,
                }

                animation = f'''{{
"frames": [{{"duration": {frame["duration"]}, "texture": {frame["texture"]}}}],
"loop": true,
"name": &"{anim_name}",
"speed": 1.0
}}'''
                animations.append(animation)

        return animations

    def generate_tres(self) -> str:
        """전체 .tres 파일 생성"""
        # 상대 경로 계산 (res:// 기준)
        godot_root = self.input_path.resolve()
        while godot_root.name != "godot" and godot_root.parent != godot_root:
            godot_root = godot_root.parent

        if godot_root.name == "godot":
            relative_path = self.input_path.resolve().relative_to(godot_root)
            texture_path = f"res://{relative_path.as_posix()}"
        else:
            # godot 폴더 못 찾으면 절대 경로 사용
            texture_path = f"res://{self.input_path.as_posix()}"

        # AtlasTexture 서브리소스
        atlas_resources = self.generate_atlas_resources()

        # 애니메이션
        animations = self.generate_animations()
        animations_str = ",\n".join(animations)

        # 전체 .tres 파일
        tres_content = f'''[gd_resource type="SpriteFrames" load_steps={len(atlas_resources) + 1} format=3 uid="uid://generated"]

[ext_resource type="Texture2D" path="{texture_path}" id="1"]

{chr(10).join(atlas_resources)}

[resource]
animations = [
{animations_str}
]
'''
        return tres_content

    def save(self) -> Path:
        """파일 저장"""
        self.output_dir.mkdir(parents=True, exist_ok=True)
        output_path = self.output_dir / f"{self.name}.tres"

        tres_content = self.generate_tres()
        output_path.write_text(tres_content, encoding="utf-8")

        return output_path


def main():
    parser = argparse.ArgumentParser(
        description="AI 업스케일된 스프라이트 시트에서 Godot SpriteFrames 리소스 생성"
    )

    parser.add_argument(
        "--input",
        type=Path,
        required=True,
        help="입력 스프라이트 시트 PNG 파일 경로",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="출력 디렉토리",
    )
    parser.add_argument(
        "--tile-size",
        type=int,
        default=32,
        help="타일 크기 (기본: 32, HD는 128)",
    )
    parser.add_argument(
        "--frames",
        type=int,
        default=4,
        help="애니메이션 프레임 수 (기본: 4)",
    )
    parser.add_argument(
        "--directions",
        type=int,
        default=4,
        choices=[1, 2, 4, 8],
        help="방향 수 (기본: 4)",
    )
    parser.add_argument(
        "--name",
        type=str,
        help="스프라이트 이름 (기본: 입력 파일명)",
    )
    parser.add_argument(
        "--fps",
        type=float,
        default=8.0,
        help="애니메이션 FPS (기본: 8.0)",
    )
    parser.add_argument(
        "--idle",
        action="store_true",
        help="idle 애니메이션 포함",
    )

    args = parser.parse_args()

    # 입력 파일 검증
    if not args.input.exists():
        print(f"Error: 입력 파일이 존재하지 않습니다: {args.input}", file=sys.stderr)
        sys.exit(1)

    # 생성
    generator = SpriteFramesGenerator(
        input_path=args.input,
        output_dir=args.output,
        tile_size=args.tile_size,
        frames=args.frames,
        directions=args.directions,
        name=args.name,
        fps=args.fps,
        include_idle=args.idle,
    )

    try:
        output_path = generator.save()
        print(f"SpriteFrames 생성 완료: {output_path}")
        print(f"  - 타일 크기: {args.tile_size}x{args.tile_size}")
        print(f"  - 프레임: {args.frames}")
        print(f"  - 방향: {args.directions}")
        print(f"  - FPS: {args.fps}")
        if args.idle:
            print(f"  - idle 애니메이션 포함")
    except Exception as e:
        print(f"Error: 생성 실패: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
