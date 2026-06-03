import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/data/services/auth_service.dart';
import 'package:keep_track/features/notifications/presentation/screens/notification_settings_screen.dart';

class AuthSettingsScreen extends StatefulWidget {
  const AuthSettingsScreen({super.key});

  @override
  State<AuthSettingsScreen> createState() => _AuthSettingsScreenState();
}

class _AuthSettingsScreenState extends State<AuthSettingsScreen> {
  final _authService = locator.get<AuthService>();

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
    _nameCtrl.text = _authService.currentUser?.displayName ?? '';
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
        _passwordSuccess = 'Password updated successfully';
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
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _authService.currentUser;
    final displayName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : (user != null ? user.email.split('@').first : 'User');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Account', style: AppTextStyles.h4.copyWith(
          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
        ),
      ),
      body: ListView(
        children: [
          _ProfileBanner(
            initials: _initials(user?.displayName, user?.email ?? ''),
            displayName: displayName,
            email: user?.email ?? '',
            isPlus: user?.isPlus ?? false,
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Account Information'),
                const SizedBox(height: 8),
                _InfoCard(isDark: isDark, fields: [
                  _FieldData('Email address', user?.email ?? '–'),
                  _FieldData('Member since', user != null ? _formatDate(user.createdAt) : '–'),
                ]),
                const SizedBox(height: 24),

                _SectionLabel('Profile'),
                const SizedBox(height: 8),
                _EditableSection(
                  isDark: isDark,
                  label: 'Display name',
                  value: user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Not set',
                  expanded: _nameExpanded,
                  onEdit: () => setState(() {
                    _nameExpanded = !_nameExpanded;
                    _nameError = null;
                  }),
                  expandedChild: _nameExpanded
                      ? _NameEditForm(
                          controller: _nameCtrl,
                          error: _nameError,
                          loading: _nameLoading,
                          isDark: isDark,
                          onSave: _saveName,
                          onCancel: () => setState(() {
                            _nameExpanded = false;
                            _nameError = null;
                          }),
                        )
                      : null,
                ),
                const SizedBox(height: 24),

                _SectionLabel('Security'),
                const SizedBox(height: 8),
                _EditableSection(
                  isDark: isDark,
                  label: 'Password',
                  value: _passwordSuccess ?? '••••••••',
                  valueColor: _passwordSuccess != null ? AppColors.success : null,
                  expanded: _passwordExpanded,
                  onEdit: () => setState(() {
                    _passwordExpanded = !_passwordExpanded;
                    _passwordError = null;
                    _passwordSuccess = null;
                  }),
                  expandedChild: _passwordExpanded
                      ? _PasswordEditForm(
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
                          onCancel: () => setState(() {
                            _passwordExpanded = false;
                            _passwordError = null;
                          }),
                        )
                      : null,
                ),

                if (PlatformNotificationHelper.instance.isSupportedPlatform) ...[
                  const SizedBox(height: 24),
                  _SectionLabel('Notifications'),
                  const SizedBox(height: 8),
                  _TappableCard(
                    isDark: isDark,
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.info,
                    label: 'Push Notifications',
                    subtitle: 'Reminders for tasks and finances',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _ProfileBanner extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final bool isPlus;

  const _ProfileBanner({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.isPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              if (isPlus) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PLUS',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      );
}


class _FieldData {
  final String label;
  final String value;
  const _FieldData(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<_FieldData> fields;

  const _InfoCard({required this.isDark, required this.fields});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fields[i].label.toUpperCase(),
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fields[i].value,
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.primaryForeground : AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (i < fields.length - 1)
              Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: border),
          ],
        ],
      ),
    );
  }
}


class _EditableSection extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool expanded;
  final VoidCallback onEdit;
  final Widget? expandedChild;

  const _EditableSection({
    required this.isDark,
    required this.label,
    required this.value,
    required this.expanded,
    required this.onEdit,
    this.valueColor,
    this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: valueColor ?? (isDark ? AppColors.primaryForeground : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        expanded ? 'Cancel' : 'Edit',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                            color: expanded ? AppColors.textSecondary : AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (expandedChild != null) ...[
            Divider(height: 1, thickness: 0.5, color: border),
            expandedChild!,
          ],
        ],
      ),
    );
  }
}


class _NameEditForm extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _NameEditForm({
    required this.controller,
    required this.error,
    required this.loading,
    required this.isDark,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(controller: controller, label: 'New display name', isDark: isDark, error: error),
          const SizedBox(height: 12),
          _FormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}


class _PasswordEditForm extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePwd;
  final bool obscureConfirm;
  final VoidCallback onTogglePwd;
  final VoidCallback onToggleConfirm;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _PasswordEditForm({
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePwd,
    required this.obscureConfirm,
    required this.onTogglePwd,
    required this.onToggleConfirm,
    required this.error,
    required this.loading,
    required this.isDark,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(
            controller: passwordCtrl,
            label: 'New password',
            obscure: obscurePwd,
            onToggleObscure: onTogglePwd,
            isDark: isDark,
            error: error,
          ),
          const SizedBox(height: 10),
          _FormField(
            controller: confirmCtrl,
            label: 'Confirm new password',
            obscure: obscureConfirm,
            onToggleObscure: onToggleConfirm,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _FormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}


class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? error;
  final bool isDark;

  const _FormField({
    required this.controller,
    required this.label,
    required this.isDark,
    this.obscure = false,
    this.onToggleObscure,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border;
    final textColor = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.dmSans(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
        ],
      ],
    );
  }
}

class _FormActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isDark;

  const _FormActions({required this.loading, required this.onSave, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}


class _TappableCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TappableCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
