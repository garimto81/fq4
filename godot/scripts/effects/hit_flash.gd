extends Node
class_name HitFlash

var target: CanvasItem = null
var original_modulate: Color
var flash_duration: float = 0.1
var flash_color: Color = Color.WHITE
var timer: float = 0.0
var is_flashing: bool = false

func setup(canvas_item: CanvasItem) -> void:
	target = canvas_item
	original_modulate = target.modulate

func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	if not AccessibilitySystem or AccessibilitySystem.can_flash():
		flash_color = color
		flash_duration = duration
		timer = 0.0
		is_flashing = true
		target.modulate = flash_color

func _process(delta: float) -> void:
	if not is_flashing:
		return

	timer += delta
	if timer >= flash_duration:
		target.modulate = original_modulate
		is_flashing = false
