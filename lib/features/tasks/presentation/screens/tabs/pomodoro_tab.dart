import 'package:flutter/material.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';

/// Pomodoro Session Tab - Coming Soon
class PomodoroTab extends ScopedScreen {
  const PomodoroTab({super.key});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends ScopedScreenState<PomodoroTab>
    with AppLayoutControlled {
  @override
  void registerServices() {
    // No services needed
  }

  @override
  void onReady() {
    configureLayout(title: 'Pomodoro', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pomodoro Timer Feature',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Track your focus sessions with Pomodoro technique.\nStay productive and manage your time effectively.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
