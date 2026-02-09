extends Node2D
class_name SelectionIndicator

@export var base_scale: float = 1.0
@export var pulse_amount: float = 0.1
@export var pulse_speed: float = 3.0

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	var pulse = sin(time * pulse_speed) * pulse_amount
	scale = Vector2.ONE * (base_scale + pulse)
