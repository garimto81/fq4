import 'package:flutter/material.dart';
import '../../poc/infrastructure/poc_definition.dart';
import '../../poc/infrastructure/poc_logger.dart';

/// 디버그 패널: severity/system 필터, 색상 코딩, monospace
class PocDebugPanel extends StatefulWidget {
  final PocLogger logger;
  final double height;

  const PocDebugPanel({
    super.key,
    required this.logger,
    this.height = 200,
  });

  @override
  State<PocDebugPanel> createState() => _PocDebugPanelState();
}

class _PocDebugPanelState extends State<PocDebugPanel> {
  final ScrollController _scrollController = ScrollController();
  final Set<LogSeverity> _activeSeverities = {
    LogSeverity.info,
    LogSeverity.warn,
    LogSeverity.error,
    LogSeverity.critical,
  };
  final Set<LogSystem> _activeSystems = Set.from(LogSystem.values);

  @override
  void initState() {
    super.initState();
    widget.logger.onLogAdded = (_) {
      if (mounted) setState(() {});
      _autoScroll();
    };
  }

  void _autoScroll() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.logger.filter(
      severities: _activeSeverities,
      systems: _activeSystems,
    );

    return Container(
      height: widget.height,
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          // Header + filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF21262D),
            child: Row(
              children: [
                const Text(
                  'Debug Log',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const Spacer(),
                // Severity filters
                for (final sev in [LogSeverity.debug, LogSeverity.info, LogSeverity.warn, LogSeverity.error])
                  _buildFilterChip(
                    sev.name.toUpperCase(),
                    _activeSeverities.contains(sev),
                    _severityColor(sev),
                    () => setState(() {
                      if (_activeSeverities.contains(sev)) {
                        _activeSeverities.remove(sev);
                      } else {
                        _activeSeverities.add(sev);
                      }
                    }),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${filtered.length}/${widget.logger.length}',
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          // Log entries
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.5),
                  child: Text(
                    entry.formatted,
                    style: TextStyle(
                      color: _severityColor(entry.severity),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.6) : Colors.white12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _severityColor(LogSeverity severity) => switch (severity) {
    LogSeverity.debug => Colors.grey,
    LogSeverity.info => Colors.white70,
    LogSeverity.warn => Colors.yellow.shade300,
    LogSeverity.error => Colors.red.shade300,
    LogSeverity.critical => Colors.red,
  };
}
