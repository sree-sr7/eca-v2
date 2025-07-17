import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'location_service.dart';
import 'package:location/location.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  final DBHelper _dbHelper = DBHelper();
  final LocationService _locationService = LocationService();

  // Singleton pattern
  factory SOSService() {
    return _instance;
  }

  SOSService._internal();

  Future<bool> sendSOSAlert(int userId, {String? customMessage}) async {
    try {
      // Get the current location
      LocationData? locationData = await _locationService.getCurrentLocation();

      if (locationData == null) {
        debugPrint('Failed to get location for SOS alert');
        // Continue without location if necessary
      }

      // Prepare the SOS message
      String message = customMessage ?? "EMERGENCY SOS ALERT: Patient needs immediate assistance!";

      // Create notification for the user themselves
      await _dbHelper.insertNotification(
        userId: userId,
        message: message,
        sosLatitude: locationData?.latitude,
        sosLongitude: locationData?.longitude,
      );

      // Get caregivers assigned to this user
      final caregivers = await _dbHelper.getActiveCaregiversForUser(userId);

      // Create notification for each caregiver
      for (var caregiver in caregivers) {
        int caregiverId = caregiver['user_id'];
        await _dbHelper.insertNotification(
          userId: userId,
          caregiverId: caregiverId,
          message: message,
          sosLatitude: locationData?.latitude,
          sosLongitude: locationData?.longitude,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error sending SOS alert: $e');
      return false;
    }
  }

  Future<void> cancelSOSAlert(int userId) async {
    try {
      // Get the most recent SOS notification for this user
      final recentSOS = await _dbHelper.getMostRecentSOSNotification(userId);

      if (recentSOS != null) {
        int notificationId = recentSOS['notification_id'];

        // Update the notification to indicate that it was canceled
        await _dbHelper.updateNotification(
            notificationId,
            {
              "message": "SOS Alert Canceled: False alarm",
              "status": "Read"
            }
        );

        // Also update any caregiver notifications
        // Find caregivers who received this alert
        final caregivers = await _dbHelper.getActiveCaregiversForUser(userId);

        for (var caregiver in caregivers) {
          int caregiverId = caregiver['user_id'];

          // Get unread SOS notifications for this caregiver from this user
          List<Map<String, dynamic>> caregiverNotifications = await _dbHelper.getUnreadSOSNotifications(caregiverId);

          for (var notification in caregiverNotifications) {
            if (notification['user_id'] == userId) {
              await _dbHelper.updateNotification(
                  notification['notification_id'],
                  {
                    "message": "SOS Alert Canceled: False alarm",
                    "status": "Read"
                  }
              );
            }
          }
        }
      }

      return;
    } catch (e) {
      debugPrint('Error canceling SOS alert: $e');
    }
  }

  // Method to retrieve SOS history for a user
  Future<List<Map<String, dynamic>>> getSOSHistory(int userId) async {
    try {
      final db = await _dbHelper.database;
      return await db.query(
        'notifications',
        where: 'user_id = ? AND sos_latitude IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      debugPrint('Error retrieving SOS history: $e');
      return [];
    }
  }
}