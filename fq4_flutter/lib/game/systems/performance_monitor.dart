/// 실시간 성능 모니터
class PerformanceMonitor {
  // FPS tracking
  final List<double> _frameTimes = [];
  double _fpsTimer = 0;
  double _currentFps = 60;
  double _minFps = 60;
  double _avgFps = 60;

  // AI tick tracking
  final List<double> _aiTickTimes = [];
  double _lastAiTickMs = 0;
  double _maxAiTickMs = 0;
  double _p99AiTickMs = 0;

  // Query tracking
  int _queriesThisSecond = 0;
  int _queriesPerSecond = 0;
  double _queryTimer = 0;

  // Unit tracking
  int allyCount = 0;
  int enemyCount = 0;

  // Getters
  double get currentFps => _currentFps;
  double get minFps => _minFps;
  double get avgFps => _avgFps;
  double get lastAiTickMs => _lastAiTickMs;
  double get maxAiTickMs => _maxAiTickMs;
  double get p99AiTickMs => _p99AiTickMs;
  int get queriesPerSecond => _queriesPerSecond;

  /// 매 프레임 호출
  void update(double dt) {
    if (dt <= 0) return;

    // FPS 계산
    _frameTimes.add(dt);
    if (_frameTimes.length > 120) _frameTimes.removeAt(0);

    _fpsTimer += dt;
    if (_fpsTimer >= 0.5) {
      _fpsTimer = 0;
      _currentFps = 1.0 / dt;
      if (_currentFps < _minFps) _minFps = _currentFps;
      if (_frameTimes.isNotEmpty) {
        final avg = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _avgFps = avg > 0 ? 1.0 / avg : 0;
      }
    }

    // Query counter
    _queryTimer += dt;
    if (_queryTimer >= 1.0) {
      _queryTimer = 0;
      _queriesPerSecond = _queriesThisSecond;
      _queriesThisSecond = 0;
    }
  }

  /// AI tick 시간 기록 (ms)
  void recordAiTick(double milliseconds) {
    _lastAiTickMs = milliseconds;
    _aiTickTimes.add(milliseconds);
    if (_aiTickTimes.length > 200) _aiTickTimes.removeAt(0);

    if (milliseconds > _maxAiTickMs) _maxAiTickMs = milliseconds;

    // P99 계산
    if (_aiTickTimes.length >= 10) {
      final sorted = List<double>.from(_aiTickTimes)..sort();
      final idx = (sorted.length * 0.99).floor().clamp(0, sorted.length - 1);
      _p99AiTickMs = sorted[idx];
    }
  }

  /// SpatialHash query 카운트
  void recordQuery() {
    _queriesThisSecond++;
  }

  /// 리셋
  void reset() {
    _frameTimes.clear();
    _aiTickTimes.clear();
    _fpsTimer = 0;
    _currentFps = 60;
    _minFps = 60;
    _avgFps = 60;
    _lastAiTickMs = 0;
    _maxAiTickMs = 0;
    _p99AiTickMs = 0;
    _queriesThisSecond = 0;
    _queriesPerSecond = 0;
    _queryTimer = 0;
    allyCount = 0;
    enemyCount = 0;
  }

  /// 성능 요약 맵
  Map<String, dynamic> toMap() {
    return {
      'fps': _currentFps,
      'minFps': _minFps,
      'avgFps': _avgFps,
      'aiTickMs': _lastAiTickMs,
      'maxAiTickMs': _maxAiTickMs,
      'p99AiTickMs': _p99AiTickMs,
      'queriesPerSec': _queriesPerSecond,
      'allyCount': allyCount,
      'enemyCount': enemyCount,
    };
  }
}
