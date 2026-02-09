# InputManager Guide

## 개요

InputManager는 게임패드/컨트롤러 자동 감지 및 버튼 프롬프트 제공을 위한 Godot Autoload 싱글톤입니다.

## 핵심 기능

| 기능 | 설명 |
|------|------|
| 자동 컨트롤러 감지 | Xbox, PlayStation, Generic 컨트롤러 자동 식별 |
| Hot-plug 지원 | 게임패드 연결/해제 실시간 감지 |
| 버튼 프롬프트 | 컨트롤러별 버튼 아이콘 경로 제공 |
| 입력 장치 전환 | 키보드 ↔ 게임패드 자동 전환 |

## 사용법

### 컨트롤러 상태 확인

```gdscript
# 게임패드 사용 중인지 확인
if InputManager.is_using_gamepad():
    print("Gamepad active")

# 현재 컨트롤러 타입
match InputManager.current_controller:
    InputManager.ControllerType.XBOX:
        print("Xbox controller")
    InputManager.ControllerType.PLAYSTATION:
        print("PlayStation controller")
```

### 버튼 프롬프트 표시

```gdscript
# 키보드: 텍스트 반환
var attack_text = InputManager.get_button_text("attack")
# → "Space"

# 게임패드: 아이콘 경로 반환
var attack_icon = InputManager.get_button_icon("attack")
# → "res://assets/ui/icons/xbox_x.png" (Xbox)
# → "res://assets/ui/icons/ps_square.png" (PlayStation)
```

### 입력 장치 변경 감지

```gdscript
func _ready() -> void:
    InputManager.input_device_changed.connect(_on_input_device_changed)
    InputManager.controller_changed.connect(_on_controller_changed)

func _on_input_device_changed(is_gamepad: bool) -> void:
    if is_gamepad:
        print("Switched to gamepad")
        # UI 버튼 프롬프트를 아이콘으로 변경
    else:
        print("Switched to keyboard")
        # UI 버튼 프롬프트를 키 텍스트로 변경

func _on_controller_changed(controller_type: InputManager.ControllerType) -> void:
    print("Controller type changed: ", controller_type)
    # 컨트롤러별 아이콘 업데이트
```

## 게임패드 매핑

### 이동 (아날로그 스틱)

| 액션 | 키보드 | 게임패드 |
|------|--------|----------|
| `move_left` | A | Left Stick Left (Axis 0, -1.0) |
| `move_right` | D | Left Stick Right (Axis 0, +1.0) |
| `move_up` | W | Left Stick Up (Axis 1, -1.0) |
| `move_down` | S | Left Stick Down (Axis 1, +1.0) |

### 액션 버튼

| 액션 | 키보드 | Xbox | PlayStation |
|------|--------|------|-------------|
| `attack` | Space | X (Button 0) | Cross (Button 0) |
| `confirm` | Enter | A (Button 0) | Cross (Button 0) |
| `cancel` | Escape | B (Button 1) | Circle (Button 1) |
| `command` | C | Y (Button 3) | Triangle (Button 3) |

### 부대 전환

| 액션 | 키보드 | 게임패드 |
|------|--------|----------|
| `next_squad` | → (Right Arrow) | RB (Button 5) |
| `prev_squad` | ← (Left Arrow) | LB (Button 4) |

### 시스템

| 액션 | 키보드 | 게임패드 |
|------|--------|----------|
| `pause` | Escape | Start (Button 6) |
| `toggle_inventory` | I | (키보드만) |

## 아이콘 리소스 구조

```
godot/assets/ui/icons/
├── xbox_a.png          # Xbox A 버튼
├── xbox_b.png          # Xbox B 버튼
├── xbox_x.png          # Xbox X 버튼
├── xbox_y.png          # Xbox Y 버튼
├── ps_cross.png        # PS Cross (×) 버튼
├── ps_circle.png       # PS Circle (○) 버튼
├── ps_square.png       # PS Square (□) 버튼
└── ps_triangle.png     # PS Triangle (△) 버튼
```

**주의:** 아이콘 파일은 별도로 추가해야 합니다. 무료 리소스:
- [Xelu's FREE Controllers & Keyboard Prompts](https://thoseawesomeguys.com/prompts/)
- [Kenney's Input Prompts](https://kenney.nl/assets/input-prompts)

## 테스트

### 테스트 씬 실행

```powershell
.\Godot_v4.4-stable_win64.exe --path godot res://scenes/test/input_manager_test.tscn
```

### 테스트 항목

- [ ] 게임패드 연결 시 자동 감지
- [ ] 게임패드 해제 시 키보드로 전환
- [ ] Xbox 컨트롤러 정확히 식별
- [ ] PlayStation 컨트롤러 정확히 식별
- [ ] 버튼 입력 시 Last Input 업데이트
- [ ] 아날로그 스틱 입력 감지 (Deadzone 0.5)

## 구현 세부사항

### ControllerType Enum

```gdscript
enum ControllerType {
    KEYBOARD,      # 키보드/마우스
    XBOX,          # Xbox 컨트롤러 (XInput)
    PLAYSTATION,   # PlayStation 컨트롤러 (DualShock/DualSense)
    GENERIC        # 기타 컨트롤러
}
```

### 컨트롤러 감지 로직

```gdscript
func _detect_controller_type() -> void:
    var joypads = Input.get_connected_joypads()
    if joypads.is_empty():
        return

    var name = Input.get_joy_name(joypads[0]).to_lower()
    if "xbox" in name or "xinput" in name:
        current_controller = ControllerType.XBOX
    elif "playstation" in name or "dualshock" in name or "dualsense" in name:
        current_controller = ControllerType.PLAYSTATION
    else:
        current_controller = ControllerType.GENERIC
```

## 알려진 제한사항

1. **단일 컨트롤러만 지원**: 현재 첫 번째 연결된 게임패드만 인식
2. **Nintendo Switch Pro Controller**: GENERIC으로 분류됨 (별도 아이콘 없음)
3. **아이콘 리소스 미포함**: 외부 에셋 필요
4. **D-Pad 미사용**: 이동은 아날로그 스틱만 사용 (D-Pad는 메뉴 전용으로 확장 가능)

## 향후 확장

- [ ] Nintendo Switch 컨트롤러 타입 추가
- [ ] 멀티플레이어 (여러 게임패드 동시 지원)
- [ ] 버튼 리매핑 UI
- [ ] 진동 피드백 (Haptic Feedback)
- [ ] 데드존 커스터마이징
