import 'package:flutter/material.dart';

enum NotificationType {
  missedMedication,
  upcomingAppointment,
  lowStock,
  expiringMedication,
  other
}

class CaregiverNotification {
  final int id;
  final int userId;
  final int? caregiverId;
  final int? medicationId;
  final int? appointmentId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final double? sosLatitude;
  final double? sosLongitude;

  const CaregiverNotification({
    required this.id,
    required this.userId,
    this.caregiverId,
    this.medicationId,
    this.appointmentId,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.sosLatitude,
    this.sosLongitude,
  });

  // Factory to create a CaregiverNotification from a database map
  factory CaregiverNotification.fromMap(Map<String, dynamic> map) {
    return CaregiverNotification(
      id: map['notification_id'] as int,
      userId: map['user_id'] as int,
      caregiverId: map['caregiver_id'] as int?,
      medicationId: map['medication_id'] as int?,
      appointmentId: map['appointment_id'] as int?,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['status'] as String) == 'Read',
      sosLatitude: map['sos_latitude'] as double?,
      sosLongitude: map['sos_longitude'] as double?,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'notification_id': id,
      'user_id': userId,
      'caregiver_id': caregiverId,
      'medication_id': medicationId,
      'appointment_id': appointmentId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'status': isRead ? 'Read' : 'Unread',
      'sos_latitude': sosLatitude,
      'sos_longitude': sosLongitude,
    };
  }

  // Updated 'type' getter in CaregiverNotification class
  NotificationType get type {
    // Check for specific keywords in the message to determine type
    final String normalizedMessage = message.toLowerCase();

    if (appointmentId != null || normalizedMessage.contains('appointment')) {
      return NotificationType.upcomingAppointment;
    } else if (medicationId != null && (normalizedMessage.contains('missed') || normalizedMessage.contains('not taken'))) {
      return NotificationType.missedMedication;
    } else if (normalizedMessage.contains('low stock') || normalizedMessage.contains('running low')) {
      return NotificationType.lowStock;
    } else if (normalizedMessage.contains('expir')) {
      return NotificationType.expiringMedication;
    } else {
      return NotificationType.other;
    }
  }

  // Get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.missedMedication:
        return Icons.medication_outlined;
      case NotificationType.upcomingAppointment:
        return Icons.calendar_today;
      case NotificationType.lowStock:
        return Icons.inventory;
      case NotificationType.expiringMedication:
        return Icons.warning_amber;
      case NotificationType.other:
        return Icons.notification_important;
    }
  }

  // Get color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.missedMedication:
        return Colors.red;
      case NotificationType.upcomingAppointment:
        return Colors.blue;
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.expiringMedication:
        return Colors.amber;
      case NotificationType.other:
        return Colors.grey;
    }
  }

  // Format creation date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }
}