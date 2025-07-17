import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import '../services/caregiver_notification_service.dart';
import '../database/db_helper.dart';

/// NotificationManager class coordinates the scheduling of notifications
/// for medications and appointments based on database data
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  factory NotificationManager() => _instance;
  NotificationManager._();

  final NotificationService _notificationService = NotificationService();
  final CaregiverNotificationService _caregiverNotificationService = CaregiverNotificationService();
  final DBHelper _dbHelper = DBHelper();
  bool _isInitialized = false;

  /// Initialize the notification manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _notificationService.initialize();
    final permissionGranted = await _notificationService.requestPermissions();

    if (permissionGranted) {
      debugPrint('Notification permissions granted');
    } else {
      debugPrint('Notification permissions denied');
    }

    _isInitialized = true;
  }

  /// Show a test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();
    await _notificationService.showTestNotification();
  }

  /// Schedule all notifications for a user
  Future<void> scheduleAllNotifications(int userId) async {
    if (!_isInitialized) await initialize();

    await scheduleMedicationNotifications(userId);
    await scheduleAppointmentNotifications(userId);
  }

  /// Schedule notifications for all medications of a user
  Future<void> scheduleMedicationNotifications(int userId) async {
    if (!_isInitialized) await initialize();

    final medicationMaps = await _dbHelper.getMedications(userId);

    for (final medicationMap in medicationMaps) {
      final medicine = Medicine.fromMap(medicationMap);

      // Schedule medication reminder
      await _notificationService.scheduleMedicineReminder(medicine);

      // Schedule expiry alert if applicable
      if (medicine.isExpiringSoon && !medicine.isExpired) {
        await _notificationService.scheduleExpiryAlert(medicine);
      }

      // Show low stock alert if applicable
      if (medicine.isLowStock) {
        await _notificationService.scheduleLowStockAlert(medicine);
      }
    }
  }

  /// Schedule notifications for all appointments of a user
  Future<void> scheduleAppointmentNotifications(int userId) async {
    if (!_isInitialized) await initialize();

    final appointments = await _dbHelper.getAppointments(userId);
    debugPrint('Scheduling notifications for ${appointments.length} appointments');

    for (final appointment in appointments) {
      final appointmentId = appointment['appointment_id'] as int;
      final doctorName = appointment['doctor_name'] as String;
      final dateStr = appointment['date'] as String;
      final timeStr = appointment['time'] as String;
      final location = appointment['location'] as String? ?? 'Not specified';

      try {
        // Parse appointment date and time
        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');

        DateTime appointmentTime;
        if (dateParts.length == 3) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          int hour = 0;
          int minute = 0;

          // Handle different time formats (12h and 24h)
          if (timeStr.contains('AM') || timeStr.contains('PM')) {
            // 12-hour format (e.g. "9:00 AM")
            final timeComponents = timeStr.split(' ');
            final hourMin = timeComponents[0].split(':');
            hour = int.parse(hourMin[0]);
            minute = int.parse(hourMin[1]);

            if (timeComponents[1] == 'PM' && hour < 12) {
              hour += 12;
            } else if (timeComponents[1] == 'AM' && hour == 12) {
              hour = 0;
            }
          } else if (timeParts.length >= 2) {
            // 24-hour format (e.g. "14:30")
            hour = int.parse(timeParts[0]);
            minute = int.parse(timeParts[1]);
          }

          appointmentTime = DateTime(year, month, day, hour, minute);
          final now = DateTime.now();

          // Only schedule future appointments
          if (appointmentTime.isAfter(now)) {
            debugPrint('Scheduling notification for appointment with Dr. $doctorName on $dateStr at $timeStr');

            // Schedule 1 day before
            final oneDayBefore = appointmentTime.subtract(const Duration(days: 1));
            if (oneDayBefore.isAfter(now)) {
              await _notificationService.showAppointmentReminder(
                appointmentId,
                doctorName,
                'Upcoming Appointment Tomorrow',
                'You have an appointment with Dr. $doctorName tomorrow at ${formatTime(timeStr)} at $location',
                oneDayBefore.add(const Duration(hours: 9)), // Notify at 9 AM
              );

              // Also notify caregiver one day before
              await _caregiverNotificationService.createAppointmentReminderNotification(
                userId: userId,
                appointmentId: appointmentId,
                doctorName: doctorName,
                appointmentDate: dateStr,
                appointmentTime: formatTime(timeStr),
                location: location,
                isDayBefore: true,
              );

              debugPrint('Scheduled 1-day reminder for appointment with Dr. $doctorName');
            }

            // Schedule 4 hours before
            final fourHoursBefore = appointmentTime.subtract(const Duration(hours: 4));
            if (fourHoursBefore.isAfter(now)) {
              await _notificationService.showAppointmentReminder(
                appointmentId + 1000, // Use different ID for this notification
                doctorName,
                'Appointment in 4 hours',
                'You have an appointment with Dr. $doctorName in 4 hours at $location',
                fourHoursBefore,
              );

              // Also notify caregiver 4 hours before
              await _caregiverNotificationService.createAppointmentReminderNotification(
                userId: userId,
                appointmentId: appointmentId,
                doctorName: doctorName,
                appointmentDate: dateStr,
                appointmentTime: formatTime(timeStr),
                location: location,
                isDayBefore: false,
              );

              debugPrint('Scheduled 4-hour reminder for appointment with Dr. $doctorName');
            }
          } else {
            debugPrint('Skipping past appointment with Dr. $doctorName on $dateStr at $timeStr');
          }
        }
      } catch (e) {
        debugPrint('Error scheduling appointment notification: $e');
        debugPrint('Problem with appointment: $appointmentId, date: $dateStr, time: $timeStr');
      }
    }
    debugPrint('Finished scheduling appointment notifications');
  }

  /// Schedule notifications for a specific medication
  Future<void> scheduleMedicationNotification(Medicine medicine) async {
    if (!_isInitialized) await initialize();

    await _notificationService.scheduleMedicineReminder(medicine);

    if (medicine.isExpiringSoon && !medicine.isExpired) {
      await _notificationService.scheduleExpiryAlert(medicine);
    }

    if (medicine.isLowStock) {
      await _notificationService.scheduleLowStockAlert(medicine);
    }
  }

  /// Check for missed medications to notify caregivers
  Future<void> checkMissedMedications() async {
    await _caregiverNotificationService.checkMissedMedications();
  }

  /// Cancel all notifications for a medication
  Future<void> cancelMedicationNotifications(String medicineId) async {
    await _notificationService.cancelNotificationsForMedicine(medicineId);
  }

  /// Cancel all notifications for an appointment
  Future<void> cancelAppointmentNotifications(int appointmentId) async {
    try {
      // Cancel the day-before notification
      await _notificationService.cancelNotification('appointment_$appointmentId'.hashCode);

      // Cancel the 4-hour notification (using the offset ID pattern from the existing code)
      await _notificationService.cancelNotification('appointment_${appointmentId + 1000}'.hashCode);

      debugPrint('Cancelled notifications for appointment $appointmentId');
    } catch (e) {
      debugPrint('Error cancelling appointment notifications: $e');
    }
  }

  /// Cancel all notifications for the user
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Helper method to format time string
  String formatTime(String timeStr) {
    try {
      // If it's already in 12-hour format, return as is
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        return timeStr;
      }

      // Convert from 24-hour to 12-hour format
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return timeStr;
    }
  }
}