extends Node
## 전역 오브젝트 풀 관리자
## 게임 전역에서 사용하는 오브젝트 풀을 중앙 관리

var pools: Dictionary = {}  # pool_name -> ObjectPool

func register_pool(pool_name: String, scene: PackedScene, initial_size: int = 10) -> void:
	if not pools.has(pool_name):
		pools[pool_name] = ObjectPool.new(scene, initial_size, self)

func acquire(pool_name: String) -> Node:
	if pools.has(pool_name):
		return pools[pool_name].acquire()
	return null

func release(pool_name: String, obj: Node) -> void:
	if pools.has(pool_name):
		pools[pool_name].release(obj)

func get_stats() -> Dictionary:
	var stats = {}
	for name in pools:
		stats[name] = {
			"active": pools[name].get_active_count(),
			"pooled": pools[name].get_pool_size()
		}
	return stats
