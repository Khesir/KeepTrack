import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/auth/presentation/widgets/login_dialog.dart';
import '../widgets/outline_button.dart';
import '../widgets/pane_widgets.dart';
import '../widgets/profile_form_widgets.dart';

class ProfileSettingsSection extends StatefulWidget {
  final bool isDark;
  final AuthController authController;

  const ProfileSettingsSection({super.key, required this.isDark, required this.authController});

  @override
  State<ProfileSettingsSection> createState() => _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState extends State<ProfileSettingsSection> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _nameExpanded = false;
  bool _nameLoading = false;
  String? _nameError;

  bool _passwordExpanded = false;
  bool _passwordLoading = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.authController.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Display name cannot be empty');
      return;
    }
    setState(() { _nameLoading = true; _nameError = null; });
    try {
      await ApiClient.instance.patch('/users/me', data: {'displayName': name});
      setState(() { _nameLoading = false; _nameExpanded = false; });
    } catch (e) {
      setState(() { _nameLoading = false; _nameError = 'Failed to update name'; });
    }
  }

  Future<void> _savePassword() async {
    final pwd = _passwordCtrl.text;
    if (pwd.isEmpty) {
      setState(() => _passwordError = 'Password cannot be empty');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }
    if (pwd != _confirmCtrl.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    setState(() { _passwordLoading = true; _passwordError = null; _passwordSuccess = null; });
    try {
      await ApiClient.instance.patch('/auth/password', data: {'password': pwd});
      _passwordCtrl.clear();
      _confirmCtrl.clear();
      setState(() {
        _passwordLoading = false;
        _passwordSuccess = 'Password updated';
        _passwordExpanded = false;
      });
    } catch (e) {
      setState(() { _passwordLoading = false; _passwordError = 'Failed to update password'; });
    }
  }

  String _initials(String? name, String email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<User?>>(
      stream: widget.authController.stream,
      initialData: widget.authController.state,
      builder: (_, snap) {
        final state = snap.data;
        final user = state is AsyncData<User?> ? state.data : widget.authController.currentUser;
        return user == null ? _buildUnauthenticated(context) : _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    final isDark = widget.isDark;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final initials = _initials(user.displayName, user.email);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                alignment: Alignment.center,
                child: user.photoUrl != null
                    ? ClipOval(child: Image.network(user.photoUrl!, width: 60, height: 60, fit: BoxFit.cover))
                    : Text(initials, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.displayName?.isNotEmpty == true ? user.displayName! : user.email.split('@').first,
                          style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        if (user.isPlus) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('PLUS', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(user.email, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        PaneSectionLabel('Account Information'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 0.5)),
          child: Column(
            children: [
              ProfileInfoField(label: 'Email address', value: user.email, isDark: isDark),
              Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: border),
              ProfileInfoField(label: 'Member since', value: _formatDate(user.createdAt), isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        PaneSectionLabel('Profile'),
        const SizedBox(height: 8),
        ProfileInlineEditCard(
          isDark: isDark,
          label: 'Display name',
          value: user.displayName?.isNotEmpty == true ? user.displayName! : 'Not set',
          expanded: _nameExpanded,
          onToggle: () => setState(() { _nameExpanded = !_nameExpanded; _nameError = null; }),
          child: _nameExpanded ? ProfileNameEditFields(
            controller: _nameCtrl,
            error: _nameError,
            loading: _nameLoading,
            isDark: isDark,
            onSave: _saveName,
            onCancel: () => setState(() { _nameExpanded = false; _nameError = null; }),
          ) : null,
        ),
        const SizedBox(height: 20),

        PaneSectionLabel('Security'),
        const SizedBox(height: 8),
        ProfileInlineEditCard(
          isDark: isDark,
          label: 'Password',
          value: _passwordSuccess ?? '••••••••',
          valueColor: _passwordSuccess != null ? AppColors.success : null,
          expanded: _passwordExpanded,
          onToggle: () => setState(() { _passwordExpanded = !_passwordExpanded; _passwordError = null; _passwordSuccess = null; }),
          child: _passwordExpanded ? ProfilePasswordEditFields(
            passwordCtrl: _passwordCtrl,
            confirmCtrl: _confirmCtrl,
            obscurePwd: _obscurePwd,
            obscureConfirm: _obscureConfirm,
            onTogglePwd: () => setState(() => _obscurePwd = !_obscurePwd),
            onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
            error: _passwordError,
            loading: _passwordLoading,
            isDark: isDark,
            onSave: _savePassword,
            onCancel: () => setState(() { _passwordExpanded = false; _passwordError = null; }),
          ) : null,
        ),
        const SizedBox(height: 20),

        PaneSectionLabel('Session'),
        const SizedBox(height: 8),
        PaneRow(
          isDark: isDark,
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          label: 'Sign Out',
          labelColor: AppColors.error,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.backgroundSecondary;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Account', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 0.5)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your account', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                    const SizedBox(height: 4),
                    Text("You're not logged in. Sign in to sync your data across devices.",
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  OutlineButton(label: 'Log in', isDark: isDark, onTap: () => LoginDialog.show(context)),
                  const SizedBox(width: 8),
                  OutlineButton(label: 'Sign up', isDark: isDark, onTap: () => LoginDialog.show(context, signUp: true), primary: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.h4),
        content: Text('You will be signed out of Keep Track.', style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async { Navigator.pop(context); await widget.authController.signOut(); },
            child: Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
