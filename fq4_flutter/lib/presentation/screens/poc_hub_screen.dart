import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../poc/infrastructure/poc_definition.dart';
import '../../poc/infrastructure/poc_e2e_controller.dart';
import '../../poc/infrastructure/poc_runner.dart';
import '../../poc/poc_manifest.dart';
import '../widgets/poc_status_badge.dart';

/// POC Hub 화면: 카테고리별 POC 목록, E2E 실행, 결과 리포트
class PocHubScreen extends StatefulWidget {
  const PocHubScreen({super.key});

  @override
  State<PocHubScreen> createState() => _PocHubScreenState();
}

class _PocHubScreenState extends State<PocHubScreen> {
  late final PocResultStore _resultStore;
  late final PocE2eController _e2eController;

  @override
  void initState() {
    super.initState();
    _resultStore = PocResultStore();
    _e2eController = PocE2eController(resultStore: _resultStore);
    _e2eController.addListener(_onE2eChanged);
  }

  void _onE2eChanged() {
    setState(() {});
    // E2E 완료 시 리포트 다이얼로그
    if (!_e2eController.isRunning && _resultStore.totalRun > 0) {
      _showReportDialog();
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Row(
          children: [
            Icon(
              _resultStore.failCount == 0 && _resultStore.errorCount == 0
                  ? Icons.check_circle
                  : Icons.warning,
              color: _resultStore.failCount == 0 && _resultStore.errorCount == 0
                  ? Colors.green
                  : Colors.amber,
            ),
            const SizedBox(width: 8),
            const Text(
              'E2E Report',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary
                _buildSummaryRow('Total', '${_resultStore.totalRun}', Colors.white),
                _buildSummaryRow('Passed', '${_resultStore.passCount}', Colors.green),
                _buildSummaryRow('Failed', '${_resultStore.failCount}', Colors.red),
                _buildSummaryRow('Errors', '${_resultStore.errorCount}', Colors.orange),
                const Divider(color: Colors.white24),
                // Detail
                Text(
                  _resultStore.generateReport(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _e2eController.removeListener(_onE2eChanged);
    _e2eController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('POC Hub'),
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (_e2eController.isRunning)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: _e2eController.progress,
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(Colors.amber),
                  ),
                ),
              ),
            ),
          if (_resultStore.totalRun > 0)
            IconButton(
              icon: const Icon(Icons.assessment),
              tooltip: 'View Report',
              onPressed: _showReportDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // E2E progress bar
          if (_e2eController.isRunning)
            _buildE2eProgressBar(),

          // POC list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final category in PocManifest.categories) ...[
                  _buildCategoryHeader(category),
                  for (final poc in PocManifest.byCategory(category))
                    _buildPocCard(poc),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Bottom bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildE2eProgressBar() {
    final current = _e2eController.currentPocId ?? '';
    final def = PocManifest.byId(current);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1A3A5C),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.amber),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Running: ${def?.name ?? current}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${_e2eController.currentIndex + 1}/${_e2eController.totalCount}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _e2eController.cancel(),
                child: const Icon(Icons.cancel, color: Colors.white38, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _e2eController.progress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPocCard(PocDefinition poc) {
    final status = _resultStore.statusFor(poc.id);
    final result = _resultStore.get(poc.id);
    final isCurrentE2e = _e2eController.currentPocId == poc.id;

    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => context.go(poc.route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Status badge
              PocStatusBadge(
                status: isCurrentE2e ? PocStatus.running : status,
                size: 16,
              ),
              const SizedBox(width: 10),
              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poc.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      poc.description,
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Tags
              for (final tag in poc.tags.take(2))
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white24, fontSize: 8),
                  ),
                ),
              // Auto/Manual indicator
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: poc.isAutoRunnable
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  poc.isAutoRunnable ? 'AUTO' : 'MANUAL',
                  style: TextStyle(
                    color: poc.isAutoRunnable ? Colors.green.shade300 : Colors.orange.shade300,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Result pass rate
              if (result != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${result.passedCount}/${result.totalCount}',
                  style: TextStyle(
                    color: result.status == PocStatus.passed
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final autoCount = PocManifest.autoRunnable.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Summary
          if (_resultStore.totalRun > 0) ...[
            _buildMiniStat('PASS', _resultStore.passCount, Colors.green),
            const SizedBox(width: 12),
            _buildMiniStat('FAIL', _resultStore.failCount, Colors.red),
            const SizedBox(width: 12),
            _buildMiniStat('ERR', _resultStore.errorCount, Colors.orange),
          ],
          const Spacer(),
          // Run All Auto button
          ElevatedButton.icon(
            onPressed: _e2eController.isRunning
                ? null
                : () {
                    _e2eController.startAll();
                    // Navigate to first auto POC
                    final route = _e2eController.nextRoute;
                    if (route != null) {
                      context.go(route);
                    }
                  },
            icon: const Icon(Icons.play_arrow, size: 16),
            label: Text('Run All Auto ($autoCount)', style: const TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
