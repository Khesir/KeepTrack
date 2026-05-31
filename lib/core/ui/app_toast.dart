import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

bool get _isDesktop =>
    kIsWeb == false &&
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

enum _ToastType { success, error, info, loading }

class AppToast {
  static void show(BuildContext context, String message) =>
      _show(context, message, _ToastType.info);

  static void success(BuildContext context, String message) =>
      _show(context, message, _ToastType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _ToastType.error);

  static VoidCallback loading(BuildContext context, String message) =>
      CapturedAppToast.capture(context).loading(message);

  static void _show(BuildContext context, String message, _ToastType type) {
    if (!_isDesktop) {
      final bg = switch (type) {
        _ToastType.success => AppColors.success,
        _ToastType.error => AppColors.error,
        _ToastType.info || _ToastType.loading => AppColors.accent,
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

/// Captures overlay/messenger references before an async gap so toasts can be
/// shown safely after operations like a native file picker that deactivate the
/// widget element on web.
class CapturedAppToast {
  final OverlayState? _overlay;
  final ScaffoldMessengerState? _messenger;

  CapturedAppToast._(this._overlay, this._messenger);

  factory CapturedAppToast.capture(BuildContext context) {
    if (_isDesktop) {
      return CapturedAppToast._(Overlay.of(context), null);
    }
    return CapturedAppToast._(null, ScaffoldMessenger.of(context));
  }

  void success(String message) => _show(message, _ToastType.success);
  void error(String message) => _show(message, _ToastType.error);
  void info(String message) => _show(message, _ToastType.info);

  VoidCallback loading(String message) {
    if (_messenger != null) {
      final ctrl = _messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(message, style: GoogleFonts.dmSans()),
        ]),
        backgroundColor: AppColors.accent,
        duration: const Duration(days: 1),
      ));
      return () => ctrl.close();
    }

    if (_overlay != null) {
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _ToastWidget(
          message: message,
          type: _ToastType.loading,
          onDismiss: () {},
          persistent: true,
        ),
      );
      _overlay.insert(entry);
      return () => entry.remove();
    }

    return () {};
  }

  void _show(String message, _ToastType type) {
    if (_messenger != null) {
      final bg = switch (type) {
        _ToastType.success => AppColors.success,
        _ToastType.error => AppColors.error,
        _ToastType.info || _ToastType.loading => AppColors.accent,
      };
      _messenger.showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.dmSans()),
        backgroundColor: bg,
      ));
      return;
    }

    if (_overlay != null) {
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _ToastWidget(
          message: message,
          type: type,
          onDismiss: () => entry.remove(),
        ),
      );
      _overlay.insert(entry);
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final VoidCallback onDismiss;
  final bool persistent;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.persistent = false,
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

    if (!widget.persistent) {
      Future.delayed(const Duration(milliseconds: 2800), _dismiss);
    }
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

  (Color bg, Color fg, Color accent, IconData? icon) get _style =>
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
        _ToastType.loading => (
            AppColors.accentLight,
            AppColors.accent,
            AppColors.accent,
            null,
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
                  if (icon != null)
                    Icon(icon, size: 16, color: fg)
                  else
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    ),
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
