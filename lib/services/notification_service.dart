import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:intl/intl.dart';
import '../models/medicine.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_init.initializeTimeZones();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request permissions separately
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) return;

    // Create medicine reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'medicine_reminders',
        'Medicine Reminders',
        description: 'Notifications for medicine reminders',
        importance: Importance.high,
      ),
    );

    // Create expiry alerts channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'expiry_alerts',
        'Medication Expiry Alerts',
        description: 'Alerts for expiring medications',
        importance: Importance.high,
      ),
    );

    // Create stock alerts channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'stock_alerts',
        'Low Stock Alerts',
        description: 'Alerts for low medication stock',
        importance: Importance.high,
      ),
    );

    // Create appointment reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'appointment_reminders',
        'Appointment Reminders',
        description: 'Notifications for appointment reminders',
        importance: Importance.high,
      ),
    );

    // Create test channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'test_channel',
        'Test Channel',
        description: 'Channel used for testing notifications',
        importance: Importance.high,
      ),
    );

    debugPrint('Android notification channels created');
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    if (!Platform.isAndroid && !Platform.isIOS) return false;

    // For Android
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin == null) return false;

      // Request Android notification permissions
      try {
        final result = await androidPlugin.requestNotificationsPermission();
        debugPrint('Android notification permission result: $result');
        return result ?? false;
      } catch (e) {
        debugPrint('Error requesting Android permissions: $e');
        return false;
      }
    }

    // For iOS
    if (Platform.isIOS) {
      // For iOS in v16.0.0, we need to use the DarwinNotificationSettings
      try {
        // Since we can't directly access the iOS plugin, we need to use the DarwinInitializationSettings
        // to request permissions during initialization or use a workaround
        // This is a slight hack but works for iOS permissions
        await _localNotifications.initialize(
          InitializationSettings(
            android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: const DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            ),
          ),
        );

        debugPrint('iOS notification permissions requested');
        // We assume success since there's no direct way to check in v16.0.0
        return true;
      } catch (e) {
        debugPrint('Error requesting iOS permissions: $e');
        return false;
      }
    }

    return false;
  }

  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();

    debugPrint('Attempting to show test notification');

    try {
      await _localNotifications.show(
        999,
        'Test Notification',
        'This is a test notification to verify the system is working',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Channel',
            channelDescription: 'Channel used for testing notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (!_isInitialized) await initialize();

    // Skip if no specific time is set
    if (medicine.timeOfDay == null) return;

    try {
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        medicine.timeOfDay!.hour,
        medicine.timeOfDay!.minute,
      );

      // If time has passed for today, schedule for tomorrow
      final effectiveDate =
          scheduledDate.isBefore(now)
              ? scheduledDate.add(const Duration(days: 1))
              : scheduledDate;

      // Use the medicine color for notification
      final Color medicineColor = medicine.color;

      await _localNotifications.zonedSchedule(
        medicine.id.hashCode,
        'Time to take ${medicine.name}',
        '${medicine.dosage} - ${medicine.frequency}',
        tz.TZDateTime.from(effectiveDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: medicineColor,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id.toString(),
      );
      debugPrint(
        'Scheduled medicine reminder for ${medicine.name} at ${effectiveDate.toString()}',
      );
    } catch (e) {
      debugPrint('Error scheduling medicine reminder: $e');
    }
  }

  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> scheduleExpiryAlert(Medicine medicine) async {
    if (!_isInitialized) await initialize();

    try {
      // Format the expiry date properly
      final expiryFormatted = DateFormat(
        'MMM d, yyyy',
      ).format(medicine.expiryDate);

      // Calculate when to send notification (7 days before expiry)
      final expiryWarningDate = medicine.expiryDate.subtract(
        const Duration(days: 7),
      );

      // Only schedule if the warning date is in the future
      if (expiryWarningDate.isBefore(DateTime.now())) return;

      final notificationId = 'expiry_${medicine.id}'.hashCode;

      await _localNotifications.zonedSchedule(
        notificationId,
        '${medicine.name} is expiring soon',
        'Your medication will expire on $expiryFormatted',
        tz.TZDateTime.from(expiryWarningDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_alerts',
            'Medication Expiry Alerts',
            channelDescription: 'Alerts for expiring medications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: medicine.id.toString(),
      );
      debugPrint('Scheduled expiry alert for ${medicine.name}');
    } catch (e) {
      debugPrint('Error scheduling expiry alert: $e');
    }
  }

  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> scheduleLowStockAlert(Medicine medicine) async {
    if (!_isInitialized) await initialize();

    try {
      // Only alert if stock is getting low (less than 5)
      if (medicine.stock > 5) return;

      final notificationId = 'stock_${medicine.id}'.hashCode;

      await _localNotifications.show(
        notificationId,
        'Low stock: ${medicine.name}',
        'You only have ${medicine.stock} units left. Consider restocking soon.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'stock_alerts',
            'Low Stock Alerts',
            channelDescription: 'Alerts for low medication stock',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: medicine.id.toString(),
      );
      debugPrint('Showed low stock alert for ${medicine.name}');
    } catch (e) {
      debugPrint('Error showing low stock alert: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      debugPrint('Cancelled notification with ID: $notificationId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelNotificationsForMedicine(String medicineId) async {
    try {
      await _localNotifications.cancel(medicineId.hashCode);
      await _localNotifications.cancel('expiry_$medicineId'.hashCode);
      await _localNotifications.cancel('stock_$medicineId'.hashCode);
      debugPrint('Cancelled notifications for medicine $medicineId');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Annotated for entry-point to ensure availability in release builds
  @pragma('vm:entry-point')
  Future<void> showAppointmentReminder(
    int appointmentId,
    String doctorName,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final notificationId = 'appointment_$appointmentId'.hashCode;
      debugPrint(
        'Creating appointment reminder with ID: $notificationId for time: ${scheduledTime.toString()}',
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body, // Use the body parameter directly
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment Reminders',
            channelDescription: 'Notifications for appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'appointment_$appointmentId',
      );
      debugPrint(
        'Scheduled appointment reminder for doctor: $doctorName at ${scheduledTime.toString()}',
      );
    } catch (e) {
      debugPrint('Error scheduling appointment reminder: $e');
    }
  }
}
