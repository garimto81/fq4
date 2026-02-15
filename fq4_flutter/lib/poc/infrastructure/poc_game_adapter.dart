// POC 게임 어댑터
// 기존 FlameGame의 metrics를 받아 검증 기준 평가 + 결과 생성
// 기존 POC 게임 코드 수정 없이 인프라 연동

import 'poc_definition.dart';
import 'poc_logger.dart';

class PocGameAdapter {
  final PocDefinition definition;
  final PocLogger logger;
  final Stopwatch _stopwatch = Stopwatch();

  PocVerificationResult? _result;

  PocGameAdapter({
    required this.definition,
    PocLogger? logger,
  }) : logger = logger ?? PocLogger();

  PocVerificationResult? get result => _result;
  bool get hasResult => _result != null;
  Duration get elapsed => _stopwatch.elapsed;

  void start() {
    _stopwatch.reset();
    _stopwatch.start();
    _result = null;
    logger.info(LogSystem.lifecycle, '${definition.id} started');
  }

  /// metrics로 검증 기준 평가하여 결과 생성
  PocVerificationResult evaluate(Map<String, dynamic> metrics) {
    _stopwatch.stop();

    final criteriaResults = <CriterionResult>[];
    bool allPassed = true;

    for (final criterion in definition.criteria) {
      bool passed;
      String detail = '';
      try {
        passed = criterion.evaluate(metrics);
      } catch (e) {
        passed = false;
        detail = 'Evaluation error: $e';
        logger.error(LogSystem.verification, 'Criterion ${criterion.id} error: $e');
      }

      if (!passed) allPassed = false;

      criteriaResults.add(CriterionResult(
        criterionId: criterion.id,
        description: criterion.description,
        passed: passed,
        detail: detail,
      ));
    }

    final status = allPassed ? PocStatus.passed : PocStatus.failed;

    logger.info(
      LogSystem.verification,
      '${definition.id} ${status.name}: '
      '${criteriaResults.where((r) => r.passed).length}/${criteriaResults.length} criteria passed',
    );

    _result = PocVerificationResult(
      pocId: definition.id,
      status: status,
      elapsed: _stopwatch.elapsed,
      criteriaResults: criteriaResults,
      finalMetrics: Map.from(metrics),
    );

    return _result!;
  }

  /// 에러로 종료
  PocVerificationResult evaluateError(String errorMessage) {
    _stopwatch.stop();
    logger.error(LogSystem.lifecycle, '${definition.id} error: $errorMessage');

    _result = PocVerificationResult(
      pocId: definition.id,
      status: PocStatus.error,
      elapsed: _stopwatch.elapsed,
      criteriaResults: [],
      finalMetrics: {},
      errorMessage: errorMessage,
    );

    return _result!;
  }
}
