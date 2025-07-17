import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  final DBHelper _dbHelper = DBHelper();
  late FirebaseDatabase _database;
  bool _initialized = false;

  // Singleton pattern
  factory FirebaseNotificationService() {
    return _instance;
  }

  FirebaseNotificationService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _database = FirebaseDatabase.instance;
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
    }
  }

  Future<void> syncSOSNotification(Map<String, dynamic> notification) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final notificationRef = _database.ref('sos_notifications').push();

      // Prepare data for Firebase (remove any SQLite-specific fields)
      final Map<String, dynamic> firebaseData = {
        'user_id': notification['user_id'],
        'caregiver_id': notification['caregiver_id'],
        'message': notification['message'],
        'created_at': notification['created_at'],
        'status': notification['status'],
        'location': {
          'latitude': notification['sos_latitude'],
          'longitude': notification['sos_longitude'],
        },
        'firebase_id': notificationRef.key,
      };

      // Send to Firebase
      await notificationRef.set(firebaseData);

      // Update local notification with Firebase ID
      await _dbHelper.updateNotification(notification['notification_id'], {
        'firebase_id': notificationRef.key,
      });
    } catch (e) {
      debugPrint('Error syncing SOS notification to Firebase: $e');

      // Log the sync failure in the offline_sync_log table
      await _dbHelper.insertOfflineSyncLog({
        'user_id': notification['user_id'],
        'table_name': 'notifications',
        'record_id': notification['notification_id'],
        'operation': 'INSERT',
        'status': 'Failed',
        'error_message': e.toString(),
      });
    }
  }

  // Listen for SOS notifications for a specific caregiver
  Stream<DatabaseEvent> listenForSOSNotifications(int caregiverId) {
    if (!_initialized) {
      initialize();
    }

    final notificationsQuery = _database
        .ref('sos_notifications')
        .orderByChild('caregiver_id')
        .equalTo(caregiverId);

    return notificationsQuery.onChildAdded;
  }
}
