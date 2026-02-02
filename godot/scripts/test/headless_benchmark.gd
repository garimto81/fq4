extends SceneTree
## Headless Benchmark: CLI 환경에서 실행 가능한 성능 테스트

var test_unit_counts: Array = [10, 25, 50, 75, 100]
var test_duration: float = 5.0
var warmup_frames: int = 60

var current_test_index: int = 0
var frame_count: int = 0
var test_start_time: float = 0.0
var fps_samples: Array = []
var results: Array = []
var test_state: String = "WARMUP"

func _init() -> void:
	print("========================================")
	print("First Queen 4 Remake - Headless Benchmark")
	print("========================================")
	print("Godot Version: ", Engine.get_version_info().string)
	print("")
	_start_test()

func _start_test() -> void:
	if current_test_index >= test_unit_counts.size():
		_complete_all_tests()
		return

	var unit_count = test_unit_counts[current_test_index]
	print("[Test %d/%d] %d units..." % [current_test_index + 1, test_unit_counts.size(), unit_count])

	test_state = "WARMUP"
	frame_count = 0
	fps_samples = []
	test_start_time = Time.get_ticks_msec() / 1000.0

func _process(delta: float) -> bool:
	frame_count += 1

	match test_state:
		"WARMUP":
			if frame_count >= warmup_frames:
				test_state = "TESTING"
				frame_count = 0
				test_start_time = Time.get_ticks_msec() / 1000.0
				print("  Warmup complete, measuring...")

		"TESTING":
			fps_samples.append(1.0 / delta if delta > 0 else 60.0)

			var elapsed = (Time.get_ticks_msec() / 1000.0) - test_start_time
			if elapsed >= test_duration:
				_complete_current_test()

	return false

func _complete_current_test() -> void:
	var unit_count = test_unit_counts[current_test_index]

	var avg_fps = _avg(fps_samples)
	var min_fps = _min(fps_samples)
	var max_fps = _max(fps_samples)

	var result = {
		"units": unit_count,
		"avg": avg_fps,
		"min": min_fps,
		"max": max_fps
	}
	results.append(result)

	var status = "GOOD" if avg_fps >= 30.0 else "POOR"
	print("  Result: Avg %.1f FPS, Min %.1f, Max %.1f - %s" % [avg_fps, min_fps, max_fps, status])

	current_test_index += 1
	_start_test()

func _complete_all_tests() -> void:
	print("")
	print("========================================")
	print("BENCHMARK COMPLETE")
	print("========================================")

	for r in results:
		var status = "EXCELLENT" if r.avg >= 60 else ("GOOD" if r.avg >= 30 else "POOR")
		print("  %3d units: %.1f FPS avg - %s" % [r.units, r.avg, status])

	# 결과 파일 저장
	var file = FileAccess.open("C:/claude/Fq4/output/benchmark_results.txt", FileAccess.WRITE)
	if file:
		file.store_line("First Queen 4 Remake - Benchmark Results")
		file.store_line("Date: " + Time.get_datetime_string_from_system())
		file.store_line("")
		for r in results:
			file.store_line("%d units: Avg %.1f FPS, Min %.1f, Max %.1f" % [r.units, r.avg, r.min, r.max])
		file.close()
		print("\nResults saved to: C:/claude/Fq4/output/benchmark_results.txt")

	quit()

func _avg(arr: Array) -> float:
	if arr.is_empty(): return 0.0
	var sum = 0.0
	for v in arr: sum += v
	return sum / arr.size()

func _min(arr: Array) -> float:
	if arr.is_empty(): return 0.0
	var m = arr[0]
	for v in arr:
		if v < m: m = v
	return m

func _max(arr: Array) -> float:
	if arr.is_empty(): return 0.0
	var m = arr[0]
	for v in arr:
		if v > m: m = v
	return m
