extends RefCounted
class_name ObjectPool
## 오브젝트 풀링 시스템
## 이펙트, 프로젝타일 등 반복 생성되는 오브젝트의 메모리 할당 최적화

var scene: PackedScene
var pool: Array[Node] = []
var active: Array[Node] = []
var parent_node: Node = null

func _init(packed_scene: PackedScene, initial_size: int = 10, parent: Node = null) -> void:
	scene = packed_scene
	parent_node = parent
	_warm_up(initial_size)

func _warm_up(count: int) -> void:
	for i in range(count):
		var obj = scene.instantiate()
		obj.set_process(false)
		obj.visible = false
		if parent_node:
			parent_node.add_child(obj)
		pool.append(obj)

func acquire() -> Node:
	var obj: Node
	if pool.is_empty():
		obj = scene.instantiate()
		if parent_node:
			parent_node.add_child(obj)
	else:
		obj = pool.pop_back()

	obj.set_process(true)
	obj.visible = true
	active.append(obj)
	return obj

func release(obj: Node) -> void:
	if obj in active:
		active.erase(obj)
		obj.set_process(false)
		obj.visible = false
		pool.append(obj)

func release_all() -> void:
	for obj in active.duplicate():
		release(obj)

func get_active_count() -> int:
	return active.size()

func get_pool_size() -> int:
	return pool.size()
