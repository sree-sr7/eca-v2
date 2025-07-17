import 'package:flutter/material.dart';
import 'dart:async';
import '../database/db_helper.dart';
import 'firebase_notification_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  final DBHelper _dbHelper = DBHelper();
  final FirebaseNotificationService _firebaseService = FirebaseNotificationService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Singleton pattern
  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal();

  void startPeriodicSync({Duration interval = const Duration(minutes: 15)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncPendingItems());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> insertOfflineSyncLog(Map<String, dynamic> logEntry) async {
    await _dbHelper.insertOfflineSyncLog(logEntry);
  }

  Future<void> syncPendingItems() async {
    if (_isSyncing) return;

    // Check for connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection, skipping sync');
      return;
    }

    _isSyncing = true;

    try {
      // Get all pending SOS notifications that need to be synced
      final pendingNotifications = await _dbHelper.getUnreadSOSNotifications(0); // 0 means get all

      for (var notification in pendingNotifications) {
        await _firebaseService.syncSOSNotification(notification);
      }

      // Get pending sync logs with failed status
      final failedSyncs = await _dbHelper.getFailedSyncLogs();

      for (var syncLog in failedSyncs) {
        if (syncLog['table_name'] == 'notifications') {
          // Get the notification
          final notification = await _dbHelper.getNotificationById(syncLog['record_id']);

          if (notification != null) {
            // Try to sync again
            await _firebaseService.syncSOSNotification(notification);

            // Update sync log
            await _dbHelper.updateSyncLog(
                syncLog['sync_id'],
                {'status': 'Synced', 'last_attempt': DateTime.now().toIso8601String()}
            );
          }
        }
        // Add more table types as needed
      }
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
}