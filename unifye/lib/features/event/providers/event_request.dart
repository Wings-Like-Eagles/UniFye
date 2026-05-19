class CreateEventRequest {
  final String title;
  final String? description;
  final DateTime startsAtUtc;
  final DateTime? endsAtUtc;
  final String? locationName;
  final String? locationAddress;
  final int? maxAttendees;

  const CreateEventRequest({
    required this.title,
    this.description,
    required this.startsAtUtc,
    this.endsAtUtc,
    this.locationName,
    this.locationAddress,
    this.maxAttendees,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'startsAtUtc': startsAtUtc.toUtc().toIso8601String(),
    'endsAtUtc': endsAtUtc?.toUtc().toIso8601String(),
    'locationName': locationName,
    'locationAddress': locationAddress,
    'maxAttendees': maxAttendees,
  };
}

class UpdateEventRequest {
  final String title;
  final String? description;
  final DateTime startsAtUtc;
  final DateTime? endsAtUtc;
  final String? locationName;
  final String? locationAddress;
  final int? maxAttendees;

  const UpdateEventRequest({
    required this.title,
    this.description,
    required this.startsAtUtc,
    this.endsAtUtc,
    this.locationName,
    this.locationAddress,
    this.maxAttendees,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'startsAtUtc': startsAtUtc.toUtc().toIso8601String(),
    'endsAtUtc': endsAtUtc?.toUtc().toIso8601String(),
    'locationName': locationName,
    'locationAddress': locationAddress,
    'maxAttendees': maxAttendees,
  };
}

class SendChatMessageRequest {
  final String content;

  const SendChatMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {'content': content};
}
