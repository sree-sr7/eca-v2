import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/medicine.dart';

class CaregiverNotificationService {
  static final CaregiverNotificationService _instance =
      CaregiverNotificationService._();
  factory CaregiverNotificationService() => _instance;
  CaregiverNotificationService._();

  final DBHelper _dbHelper = DBHelper();

  // Create notification for missed medication
  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> createMissedMedicationNotification({
    required int userId,
    required int medicationId,
    required String medicationName,
    required String dosage,
    required String scheduledTime,
  }) async {
    // Get active caregivers for this user
    final caregivers = await _dbHelper.getActiveCaregiversForUser(userId);

    if (caregivers.isEmpty) {
      debugPrint('No active caregivers found for user $userId');
      return;
    }

    final message =
        'Missed medication: $medicationName ($dosage) scheduled for $scheduledTime';

    // Create a notification for each caregiver
    for (final caregiver in caregivers) {
      await _dbHelper.insertNotification(
        userId: userId,
        caregiverId: caregiver['user_id'],
        medicationId: medicationId,
        message: message,
      );
      debugPrint(
        'Created missed medication notification for caregiver ${caregiver['user_id']}',
      );
    }
  }

  // Create notification for upcoming appointment
  Future<void> createAppointmentReminderNotification({
    required int userId,
    required int appointmentId,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
    required String location,
    required bool isDayBefore,
  }) async {
    // Get active caregivers for this user
    final caregivers = await _dbHelper.getActiveCaregiversForUser(userId);

    if (caregivers.isEmpty) {
      debugPrint('No active caregivers found for user $userId');
      return;
    }

    final timeframe = isDayBefore ? 'tomorrow' : 'in 4 hours';
    final message =
        'Upcoming appointment $timeframe with Dr. $doctorName at $appointmentTime on $appointmentDate (Location: $location)';

    // Create a notification for each caregiver
    for (final caregiver in caregivers) {
      await _dbHelper.insertNotification(
        userId: userId,
        caregiverId: caregiver['user_id'],
        appointmentId: appointmentId,
        message: message,
      );
      debugPrint(
        'Created appointment reminder notification for caregiver ${caregiver['user_id']}',
      );
    }
  }

  // Check for missed medications
  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> checkMissedMedications() async {
    final users = await _dbHelper.getUsers();

    for (final user in users) {
      final userId = user['user_id'] as int;
      final medications = await _dbHelper.getMedications(userId);

      for (final med in medications) {
        final medicine = Medicine.fromMap(med);
        final medicationId = int.parse(medicine.id);

        // Skip if already taken
        if (medicine.isTaken) continue;

        // Check if medication time has passed
        if (medicine.timeOfDay != null) {
          final now = DateTime.now();
          final scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            medicine.timeOfDay!.hour,
            medicine.timeOfDay!.minute,
          );

          // If scheduled time was over 30 minutes ago and medicine not taken
          final timeDifference = now.difference(scheduledDateTime).inMinutes;
          if (timeDifference > 30) {
            // Create notification for caregivers
            await createMissedMedicationNotification(
              userId: userId,
              medicationId: medicationId,
              medicationName: medicine.name,
              dosage: medicine.dosage,
              scheduledTime: medicine.formattedTime,
            );

            debugPrint(
              'Detected missed medication: ${medicine.name} for user $userId',
            );
          }
        }
      }
    }
  }

  // Get all notifications for a caregiver
  Future<List<Map<String, dynamic>>> getCaregiverNotifications(
    int caregiverId,
  ) async {
    return await _dbHelper.getCaregiverNotifications(caregiverId);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    await _dbHelper.markNotificationAsRead(notificationId);
  }
}
