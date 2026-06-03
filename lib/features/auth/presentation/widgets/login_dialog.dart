import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

class LoginDialog extends StatefulWidget {
  final bool initialSignUp;

  const LoginDialog({super.key, this.initialSignUp = false});

  static Future<void> show(BuildContext context, {bool signUp = false}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => LoginDialog(initialSignUp: signUp),
    );
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  late final AuthController _authController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _showGoogle =>
      kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    _authController = locator.get<AuthController>();
    _authController.stream.listen(_onAuthState);
  }

  void _onAuthState(AsyncState<User?> state) {
    if (!mounted) return;
    if (state is AsyncLoading) {
      setState(() => _isLoading = true);
    } else if (state is AsyncData<User?> && state.data != null) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (state is AsyncError<User?>) {
      setState(() {
        _isLoading = false;
        _errorMessage = _humanize(state.message);
      });
      _authController.cancelSignIn();
    } else {
      setState(() => _isLoading = false);
    }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _isLoading ? _buildLoading() : _buildForm(),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _authController.cancelSignIn();
              setState(() => _isLoading = false);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSignUp ? 'Sign up' : 'Log in',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isSignUp) ...[
            _buildField('DISPLAY NAME (OPTIONAL)', _nameController, hint: 'Your name'),
            const SizedBox(height: 14),
          ],
          _buildField(
            'EMAIL',
            _emailController,
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildPasswordField(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildError(),
          ],
          const SizedBox(height: 18),
          _buildPrimaryButton(),
          if (_showGoogle) ...[
            const SizedBox(height: 14),
            _buildDivider(),
            const SizedBox(height: 14),
            _GoogleButton(onTap: _authController.signInWithGoogle),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Already have an account?  ' : "Don't have an account?  ",
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
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
        const SizedBox(height: 5),
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
        const SizedBox(height: 5),
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
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textTertiary),
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

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
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
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          _isSignUp ? 'Create Account' : 'Log In',
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
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
        Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
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
          height: 42,
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
