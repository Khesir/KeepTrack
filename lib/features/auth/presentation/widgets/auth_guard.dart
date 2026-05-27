import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/screens/welcome_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  static const _choiceKey = 'auth_mode_chosen';

  static Future<void> resetChoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_choiceKey);
  }

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final AuthController _authController;
  bool _hasChosen = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _authController = locator.get<AuthController>();
    _loadChoice();
  }

  Future<void> _loadChoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasChosen = prefs.getBool(AuthGuard._choiceKey) ?? false;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _onContinueFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AuthGuard._choiceKey, true);
    if (mounted) setState(() => _hasChosen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) return _splash();

    return AsyncStreamBuilder<dynamic>(
      state: _authController,
      loadingBuilder: (_) => _splash(),
      errorBuilder: (_, __) => _resolve(),
      builder: (_, __) => _resolve(),
    );
  }

  Widget _resolve() {
    if (_authController.isAuthenticated || _hasChosen) return widget.child;
    return WelcomeScreen(onContinueFree: _onContinueFree);
  }

  Widget _splash() {
    return const Scaffold(
      backgroundColor: Color(0xFF1E1E1C),
      body: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}
