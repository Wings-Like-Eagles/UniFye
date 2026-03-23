class SwipeCandidate {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final List<String> interests;
  final String? imageUrl;

  SwipeCandidate({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.interests,
    this.imageUrl,
  });

  factory SwipeCandidate.fromJson(Map<String, dynamic> json) {
    final dynamic interestsJson = json['interests'];
    final interests = interestsJson is List
        ? interestsJson.map((item) => item.toString()).toList()
        : <String>[];

    return SwipeCandidate(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      interests: interests,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  String get fullName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Unknown User' : fullName;
  }
}
