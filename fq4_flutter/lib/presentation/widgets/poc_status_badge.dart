import 'package:flutter/material.dart';
import '../../poc/infrastructure/poc_definition.dart';

/// 상태 배지: 작은 원형 (PASS=초록, FAIL=빨강, 나머지=회색)
class PocStatusBadge extends StatelessWidget {
  final PocStatus status;
  final double size;

  const PocStatusBadge({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
      ),
      child: _icon,
    );
  }

  Color get _color => switch (status) {
    PocStatus.passed => Colors.green,
    PocStatus.failed => Colors.red,
    PocStatus.running => Colors.amber,
    PocStatus.error => Colors.orange,
    PocStatus.skipped => Colors.grey.shade600,
    PocStatus.notRun => Colors.grey.shade800,
  };

  Widget? get _icon {
    final iconSize = size * 0.7;
    return switch (status) {
      PocStatus.passed => Icon(Icons.check, size: iconSize, color: Colors.white),
      PocStatus.failed => Icon(Icons.close, size: iconSize, color: Colors.white),
      PocStatus.running => SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      ),
      PocStatus.error => Icon(Icons.error_outline, size: iconSize, color: Colors.white),
      _ => null,
    };
  }
}
