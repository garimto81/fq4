extends Node
## AccessibilitySystem: 접근성 기능 관리

# 색맹 모드
enum ColorBlindMode { NONE, PROTANOPIA, DEUTERANOPIA, TRITANOPIA }

# 설정
var color_blind_mode: ColorBlindMode = ColorBlindMode.NONE
var font_scale: float = 1.0  # 0.8 ~ 1.5
var high_contrast: bool = false
var screen_shake_enabled: bool = true
var flash_effects_enabled: bool = true
var subtitle_enabled: bool = true
var subtitle_background: bool = true

# 색맹 색상 팔레트 (원본 -> 변환)
var color_palettes: Dictionary = {
	ColorBlindMode.NONE: {},
	ColorBlindMode.PROTANOPIA: {
		Color.RED: Color(0.56, 0.56, 0.0),
		Color.GREEN: Color(0.68, 0.68, 0.0)
	},
	ColorBlindMode.DEUTERANOPIA: {
		Color.RED: Color(0.625, 0.375, 0.0),
		Color.GREEN: Color(0.7, 0.7, 0.0)
	},
	ColorBlindMode.TRITANOPIA: {
		Color.BLUE: Color(0.0, 0.5, 0.5),
		Color.YELLOW: Color(1.0, 0.5, 0.5)
	}
}

signal settings_changed()


func _ready() -> void:
	_load_settings()


## 색맹 모드 설정
func set_color_blind_mode(mode: ColorBlindMode) -> void:
	color_blind_mode = mode
	_apply_color_blind_shader()
	settings_changed.emit()
	_save_settings()


## 폰트 스케일 설정 (0.8 ~ 1.5)
func set_font_scale(scale: float) -> void:
	font_scale = clamp(scale, 0.8, 1.5)
	_apply_font_scale()
	settings_changed.emit()
	_save_settings()


## 고대비 모드
func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	_apply_high_contrast()
	settings_changed.emit()
	_save_settings()


## 화면 흔들림
func set_screen_shake(enabled: bool) -> void:
	screen_shake_enabled = enabled
	_save_settings()


## 플래시 효과
func set_flash_effects(enabled: bool) -> void:
	flash_effects_enabled = enabled
	_save_settings()


## 자막 설정
func set_subtitle_enabled(enabled: bool) -> void:
	subtitle_enabled = enabled
	settings_changed.emit()
	_save_settings()


## 자막 배경
func set_subtitle_background(enabled: bool) -> void:
	subtitle_background = enabled
	settings_changed.emit()
	_save_settings()


## 색상 변환 (색맹 모드 적용)
func adjust_color(original: Color) -> Color:
	if color_blind_mode == ColorBlindMode.NONE:
		return original
	var palette = color_palettes[color_blind_mode]
	for key in palette:
		if original.is_equal_approx(key):
			return palette[key]
	return original


## 화면 흔들림 허용 여부
func can_shake_screen() -> bool:
	return screen_shake_enabled


## 플래시 효과 허용 여부
func can_flash() -> bool:
	return flash_effects_enabled


## 색맹 셰이더 적용
func _apply_color_blind_shader() -> void:
	# 전역 셰이더 또는 CanvasLayer로 색맹 필터 적용
	# GraphicsManager와 연동
	if has_node("/root/GraphicsManager"):
		var gfx_manager = get_node("/root/GraphicsManager")
		if gfx_manager.has_method("set_color_blind_mode"):
			gfx_manager.set_color_blind_mode(color_blind_mode)


## 폰트 스케일 적용
func _apply_font_scale() -> void:
	# Theme 리소스의 기본 폰트 크기 조절
	# Godot 4.4의 ThemeDB를 통해 전역 테마 수정
	var default_theme = ThemeDB.get_project_theme()
	if default_theme:
		var default_font_size = 16
		var scaled_size = int(default_font_size * font_scale)
		default_theme.set_default_font_size(scaled_size)


## 고대비 적용
func _apply_high_contrast() -> void:
	# UI 테마의 대비 조절
	var default_theme = ThemeDB.get_project_theme()
	if default_theme and high_contrast:
		# 고대비 색상 설정
		default_theme.set_color("font_color", "Label", Color.WHITE)
		default_theme.set_color("font_outline_color", "Label", Color.BLACK)
		default_theme.set_constant("outline_size", "Label", 2)
	elif default_theme:
		# 기본값 복원
		default_theme.set_color("font_color", "Label", Color(0.875, 0.875, 0.875))
		default_theme.set_color("font_outline_color", "Label", Color.TRANSPARENT)
		default_theme.set_constant("outline_size", "Label", 0)


## 설정 저장
func _save_settings() -> void:
	var settings = {
		"color_blind_mode": color_blind_mode,
		"font_scale": font_scale,
		"high_contrast": high_contrast,
		"screen_shake_enabled": screen_shake_enabled,
		"flash_effects_enabled": flash_effects_enabled,
		"subtitle_enabled": subtitle_enabled,
		"subtitle_background": subtitle_background
	}
	if has_node("/root/SaveSystem"):
		SaveSystem.save_data("accessibility_settings", settings)


## 설정 로드
func _load_settings() -> void:
	if not has_node("/root/SaveSystem"):
		return

	var settings = SaveSystem.load_data("accessibility_settings")
	if settings.is_empty():
		return

	color_blind_mode = settings.get("color_blind_mode", ColorBlindMode.NONE)
	font_scale = settings.get("font_scale", 1.0)
	high_contrast = settings.get("high_contrast", false)
	screen_shake_enabled = settings.get("screen_shake_enabled", true)
	flash_effects_enabled = settings.get("flash_effects_enabled", true)
	subtitle_enabled = settings.get("subtitle_enabled", true)
	subtitle_background = settings.get("subtitle_background", true)

	# 설정 적용
	_apply_color_blind_shader()
	_apply_font_scale()
	_apply_high_contrast()
