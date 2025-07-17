// models/notification_model.dart
import 'package:flutter/material.dart';

enum NotificationType {
  missedMedication,
  medicationReminder,
  appointment,
  medicineStock,
  medicineExpiry,
  sos,
  healthUpdate,
  system,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  // Optional fields for specific notification types
  Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.additionalData,
  });

  // Factory method to create from JSON (for future use with Firebase/SQLite)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['time'] as String),
      type: NotificationType.values.firstWhere(
            (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Method to convert to JSON (for future use with Firebase/SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }
}