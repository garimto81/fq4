extends Node2D
## PerformanceTestController: 100 유닛 성능 테스트 컨트롤러
##
## 자동 벤치마크 실행 및 수동 테스트 지원

@onready var spawner: UnitSpawner = $UnitSpawner
@onready var benchmark: Benchmark = $Benchmark
@onready var fps_label: Label = $UI/HUD/FPSPanel/FPSLabel
@onready var memory_label: Label = $UI/HUD/FPSPanel/MemoryLabel
@onready var status_label: Label = $UI/HUD/StatusPanel/StatusLabel
@onready var info_label: Label = $UI/HUD/InfoPanel/InfoLabel

# 테스트 설정
var current_unit_count: int = 0
var max_unit_count: int = 100
var auto_benchmark_mode: bool = false

# 생성된 유닛 추적
var spawned_units: Array = []

func _ready() -> void:
	_setup_ui()
	_connect_benchmark_signals()

	# GameManager 초기화
	if GameManager:
		GameManager.clear_all_units()

	print("Performance Test Ready")
	print("Press SPACE to start automatic benchmark")
	print("Press 1-9 to spawn 10-90 units manually")
	print("Press 0 to spawn 100 units")
	print("Press R to reset")

func _setup_ui() -> void:
	info_label.text = """Performance Test Controls

SPACE: Start Auto Benchmark
1-9: Spawn 10-90 units
0: Spawn 100 units
R: Reset all units
Q: Quit test

Status: Ready"""

func _connect_benchmark_signals() -> void:
	benchmark.test_started.connect(_on_test_started)
	benchmark.test_warmup_complete.connect(_on_test_warmup_complete)
	benchmark.test_complete.connect(_on_test_complete)
	benchmark.all_tests_complete.connect(_on_all_tests_complete)

func _process(_delta: float) -> void:
	_update_fps_display()
	_handle_input()

func _update_fps_display() -> void:
	var fps = Engine.get_frames_per_second()
	var memory_mb = OS.get_static_memory_usage() / 1024.0 / 1024.0

	# FPS 색상 (60+ 녹색, 30-60 노란색, 30 미만 빨간색)
	var fps_color = Color.GREEN
	if fps < 60:
		fps_color = Color.YELLOW
	if fps < 30:
		fps_color = Color.RED

	fps_label.text = "FPS: %d" % fps
	fps_label.modulate = fps_color

	# 메모리 색상 (500MB 기준)
	var memory_color = Color.GREEN
	if memory_mb > 400:
		memory_color = Color.YELLOW
	if memory_mb > 500:
		memory_color = Color.RED

	memory_label.text = "Memory: %.1f MB" % memory_mb
	memory_label.modulate = memory_color

	# Spatial hash 통계
	var spatial_cells = 0
	if GameManager and GameManager.spatial_hash:
		spatial_cells = GameManager.spatial_hash.cells.size()

	# 상태 표시
	if auto_benchmark_mode:
		var test_status = benchmark.test_state
		status_label.text = "Benchmark: %s\nUnits: %d\nTest: %d/%d\nSpatial Cells: %d" % [
			test_status,
			current_unit_count,
			benchmark.current_test_index + 1,
			benchmark.test_unit_counts.size(),
			spatial_cells
		]
	else:
		status_label.text = "Manual Mode\nUnits: %d/%d\nFPS: %d\nMemory: %.1f MB\nSpatial Cells: %d" % [
			current_unit_count,
			max_unit_count,
			fps,
			memory_mb,
			spatial_cells
		]

func _handle_input() -> void:
	# SPACE: 자동 벤치마크 시작
	if Input.is_action_just_pressed("ui_accept"):  # SPACE
		if not auto_benchmark_mode:
			_start_auto_benchmark()

	# R: 리셋
	if Input.is_key_pressed(KEY_R):
		_reset_test()

	# Q: 종료
	if Input.is_key_pressed(KEY_Q):
		if auto_benchmark_mode:
			benchmark.cancel_benchmark()
			auto_benchmark_mode = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")

	# 숫자키: 유닛 수동 스폰
	if not auto_benchmark_mode:
		for i in range(10):
			if Input.is_key_pressed(KEY_0 + i):
				var unit_count = 10 * i if i > 0 else 100
				_spawn_units_manual(unit_count)
				return

## 자동 벤치마크 시작
func _start_auto_benchmark() -> void:
	print("\nStarting automatic benchmark...")
	auto_benchmark_mode = true
	_reset_test()
	benchmark.start_benchmark()

## 수동 유닛 스폰
func _spawn_units_manual(count: int) -> void:
	_reset_test()
	_spawn_units(count)
	print("Spawned %d units manually" % count)

## 유닛 스폰 (내부)
func _spawn_units(count: int) -> void:
	current_unit_count = count
	spawned_units.clear()

	# 플레이어 진영 유닛 (파란색)
	var player_count = count / 2
	var player_start = Vector2(200, 360)
	var player_units = spawner.spawn_random_units(player_count, true, player_start)
	spawned_units.append_array(player_units)

	# 리더 설정
	if player_units.size() > 0:
		var leader = player_units[0]
		for i in range(1, player_units.size()):
			if player_units[i].has_method("set_leader"):
				player_units[i].set_leader(leader)

	# 적 진영 유닛 (빨간색)
	var enemy_count = count - player_count
	var enemy_start = Vector2(1000, 360)
	var enemy_units = spawner.spawn_random_units(enemy_count, false, enemy_start)
	spawned_units.append_array(enemy_units)

	print("Spawned %d units: %d player, %d enemy" % [count, player_count, enemy_count])

## 테스트 리셋
func _reset_test() -> void:
	# 모든 유닛 제거
	for unit in spawned_units:
		if is_instance_valid(unit):
			unit.queue_free()
	spawned_units.clear()

	# GameManager 클리어
	if GameManager:
		GameManager.clear_all_units()

	current_unit_count = 0
	print("Test reset")

## 벤치마크 시그널 핸들러
func _on_test_started(unit_count: int) -> void:
	print("Test started: %d units" % unit_count)
	_spawn_units(unit_count)

func _on_test_warmup_complete(unit_count: int) -> void:
	print("Warmup complete for %d units" % unit_count)

func _on_test_complete(unit_count: int, avg_fps: float, min_fps: float, max_fps: float) -> void:
	print("Test complete: %d units - Avg: %.1f, Min: %.1f, Max: %.1f FPS" % [
		unit_count, avg_fps, min_fps, max_fps
	])
	_reset_test()

func _on_all_tests_complete(results: Array) -> void:
	print("All benchmark tests complete!")
	auto_benchmark_mode = false

	# 최종 결과 요약
	info_label.text = """Benchmark Complete!

Check output/benchmark_results.txt
for detailed results.

Press R to reset
Press Q to quit"""
