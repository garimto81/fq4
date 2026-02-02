# Phase 1 Enhanced Graphics - Quick Start

## 빠른 시작

### 1. Godot에서 프로젝트 열기

```bash
cd C:\claude\Fq4
Godot_v4.4-stable_win64.exe --editor
```

프로젝트 선택: `C:\claude\Fq4\godot\project.godot`

### 2. GraphicsManager 확인

**AutoLoad 확인:**
- Project → Project Settings → AutoLoad
- `GraphicsManager` 항목 확인 (경로: `res://scripts/autoload/graphics_manager.gd`)

### 3. 그래픽 모드 테스트

**테스트 씬 실행:**
1. Godot 에디터에서 `F5` 키 (Run Project)
2. 콘솔에서 모드 확인: `Graphics mode: ENHANCED`

**런타임 전환:**
```gdscript
# Godot 스크립트 콘솔에서
GraphicsManager.toggle_graphics_mode()
```

### 4. 파티클 효과 테스트

**씬에 파티클 추가:**
```gdscript
extends Node2D

func _ready():
    # 화면 중앙에 파티클 생성
    var center = get_viewport_rect().size / 2
    GraphicsManager.spawn_particle("magic", center, self)
```

### 5. 스프라이트 확인

**업스케일된 스프라이트:**
- `assets/sprites/characters/fq4_4x.png` (1.6MB)
- `assets/sprites/effects/magic_4x.png` (55KB)
- `assets/sprites/ui/font_4x.png` (7.8KB)

**에디터에서 확인:**
1. FileSystem → `res://assets/sprites/`
2. 파일 더블클릭 → 프리뷰

## 주요 API

### GraphicsManager

```gdscript
# 그래픽 모드
GraphicsManager.apply_graphics_mode(GraphicsManager.GraphicsMode.ENHANCED)
GraphicsManager.apply_graphics_mode(GraphicsManager.GraphicsMode.CLASSIC)
GraphicsManager.toggle_graphics_mode()

# 파티클
GraphicsManager.spawn_particle("hit", position, parent)
GraphicsManager.spawn_particle("magic", position)
GraphicsManager.spawn_particle("level_up", position)
GraphicsManager.spawn_particle("death", position)

# 셰이더
GraphicsManager.set_crt_intensity(0.5)  # Classic 모드
GraphicsManager.set_pixelate_size(4.0)
sprite.material = GraphicsManager.get_sprite_material(true)  # 외곽선
```

### 팔레트

```gdscript
var palette := GraphicsManager.enhanced_palette
var color := palette.map_color(5)  # Cyan → Enhanced Cyan
var closest := palette.find_closest_color(Color.RED, true)
```

### 애니메이션

```gdscript
var config := GraphicsManager.animation_config
var anim := config.get_animation_data("walk", true)
print(anim.frames)  # 8
print(anim.fps)     # 10

var region := config.get_frame_region("walk", 3, 2)  # 프레임 3, 방향 East
```

## 파일 구조

```
godot/
├── assets/sprites/        # 업스케일 스프라이트 (4x)
├── resources/             # 팔레트, 애니메이션 설정
├── scenes/effects/        # 파티클 씬 4종
├── scripts/
│   ├── autoload/          # GraphicsManager
│   └── resources/         # ColorPalette, AnimationConfig
├── shaders/               # CRT, Pixelate, Outline
├── themes/                # Enhanced, Classic UI
└── tools/                 # upscale_sprites.py
```

## 문제 해결

### 스프라이트가 흐릿함
→ Project Settings → Rendering → Textures → Default Texture Filter = **Nearest**

### 파티클이 안 보임
→ `GraphicsManager.current_mode == GraphicsMode.ENHANCED` 확인

### CRT 효과가 너무 강함
→ `GraphicsManager.set_crt_intensity(0.2)`

## 다음 단계

상세 문서: `docs/GRAPHICS_SYSTEM.md`
구현 요약: `PHASE1_IMPLEMENTATION.md`
