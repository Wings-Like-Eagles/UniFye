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
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAtUtc: DateTime.parse(json['startsAtUtc'] as String),
      endsAtUtc: json['endsAtUtc'] != null
          ? DateTime.parse(json['endsAtUtc'] as String)
          : null,
      locationName: json['locationName'] as String?,
      locationAddress: json['locationAddress'] as String?,
      attendeeCount: json['attendeeCount'] as int,
      maxAttendees: json['maxAttendees'] as int?,
      organiserId: json['organiserId'] as String,
      organiserName: json['organiserName'] as String,
      organiserImageUrl: json['organiserImageUrl'] as String?,
      isAttending: json['isAttending'] as bool,
    );
  }

  bool get isFull =>
      maxAttendees != null && attendeeCount >= maxAttendees!;

  int? get spotsLeft =>
      maxAttendees != null ? maxAttendees! - attendeeCount : null;
}
