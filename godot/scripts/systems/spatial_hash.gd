extends RefCounted
class_name SpatialHash
## 공간 분할 해시맵
## 100 유닛 이상 성능 목표를 위한 효율적인 공간 쿼리 시스템

var cell_size: float = 100.0
var cells: Dictionary = {}  # Vector2i -> Array[Node]

func clear() -> void:
	cells.clear()

func insert(obj: Node, position: Vector2) -> void:
	var cell_key = _get_cell_key(position)
	if not cells.has(cell_key):
		cells[cell_key] = []
	cells[cell_key].append(obj)

func remove(obj: Node, position: Vector2) -> void:
	var cell_key = _get_cell_key(position)
	if cells.has(cell_key):
		cells[cell_key].erase(obj)

func update(obj: Node, old_pos: Vector2, new_pos: Vector2) -> void:
	var old_key = _get_cell_key(old_pos)
	var new_key = _get_cell_key(new_pos)
	if old_key != new_key:
		remove(obj, old_pos)
		insert(obj, new_pos)

func query_range(center: Vector2, radius: float) -> Array:
	var result: Array = []
	var min_cell = _get_cell_key(center - Vector2(radius, radius))
	var max_cell = _get_cell_key(center + Vector2(radius, radius))

	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell_key = Vector2i(x, y)
			if cells.has(cell_key):
				for obj in cells[cell_key]:
					if is_instance_valid(obj):
						var dist = center.distance_to(obj.global_position)
						if dist <= radius:
							result.append(obj)
	return result

func query_nearest(center: Vector2, radius: float, filter: Callable = Callable()) -> Node:
	var candidates = query_range(center, radius)
	var nearest = null
	var nearest_dist = radius
	for obj in candidates:
		if filter.is_valid() and not filter.call(obj):
			continue
		var dist = center.distance_to(obj.global_position)
		if dist < nearest_dist:
			nearest = obj
			nearest_dist = dist
	return nearest

func _get_cell_key(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x / cell_size), int(position.y / cell_size))
