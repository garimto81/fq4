import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// POC 화면 공통 mixin
///
/// 기존 9개 화면의 중복 코드 통합:
/// - safeSetState
/// - log scroll controller
/// - log management
mixin PocScreenMixin<T extends StatefulWidget> on State<T> {
  final ScrollController logScrollController = ScrollController();
  final List<String> battleLogs = [];
  int maxLogEntries = 200;

  /// Flame -> Flutter 안전한 setState (addPostFrameCallback)
  void safeSetState(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// 로그 추가 + 자동 스크롤
  void addLog(String log) {
    safeSetState(() {
      battleLogs.add(log);
      if (battleLogs.length > maxLogEntries) {
        battleLogs.removeRange(0, battleLogs.length - maxLogEntries);
      }
    });
    autoScrollLog();
  }

  /// 로그 리스트 자동 하단 스크롤
  void autoScrollLog() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (logScrollController.hasClients) {
        logScrollController.animateTo(
          logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// HP 비율에 따른 색상
  Color hpColor(double ratio) {
    if (ratio <= 0) return Colors.grey;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.yellow.shade700;
    return Colors.red;
  }

  /// 로그 텍스트 색상
  Color logColor(String log) {
    if (log.contains('defeated')) return Colors.red.shade300;
    if (log.contains('===')) return Colors.yellow.shade300;
    if (log.contains('CRIT')) return Colors.orange.shade300;
    if (log.contains('MISS')) return Colors.grey;
    return Colors.white60;
  }

  @override
  void dispose() {
    logScrollController.dispose();
    super.dispose();
  }
}
