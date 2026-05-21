import 'package:flutter/material.dart';

class AppRestartWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRestart;

  const AppRestartWidget({super.key, required this.child, this.onRestart});

  static _AppRestartWidgetState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppRestartWidgetState>()!;

  @override
  State<AppRestartWidget> createState() => _AppRestartWidgetState();
}

class _AppRestartWidgetState extends State<AppRestartWidget> {
  Key _key = UniqueKey();

  void restart() {
    widget.onRestart?.call();
    setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
