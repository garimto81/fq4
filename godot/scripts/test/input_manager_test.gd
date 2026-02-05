extends Control
## InputManager 테스트 씬
##
## 게임패드 연결/해제 감지 및 버튼 프롬프트 테스트

@onready var controller_type_label: Label = $VBoxContainer/ControllerType
@onready var gamepad_connected_label: Label = $VBoxContainer/GamepadConnected
@onready var last_input_label: Label = $VBoxContainer/LastInput
@onready var attack_button_label: Label = $VBoxContainer/ButtonPrompts/AttackButton
@onready var confirm_button_label: Label = $VBoxContainer/ButtonPrompts/ConfirmButton
@onready var cancel_button_label: Label = $VBoxContainer/ButtonPrompts/CancelButton

func _ready() -> void:
	# InputManager 시그널 연결
	InputManager.controller_changed.connect(_on_controller_changed)
	InputManager.input_device_changed.connect(_on_input_device_changed)

	# 초기 상태 업데이트
	_update_ui()

func _input(event: InputEvent) -> void:
	# 입력 이벤트 표시
	if event is InputEventKey and event.pressed:
		last_input_label.text = "Last Input: Key (%s)" % event.as_text_key_label()
	elif event is InputEventJoypadButton and event.pressed:
		last_input_label.text = "Last Input: Button %d" % event.button_index
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.5:  # Deadzone
			last_input_label.text = "Last Input: Axis %d = %.2f" % [event.axis, event.axis_value]

func _on_controller_changed(controller_type: InputManager.ControllerType) -> void:
	_update_ui()

func _on_input_device_changed(is_gamepad: bool) -> void:
	_update_ui()

func _update_ui() -> void:
	# 컨트롤러 타입 표시
	var type_name: String
	match InputManager.current_controller:
		InputManager.ControllerType.KEYBOARD:
			type_name = "KEYBOARD"
		InputManager.ControllerType.XBOX:
			type_name = "XBOX"
		InputManager.ControllerType.PLAYSTATION:
			type_name = "PLAYSTATION"
		InputManager.ControllerType.GENERIC:
			type_name = "GENERIC"
		_:
			type_name = "UNKNOWN"

	controller_type_label.text = "Controller Type: %s" % type_name
	gamepad_connected_label.text = "Gamepad Connected: %s" % ("Yes" if InputManager.is_gamepad_connected else "No")

	# 버튼 프롬프트 업데이트
	if InputManager.is_using_gamepad():
		attack_button_label.text = "Attack: Button 0 (A/Cross)"
		confirm_button_label.text = "Confirm: Button 0 (A/Cross)"
		cancel_button_label.text = "Cancel: Button 1 (B/Circle)"
	else:
		attack_button_label.text = "Attack: %s" % InputManager.get_button_text("attack")
		confirm_button_label.text = "Confirm: %s" % InputManager.get_button_text("confirm")
		cancel_button_label.text = "Cancel: %s" % InputManager.get_button_text("cancel")
