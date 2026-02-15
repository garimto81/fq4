// POC 시스템 핵심 데이터 모델
// POC 상태, 검증 기준, 정의, 결과를 표현하는 데이터 클래스 모음

/// POC 실행 상태
enum PocStatus {
  notRun,
  running,
  passed,
  failed,
  error,
  skipped,
}

/// 로그 심각도
enum LogSeverity {
  debug,
  info,
  warn,
  error,
  critical,
}

/// 로그 시스템 (출처)
enum LogSystem {
  combat,
  ai,
  render,
  physics,
  spawn,
  ui,
  verification,
  lifecycle,
}

/// 단일 검증 기준
class PocCriterion {
  final String id;
  final String description;
  final bool Function(Map<String, dynamic> metrics) evaluate;

  const PocCriterion({
    required this.id,
    required this.description,
    required this.evaluate,
  });
}

/// POC 정의 (manifest 엔트리)
class PocDefinition {
  final String id;
  final String name;
  final String category;
  final String description;
  final String route;
  final List<PocCriterion> criteria;
  final Duration timeout;
  final bool requiresInput;
  final List<String> tags;

  const PocDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.route,
    required this.criteria,
    this.timeout = const Duration(seconds: 60),
    this.requiresInput = false,
    this.tags = const [],
  });

  bool get isAutoRunnable => !requiresInput;
}

/// 단일 criterion 검증 결과
class CriterionResult {
  final String criterionId;
  final String description;
  final bool passed;
  final String detail;

  const CriterionResult({
    required this.criterionId,
    required this.description,
    required this.passed,
    this.detail = '',
  });
}

/// POC 검증 결과
class PocVerificationResult {
  final String pocId;
  final PocStatus status;
  final Duration elapsed;
  final List<CriterionResult> criteriaResults;
  final Map<String, dynamic> finalMetrics;
  final String? errorMessage;

  const PocVerificationResult({
    required this.pocId,
    required this.status,
    required this.elapsed,
    required this.criteriaResults,
    required this.finalMetrics,
    this.errorMessage,
  });

  int get passedCount => criteriaResults.where((r) => r.passed).length;
  int get totalCount => criteriaResults.length;
  double get passRate => totalCount > 0 ? passedCount / totalCount : 0;
}
