/// Log viewer screen for production debugging
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Screen that displays all app logs
///
/// Useful for debugging production builds where console logs
/// are not accessible.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _scrollController = ScrollController();
  List<LogEntry> _logs = [];
  LogLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _refreshLogs();

    // Listen for new logs
    AppLogger().addListener(_onNewLog);
  }

  @override
  void dispose() {
    AppLogger().removeListener(_onNewLog);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewLog(LogEntry entry) {
    setState(() {
      _refreshLogs();
    });

    // Auto-scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _refreshLogs() {
    _logs = AppLogger.getLogs();
    if (_filterLevel != null) {
      _logs = _logs.where((log) => log.level == _filterLevel).toList();
    }
  }

  void _copyLogsToClipboard() {
    final text = _logs.map((log) => log.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _clearLogs() {
    AppLogger().clear();
    setState(() {
      _refreshLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          // Filter menu
          PopupMenuButton<LogLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (level) {
              setState(() {
                _filterLevel = level;
                _refreshLogs();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Levels'),
              ),
              ...LogLevel.values.map(
                (level) => PopupMenuItem(
                  value: level,
                  child: Text(level.name.toUpperCase()),
                ),
              ),
            ],
          ),
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy logs to clipboard',
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Log count and filter indicator
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(
                  '${_logs.length} log entries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_filterLevel != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      _filterLevel!.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    onDeleted: () {
                      setState(() {
                        _filterLevel = null;
                        _refreshLogs();
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),

          // Log list
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _LogEntryTile(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single log entry
class _LogEntryTile extends StatelessWidget {
  final LogEntry log;

  const _LogEntryTile({required this.log});

  Color _getLogColor(BuildContext context) {
    switch (log.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _getLogIcon() {
    switch (log.level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLogColor(context);
    final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: log.stackTrace != null
          ? () {
              // Show full stack trace in dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Stack Trace - ${log.level.name.toUpperCase()}'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      '${log.message}\n\n${log.stackTrace}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '${log.message}\n\n${log.stackTrace}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stack trace copied to clipboard'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Copy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(
              _getLogIcon(),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time and level
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.level.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (log.stackTrace != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.code,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message
                  SelectableText(
                    log.message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
