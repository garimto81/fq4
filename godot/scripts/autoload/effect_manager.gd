extends Node

const DAMAGE_POPUP_SCENE = preload("res://scenes/effects/damage_popup.tscn")

func _ready() -> void:
	PoolManager.register_pool("damage_popup", DAMAGE_POPUP_SCENE, 20)

func spawn_damage_popup(position: Vector2, amount: int, type: String = "normal") -> void:
	var popup = PoolManager.acquire("damage_popup")
	if popup:
		popup.global_position = position + Vector2(randf_range(-10, 10), -20)
		popup.setup(amount, type)

func spawn_hit_flash(target: CanvasItem, color: Color = Color.WHITE) -> void:
	# 타겟에 HitFlash 컴포넌트 추가 또는 재사용
	var flash = target.get_node_or_null("HitFlash")
	if not flash:
		flash = HitFlash.new()
		flash.name = "HitFlash"
		target.add_child(flash)
		flash.setup(target)
	flash.flash(color)
