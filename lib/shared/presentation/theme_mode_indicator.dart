import 'package:flutter/material.dart';

class ThemeModeIndicator extends StatelessWidget {
  const ThemeModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Get app brightness (light/dark based on ThemeMode & system)
    final brightness = Theme.of(context).brightness;

    // Get system brightness
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    // Determine current mode label
    final modeLabel = brightness == Brightness.light ? 'Light' : 'Dark';
    final systemLabel = systemBrightness == Brightness.light ? 'Light' : 'Dark';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          brightness == Brightness.light
              ? Icons.wb_sunny
              : Icons.nightlight_round,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '$modeLabel (System: $systemLabel)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
