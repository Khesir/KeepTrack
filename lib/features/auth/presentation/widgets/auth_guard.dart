import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/auth/presentation/screens/login_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

/// Auth Guard widget that protects routes requiring authentication
///
/// Usage:
/// ```dart
/// AuthGuard(
///   child: MainScreen(),
/// )
/// ```
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

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
      loadingBuilder: (context) => _buildSplash(),
      errorBuilder: (context, message) {
        // On auth error, show login screen
        return const LoginScreen();
      },
      builder: (context, data) {
        // Check if user is authenticated
        if (_authController.isAuthenticated) {
          // User is authenticated, show protected content
          return widget.child;
        } else {
          // User is not authenticated, show login screen
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Personal Codex',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
