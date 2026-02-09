extends Node2D

var test_sprite: Sprite2D
var current_damage_type: String = "normal"

func _ready() -> void:
	# 테스트용 스프라이트 생성 (히트 플래시 테스트용)
	test_sprite = Sprite2D.new()
	test_sprite.position = Vector2(640, 400)
	# 간단한 사각형 텍스처 생성
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	test_sprite.texture = ImageTexture.create_from_image(img)
	add_child(test_sprite)

	print("Effects Test Scene loaded")
	print("PoolManager stats: ", PoolManager.get_stats())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var amount = randi_range(10, 100)
		EffectManager.spawn_damage_popup(event.position, amount, current_damage_type)

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_damage_type = "normal"
				print("Damage type: normal")
			KEY_2:
				current_damage_type = "critical"
				print("Damage type: critical")
			KEY_3:
				current_damage_type = "heal"
				print("Damage type: heal")
			KEY_4:
				current_damage_type = "miss"
				print("Damage type: miss")
			KEY_5:
				current_damage_type = "block"
				print("Damage type: block")
			KEY_F:
				test_hit_flash()

func test_hit_flash() -> void:
	if test_sprite:
		EffectManager.spawn_hit_flash(test_sprite, Color.WHITE)
		print("Hit flash triggered")

func _process(_delta: float) -> void:
	# 풀 상태 주기적으로 출력 (디버깅용)
	if Engine.get_process_frames() % 60 == 0:
		var stats = PoolManager.get_stats()
		if stats.has("damage_popup"):
			print("Pool stats - active: ", stats["damage_popup"]["active"],
				  " pooled: ", stats["damage_popup"]["pooled"])
