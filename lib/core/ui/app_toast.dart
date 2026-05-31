import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

bool get _isDesktop =>
    kIsWeb == false &&
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

enum _ToastType { success, error, info }

class AppToast {
  static void show(BuildContext context, String message) =>
      _show(context, message, _ToastType.info);

  static void success(BuildContext context, String message) =>
      _show(context, message, _ToastType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _ToastType.error);

  static void _show(BuildContext context, String message, _ToastType type) {
    if (!_isDesktop) {
      final bg = switch (type) {
        _ToastType.success => AppColors.success,
        _ToastType.error => AppColors.error,
        _ToastType.info => AppColors.accent,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.dmSans()),
          backgroundColor: bg,
        ),
      );
      return;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2800), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  (Color bg, Color fg, Color accent, IconData icon) get _style =>
      switch (widget.type) {
        _ToastType.success => (
            AppColors.successLight,
            AppColors.success,
            AppColors.success,
            Icons.check_circle_rounded,
          ),
        _ToastType.error => (
            AppColors.errorLight,
            AppColors.error,
            AppColors.error,
            Icons.error_rounded,
          ),
        _ToastType.info => (
            AppColors.accentLight,
            AppColors.accent,
            AppColors.accent,
            Icons.info_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, accent, icon) = _style;

    return Positioned(
      right: 16,
      bottom: 32,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
