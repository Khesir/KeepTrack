import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _pageBg = Color(0xFF1E1E1C);

  bool get _showGoogle =>
      kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

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

  String _humanize(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('unauthorized') ||
        lower.contains('invalid credentials') ||
        lower.contains('401') ||
        lower.contains('wrong password') ||
        lower.contains('user not found')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email already') ||
        lower.contains('already registered')) {
      return 'This email is already in use.';
    }
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'Connection failed. Check your internet and try again.';
    }
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: AsyncStreamBuilder<dynamic>(
        state: _authController,
        loadingBuilder: (_) => _buildLoading(),
        errorBuilder: (_, msg) {
          // Stay on the form — capture error in local state and reset controller
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _errorMessage = _humanize(msg));
              _authController.cancelSignIn();
            }
          });
          return _buildPage();
        },
        builder: (_, __) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 56,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create an account' : 'Welcome back!',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUp
                ? 'Join Keep Track today'
                : "We're excited to see you again!",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_isSignUp) ...[
            _buildField(
              'DISPLAY NAME (OPTIONAL)',
              _nameController,
              hint: 'Your name',
            ),
            const SizedBox(height: 16),
          ],
          _buildField(
            'EMAIL',
            _emailController,
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(),
          // ── Inline error banner ─────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildPrimaryButton(),
          const SizedBox(height: 16),
          if (_showGoogle) ...[
            _buildDivider(),
            const SizedBox(height: 16),
            _GoogleButton(onTap: _authController.signInWithGoogle),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? 'Already have an account?  '
                    : "Don't have an account?  ",
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _errorMessage = null;
                }),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    _isSignUp ? 'Sign in' : 'Register',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASSWORD',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: _inputDecoration('••••••••').copyWith(
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: AppColors.textTertiary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.inputFocus, width: 1.5),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          _isSignUp ? 'Create Account' : 'Log In',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _errorMessage = null);
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
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/wordmark-light.svg', height: 50),
          const SizedBox(height: 36),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSignUp ? 'Creating account…' : 'Signing in…',
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _authController.cancelSignIn,
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.backgroundSecondary : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.g_mobiledata_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                'Continue with Google',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
