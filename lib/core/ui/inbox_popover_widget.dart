import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/config/app_info.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/inbox/domain/controller/inbox_controller.dart';
import 'package:keep_track/features/inbox/domain/entities/announcement.dart';
import 'package:url_launcher/url_launcher.dart';

class InboxPopoverWidget extends StatelessWidget {
  final LayerLink link;
  final bool isDark;
  final VoidCallback onDismiss;

  const InboxPopoverWidget({
    super.key,
    required this.link,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final controller = locator.get<InboxController>();
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.3)
        : AppColors.border.withValues(alpha: 0.7);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 480),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                    child: Row(
                      children: [
                        Text(
                          'Inbox',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.primaryForeground
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        StreamBuilder<AsyncState<List<Announcement>>>(
                          stream: controller.stream,
                          initialData: controller.state,
                          builder: (_, __) {
                            if (controller.unreadCount == 0) return const SizedBox.shrink();
                            return TextButton(
                              onPressed: controller.markAllAsRead,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Mark all read',
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.accent),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: borderColor),
                  StreamBuilder<AsyncState<List<Announcement>>>(
                    stream: controller.stream,
                    initialData: controller.state,
                    builder: (_, snapshot) {
                      final s = snapshot.data;
                      if (s is AsyncLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (s is AsyncError) {
                        return _EmptyState(
                          isDark: isDark,
                          icon: Icons.error_outline_rounded,
                          message: 'Could not load messages',
                        );
                      }
                      final announcements =
                          s is AsyncData<List<Announcement>> ? s.data : <Announcement>[];
                      if (announcements.isEmpty) {
                        return _EmptyState(
                          isDark: isDark,
                          icon: Icons.inbox_outlined,
                          message: 'No messages',
                        );
                      }
                      const _limit = 10;
                      final visible = announcements.take(_limit).toList();
                      final overflow = announcements.length - visible.length;
                      return Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, thickness: 0.5, color: borderColor),
                                itemBuilder: (_, i) => _AnnouncementTile(
                                  announcement: visible[i],
                                  isDark: isDark,
                                  isRead: controller.isRead(visible[i].id),
                                  onMarkRead: () => controller.markAsRead(visible[i].id),
                                ),
                              ),
                            ),
                            if (overflow > 0) ...[
                              Divider(height: 1, thickness: 0.5, color: borderColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  '+$overflow more',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;

  const _EmptyState({required this.isDark, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 10),
            Text(message,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final bool isDark;
  final bool isRead;
  final VoidCallback onMarkRead;

  const _AnnouncementTile({
    required this.announcement,
    required this.isDark,
    required this.isRead,
    required this.onMarkRead,
  });

  Color _typeColor(AnnouncementType type) => switch (type) {
        AnnouncementType.info => AppColors.info,
        AnnouncementType.warning => AppColors.warning,
        AnnouncementType.release => AppColors.success,
        AnnouncementType.update => AppColors.accent,
      };

  String _typeLabel(AnnouncementType type) => switch (type) {
        AnnouncementType.info => 'Info',
        AnnouncementType.warning => 'Warning',
        AnnouncementType.release => 'Release',
        AnnouncementType.update => 'Update',
      };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(announcement.type);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => onMarkRead(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRead ? Colors.transparent : AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(announcement.type),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(announcement.publishedAt),
                        style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    announcement.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    announcement.body,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (announcement.ctaUrl != null) ...[
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          onMarkRead();
                          launchUrl(Uri.parse(AppInfo.announcementsUrl));
                        },
                        child: Text(
                          announcement.ctaLabel ?? 'Read more',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
