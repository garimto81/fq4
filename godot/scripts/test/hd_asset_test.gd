extends Node2D
"""HD 에셋 렌더링 테스트 씬"""

@onready var background: TextureRect = $Background
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mode_label: Label = $UI/ModeLabel
@onready var fps_label: Label = $UI/FPSLabel

var hd_backgrounds := [
	"res://assets/images/hd/FQ4GLOGO_ai4x.png",
	"res://assets/images/hd/FQOP_01_ai4x.png",
	"res://assets/images/hd/FQOP_02_ai4x.png",
]
var current_bg_index := 0

func _ready():
	# 기본 HD_REMASTERED 모드
	GraphicsManager.apply_graphics_mode(GraphicsManager.GraphicsMode.HD_REMASTERED)
	_update_mode_label()
	_load_background()

	# 스프라이트 애니메이션 시작
	if sprite.sprite_frames:
		sprite.play("walk_down")

func _process(_delta):
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _load_background():
	var tex = load(hd_backgrounds[current_bg_index])
	if tex:
		background.texture = tex

func _update_mode_label():
	var mode_name := ""
	match GraphicsManager.current_mode:
		GraphicsManager.GraphicsMode.CLASSIC:
			mode_name = "CLASSIC"
		GraphicsManager.GraphicsMode.ENHANCED:
			mode_name = "ENHANCED"
		GraphicsManager.GraphicsMode.HD_REMASTERED:
			mode_name = "HD_REMASTERED"
	mode_label.text = "Mode: " + mode_name

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# 모드 순환
		var next_mode = (GraphicsManager.current_mode + 1) % 3
		GraphicsManager.apply_graphics_mode(next_mode)
		_update_mode_label()
	elif event.is_action_pressed("ui_right"):
		# 다음 배경
		current_bg_index = (current_bg_index + 1) % hd_backgrounds.size()
		_load_background()
	elif event.is_action_pressed("ui_left"):
		# 이전 배경
		current_bg_index = (current_bg_index - 1 + hd_backgrounds.size()) % hd_backgrounds.size()
		_load_background()

func _on_mode_button_pressed(mode: int):
	GraphicsManager.apply_graphics_mode(mode)
	_update_mode_label()
