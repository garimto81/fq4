extends Node2D
class_name DamagePopup

@onready var label: Label = $Label

var velocity: Vector2 = Vector2(0, -50)
var lifetime: float = 1.0
var timer: float = 0.0

func _ready() -> void:
	timer = 0.0

func setup(amount: int, damage_type: String = "normal") -> void:
	label.text = str(amount)

	match damage_type:
		"normal":
			label.modulate = Color.WHITE
		"critical":
			label.text = str(amount) + "!"
			label.modulate = Color.YELLOW
			scale = Vector2(1.5, 1.5)
		"heal":
			label.text = "+" + str(amount)
			label.modulate = Color.GREEN
		"miss":
			label.text = "MISS"
			label.modulate = Color.GRAY
		"block":
			label.text = "BLOCK"
			label.modulate = Color.LIGHT_BLUE

func _process(delta: float) -> void:
	timer += delta
	position += velocity * delta
	velocity.y += 50 * delta  # 약간의 중력

	# 페이드 아웃
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = alpha

	if timer >= lifetime:
		# 풀로 반환
		PoolManager.release("damage_popup", self)
