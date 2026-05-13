class UserResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final DateTime? dateOfBirth;
  final List<String> interests;
  final String? imageUrl;
  final DateTime? createdAtUtc;

  const UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.dateOfBirth,
    required this.interests,
    this.imageUrl,
    this.createdAtUtc,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    gender: json['gender'] as String,
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.tryParse(json['dateOfBirth'] as String)
        : null,
    interests: (json['interests'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ??
        [],
    imageUrl: json['imageUrl'] as String?,
    createdAtUtc: json['createdAtUtc'] != null
        ? DateTime.tryParse(json['createdAtUtc'] as String)
        : null,
  );
}
