import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/screens/login_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = locator.get<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<dynamic>(
      state: _authController,
      loadingBuilder: (_) => _buildSplash(),
      errorBuilder: (_, __) => const LoginScreen(),
      builder: (_, __) {
        if (_authController.isAuthenticated) return widget.child;
        return const LoginScreen();
      },
    );
  }

  Widget _buildSplash() {
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
