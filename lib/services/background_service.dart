import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import '../services/caregiver_notification_service.dart';
import '../database/db_helper.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._();
  factory BackgroundService() => _instance;
  BackgroundService._();

  final NotificationService _notificationService = NotificationService();
  final DBHelper _dbHelper = DBHelper();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Initialize notification service
    await _notificationService.initialize();

    // Configure background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: 'medication_reminders',
        initialNotificationTitle: 'Medication Reminder Service',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    final notificationService = NotificationService();
    await notificationService.initialize();

    final dbHelper = DBHelper();
    final caregiverNotificationService = CaregiverNotificationService();

    // If using Android, setup as a foreground service
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Set up periodic check for upcoming medications and appointments
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _checkUpcomingMedications(dbHelper, notificationService);
      await _checkUpcomingAppointments(dbHelper, notificationService);

      // Check for missed medications every 15 minutes
      await _checkMissedMedications(caregiverNotificationService);
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static Future<void> _checkUpcomingMedications(
      DBHelper dbHelper, NotificationService notificationService) async {
    // Get all users who have medications
    final users = await dbHelper.getUsers();

    for (final user in users) {
      final userId = user['user_id'] as int;
      final medications = await dbHelper.getMedications(userId);

      for (final med in medications) {
        final medicine = Medicine.fromMap(med);

        // Check if notification should be scheduled
        final nextScheduledTime = medicine.nextScheduledTime;
        if (nextScheduledTime != null) {
          final now = DateTime.now();
          final difference = nextScheduledTime.difference(now).inMinutes;

          // If medication is due within 30 minutes, schedule notification
          if (difference >= 0 && difference <= 30) {
            await notificationService.scheduleMedicineReminder(medicine);
          }
        }
      }
    }
  }

  static Future<void> _checkUpcomingAppointments(
      DBHelper dbHelper, NotificationService notificationService) async {
    // Get all users who have appointments
    final users = await dbHelper.getUsers();

    for (final user in users) {
      final userId = user['user_id'] as int;
      final appointments = await dbHelper.getAppointments(userId);

      for (final appointment in appointments) {
        final dateStr = appointment['date'] as String;
        final timeStr = appointment['time'] as String;

        try {
          // Parse date and time
          final date = DateTime.parse(dateStr);
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          final appointmentDateTime = DateTime(
              date.year, date.month, date.day, hour, minute);

          final now = DateTime.now();
          final difference = appointmentDateTime.difference(now).inMinutes;

          // If appointment is due within 60 minutes, send notification
          if (difference >= 0 && difference <= 60) {
            final doctorName = appointment['doctor_name'] as String;
            final location = appointment['location'] as String? ?? 'Not specified';

            await notificationService.showAppointmentReminder(
              appointment['appointment_id'] as int,
              doctorName,
              'Appointment in ${difference ~/ 60} hour(s) and ${difference % 60} minutes',
              'Location: $location',
              appointmentDateTime,
            );
          }
        } catch (e) {
          debugPrint('Error parsing appointment date/time: $e');
        }
      }
    }
  }

  // New method to check for missed medications and notify caregivers
  static Future<void> _checkMissedMedications(
      CaregiverNotificationService caregiverNotificationService) async {
    await caregiverNotificationService.checkMissedMedications();
  }
}