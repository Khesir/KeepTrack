import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/navigation/app_navigator.dart';
import 'package:keep_track/core/theme/app_theme.dart';

const _boxes = [
  'transactions',
  'budgets',
  'budget_categories',
  'month_plans',
  'goals',
  'debts',
  'planned_payments',
  'wallets',
  'subscriptions',
  'transaction_plans',
  'finance_categories',
  'budget_profiles',
];

void showHiveInspector(BuildContext context) {
  final ctx = AppNavigator.context ?? context;
  showDialog(
    context: ctx,
    builder: (_) => const _HiveInspectorDialog(),
  );
}

class _HiveInspectorDialog extends StatefulWidget {
  const _HiveInspectorDialog();

  @override
  State<_HiveInspectorDialog> createState() => _HiveInspectorDialogState();
}

class _HiveInspectorDialogState extends State<_HiveInspectorDialog> {
  String _selected = _boxes.first;
  List<Map<String, dynamic>> _records = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load(_selected);
  }

  Future<void> _load(String box) async {
    setState(() { _loading = true; _selected = box; });
    final cache = locator.get<LocalCache>();
    final records = await cache.getAll(box);
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242422) : Colors.white;
    final sidebarBg = isDark ? const Color(0xFF1E1E1C) : const Color(0xFFEBE9E1);
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(32),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 900,
        height: 600,
        child: Row(
          children: [
            // Sidebar — box list
            Container(
              width: 180,
              color: sidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    child: Text('HIVE BOXES', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: _boxes.map((box) {
                        final selected = box == _selected;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _load(box),
                            child: Container(
                              height: 32,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                box,
                                style: GoogleFonts.dmMono(
                                  fontSize: 12,
                                  color: selected ? AppColors.accent : AppColors.textSecondary,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: border),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
                    child: Row(
                      children: [
                        Text(_selected, style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text('${_records.length}', style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.accent)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () => _load(_selected),
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Records
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _records.isEmpty
                            ? Center(child: Text('Empty', style: GoogleFonts.dmSans(color: AppColors.textSecondary)))
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _records.length,
                                separatorBuilder: (_, __) => Divider(height: 12, color: border),
                                itemBuilder: (_, i) => _RecordTile(record: _records[i], isDark: isDark),
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

class _RecordTile extends StatefulWidget {
  final Map<String, dynamic> record;
  final bool isDark;
  const _RecordTile({required this.record, required this.isDark});

  @override
  State<_RecordTile> createState() => _RecordTileState();
}

class _RecordTileState extends State<_RecordTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.record['id'] as String? ?? '(no id)';
    final name = widget.record['name'] as String? ?? widget.record['description'] as String? ?? '';
    final pretty = const JsonEncoder.withIndent('  ').convert(widget.record);
    final fg = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(name.isNotEmpty ? '$name  ·  $id' : id, style: GoogleFonts.dmMono(fontSize: 12, color: fg), overflow: TextOverflow.ellipsis)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: pretty)),
                    child: Icon(Icons.copy_rounded, size: 13, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(pretty, style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
