import 'package:flutter/material.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final int stock;
  final DateTime expiryDate;
  final TimeOfDay? timeOfDay;
  final Color color;
  final IconData icon;
  final bool isTaken;
  final String? notes; // This is now for actual notes content
  final String scheduleType; // 'daily', 'weekly', or 'monthly'

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.stock,
    required this.expiryDate,
    this.timeOfDay,
    this.notes,
    this.color = Colors.blue,
    this.icon = Icons.medication,
    this.isTaken = false,
    this.scheduleType = 'daily',
  });

  // Add a copyWith method to create a new instance with updated values
  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    int? stock,
    DateTime? expiryDate,
    TimeOfDay? timeOfDay,
    String? notes,
    Color? color,
    IconData? icon,
    bool? isTaken,
    String? scheduleType,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      stock: stock ?? this.stock,
      expiryDate: expiryDate ?? this.expiryDate,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isTaken: isTaken ?? this.isTaken,
      scheduleType: scheduleType ?? this.scheduleType,
    );
  }

  // Convert Medicine to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      'medication_id': int.tryParse(id), // Convert string ID to int
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'stock': stock,
      'date': expiryDate.toIso8601String(), // Match your database column name
      'reminder_time': timeOfDay != null
          ? '${timeOfDay!.hour.toString().padLeft(2, '0')}:${timeOfDay!.minute.toString().padLeft(2, '0')}'
          : null, // Format time as string
      'taken': isTaken ? 1 : 0, // Convert boolean to integer
      'schedule_type': scheduleType,
      'notes': notes, // Store the actual user notes text directly
    };
  }

  // Factory to create a Medicine from a database map
  factory Medicine.fromMap(Map<String, dynamic> map) {
    // Parse time string to TimeOfDay
    TimeOfDay? timeOfDay;
    final timeString = map['reminder_time'] as String? ?? '';
    if (timeString.isNotEmpty) {
      final timeParts = timeString.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour != null && minute != null) {
          timeOfDay = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    // Parse the date string
    DateTime expiryDate;
    try {
      expiryDate = DateTime.parse(map['date'] as String);
    } catch (e) {
      // Use a default expiry date if parsing fails
      expiryDate = DateTime.now().add(const Duration(days: 365));
    }

    // Capture the actual notes text
    final notes = map['notes'] as String?;

    return Medicine(
      id: map['medication_id'].toString(), // Convert int to string
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      stock: map['stock'] ?? 0,
      expiryDate: expiryDate,
      timeOfDay: timeOfDay,
      notes: notes, // Store the actual notes
      color: Colors.blue, // Use default app colors instead of storing in DB
      icon: Icons.medication, // Use default icon
      isTaken: (map['taken'] as int?) == 1, // Convert int to boolean
      scheduleType: map['schedule_type'] as String? ?? 'daily',
    );
  }

  // Helper method to parse TimeOfDay from string
  static TimeOfDay? parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    final parts = timeString.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  // Utility getters
  bool get isLowStock => stock < 10;

  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  bool get isExpired {
    final now = DateTime.now();
    return expiryDate.isBefore(now);
  }

  // Simplified next scheduled time
  DateTime? get nextScheduledTime {
    if (timeOfDay == null) return null;
    final now = DateTime.now();

    switch (scheduleType) {
      case 'daily':
      // Daily schedule - check for today or tomorrow
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );

        // If the scheduled time for today has passed, return tomorrow's time
        if (scheduledTime.isBefore(now)) {
          return scheduledTime.add(const Duration(days: 1));
        }
        return scheduledTime;

      case 'weekly':
      // Weekly schedule - simple implementation, just set to next week
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );

        // If today's time has passed, set to next week
        if (scheduledTime.isBefore(now)) {
          return scheduledTime.add(const Duration(days: 7));
        }
        return scheduledTime;

      case 'monthly':
      // Monthly schedule - simple implementation, set to next month
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );

        // Set to next month
        if (scheduledTime.isBefore(now)) {
          // Move to next month
          int nextMonth = now.month + 1;
          int year = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            year++;
          }
          return DateTime(
            year,
            nextMonth,
            1, // Use first day of next month
            timeOfDay!.hour,
            timeOfDay!.minute,
          );
        }
        return scheduledTime;

      default:
      // Default daily behavior
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay!.hour,
          timeOfDay!.minute,
        );

        if (scheduledTime.isBefore(now)) {
          return scheduledTime.add(const Duration(days: 1));
        }
        return scheduledTime;
    }
  }

  // Format time of day
  String get formattedTime {
    if (timeOfDay == null) return 'Not set';

    final hour = timeOfDay!.hour;
    final minute = timeOfDay!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$formattedHour:$minute $period';
  }

  // Simplified schedule description
  String get scheduleDescription {
    switch (scheduleType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Custom schedule';
    }
  }
}