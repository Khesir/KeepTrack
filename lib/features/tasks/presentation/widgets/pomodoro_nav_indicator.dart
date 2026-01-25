import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';

/// Compact pomodoro timer indicator for navigation bars
/// Shows elapsed/remaining time when a session is active
class PomodoroNavIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const PomodoroNavIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final controller = locator.get<PomodoroSessionController>();

    return AsyncStreamBuilder<PomodoroSessionState>(
      state: controller,
      builder: (context, state) {
        final session = state.currentSession;

        // Don't show if no active session or session is completed/cancelled
        if (session == null ||
            session.status == PomodoroSessionStatus.completed ||
            session.status == PomodoroSessionStatus.canceled) {
          return const SizedBox.shrink();
        }

        // Get session color
        Color sessionColor;
        switch (session.type) {
          case PomodoroSessionType.pomodoro:
            sessionColor = Colors.red;
            break;
          case PomodoroSessionType.shortBreak:
            sessionColor = Colors.green;
            break;
          case PomodoroSessionType.longBreak:
            sessionColor = Colors.blue;
            break;
          case PomodoroSessionType.stopwatch:
            sessionColor = Colors.amber;
            break;
        }

        // Calculate display time
        final int displaySeconds;
        if (session.isStopwatch) {
          displaySeconds = session.elapsedSeconds;
        } else {
          displaySeconds = session.remainingSeconds;
        }

        final hours = displaySeconds ~/ 3600;
        final minutes = (displaySeconds % 3600) ~/ 60;
        final seconds = displaySeconds % 60;

        final timeText = hours > 0
            ? '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
            : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final isRunning = state.isRunning;

        return Tooltip(
          message: '${session.type.displayName} - Tap to view',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sessionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sessionColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing indicator for running sessions
                  _PulsingDot(
                    color: sessionColor,
                    isAnimating: isRunning,
                  ),
                  const SizedBox(width: 8),
                  // Time display
                  Text(
                    timeText,
                    style: TextStyle(
                      color: sessionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // Pause indicator
                  if (!isRunning) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.pause,
                      size: 14,
                      color: sessionColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loadingBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Pulsing dot indicator for active sessions
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isAnimating;

  const _PulsingDot({
    required this.color,
    required this.isAnimating,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(
              widget.isAnimating ? _animation.value : 1.0,
            ),
            shape: BoxShape.circle,
            boxShadow: widget.isAnimating
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4 * _animation.value),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
