extends Control
"""
Graphics Settings UI
그래픽 모드 선택 및 CRT 강도 조절 UI
"""

@onready var mode_option: OptionButton = $VBoxContainer/ModeOption
@onready var crt_slider: HSlider = $VBoxContainer/CRTContainer/CRTSlider
@onready var crt_container: HBoxContainer = $VBoxContainer/CRTContainer
@onready var close_button: Button = $VBoxContainer/CloseButton


func _ready():
	# 모드 옵션 설정
	mode_option.clear()
	mode_option.add_item("CLASSIC", GraphicsManager.GraphicsMode.CLASSIC)
	mode_option.add_item("ENHANCED", GraphicsManager.GraphicsMode.ENHANCED)
	mode_option.add_item("HD REMASTERED", GraphicsManager.GraphicsMode.HD_REMASTERED)

	# 현재 모드 선택
	mode_option.selected = GraphicsManager.current_mode

	# CRT 슬라이더 초기값 (0.0 ~ 1.0)
	crt_slider.min_value = 0.0
	crt_slider.max_value = 1.0
	crt_slider.step = 0.05
	crt_slider.value = 0.3  # 기본값

	# CRT 슬라이더는 CLASSIC 모드에서만 표시
	_update_crt_visibility()

	# 시그널 연결
	mode_option.item_selected.connect(_on_mode_selected)
	crt_slider.value_changed.connect(_on_crt_changed)
	close_button.pressed.connect(_on_close_pressed)


func _on_mode_selected(index: int):
	"""그래픽 모드 변경"""
	GraphicsManager.apply_graphics_mode(index as GraphicsManager.GraphicsMode)
	_update_crt_visibility()


func _on_crt_changed(value: float):
	"""CRT 강도 변경"""
	GraphicsManager.set_crt_intensity(value)


func _update_crt_visibility():
	"""CRT 슬라이더 가시성 업데이트"""
	crt_container.visible = (GraphicsManager.current_mode == GraphicsManager.GraphicsMode.CLASSIC)


func _on_close_pressed():
	"""닫기 버튼"""
	hide()
