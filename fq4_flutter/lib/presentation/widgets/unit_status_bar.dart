import 'package:flutter/material.dart';

/// 유닛 HP/상태 표시 위젯
class UnitStatusBar extends StatelessWidget {
  const UnitStatusBar({
    super.key,
    required this.name,
    required this.hpRatio,
    this.isAlly = true,
    this.compact = false,
  });

  final String name;
  final double hpRatio;
  final bool isAlly;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final barHeight = compact ? 8.0 : 12.0;
    final fontSize = compact ? 11.0 : 13.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            isAlly ? '★' : '☠',
            style: TextStyle(
              color: isAlly ? Colors.blue.shade300 : Colors.red.shade300,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: compact ? 60 : 80,
            child: Text(
              name,
              style: TextStyle(
                color: hpRatio <= 0 ? Colors.white30 : Colors.white,
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hpRatio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _hpColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Text(
              hpRatio <= 0 ? 'DEAD' : '${(hpRatio * 100).toInt()}%',
              style: TextStyle(
                color: hpRatio <= 0 ? Colors.red.shade300 : Colors.white60,
                fontSize: fontSize - 2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color get _hpColor {
    if (hpRatio <= 0) return Colors.grey;
    if (hpRatio > 0.5) return Colors.green;
    if (hpRatio > 0.25) return Colors.yellow.shade700;
    return Colors.red;
  }
}
