class EventSummary {
  final String id;
  final String title;
  final String? description;
  final DateTime startsAtUtc;
  final DateTime? endsAtUtc;
  final String? locationName;
  final String? locationAddress;
  final int attendeeCount;
  final int? maxAttendees;
  final String organiserId;
  final String organiserName;
  final String? organiserImageUrl;
  final bool isAttending;
  final String posterUrl;

  const EventSummary({
    required this.id,
    required this.title,
    this.description,
    required this.startsAtUtc,
    this.endsAtUtc,
    this.locationName,
    this.locationAddress,
    required this.attendeeCount,
    this.maxAttendees,
    required this.organiserId,
    required this.organiserName,
    this.organiserImageUrl,
    required this.isAttending,
    required this.posterUrl,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      startsAtUtc: DateTime.parse(json['startsAt'] as String),
      endsAtUtc: json['endsAt'] != null
          ? DateTime.parse(json['endsAt'] as String)
          : null,
      locationName: json['locationName'] as String?,
      locationAddress: json['locationAddress'] as String?,
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      maxAttendees: (json['maxAttendees'] as num?)?.toInt(),
      organiserId: json['organiserId'].toString(),
      organiserName: (json['organiserName'] ?? '').toString(),
      organiserImageUrl: json['organiserImageUrl'] as String?,
      isAttending: json['isAttending'] as bool? ?? false,
      posterUrl: (json['posterUrl'] as String?) ?? '',
    );
  }

  bool get isFull =>
      maxAttendees != null && attendeeCount >= maxAttendees!;

  int? get spotsLeft =>
      maxAttendees != null ? maxAttendees! - attendeeCount : null;
}
