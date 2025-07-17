// models/user.dart
import 'package:flutter/foundation.dart';

class User {
  final int userId;
  final String firstName;
  final String lastName;
  final int age;
  final String phoneNumber;
  final String email;
  final String role;
  final int? caregiverId;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? address;
  final String? relationship;
  final String? chronicConditions;
  final String? allergies;
  final String createdAt;
  final String lastSyncedAt;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.caregiverId,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
    this.relationship,
    this.chronicConditions,
    this.allergies,
    required this.createdAt,
    required this.lastSyncedAt,
  });

  // Full name computed property
  String get fullName => '$firstName $lastName';

  // Check if user is elderly
  bool get isElderly => role == 'elderly';

  // Check if user is caregiver
  bool get isCaregiver => role == 'caregiver';

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Create a User from a Map (for database operations)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      age: map['age'] ?? 0,
      phoneNumber: map['phone_number'],
      email: map['email'],
      role: map['role'],
      caregiverId: map['caregiver_id'],
      dateOfBirth: map['date_of_birth'],
      gender: map['gender'],
      bloodGroup: map['blood_group'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      address: map['address'],
      relationship: map['relationship'],
      chronicConditions: map['chronic_conditions'],
      allergies: map['allergies'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      lastSyncedAt: map['last_synced_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  // Convert User to a Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
      'phone_number': phoneNumber,
      'email': email,
      'role': role,
      'caregiver_id': caregiverId,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'address': address,
      'relationship': relationship,
      'chronic_conditions': chronicConditions,
      'allergies': allergies,
      'created_at': createdAt,
      'last_synced_at': lastSyncedAt,
    };
  }

  // Create a copy of the user with updated fields
  User copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    int? age,
    String? phoneNumber,
    String? email,
    String? role,
    int? caregiverId,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? relationship,
    String? chronicConditions,
    String? allergies,
    String? createdAt,
    String? lastSyncedAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      caregiverId: caregiverId ?? this.caregiverId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      address: address ?? this.address,
      relationship: relationship ?? this.relationship,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return 'User(userId: $userId, firstName: $firstName, lastName: $lastName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.userId == userId &&
        other.email == email;
  }

  @override
  int get hashCode => userId.hashCode ^ email.hashCode;
}