# Graphics System Documentation

**First Queen 4 Remake - Enhanced Graphics**

## 개요

Phase 1 Enhanced 그래픽 시스템은 원본 PC-9801 그래픽을 AI 업스케일 및 현대적 효과로 재해석합니다.

## 주요 기능

### 1. 이중 그래픽 모드

| 모드 | 해상도 | 팔레트 | 효과 |
|------|--------|--------|------|
| **Classic** | 320x200 (4x 스케일) | 16색 | CRT 필터 |
| **Enhanced** | 1280x800 | 256색 | 파티클, 외곽선 |

**토글 방법:**
- 런타임: `GraphicsManager.toggle_graphics_mode()`
- 키보드: `F5` (설정 시)

### 2. 컬러 팔레트 시스템

**파일:** `resources/palettes/enhanced_palette.tres`

- 원본 16색 보존
- 256색으로 확장 (그라데이션 보간)
- 자동 색상 매핑

**사용 예시:**
```gdscript
var palette := GraphicsManager.enhanced_palette
var color := palette.map_color(5)  # Cyan → Enhanced Cyan
```

### 3. 스프라이트 업스케일

**도구:** `tools/upscale_sprites.py`

```bash
python tools/upscale_sprites.py
```

**처리 과정:**
1. `output/sprites/` 원본 PNG 로드
2. xBRZ 4배 업스케일 (320x200 → 1280x800)
3. `godot/assets/sprites/` 카테고리별 저장

**카테고리:**
- `characters/`: FQ4, FQ4P, FQ4P2
- `effects/`: MAGIC, MAGIC_BRIGHT
- `ui/`: CLASS, FONT, BIGFONT

### 4. 파티클 시스템

#### 파티클 타입

| 타입 | 씬 파일 | 용도 |
|------|---------|------|
| `hit` | `hit_particle.tscn` | 공격 피격 |
| `magic` | `magic_particle.tscn` | 마법 시전 |
| `level_up` | `level_up_particle.tscn` | 레벨업 |
| `death` | `death_particle.tscn` | 사망 |

#### 사용 예시

```gdscript
# 피격 파티클 생성
GraphicsManager.spawn_particle("hit", enemy.global_position, get_parent())

# 마법 파티클 생성
var particle = GraphicsManager.spawn_particle("magic", caster.global_position)
```

### 5. 셰이더 효과

#### CRT 필터 (Classic 모드)

**파일:** `shaders/crt_filter.gdshader`

**파라미터:**
- `scan_line_intensity`: 주사선 강도 (0.0 ~ 1.0)
- `curvature`: 화면 곡률 (0.0 ~ 0.1)
- `vignette_intensity`: 비네팅 (0.0 ~ 1.0)
- `chromatic_aberration`: 색수차 (0.0 ~ 0.01)

```gdscript
GraphicsManager.set_crt_intensity(0.5)  # 중간 강도
```

#### 픽셀화 필터

**파일:** `shaders/pixelate.gdshader`

**파라미터:**
- `pixel_size`: 픽셀 크기 (1.0 ~ 32.0)
- `apply_dithering`: 디더링 활성화 (bool)

```gdscript
GraphicsManager.set_pixelate_size(4.0)
```

#### 외곽선 셰이더 (Enhanced 모드)

**파일:** `shaders/outline.gdshader`

**파라미터:**
- `outline_color`: 외곽선 색상
- `outline_thickness`: 두께 (0.0 ~ 10.0)
- `use_palette_color`: 팔레트 색상 사용

```gdscript
# 캐릭터 스프라이트에 외곽선 적용
sprite.material = GraphicsManager.get_sprite_material(true)
```

### 6. 애니메이션 설정

**파일:** `resources/animation_config.tres`

#### 캐릭터 애니메이션

| 애니메이션 | 프레임 | FPS | 루프 |
|-----------|--------|-----|------|
| `idle` | 4 | 4 | ✓ |
| `walk` | 8 | 10 | ✓ |
| `run` | 8 | 12 | ✓ |
| `attack` | 6 | 12 | ✗ |
| `cast` | 5 | 10 | ✗ |
| `hurt` | 2 | 8 | ✗ |
| `death` | 4 | 6 | ✗ |
| `defend` | 2 | 4 | ✓ |

#### 8방향 레이아웃

스프라이트 시트 row 순서:
```
Row 0: Down (South)
Row 1: Down-Right (South-East)
Row 2: Right (East)
Row 3: Up-Right (North-East)
Row 4: Up (North)
Row 5: Up-Left (North-West)
Row 6: Left (West)
Row 7: Down-Left (South-West)
```

#### 사용 예시

```gdscript
var config := GraphicsManager.animation_config
var anim_data := config.get_animation_data("walk", true)

print(anim_data.frames)  # 8
print(anim_data.fps)     # 10

# 프레임 영역 계산
var region := config.get_frame_region("walk", 3, 2)  # 3번 프레임, 오른쪽 방향
```

### 7. UI 테마

#### Enhanced 테마

**파일:** `themes/enhanced_theme.tres`

- 16px 폰트
- 부드러운 그라데이션 버튼
- 반투명 패널
- 그림자 효과

```gdscript
$Panel.theme = load("res://themes/enhanced_theme.tres")
```

#### Classic 테마

**파일:** `themes/classic_theme.tres`

- 8px 픽셀 폰트
- 단색 버튼
- 16색 팔레트
- CRT 스타일

```gdscript
$Panel.theme = load("res://themes/classic_theme.tres")
```

## 디렉토리 구조

```
godot/
├── assets/
│   ├── sprites/
│   │   ├── characters/     # FQ4 캐릭터 (4x 업스케일)
│   │   ├── effects/        # 마법 이펙트
│   │   └── ui/             # UI 스프라이트
│   ├── tilesets/           # 맵 타일셋
│   └── fonts/              # 폰트 파일
├── resources/
│   ├── palettes/
│   │   └── enhanced_palette.tres  # 256색 팔레트
│   └── animation_config.tres      # 애니메이션 설정
├── scenes/
│   └── effects/            # 파티클 씬
│       ├── hit_particle.tscn
│       ├── magic_particle.tscn
│       ├── level_up_particle.tscn
│       └── death_particle.tscn
├── scripts/
│   ├── autoload/
│   │   └── graphics_manager.gd    # 그래픽 관리자
│   └── resources/
│       ├── color_palette.gd       # 팔레트 스크립트
│       └── animation_config.gd    # 애니메이션 스크립트
├── shaders/
│   ├── crt_filter.gdshader        # CRT 효과
│   ├── pixelate.gdshader          # 픽셀화
│   └── outline.gdshader           # 외곽선
├── themes/
│   ├── enhanced_theme.tres        # Enhanced UI
│   └── classic_theme.tres         # Classic UI
└── tools/
    └── upscale_sprites.py         # 스프라이트 업스케일 도구
```

## 성능 고려사항

### 최적화 팁

1. **파티클 제한**
   - 동시 파티클 수 제한 (권장: 50개)
   - `spawn_particle()` 반환값 추적

2. **셰이더 캐싱**
   - `GraphicsManager`가 자동으로 머티리얼 캐싱
   - 런타임 생성 금지

3. **스프라이트 아틀라스**
   - 같은 카테고리 스프라이트는 하나의 시트로 통합
   - Godot의 자동 아틀라스 기능 활용

4. **LOD (Level of Detail)**
   - 화면 밖 캐릭터는 애니메이션 일시정지
   - `VisibleOnScreenNotifier2D` 사용

## 확장 가능성

### Phase 2 추가 예정

- **동적 조명**: PointLight2D + 노멀맵
- **날씨 효과**: 비, 눈, 안개 파티클
- **포스트 프로세싱**: Bloom, Color Grading
- **커스텀 셰이더**: 물결, 왜곡, 전환 효과

### 커스텀 파티클 추가

1. `scenes/effects/` 에 `.tscn` 생성
2. `GraphicsManager._load_resources()` 에 로드 추가
3. `spawn_particle()` switch 문에 케이스 추가

## 문제 해결

### 스프라이트가 흐릿함

**원인:** Godot의 필터링 활성화

**해결:**
```gdscript
# project.godot
[rendering]
textures/canvas_textures/default_texture_filter=0  # Nearest
```

### 파티클이 표시되지 않음

**원인:** Classic 모드 또는 파티클 씬 로드 실패

**해결:**
```gdscript
# Enhanced 모드 확인
print(GraphicsManager.current_mode)  # 1이어야 함

# 파티클 씬 확인
print(GraphicsManager.hit_particle_scene != null)
```

### CRT 효과가 너무 강함

**원인:** 기본 파라미터가 높음

**해결:**
```gdscript
GraphicsManager.set_crt_intensity(0.2)  # 약하게 조정
```

## 참고 자료

- [Godot Shader 문서](https://docs.godotengine.org/en/stable/tutorials/shaders/index.html)
- [CPUParticles2D 문서](https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html)
- [xBRZ 알고리즘](https://github.com/atheros/xbrzscale)
