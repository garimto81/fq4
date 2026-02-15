// E2E 컨트롤러
// auto-runnable POC 순차 실행, 진행 상황 관리, 결과 수집

import 'package:flutter/foundation.dart';
import 'poc_definition.dart';
import 'poc_runner.dart';
import '../poc_manifest.dart';

class PocE2eController extends ChangeNotifier {
  final PocResultStore resultStore;

  PocE2eController({required this.resultStore});

  bool _running = false;
  bool _cancelled = false;
  int _currentIndex = 0;
  List<PocDefinition> _queue = [];
  String? _currentPocId;

  bool get isRunning => _running;
  int get currentIndex => _currentIndex;
  int get totalCount => _queue.length;
  String? get currentPocId => _currentPocId;
  double get progress => totalCount > 0 ? _currentIndex / totalCount : 0;

  /// auto-runnable POC 전체 실행
  void startAll() {
    startSelected(PocManifest.autoRunnable.map((d) => d.id).toList());
  }

  /// 선택된 POC 실행 시작
  void startSelected(List<String> pocIds) {
    if (_running) return;

    _queue = pocIds
        .map((id) => PocManifest.byId(id))
        .whereType<PocDefinition>()
        .toList();

    _running = true;
    _cancelled = false;
    _currentIndex = 0;
    _currentPocId = _queue.isNotEmpty ? _queue[0].id : null;
    notifyListeners();
  }

  /// 현재 POC 결과 보고 (화면에서 호출)
  void reportResult(PocVerificationResult result) {
    resultStore.store(result);
    _currentIndex++;

    if (_cancelled || _currentIndex >= _queue.length) {
      _running = false;
      _currentPocId = null;
    } else {
      _currentPocId = _queue[_currentIndex].id;
    }
    notifyListeners();
  }

  /// 다음 실행할 POC의 route 반환 (null이면 완료)
  String? get nextRoute {
    if (!_running || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex].route;
  }

  /// 취소
  void cancel() {
    _cancelled = true;
    _running = false;
    _currentPocId = null;
    notifyListeners();
  }

  /// 리셋
  void reset() {
    _running = false;
    _cancelled = false;
    _currentIndex = 0;
    _queue = [];
    _currentPocId = null;
    resultStore.clear();
    notifyListeners();
  }
}
