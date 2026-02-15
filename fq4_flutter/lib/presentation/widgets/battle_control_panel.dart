import 'package:flutter/material.dart';
import 'unit_status_bar.dart';

/// 하단 전투 컨트롤 패널 위젯
class BattleControlPanel extends StatelessWidget {
  const BattleControlPanel({
    super.key,
    required this.allies,
    required this.enemies,
    this.onButtonA,
    this.onButtonB,
    this.buttonALabel = 'Test A',
    this.buttonBLabel = 'Test B',
  });

  final List<({String name, double hpRatio})> allies;
  final List<({String name, double hpRatio})> enemies;
  final VoidCallback? onButtonA;
  final VoidCallback? onButtonB;
  final String buttonALabel;
  final String buttonBLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ally status
          for (final ally in allies)
            UnitStatusBar(
              name: ally.name,
              hpRatio: ally.hpRatio,
              isAlly: true,
              compact: true,
            ),
          if (enemies.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 8),
            for (final enemy in enemies)
              UnitStatusBar(
                name: enemy.name,
                hpRatio: enemy.hpRatio,
                isAlly: false,
                compact: true,
              ),
          ],
          const Spacer(),
          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onButtonA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(buttonALabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onButtonB,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(buttonBLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
