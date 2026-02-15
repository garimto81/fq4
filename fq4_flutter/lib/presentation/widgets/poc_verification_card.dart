import 'package:flutter/material.dart';
import '../../poc/infrastructure/poc_definition.dart';
import 'poc_status_badge.dart';

/// 검증 결과 카드: POC 이름 + 전체 상태 + 각 criterion 결과
class PocVerificationCard extends StatelessWidget {
  final String pocName;
  final PocVerificationResult? result;

  const PocVerificationCard({
    super.key,
    required this.pocName,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return _buildWaiting();
    }
    return _buildResult(result!);
  }

  Widget _buildWaiting() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const PocStatusBadge(status: PocStatus.notRun, size: 14),
          const SizedBox(width: 8),
          Text(
            pocName,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Spacer(),
          const Text(
            'Waiting...',
            style: TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(PocVerificationResult result) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: result.status == PocStatus.passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + status + time
          Row(
            children: [
              PocStatusBadge(status: result.status, size: 14),
              const SizedBox(width: 8),
              Text(
                pocName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${result.elapsed.inMilliseconds}ms',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
          if (result.criteriaResults.isNotEmpty) ...[
            const SizedBox(height: 4),
            // Criteria list
            for (final cr in result.criteriaResults)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      cr.passed ? Icons.check_circle : Icons.cancel,
                      size: 10,
                      color: cr.passed ? Colors.green : Colors.red.shade300,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cr.description,
                        style: TextStyle(
                          color: cr.passed ? Colors.white60 : Colors.red.shade200,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (result.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              result.errorMessage!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}
