# First Queen 4 HD - Build Instructions

## 프로젝트 상태

릴리즈 빌드 설정이 완료되었습니다.

### 구성 파일

| 파일 | 상태 | 설명 |
|------|------|------|
| `godot/project.godot` | ✅ | 릴리즈 설정 추가 (v1.0.0, 아이콘, 스플래시) |
| `godot/export_presets.cfg` | ✅ | 3개 플랫폼 프리셋 (Windows, Linux, macOS) |
| `godot/icon.ico` | ✅ | Windows 아이콘 (FQ4.ico 복사) |
| `godot/assets/images/splash/boot_splash.png` | ✅ | 부트 스플래시 (1280x800) |
| `build/windows/` | ✅ | Windows 빌드 출력 디렉토리 |
| `build/linux/` | ✅ | Linux 빌드 출력 디렉토리 |
| `build/macos/` | ✅ | macOS 빌드 출력 디렉토리 |

### 프로젝트 설정 (project.godot)

```ini
config/name="First Queen 4 HD"
config/description="First Queen 4 HD Remake - Gocha-Kyara Real-time Tactical RPG"
config/version="1.0.0"
config/icon="res://icon.ico"
boot_splash/image="res://assets/images/splash/boot_splash.png"
boot_splash/bg_color=Color(0, 0, 0, 1)
```

## 빌드 전 필수 작업

**⚠️ 다음 스크립트 에러 수정 필요:**

| 에러 | 영향 파일 | 원인 |
|------|----------|------|
| `SpatialHash` 타입 없음 | `game_manager.gd` | 공간 해시 클래스 미구현 |
| `ObjectPool` 식별자 없음 | `pool_manager.gd` | 오브젝트 풀 클래스 미구현 |
| `HitFlash` 식별자 없음 | `effect_manager.gd` | 타격 이펙트 클래스 미구현 |
| `AchievementData` 타입 없음 | `achievement_system.gd` | 업적 데이터 리소스 미정의 |

**빌드 전 실행 명령:**
```powershell
# 에러 확인
C:\claude\Fq4\Godot_v4.4-stable_win64_console.exe --path C:\claude\Fq4\godot --headless --quit
```

## 빌드 방법

### 1. Godot 에디터 UI 사용 (권장)

```powershell
# 에디터 열기
C:\claude\Fq4\Godot_v4.4-stable_win64.exe --path C:\claude\Fq4\godot --editor
```

**에디터 내 빌드:**
1. Project → Export
2. 플랫폼 선택 (Windows Desktop / Linux/X11 / macOS)
3. Export Project 클릭
4. 출력 경로 확인: `C:\claude\Fq4\build\{platform}\`

### 2. CLI 빌드 (자동화)

```powershell
# Windows 빌드 (64-bit)
C:\claude\Fq4\Godot_v4.4-stable_win64_console.exe --headless --export-release "Windows Desktop" "C:\claude\Fq4\build\windows\FirstQueen4HD.exe"

# Linux 빌드 (x86_64)
C:\claude\Fq4\Godot_v4.4-stable_win64_console.exe --headless --export-release "Linux/X11" "C:\claude\Fq4\build\linux\FirstQueen4HD.x86_64"

# macOS 빌드 (Universal)
C:\claude\Fq4\Godot_v4.4-stable_win64_console.exe --headless --export-release "macOS" "C:\claude\Fq4\build\macos\FirstQueen4HD.app"
```

### 3. 전체 플랫폼 빌드 스크립트

**`build_all.ps1` 생성:**
```powershell
$GODOT_BIN = "C:\claude\Fq4\Godot_v4.4-stable_win64_console.exe"
$PROJECT_PATH = "C:\claude\Fq4\godot"
$BUILD_DIR = "C:\claude\Fq4\build"

Write-Host "Building First Queen 4 HD - All Platforms..."

# Windows
Write-Host "`nBuilding Windows (x64)..."
& $GODOT_BIN --headless --path $PROJECT_PATH --export-release "Windows Desktop" "$BUILD_DIR\windows\FirstQueen4HD.exe"

# Linux
Write-Host "`nBuilding Linux (x86_64)..."
& $GODOT_BIN --headless --path $PROJECT_PATH --export-release "Linux/X11" "$BUILD_DIR\linux\FirstQueen4HD.x86_64"

# macOS
Write-Host "`nBuilding macOS (Universal)..."
& $GODOT_BIN --headless --path $PROJECT_PATH --export-release "macOS" "$BUILD_DIR\macos\FirstQueen4HD.app"

Write-Host "`n✅ Build completed!"
Write-Host "Output: $BUILD_DIR"
```

**실행:**
```powershell
.\build_all.ps1
```

## 빌드 출력 구조

```
build/
├── windows/
│   ├── FirstQueen4HD.exe        # 실행 파일
│   └── FirstQueen4HD.pck        # 리소스 팩 (embed_pck=true 시 exe에 포함)
├── linux/
│   ├── FirstQueen4HD.x86_64     # 실행 파일
│   └── FirstQueen4HD.pck
└── macos/
    └── FirstQueen4HD.app/       # macOS 번들
        ├── Contents/
        │   ├── Info.plist
        │   ├── MacOS/
        │   │   └── FirstQueen4HD
        │   └── Resources/
        │       └── FirstQueen4HD.pck
```

## 배포 체크리스트

- [ ] 모든 스크립트 에러 수정 (`SpatialHash`, `ObjectPool`, `AchievementData` 등)
- [ ] 게임 정상 실행 확인 (`--headless --quit` 에러 없음)
- [ ] HD 에셋 배포 완료 (`godot/assets/images/backgrounds/hd/`)
- [ ] 번역 파일 완료 (`resources/translations/*.csv`)
- [ ] 3개 챕터 맵 완성 (`scenes/maps/chapter1~3/`)
- [ ] 빌드 테스트 (Windows/Linux/macOS 각각)
- [ ] 아이콘/스플래시 이미지 최종 확인
- [ ] LICENSE.md 업데이트 (Original: Kure Software 1994)

## Export Presets 설정

| 옵션 | Windows | Linux | macOS |
|------|---------|-------|-------|
| embed_pck | ✅ | ✅ | ✅ |
| texture_format | bptc, s3tc | bptc, s3tc | bptc, s3tc |
| product_version | 1.0.0 | - | - |
| company_name | FQ4 HD Team | - | - |
| copyright | Original: Kure Software 1994 | - | - |

## 라이센스 주의사항

**Original Game:**
- First Queen 4 © 1994 Kure Software
- DOS 버전 원본 에셋 사용 (역공학)

**Remake:**
- Godot 4.4 (MIT License)
- Python 에셋 도구 (MIT License)

**배포 시:**
- 원작 저작권 명시 필수
- 상업적 배포 전 Kure Software 권리 확인 필요

## 참조

- Godot Export Documentation: https://docs.godotengine.org/en/stable/tutorials/export/
- Godot CLI Export: `--export-release` 또는 `--export-debug`
