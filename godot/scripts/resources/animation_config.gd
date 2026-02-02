extends Resource
class_name AnimationConfig
"""
애니메이션 설정 리소스
스프라이트 시트 프레임 및 FPS 정의
"""

@export var character_animations: Dictionary = {}
@export var effect_animations: Dictionary = {}
@export var direction_layout: Dictionary = {}
@export var animation_priority: Dictionary = {}


func get_animation_data(anim_name: String, is_character: bool = true) -> Dictionary:
	"""
	애니메이션 데이터 가져오기

	Args:
		anim_name: 애니메이션 이름
		is_character: true면 캐릭터, false면 이펙트

	Returns:
		애니메이션 설정 딕셔너리 { frames, fps, loop, frame_size }
	"""
	var animations := character_animations if is_character else effect_animations

	if anim_name not in animations:
		push_warning("Animation '%s' not found" % anim_name)
		return {
			"frames": 1,
			"fps": 10,
			"loop": false,
			"frame_size": Vector2i(32, 32)
		}

	return animations[anim_name]


func get_direction_row(direction: String) -> int:
	"""
	방향에 해당하는 스프라이트 시트 row 가져오기

	Args:
		direction: 방향 문자열 (down, up, left, right, 등)

	Returns:
		Row 인덱스
	"""
	if direction not in direction_layout:
		push_warning("Direction '%s' not found" % direction)
		return 0

	return direction_layout[direction]


func get_animation_priority(anim_name: String) -> int:
	"""
	애니메이션 우선순위 가져오기

	Args:
		anim_name: 애니메이션 이름

	Returns:
		우선순위 값 (높을수록 우선)
	"""
	if anim_name not in animation_priority:
		return 0

	return animation_priority[anim_name]


func can_interrupt(current_anim: String, new_anim: String) -> bool:
	"""
	현재 애니메이션을 새 애니메이션으로 중단할 수 있는지 확인

	Args:
		current_anim: 현재 재생 중인 애니메이션
		new_anim: 재생하려는 새 애니메이션

	Returns:
		중단 가능 여부
	"""
	var current_priority := get_animation_priority(current_anim)
	var new_priority := get_animation_priority(new_anim)

	return new_priority >= current_priority


func get_frame_region(anim_name: String, frame: int, direction_row: int = 0) -> Rect2i:
	"""
	특정 프레임의 스프라이트 시트 영역 계산

	Args:
		anim_name: 애니메이션 이름
		frame: 프레임 번호 (0부터 시작)
		direction_row: 방향 row (8방향 시트의 경우)

	Returns:
		스프라이트 시트 내 영역 (픽셀 좌표)
	"""
	var anim_data := get_animation_data(anim_name, true)
	var frame_size: Vector2i = anim_data.get("frame_size", Vector2i(32, 32))

	var x := frame * frame_size.x
	var y := direction_row * frame_size.y

	return Rect2i(x, y, frame_size.x, frame_size.y)
