extends Node
"""
그래픽 관리자 (AutoLoad)
Enhanced/Classic 그래픽 모드 전환 및 효과 관리
"""

enum GraphicsMode {
	CLASSIC,      # 원본 320x200, 16색, CRT 효과
	ENHANCED,     # 1280x800, 256색, 파티클 효과
	HD_REMASTERED # 1280x800, AI 업스케일 에셋 사용
}

# HD 에셋 경로
const HD_SPRITES_PATH = "res://assets/sprites/"
const HD_IMAGES_PATH = "res://assets/images/hd/"
const HD_FONTS_PATH = "res://assets/fonts/hd/"

# 현재 그래픽 모드
var current_mode: GraphicsMode = GraphicsMode.ENHANCED

# HD 에셋 사용 여부
var use_hd_assets: bool = false

# 리소스 참조 (타입 어노테이션 제거 - Autoload 로드 순서 이슈)
var enhanced_palette = null  # FQ4ColorPalette
var animation_config = null  # AnimationConfig

# 셰이더 머티리얼
var crt_material: ShaderMaterial = null
var pixelate_material: ShaderMaterial = null
var outline_material: ShaderMaterial = null

# 파티클 씬
var hit_particle_scene: PackedScene = null
var magic_particle_scene: PackedScene = null
var level_up_particle_scene: PackedScene = null
var death_particle_scene: PackedScene = null


func _ready():
	_load_resources()
	_setup_shaders()
	apply_graphics_mode(current_mode)


func _load_resources():
	"""리소스 로드"""
	# 팔레트
	enhanced_palette = load("res://resources/palettes/enhanced_palette.tres")
	if not enhanced_palette:
		push_error("Failed to load enhanced_palette.tres")

	# 애니메이션 설정
	animation_config = load("res://resources/animation_config.tres")
	if not animation_config:
		push_error("Failed to load animation_config.tres")

	# 파티클 씬
	hit_particle_scene = load("res://scenes/effects/hit_particle.tscn")
	magic_particle_scene = load("res://scenes/effects/magic_particle.tscn")
	level_up_particle_scene = load("res://scenes/effects/level_up_particle.tscn")
	death_particle_scene = load("res://scenes/effects/death_particle.tscn")


func _setup_shaders():
	"""셰이더 머티리얼 초기화"""
	# CRT 효과
	var crt_shader := load("res://shaders/crt_filter.gdshader") as Shader
	if crt_shader:
		crt_material = ShaderMaterial.new()
		crt_material.shader = crt_shader
		crt_material.set_shader_parameter("scan_line_intensity", 0.3)
		crt_material.set_shader_parameter("curvature", 0.03)

	# 픽셀화 효과
	var pixelate_shader := load("res://shaders/pixelate.gdshader") as Shader
	if pixelate_shader:
		pixelate_material = ShaderMaterial.new()
		pixelate_material.shader = pixelate_shader
		pixelate_material.set_shader_parameter("pixel_size", 4.0)

	# 외곽선 효과
	var outline_shader := load("res://shaders/outline.gdshader") as Shader
	if outline_shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = outline_shader
		outline_material.set_shader_parameter("outline_thickness", 1.5)
		outline_material.set_shader_parameter("outline_color", Color.BLACK)


func apply_graphics_mode(mode: GraphicsMode):
	"""
	그래픽 모드 적용

	Args:
		mode: CLASSIC 또는 ENHANCED
	"""
	current_mode = mode

	match mode:
		GraphicsMode.CLASSIC:
			_apply_classic_mode()
		GraphicsMode.ENHANCED:
			_apply_enhanced_mode()
		GraphicsMode.HD_REMASTERED:
			_apply_hd_remastered_mode()

	var mode_name := ""
	match mode:
		GraphicsMode.CLASSIC:
			mode_name = "CLASSIC"
		GraphicsMode.ENHANCED:
			mode_name = "ENHANCED"
		GraphicsMode.HD_REMASTERED:
			mode_name = "HD_REMASTERED"

	print("Graphics mode: %s" % mode_name)


func _apply_classic_mode():
	"""클래식 모드 적용"""
	# 해상도 변경 (320x200 → 1280x800 스케일)
	get_window().size = Vector2i(1280, 800)
	get_tree().root.content_scale_factor = 4.0

	# CRT 효과 활성화
	if crt_material:
		_apply_screen_shader(crt_material)

	# 파티클 비활성화
	_set_particles_enabled(false)


func _apply_enhanced_mode():
	"""Enhanced 모드 적용"""
	# 해상도 설정
	get_window().size = Vector2i(1280, 800)
	get_tree().root.content_scale_factor = 1.0

	# 셰이더 제거
	_remove_screen_shader()

	# 파티클 활성화
	_set_particles_enabled(true)

	# HD 에셋 비활성화
	use_hd_assets = false


func _apply_hd_remastered_mode():
	"""HD Remastered 모드 적용"""
	# 해상도 설정
	get_window().size = Vector2i(1280, 800)
	get_tree().root.content_scale_factor = 1.0

	# 셰이더 제거
	_remove_screen_shader()

	# 파티클 활성화
	_set_particles_enabled(true)

	# HD 에셋 활성화
	use_hd_assets = true


func _apply_screen_shader(material: ShaderMaterial):
	"""화면 전체에 셰이더 적용"""
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "ScreenShader"

	var color_rect := ColorRect.new()
	color_rect.material = material
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0

	canvas_layer.add_child(color_rect)
	get_tree().root.add_child(canvas_layer)


func _remove_screen_shader():
	"""화면 셰이더 제거"""
	var shader_layer := get_tree().root.get_node_or_null("ScreenShader")
	if shader_layer:
		shader_layer.queue_free()


func _set_particles_enabled(enabled: bool):
	"""
	모든 파티클 효과 활성화/비활성화

	Args:
		enabled: true면 활성화
	"""
	get_tree().call_group("particles", "set_emitting", enabled)


func get_sprite_path(base_name: String) -> String:
	"""
	스프라이트 경로 가져오기

	Args:
		base_name: 베이스 파일 이름 (확장자 제외)

	Returns:
		HD 모드일 때 hd/ 폴더의 _ai4x.png, 아니면 기존 경로
	"""
	if use_hd_assets:
		return HD_SPRITES_PATH + "hd/" + base_name + "_ai4x.png"
	else:
		return HD_SPRITES_PATH + base_name + ".png"


func toggle_graphics_mode():
	"""그래픽 모드 토글 (Classic ↔ Enhanced)"""
	if current_mode == GraphicsMode.CLASSIC:
		apply_graphics_mode(GraphicsMode.ENHANCED)
	else:
		apply_graphics_mode(GraphicsMode.CLASSIC)


func spawn_particle(type: String, position: Vector2, parent: Node2D = null) -> Node:
	"""
	파티클 효과 생성

	Args:
		type: 파티클 타입 (hit, magic, level_up, death)
		position: 생성 위치
		parent: 부모 노드 (null이면 현재 씬의 루트)

	Returns:
		생성된 파티클 노드
	"""
	if current_mode == GraphicsMode.CLASSIC:
		return null  # 클래식 모드에서는 파티클 비활성화

	# HD_REMASTERED 모드는 파티클 활성화

	var scene: PackedScene = null
	match type:
		"hit":
			scene = hit_particle_scene
		"magic":
			scene = magic_particle_scene
		"level_up":
			scene = level_up_particle_scene
		"death":
			scene = death_particle_scene
		_:
			push_warning("Unknown particle type: %s" % type)
			return null

	if not scene:
		return null

	var particle := scene.instantiate()
	particle.position = position

	if not parent:
		parent = get_tree().current_scene

	parent.add_child(particle)

	# 파티클이 끝나면 자동 제거
	if particle.has_signal("finished"):
		particle.finished.connect(particle.queue_free)
	else:
		# CPUParticles2D의 경우 lifetime 후 제거
		if particle is CPUParticles2D:
			var timer := Timer.new()
			timer.wait_time = particle.lifetime + 0.1
			timer.one_shot = true
			timer.timeout.connect(particle.queue_free)
			particle.add_child(timer)
			timer.start()

	return particle


func get_sprite_material(enable_outline: bool = false) -> ShaderMaterial:
	"""
	스프라이트용 머티리얼 가져오기

	Args:
		enable_outline: 외곽선 효과 활성화

	Returns:
		ShaderMaterial 또는 null
	"""
	if current_mode == GraphicsMode.ENHANCED and enable_outline:
		return outline_material
	return null


func set_crt_intensity(intensity: float):
	"""
	CRT 효과 강도 설정

	Args:
		intensity: 0.0 ~ 1.0
	"""
	if crt_material:
		crt_material.set_shader_parameter("scan_line_intensity", intensity * 0.5)


func set_pixelate_size(size: float):
	"""
	픽셀화 크기 설정

	Args:
		size: 1.0 ~ 32.0
	"""
	if pixelate_material:
		pixelate_material.set_shader_parameter("pixel_size", size)
