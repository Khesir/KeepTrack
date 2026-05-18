import 'package:flutter/material.dart';

class AppNavigator {
  static final key = GlobalKey<NavigatorState>();
  static BuildContext? get context => key.currentContext;
}
