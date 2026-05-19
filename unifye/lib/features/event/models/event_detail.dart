class EventAttendee {
  final String id;
  final String name;
  final String? imageUrl;

  const EventAttendee({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class EventDetail {
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
  final List<EventAttendee> attendees;

  const EventDetail({
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
    required this.attendees,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAtUtc: DateTime.parse(json['startsAt'] as String),   // was 'startsAtUtc'
      endsAtUtc:   json['endsAt'] != null
          ? DateTime.parse(json['endsAt'] as String) // was 'endsAtUtc'
          : null,
      locationName: json['locationName'] as String?,
      locationAddress: json['locationAddress'] as String?,
      attendeeCount: json['attendeeCount'] as int,
      maxAttendees: json['maxAttendees'] as int?,
      organiserId: json['organiserId'] as String,
      organiserName: json['organiserName'] as String,
      organiserImageUrl: json['organiserImageUrl'] as String?,
      isAttending: json['isAttending'] as bool,
      attendees: (json['attendees'] as List<dynamic>? ?? [])
          .map((a) => EventAttendee.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isFull =>
      maxAttendees != null && attendeeCount >= maxAttendees!;

  int? get spotsLeft =>
      maxAttendees != null ? maxAttendees! - attendeeCount : null;
}




// class EventSummary {
//   final String id;
//   final String title;
//   final String? description;
//   final DateTime startsAtUtc;
//   final DateTime? endsAtUtc;
//   final String? locationName;
//   final String? locationAddress;
//   final int attendeeCount;
//   final int? maxAttendees;
//   final String organiserId;
//   final String organiserName;
//   final String? organiserImageUrl;
//   final bool isAttending;

//   const EventSummary({
//     required this.id,
//     required this.title,
//     this.description,
//     required this.startsAtUtc,
//     this.endsAtUtc,
//     this.locationName,
//     this.locationAddress,
//     required this.attendeeCount,
//     this.maxAttendees,
//     required this.organiserId,
//     required this.organiserName,
//     this.organiserImageUrl,
//     required this.isAttending,
//   });

//   factory EventSummary.fromJson(Map<String, dynamic> json) {
//     return EventSummary(
//       id: json['id'],
//       title: json['title'],
//       description: json['description'],
//       startsAtUtc: DateTime.parse(json['startsAtUtc']),
//       endsAtUtc: json['endsAtUtc'] != null ? DateTime.parse(json['endsAtUtc']) : null,
//       locationName: json['locationName'],
//       locationAddress: json['locationAddress'],
//       attendeeCount: json['attendeeCount'],
//       maxAttendees: json['maxAttendees'],
//       organiserId: json['organiserId'],
//       organiserName: json['organiserName'],
//       organiserImageUrl: json['organiserImageUrl'],
//       isAttending: json['isAttending'],
//     );
//   }
// }
