extends Node
## Spatial Hash 단위 테스트

func _ready() -> void:
	print("=== Spatial Hash Test ===")
	test_basic_operations()
	test_range_query()
	test_nearest_query()
	test_update()
	print("=== All Tests Passed ===")

func test_basic_operations() -> void:
	print("\n[Test] Basic Operations")
	var hash = SpatialHash.new()
	hash.cell_size = 100.0

	var node1 = Node2D.new()
	node1.global_position = Vector2(50, 50)

	var node2 = Node2D.new()
	node2.global_position = Vector2(150, 150)

	# Insert
	hash.insert(node1, node1.global_position)
	hash.insert(node2, node2.global_position)
	assert(hash.cells.size() > 0, "Cells should have entries")

	# Remove
	hash.remove(node1, node1.global_position)
	var result = hash.query_range(Vector2(50, 50), 10.0)
	assert(node1 not in result, "Node1 should be removed")

	node1.free()
	node2.free()
	print("  ✓ Insert/Remove OK")

func test_range_query() -> void:
	print("\n[Test] Range Query")
	var hash = SpatialHash.new()
	hash.cell_size = 100.0

	var nodes = []
	for i in range(10):
		var node = Node2D.new()
		node.global_position = Vector2(i * 50, 0)
		hash.insert(node, node.global_position)
		nodes.append(node)

	# Query within 150 units from origin
	var result = hash.query_range(Vector2(0, 0), 150.0)
	assert(result.size() <= 4, "Should find nearby nodes only")

	for node in nodes:
		node.free()
	print("  ✓ Range Query OK")

func test_nearest_query() -> void:
	print("\n[Test] Nearest Query")
	var hash = SpatialHash.new()
	hash.cell_size = 100.0

	var node1 = Node2D.new()
	node1.global_position = Vector2(100, 0)
	hash.insert(node1, node1.global_position)

	var node2 = Node2D.new()
	node2.global_position = Vector2(300, 0)
	hash.insert(node2, node2.global_position)

	# Find nearest to origin
	var nearest = hash.query_nearest(Vector2(0, 0), 500.0)
	assert(nearest == node1, "Should find node1 as nearest")

	node1.free()
	node2.free()
	print("  ✓ Nearest Query OK")

func test_update() -> void:
	print("\n[Test] Update")
	var hash = SpatialHash.new()
	hash.cell_size = 100.0

	var node = Node2D.new()
	var old_pos = Vector2(50, 50)
	var new_pos = Vector2(250, 250)

	node.global_position = old_pos
	hash.insert(node, old_pos)

	# Move node
	node.global_position = new_pos
	hash.update(node, old_pos, new_pos)

	# Should find in new cell
	var result = hash.query_range(new_pos, 50.0)
	assert(node in result, "Should find node in new position")

	# Should not find in old cell
	var old_result = hash.query_range(old_pos, 50.0)
	assert(node not in old_result, "Should not find node in old position")

	node.free()
	print("  ✓ Update OK")
