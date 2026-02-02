extends Resource
class_name FQ4ColorPalette
"""
컬러 팔레트 리소스
16색 → 256색 확장 매핑 관리
"""

@export var name: String = ""
@export var description: String = ""
@export var original_colors: PackedColorArray = []
@export var extended_colors: PackedColorArray = []
@export var color_mapping: Dictionary = {}


func get_original_color(index: int) -> Color:
	"""원본 16색 팔레트에서 색상 가져오기"""
	if index < 0 or index >= original_colors.size():
		push_warning("Invalid color index: %d" % index)
		return Color.MAGENTA
	return original_colors[index]


func get_extended_color(index: int) -> Color:
	"""확장 256색 팔레트에서 색상 가져오기"""
	if index < 0 or index >= extended_colors.size():
		push_warning("Invalid extended color index: %d" % index)
		return Color.MAGENTA
	return extended_colors[index]


func map_color(original_index: int) -> Color:
	"""
	원본 16색 인덱스를 256색으로 매핑

	Args:
		original_index: 원본 색상 인덱스 (0-15)

	Returns:
		매핑된 256색 팔레트의 Color
	"""
	if original_index not in color_mapping:
		push_warning("No mapping for color index: %d" % original_index)
		return get_original_color(original_index)

	var extended_index: int = color_mapping[original_index]
	return get_extended_color(extended_index)


func get_gradient_colors(start_index: int, end_index: int, steps: int) -> PackedColorArray:
	"""
	두 색상 사이의 그라데이션 생성

	Args:
		start_index: 시작 색상 인덱스
		end_index: 끝 색상 인덱스
		steps: 보간 단계 수

	Returns:
		그라데이션 색상 배열
	"""
	var result: PackedColorArray = []
	var start_color := get_extended_color(start_index)
	var end_color := get_extended_color(end_index)

	for i in range(steps):
		var t := float(i) / float(steps - 1)
		result.append(start_color.lerp(end_color, t))

	return result


func find_closest_color(target: Color, use_extended: bool = true) -> int:
	"""
	가장 유사한 팔레트 색상 찾기

	Args:
		target: 찾을 색상
		use_extended: true면 256색, false면 16색

	Returns:
		가장 유사한 색상의 인덱스
	"""
	var palette := extended_colors if use_extended else original_colors
	var closest_index := 0
	var min_distance := INF

	for i in range(palette.size()):
		var dist := _color_distance(target, palette[i])
		if dist < min_distance:
			min_distance = dist
			closest_index = i

	return closest_index


func _color_distance(a: Color, b: Color) -> float:
	"""색상 간 거리 계산 (Euclidean distance)"""
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return dr * dr + dg * dg + db * db
