extends Node
## InputManager: 게임패드 및 입력 관리
##
## 게임패드/컨트롤러 자동 감지 및 버튼 프롬프트 제공

enum ControllerType { KEYBOARD, XBOX, PLAYSTATION, GENERIC }

var current_controller: ControllerType = ControllerType.KEYBOARD
var is_gamepad_connected: bool = false

# 버튼 프롬프트 아이콘 경로
var button_icons: Dictionary = {
	ControllerType.XBOX: {
		"confirm": "res://assets/ui/icons/xbox_a.png",
		"cancel": "res://assets/ui/icons/xbox_b.png",
		"attack": "res://assets/ui/icons/xbox_x.png",
		"command": "res://assets/ui/icons/xbox_y.png"
	},
	ControllerType.PLAYSTATION: {
		"confirm": "res://assets/ui/icons/ps_cross.png",
		"cancel": "res://assets/ui/icons/ps_circle.png",
		"attack": "res://assets/ui/icons/ps_square.png",
		"command": "res://assets/ui/icons/ps_triangle.png"
	}
}

signal controller_changed(controller_type: ControllerType)
signal input_device_changed(is_gamepad: bool)

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_detect_connected_gamepads()

func _input(event: InputEvent) -> void:
	# 입력 장치 감지
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not is_gamepad_connected or current_controller == ControllerType.KEYBOARD:
			_switch_to_gamepad()
	elif event is InputEventKey or event is InputEventMouse:
		if is_gamepad_connected or current_controller != ControllerType.KEYBOARD:
			_switch_to_keyboard()

func _switch_to_gamepad() -> void:
	is_gamepad_connected = true
	_detect_controller_type()
	input_device_changed.emit(true)

func _switch_to_keyboard() -> void:
	is_gamepad_connected = false
	current_controller = ControllerType.KEYBOARD
	input_device_changed.emit(false)

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

	controller_changed.emit(current_controller)

func _detect_connected_gamepads() -> void:
	var joypads = Input.get_connected_joypads()
	if not joypads.is_empty():
		_switch_to_gamepad()

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		_switch_to_gamepad()
	else:
		var joypads = Input.get_connected_joypads()
		if joypads.is_empty():
			_switch_to_keyboard()

## 버튼 아이콘 경로 반환
func get_button_icon(action: String) -> String:
	if current_controller == ControllerType.KEYBOARD:
		return ""  # 키보드는 텍스트 사용
	if button_icons.has(current_controller):
		return button_icons[current_controller].get(action, "")
	return ""

## 버튼 텍스트 반환 (키보드용)
func get_button_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return event.as_text_key_label()
	return action

## 컨트롤러 연결 여부
func is_using_gamepad() -> bool:
	return is_gamepad_connected
