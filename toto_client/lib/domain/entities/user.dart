import 'package:equatable/equatable.dart';

/// Entité User (domain layer)
class User extends Equatable {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String? photoUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    this.photoUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        fullName,
        email,
        photoUrl,
        isVerified,
        isActive,
        createdAt,
      ];

  User copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? email,
    String? photoUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
