// 구조화 로거
// POC 실행 중 발생하는 이벤트를 severity/system별로 기록하고 필터링

import 'poc_definition.dart';

/// 단일 로그 엔트리
class PocLogEntry {
  final DateTime timestamp;
  final LogSeverity severity;
  final LogSystem system;
  final String message;
  final String? detail;
  final Map<String, dynamic>? data;

  PocLogEntry({
    DateTime? timestamp,
    required this.severity,
    required this.system,
    required this.message,
    this.detail,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formatted {
    final ts = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    final sev = severity.name.toUpperCase().padRight(5);
    final sys = '[${system.name}]'.padRight(14);
    return '$ts $sev $sys $message';
  }
}

/// POC 구조화 로거
class PocLogger {
  final List<PocLogEntry> _entries = [];
  final int maxEntries;
  void Function(PocLogEntry)? onLogAdded;

  PocLogger({this.maxEntries = 500, this.onLogAdded});

  List<PocLogEntry> get entries => List.unmodifiable(_entries);

  void _add(PocLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    onLogAdded?.call(entry);
  }

  void log(LogSeverity severity, LogSystem system, String message, {
    String? detail,
    Map<String, dynamic>? data,
  }) {
    _add(PocLogEntry(
      severity: severity,
      system: system,
      message: message,
      detail: detail,
      data: data,
    ));
  }

  void debug(LogSystem system, String message, {Map<String, dynamic>? data}) =>
      log(LogSeverity.debug, system, message, data: data);

  void info(LogSystem system, String message, {Map<String, dynamic>? data}) =>
      log(LogSeverity.info, system, message, data: data);

  void warn(LogSystem system, String message, {Map<String, dynamic>? data}) =>
      log(LogSeverity.warn, system, message, data: data);

  void error(LogSystem system, String message, {String? detail, Map<String, dynamic>? data}) =>
      log(LogSeverity.error, system, message, detail: detail, data: data);

  /// severity별 필터링
  List<PocLogEntry> bySeverity(LogSeverity severity) =>
      _entries.where((e) => e.severity == severity).toList();

  /// system별 필터링
  List<PocLogEntry> bySystem(LogSystem system) =>
      _entries.where((e) => e.system == system).toList();

  /// severity + system 복합 필터링
  List<PocLogEntry> filter({
    Set<LogSeverity>? severities,
    Set<LogSystem>? systems,
  }) {
    return _entries.where((e) {
      if (severities != null && !severities.contains(e.severity)) return false;
      if (systems != null && !systems.contains(e.system)) return false;
      return true;
    }).toList();
  }

  bool get hasErrors => _entries.any((e) =>
      e.severity == LogSeverity.error || e.severity == LogSeverity.critical);

  PocLogEntry? get firstError {
    for (final e in _entries) {
      if (e.severity == LogSeverity.error || e.severity == LogSeverity.critical) {
        return e;
      }
    }
    return null;
  }

  void clear() => _entries.clear();

  int get length => _entries.length;
}
