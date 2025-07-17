import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/caregiver_notification.dart';
import '../services/notification_service.dart';
import '../services/caregiver_notification_service.dart';

class CaregiverNotificationRepository {
  static final CaregiverNotificationRepository _instance = CaregiverNotificationRepository._();
  factory CaregiverNotificationRepository() => _instance;
  CaregiverNotificationRepository._();

  final DBHelper _dbHelper = DBHelper();
  final CaregiverNotificationService _notificationService = CaregiverNotificationService();

  // Get all notifications for a caregiver with optional filtering
  Future<List<CaregiverNotification>> getNotifications(
      int caregiverId, {
        bool unreadOnly = false,
        NotificationType? type,
        int? patientId,
      }) async {
    // Get raw notification data
    final notifications = await _notificationService.getCaregiverNotifications(caregiverId);

    // Convert to model objects
    final notificationModels = notifications
        .map((map) => CaregiverNotification.fromMap(map))
        .toList();

    // Apply filters
    return notificationModels.where((notification) {
      // Filter by read status if requested
      if (unreadOnly && notification.isRead) {
        return false;
      }

      // Filter by notification type if specified
      if (type != null && notification.type != type) {
        return false;
      }

      // Filter by patient ID if specified
      if (patientId != null && notification.userId != patientId) {
        return false;
      }

      return true;
    }).toList()
    // Sort notifications by date (newest first)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    await _dbHelper.markNotificationAsRead(notificationId);
  }

  // Mark all notifications for a caregiver as read
  Future<void> markAllAsRead(int caregiverId) async {
    final notifications = await _notificationService.getCaregiverNotifications(caregiverId);

    for (final notification in notifications) {
      if (notification['status'] == 'Unread') {
        await _dbHelper.markNotificationAsRead(notification['notification_id'] as int);
      }
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    await _dbHelper.deleteNotification(notificationId);
  }

  // Get count of unread notifications
  Future<int> getUnreadCount(int caregiverId) async {
    final notifications = await _notificationService.getCaregiverNotifications(caregiverId);
    return notifications.where((n) => n['status'] == 'Unread').length;
  }

  // Get patients with notifications for a caregiver
  Future<List<Map<String, dynamic>>> getPatientsWithNotifications(int caregiverId) async {
    final db = await _dbHelper.database;

    // This query gets unique patients who have notifications for this caregiver
    final result = await db.rawQuery('''
      SELECT DISTINCT u.user_id, u.username, u.email, u.first_name, u.last_name, 
        (SELECT COUNT(*) FROM notifications 
         WHERE user_id = u.user_id AND caregiver_id = ? AND status = 'Unread') as unread_count
      FROM users u
      INNER JOIN notifications n ON u.user_id = n.user_id
      WHERE n.caregiver_id = ?
      ORDER BY unread_count DESC, u.first_name, u.last_name
    ''', [caregiverId, caregiverId]);

    return result;
  }
}