const _months = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String lastSyncedSubtitle(DateTime? lastSyncedAt) {
  if (lastSyncedAt == null) return 'No cloud backup yet';
  final local = lastSyncedAt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inSeconds < 60) return 'Last synced: just now';
  if (diff.inHours < 1) return 'Last synced: ${diff.inMinutes}m ago';
  if (diff.inDays < 1) return 'Last synced: ${diff.inHours}h ago';
  final day = '${local.day} ${_months[local.month]} ${local.year}';
  return 'Last synced: $day';
}
