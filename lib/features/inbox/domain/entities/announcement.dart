enum AnnouncementType { info, warning, release, update }

class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementType type;
  final String? ctaLabel;
  final String? ctaUrl;
  final DateTime publishedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.ctaLabel,
    this.ctaUrl,
    required this.publishedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] ?? json['_id']) as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: AnnouncementType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => AnnouncementType.info,
      ),
      ctaLabel: json['ctaLabel'] as String?,
      ctaUrl: json['ctaUrl'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }
}
