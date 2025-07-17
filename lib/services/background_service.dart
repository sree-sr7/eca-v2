import 'dart:async';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import '../services/caregiver_notification_service.dart';
import '../database/db_helper.dart';

/// Background service for handling medication and appointment reminders
/// Uses WorkManager for reliable background task execution with proper entry-point annotations
class BackgroundReminderService {
  static const String taskName = "medication_reminder_task";
  static const String _uniqueTaskName = "periodic_medication_check";

  static final BackgroundReminderService _instance =
      BackgroundReminderService._();
  factory BackgroundReminderService() => _instance;
  BackgroundReminderService._();

  /// Initialize the background service with proper platform configurations
  Future<void> initialize() async {
    try {
      // Platform-specific initialization
      await _initializePlatformSpecific();

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode, // Use Flutter's debug mode detection
      );

      // Schedule periodic task to run every 15 minutes
      await schedulePeriodicTask();

      debugPrint('BackgroundReminderService initialized successfully');
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Platform-specific initialization for Android and iOS
  Future<void> _initializePlatformSpecific() async {
    try {
      if (Platform.isAndroid) {
        // Android-specific configuration
        debugPrint('Configuring background service for Android');
        // Additional Android-specific setup can be added here
      } else if (Platform.isIOS) {
        // iOS-specific configuration
        debugPrint('Configuring background service for iOS');
        // Additional iOS-specific setup can be added here
      }
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Schedule periodic background task for medication and appointment checks
  Future<void> schedulePeriodicTask() async {
    try {
      // Cancel existing tasks first to avoid duplicates
      await Workmanager().cancelByUniqueName(_uniqueTaskName);

      await Workmanager().registerPeriodicTask(
        _uniqueTaskName,
        taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(seconds: 30),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('Periodic background task scheduled successfully');
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('All background tasks cancelled');
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Cancel specific background task
  Future<void> cancelTask() async {
    try {
      await Workmanager().cancelByUniqueName(_uniqueTaskName);
      debugPrint('Background task cancelled');
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Restart the background service (useful after app updates or configuration changes)
  Future<void> restart() async {
    try {
      await cancelAllTasks();
      await initialize();
      debugPrint('Background service restarted successfully');
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
    }
  }
}

/// Entry point for background task execution
/// Must be annotated with @pragma('vm:entry-point') for release builds
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background task started: $task');

      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      switch (task) {
        case BackgroundReminderService.taskName:
          await _performMedicationAndAppointmentCheck();
          break;
        default:
          debugPrint('Unknown background task: $task');
          return false;
      }

      debugPrint('Background task completed successfully: $task');
      return true;
    } catch (e, stackTrace) {
      BackgroundErrorHandler.handleError(e, stackTrace);
      return false; // Task failed but don't crash the service
    }
  });
}

/// Perform medication and appointment checks
/// Annotated for entry-point to ensure availability in release builds
@pragma('vm:entry-point')
Future<void> _performMedicationAndAppointmentCheck() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();

    final dbHelper = DBHelper();
    final caregiverNotificationService = CaregiverNotificationService();

    // Check upcoming medications
    await _checkUpcomingMedications(dbHelper, notificationService);

    // Check upcoming appointments
    await _checkUpcomingAppointments(dbHelper, notificationService);

    // Check for missed medications and notify caregivers
    await _checkMissedMedications(caregiverNotificationService);

    // Check for low stock and expiry alerts
    await _checkMedicationAlerts(dbHelper, notificationService);

    debugPrint('Medication and appointment check completed');
  } catch (e, stackTrace) {
    BackgroundErrorHandler.handleError(e, stackTrace);
  }
}

/// Check for upcoming medications and send reminders
/// Annotated for entry-point to ensure availability in release builds
@pragma('vm:entry-point')
Future<void> _checkUpcomingMedications(
  DBHelper dbHelper,
  NotificationService notificationService,
) async {
  try {
    final users = await BackgroundErrorHandler.handleDatabaseOperation(
      () => dbHelper.getUsers(),
    );

    if (users == null) {
      debugPrint('Failed to retrieve users from database');
      return;
    }

    for (final user in users) {
      final userId = user['user_id'] as int;
      final medications = await BackgroundErrorHandler.handleDatabaseOperation(
        () => dbHelper.getMedications(userId),
      );

      if (medications == null) {
        debugPrint('Failed to retrieve medications for user $userId');
        continue;
      }

      for (final med in medications) {
        try {
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
        } catch (e, stackTrace) {
          BackgroundErrorHandler.handleNotificationError(
            e,
            stackTrace,
            'scheduling medication reminder',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    BackgroundErrorHandler.handleError(e, stackTrace);
  }
}

/// Check for upcoming appointments and send reminders
/// Supports multiple notification timings: 1 day, 4 hours, 60 minutes before
/// Annotated for entry-point to ensure availability in release builds
@pragma('vm:entry-point')
Future<void> _checkUpcomingAppointments(
  DBHelper dbHelper,
  NotificationService notificationService,
) async {
  try {
    final users = await BackgroundErrorHandler.handleDatabaseOperation(
      () => dbHelper.getUsers(),
    );

    if (users == null) {
      debugPrint('Failed to retrieve users from database');
      return;
    }

    for (final user in users) {
      final userId = user['user_id'] as int;
      final appointments = await BackgroundErrorHandler.handleDatabaseOperation(
        () => dbHelper.getAppointments(userId),
      );

      if (appointments == null) {
        debugPrint('Failed to retrieve appointments for user $userId');
        continue;
      }

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
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          final now = DateTime.now();
          final difference = appointmentDateTime.difference(now).inMinutes;

          final doctorName = appointment['doctor_name'] as String;
          final location =
              appointment['location'] as String? ?? 'Not specified';
          final appointmentId = appointment['appointment_id'] as int;

          // Send notifications at different intervals
          if (difference >= 1430 && difference <= 1450) {
            // ~1 day before (24 hours = 1440 minutes)
            await notificationService.showAppointmentReminder(
              appointmentId,
              doctorName,
              'Appointment Tomorrow',
              'Reminder: You have an appointment with Dr. $doctorName tomorrow at $timeStr. Location: $location',
              appointmentDateTime.subtract(const Duration(days: 1)),
            );
          } else if (difference >= 230 && difference <= 250) {
            // ~4 hours before (240 minutes)
            await notificationService.showAppointmentReminder(
              appointmentId,
              doctorName,
              'Appointment in 4 Hours',
              'Reminder: You have an appointment with Dr. $doctorName in 4 hours at $timeStr. Location: $location',
              appointmentDateTime.subtract(const Duration(hours: 4)),
            );
          } else if (difference >= 50 && difference <= 70) {
            // ~60 minutes before
            await notificationService.showAppointmentReminder(
              appointmentId,
              doctorName,
              'Appointment in 1 Hour',
              'Reminder: You have an appointment with Dr. $doctorName in 1 hour at $timeStr. Location: $location',
              appointmentDateTime.subtract(const Duration(minutes: 60)),
            );
          }
        } catch (e, stackTrace) {
          BackgroundErrorHandler.handleNotificationError(
            e,
            stackTrace,
            'scheduling appointment reminder for appointment ${appointment['appointment_id']}',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    BackgroundErrorHandler.handleError(e, stackTrace);
  }
}

/// Check for missed medications and notify caregivers
/// Annotated for entry-point to ensure availability in release builds
@pragma('vm:entry-point')
Future<void> _checkMissedMedications(
  CaregiverNotificationService caregiverNotificationService,
) async {
  try {
    await caregiverNotificationService.checkMissedMedications();
  } catch (e, stackTrace) {
    BackgroundErrorHandler.handleError(e, stackTrace);
  }
}

/// Check for medication stock and expiry alerts
/// Annotated for entry-point to ensure availability in release builds
@pragma('vm:entry-point')
Future<void> _checkMedicationAlerts(
  DBHelper dbHelper,
  NotificationService notificationService,
) async {
  try {
    final users = await BackgroundErrorHandler.handleDatabaseOperation(
      () => dbHelper.getUsers(),
    );

    if (users == null) {
      debugPrint('Failed to retrieve users from database');
      return;
    }

    for (final user in users) {
      final userId = user['user_id'] as int;
      final medications = await BackgroundErrorHandler.handleDatabaseOperation(
        () => dbHelper.getMedications(userId),
      );

      if (medications == null) {
        debugPrint('Failed to retrieve medications for user $userId');
        continue;
      }

      for (final med in medications) {
        try {
          final medicine = Medicine.fromMap(med);

          // Check for low stock (less than 3 doses)
          if (medicine.stock < 3) {
            await notificationService.scheduleLowStockAlert(medicine);
          }

          // Check for expiry alerts (within 7 days)
          final daysUntilExpiry =
              medicine.expiryDate.difference(DateTime.now()).inDays;
          if (daysUntilExpiry <= 7 && daysUntilExpiry >= 0) {
            await notificationService.scheduleExpiryAlert(medicine);
          }
        } catch (e, stackTrace) {
          BackgroundErrorHandler.handleNotificationError(
            e,
            stackTrace,
            'checking medication alerts',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    BackgroundErrorHandler.handleError(e, stackTrace);
  }
}

/// Error handler for background service operations
/// Provides centralized error handling and logging
class BackgroundErrorHandler {
  /// Handle errors that occur in background service operations
  /// Logs errors without crashing the service and implements retry logic
  @pragma('vm:entry-point')
  static void handleError(Object error, StackTrace stackTrace) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] Background Service Error: $error');
    debugPrint('[$timestamp] Stack Trace: $stackTrace');

    // Log error type for better debugging
    debugPrint('[$timestamp] Error Type: ${error.runtimeType}');

    // In a production app, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry

    // For now, we just log the error and continue
    // This ensures the background service remains stable
  }

  /// Handle database-specific errors with retry logic
  @pragma('vm:entry-point')
  static Future<T?> handleDatabaseOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        debugPrint(
          'Database operation failed (attempt $attempt/$maxRetries): $e',
        );

        if (attempt == maxRetries) {
          handleError(e, stackTrace);
          return null;
        }

        // Wait before retrying
        await Future.delayed(retryDelay * attempt);
      }
    }
    return null;
  }

  /// Handle notification-specific errors
  @pragma('vm:entry-point')
  static void handleNotificationError(
    Object error,
    StackTrace stackTrace,
    String context,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] Notification Error in $context: $error');
    debugPrint('[$timestamp] Stack Trace: $stackTrace');
  }
}
