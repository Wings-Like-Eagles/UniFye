import 'package:unifye/features/profile/models/user_response.dart';

class ProfileState {
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final DateTime? dateOfBirth;
  final List<String> interests;
  final String? imageUrl;

  // Stats — replace with real endpoint values once available
  final int matches;
  final int likes;
  final int views;

  const ProfileState({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.dateOfBirth,
    required this.interests,
    this.imageUrl,
    this.matches = 0,
    this.likes = 0,
    this.views = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayInitial =>
      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  factory ProfileState.initial() => const ProfileState(
    firstName: '',
    lastName: '',
    email: '',
    gender: '',
    interests: [],
  );

  factory ProfileState.fromResponse(UserResponse r) => ProfileState(
    firstName: r.firstName,
    lastName: r.lastName,
    email: r.email,
    gender: r.gender,
    dateOfBirth: r.dateOfBirth,
    interests: r.interests.toList(),
    imageUrl: r.imageUrl,
    matches: 0,
    likes: 0,
    views: 0,
  );

  ProfileState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? interests,
    String? imageUrl,
    bool clearImage = false,
    int? matches,
    int? likes,
    int? views,
  }) {
    return ProfileState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      interests: interests ?? this.interests,
      imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
      matches: matches ?? this.matches,
      likes: likes ?? this.likes,
      views: views ?? this.views,
    );
  }
}