import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/gcash_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;
  bool _useEmailPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _authController = locator.get<AuthController>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GCashColors.background,
      body: AsyncStreamBuilder<dynamic>(
        state: _authController,
        loadingBuilder: (context) => _buildLoading(),
        errorBuilder: (context, message) => _buildError(message),
        builder: (context, data) {
          // If user is authenticated, this screen shouldn't be shown
          // (handled by auth guard in main.dart)
          return _buildLoginContent();
        },
      ),
    );
  }

  Widget _buildLoginContent() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isDesktop) {
      // Desktop: Split screen layout (1/2 logo, 1/2 form)
      return Row(
        children: [
          // Left side: Branding
          Expanded(
            child: Container(
              color: GCashColors.primary,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Keep Track',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your personal productivity hub',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side: Form
          Expanded(
            child: Container(
              color: GCashColors.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildAuthForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile/Tablet: Centered layout
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GCashColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Keep Track',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: GCashColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personal productivity hub',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                _buildAuthForm(),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Sign up to get started'
              : 'Sign in to your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Mobile: Show Google OAuth option
        if (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS) ...[
          if (!_useEmailPassword) ...[
            _buildGoogleSignInButton(),
            const SizedBox(height: 16),
            _buildDividerWithText('OR'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _useEmailPassword = true),
              child: const Text('Sign in with Email/Password'),
            ),
          ] else ...[
            _buildEmailPasswordForm(),
            const SizedBox(height: 16),
            _buildDividerWithText('OR'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _useEmailPassword = false),
              child: const Text('Sign in with Google'),
            ),
          ],
        ]
        // Desktop/Web: Email/Password only (or Google for web)
        else ...[
          // Web: Show Google option
          if (kIsWeb && !_useEmailPassword) ...[
            _buildGoogleSignInButton(),
            const SizedBox(height: 16),
            _buildDividerWithText('OR'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _useEmailPassword = true),
              child: const Text('Sign in with Email/Password'),
            ),
          ] else ...[
            _buildEmailPasswordForm(),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              _buildDividerWithText('OR'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _useEmailPassword = false),
                child: const Text('Sign in with Google'),
              ),
            ],
          ],
        ],

        const SizedBox(height: 24),

        // Dev mode features - Always show on desktop (Windows, macOS, Linux)
        FutureBuilder<bool>(
          future: _shouldShowDevMode(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return Column(
                children: [
                  _buildAdminSignInButton(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.code,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Dev Mode',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 24),

        // Terms
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildEmailPasswordForm() {
    return Column(
      children: [
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_isSignUp) {
              _authController.signUpWithEmail(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                displayName: _nameController.text.trim().isEmpty
                    ? null
                    : _nameController.text.trim(),
              );
            } else {
              _authController.signInWithEmail(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GCashColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _isSignUp = !_isSignUp),
          child: Text(
            _isSignUp
                ? 'Already have an account? Sign in'
                : "Don't have an account? Create one",
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _authController.signInWithGoogle(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google logo - using icon fallback for now
              Icon(
                Icons.login,
                size: 24,
                color: GCashColors.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSignInButton() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _authController.signInAsAdmin(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text(
                'Sign in as Admin (Dev)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon during loading
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GCashColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(GCashColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Signing in...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Cancel button
          TextButton(
            onPressed: () => _authController.cancelSignIn(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Sign-in Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Reset state and try again
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GCashColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _shouldShowDevMode() async {
    try {
      // Always show dev mode on desktop platforms (Windows, macOS, Linux)
      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.windows ||
          platform == TargetPlatform.macOS ||
          platform == TargetPlatform.linux) {
        return true;
      }

      // For mobile/web, check env variable
      return dotenv.env['DEV_BYPASS'] == 'true';
    } catch (e) {
      return false;
    }
  }
}
