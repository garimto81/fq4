extends Node
class_name Benchmark
## Benchmark: 성능 측정 유틸리티
##
## 유닛 수별 FPS 측정 및 결과 저장

# 벤치마크 설정
var test_unit_counts: Array[int] = [10, 25, 50, 75, 100]
var test_duration: float = 10.0  # 각 테스트당 10초
var warmup_time: float = 2.0     # 워밍업 2초

# 측정 데이터
var current_test_index: int = 0
var current_test_time: float = 0.0
var test_state: String = "IDLE"  # IDLE, WARMUP, TESTING, COMPLETE

var fps_samples: Array[float] = []
var memory_samples: Array[float] = []

# 결과 저장
var results: Array[Dictionary] = []

signal test_started(unit_count: int)
signal test_warmup_complete(unit_count: int)
signal test_complete(unit_count: int, avg_fps: float, min_fps: float, max_fps: float)
signal all_tests_complete(results: Array)

func _ready() -> void:
	pass

## 벤치마크 시작
func start_benchmark() -> void:
	print("========================================")
	print("First Queen 4 Remake - Performance Benchmark")
	print("========================================")
	results.clear()
	current_test_index = 0
	_start_next_test()

## 다음 테스트 시작
func _start_next_test() -> void:
	if current_test_index >= test_unit_counts.size():
		_complete_all_tests()
		return

	var unit_count = test_unit_counts[current_test_index]
	print("\n[Test %d/%d] Starting test with %d units..." % [current_test_index + 1, test_unit_counts.size(), unit_count])

	test_state = "WARMUP"
	current_test_time = 0.0
	fps_samples.clear()
	memory_samples.clear()

	test_started.emit(unit_count)

## 프레임마다 호출
func _process(delta: float) -> void:
	if test_state == "IDLE" or test_state == "COMPLETE":
		return

	current_test_time += delta

	match test_state:
		"WARMUP":
			if current_test_time >= warmup_time:
				print("  Warmup complete. Starting measurement...")
				test_state = "TESTING"
				current_test_time = 0.0
				var unit_count = test_unit_counts[current_test_index]
				test_warmup_complete.emit(unit_count)

		"TESTING":
			# FPS 샘플 수집
			var current_fps = Engine.get_frames_per_second()
			fps_samples.append(current_fps)

			# 메모리 샘플 수집
			var memory_mb = OS.get_static_memory_usage() / 1024.0 / 1024.0
			memory_samples.append(memory_mb)

			# 테스트 완료
			if current_test_time >= test_duration:
				_complete_current_test()

## 현재 테스트 완료
func _complete_current_test() -> void:
	var unit_count = test_unit_counts[current_test_index]

	# FPS 통계 계산
	var avg_fps = _calculate_average(fps_samples)
	var min_fps = _calculate_min(fps_samples)
	var max_fps = _calculate_max(fps_samples)

	# 메모리 통계 계산
	var avg_memory = _calculate_average(memory_samples)
	var max_memory = _calculate_max(memory_samples)

	# 결과 저장
	var result = {
		"unit_count": unit_count,
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"avg_memory_mb": avg_memory,
		"max_memory_mb": max_memory,
		"samples": fps_samples.size()
	}
	results.append(result)

	# 결과 출력
	print("  Test complete:")
	print("    FPS - Avg: %.1f, Min: %.1f, Max: %.1f" % [avg_fps, min_fps, max_fps])
	print("    Memory - Avg: %.1f MB, Max: %.1f MB" % [avg_memory, max_memory])

	# 목표 달성 여부
	var status = _get_performance_status(avg_fps, min_fps)
	print("    Status: %s" % status)

	test_complete.emit(unit_count, avg_fps, min_fps, max_fps)

	# 다음 테스트로
	current_test_index += 1
	test_state = "IDLE"

	# 잠시 대기 후 다음 테스트
	await get_tree().create_timer(1.0).timeout
	_start_next_test()

## 모든 테스트 완료
func _complete_all_tests() -> void:
	test_state = "COMPLETE"

	print("\n========================================")
	print("Benchmark Complete!")
	print("========================================")
	print("\nSummary:")

	for result in results:
		var status = _get_performance_status(result.avg_fps, result.min_fps)
		print("  %3d units: Avg %.1f FPS, Min %.1f FPS - %s" % [
			result.unit_count,
			result.avg_fps,
			result.min_fps,
			status
		])

	# 파일로 저장
	_save_results_to_file()

	all_tests_complete.emit(results)

## 성능 상태 판정
func _get_performance_status(avg_fps: float, min_fps: float) -> String:
	if avg_fps >= 60.0 and min_fps >= 50.0:
		return "EXCELLENT (60 FPS target)"
	elif avg_fps >= 30.0 and min_fps >= 25.0:
		return "GOOD (30 FPS target)"
	elif avg_fps >= 30.0:
		return "ACCEPTABLE (unstable)"
	else:
		return "POOR (optimization needed)"

## 결과를 파일로 저장
func _save_results_to_file() -> void:
	var output_path = "C:/claude/Fq4/output/benchmark_results.txt"
	var file = FileAccess.open(output_path, FileAccess.WRITE)

	if not file:
		print("Failed to save results to file: ", output_path)
		return

	file.store_line("========================================")
	file.store_line("First Queen 4 Remake - Performance Benchmark")
	file.store_line("========================================")
	file.store_line("Date: " + Time.get_datetime_string_from_system())
	file.store_line("")
	file.store_line("System Information:")
	file.store_line("  OS: " + OS.get_name())
	file.store_line("  Processor: " + str(OS.get_processor_count()) + " cores")
	file.store_line("  GPU: " + RenderingServer.get_video_adapter_name())
	file.store_line("")
	file.store_line("Test Settings:")
	file.store_line("  Test Duration: %.1f seconds" % test_duration)
	file.store_line("  Warmup Time: %.1f seconds" % warmup_time)
	file.store_line("")
	file.store_line("Results:")
	file.store_line("--------")

	for result in results:
		var status = _get_performance_status(result.avg_fps, result.min_fps)
		file.store_line("")
		file.store_line("Units: %d" % result.unit_count)
		file.store_line("  FPS - Avg: %.1f, Min: %.1f, Max: %.1f" % [result.avg_fps, result.min_fps, result.max_fps])
		file.store_line("  Memory - Avg: %.1f MB, Max: %.1f MB" % [result.avg_memory_mb, result.max_memory_mb])
		file.store_line("  Samples: %d" % result.samples)
		file.store_line("  Status: %s" % status)

	file.store_line("")
	file.store_line("========================================")
	file.store_line("Performance Goals:")
	file.store_line("  Recommended: 100 units @ 60 FPS")
	file.store_line("  Minimum: 100 units @ 30 FPS")
	file.store_line("  Memory: < 500 MB")
	file.store_line("========================================")

	file.close()
	print("\nResults saved to: ", output_path)

## 평균 계산
func _calculate_average(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var sum = 0.0
	for value in samples:
		sum += value
	return sum / float(samples.size())

## 최소값 계산
func _calculate_min(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var min_value = samples[0]
	for value in samples:
		if value < min_value:
			min_value = value
	return min_value

## 최대값 계산
func _calculate_max(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var max_value = samples[0]
	for value in samples:
		if value > max_value:
			max_value = value
	return max_value

## 테스트 취소
func cancel_benchmark() -> void:
	test_state = "IDLE"
	print("\nBenchmark cancelled.")
