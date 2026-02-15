// POC 결과 저장소
// 실행 결과 저장, 집계, 텍스트 리포트 생성

import 'poc_definition.dart';

class PocResultStore {
  final Map<String, PocVerificationResult> _results = {};

  void store(PocVerificationResult result) {
    _results[result.pocId] = result;
  }

  PocVerificationResult? get(String pocId) => _results[pocId];

  List<PocVerificationResult> get all => _results.values.toList();

  void clear() => _results.clear();

  int get passCount =>
      _results.values.where((r) => r.status == PocStatus.passed).length;

  int get failCount =>
      _results.values.where((r) => r.status == PocStatus.failed).length;

  int get errorCount =>
      _results.values.where((r) => r.status == PocStatus.error).length;

  int get totalRun => _results.length;

  PocStatus statusFor(String pocId) =>
      _results[pocId]?.status ?? PocStatus.notRun;

  /// 텍스트 리포트 생성
  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('=== POC Verification Report ===');
    buf.writeln('Total: $totalRun | PASS: $passCount | FAIL: $failCount | ERROR: $errorCount');
    buf.writeln('');

    for (final result in _results.values) {
      final icon = switch (result.status) {
        PocStatus.passed => 'PASS',
        PocStatus.failed => 'FAIL',
        PocStatus.error => 'ERR ',
        _ => '----',
      };
      buf.writeln('[$icon] ${result.pocId} (${result.elapsed.inMilliseconds}ms)');

      for (final cr in result.criteriaResults) {
        final mark = cr.passed ? '+' : '-';
        buf.writeln('  [$mark] ${cr.description}');
        if (cr.detail.isNotEmpty) {
          buf.writeln('      ${cr.detail}');
        }
      }

      if (result.errorMessage != null) {
        buf.writeln('  ERROR: ${result.errorMessage}');
      }
      buf.writeln('');
    }

    return buf.toString();
  }
}
