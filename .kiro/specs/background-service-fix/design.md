# Design Document

## Overview

This design addresses the core performance and reliability issues in the Flutter medicine management app by implementing proper background service architecture, Firebase Cloud Messaging (FCM) for cross-device notifications, optimizing UI performance for high refresh rate displays (120Hz+), and cleaning up the database structure. The solution focuses on creating a robust, efficient system that provides reliable medication and appointment reminders with real-time caregiver notifications while maintaining the existing UI design and feel.

## Architecture

### Background Service Architecture

The background service will be restructured using Flutter's `workmanager` plugin with proper entry-point annotations and platform-specific configurations:

```
Background Service Layer
├── WorkManager Configuration
├── Entry Point Annotations (@pragma('vm:entry-point'))
├── Platform-Specific Handlers (Android/iOS)
├── Database Access Layer
├── FCM Integration
├── Local & Push Notification Service
└── Error Handling & Logging
```

### Firebase Cloud Messaging (FCM) Architecture

FCM will handle cross-device notifications for caregivers:

```
FCM Integration
├── Device Token Management
├── Firebase Realtime Database Sync
├── Push Notification Service
├── Caregiver Notification Handler
└── SOS Emergency Alerts
```

### Performance Optimization Architecture

UI performance will be improved through:
- Async database operations on background isolates
- Widget optimization and lazy loading
- Efficient state management
- High refresh rate support (120Hz+ displays)
- Frame rate monitoring and optimization

### Database Cleanup Architecture

Database structure will be simplified by:
- Removing unused tables (caregiver_assignments, care_plans, payments, feedback)
- Optimizing existing table structures
- Creating migration scripts for safe cleanup
- Updating data access patterns

## Components and Interfaces

### 1. Background Service Components

#### WorkManager Service
```dart
class BackgroundReminderService {
  static const String taskName = "medication_reminder_task";
  
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    // Entry point for background execution
  }
  
  Future<void> initialize() async {
    // Platform-specific initialization
  }
  
  Future<void> schedulePeriodicTask() async {
    // Schedule background checks every 15 minutes
  }
}
```

#### Notification Handler
```dart
class NotificationHandler {
  Future<void> sendMedicationReminder(Medication medication) async {}
  Future<void> sendAppointmentReminder(Appointment appointment) async {
    // Send notifications: 1 day before, 4 hours before, 60 minutes before
  }
  Future<void> sendLowStockAlert(Medication medication) async {}
  Future<void> sendExpiryAlert(Medication medication) async {}
  Future<void> notifyCaregiver(String message, String userId) async {}
  Future<void> sendMissedMedicationAlert(String caregiverId, Medication medication) async {}
  Future<void> sendMissedAppointmentAlert(String caregiverId, Appointment appointment) async {}
}
```

### 2. Firebase Cloud Messaging Components

#### FCM Service
```dart
class FCMService {
  Future<void> initialize() async {
    // Initialize FCM and request permissions
  }
  
  Future<String?> getDeviceToken() async {
    // Get FCM device token
  }
  
  Future<void> subscribeToTopic(String topic) async {
    // Subscribe to caregiver notifications
  }
  
  Future<void> sendPushNotification(String token, String title, String body) async {
    // Send push notification to specific device
  }
}
```

#### Firebase Sync Service
```dart
class FirebaseSyncService {
  Future<void> syncMissedEvents() async {
    // Sync missed medications and appointments to Firebase
  }
  
  Future<void> updateCaregiverDeviceToken(String userId, String token) async {
    // Store caregiver device tokens in Firebase
  }
  
  Future<void> sendSOSAlert(String userId, String? location) async {
    // Send emergency SOS alert to Firebase and notify caregiver
  }
}
```

### 3. Authentication Components

#### Auth Service
```dart
class AuthService {
  Future<void> logout() async {
    // Clear local data, Firebase auth, and FCM tokens
  }
  
  Future<bool> isLoggedIn() async {
    // Check authentication status
  }
  
  Future<void> clearUserData() async {
    // Clear all local user data on logout
  }
}
```

### 2. Performance Optimization Components

#### Async Database Service
```dart
class AsyncDatabaseService {
  static final Isolate _backgroundIsolate = Isolate.spawn(_isolateEntryPoint);
  
  Future<List<T>> queryAsync<T>(String query) async {
    // Execute database operations on background isolate
  }
}
```

#### Performance Monitor
```dart
class PerformanceMonitor {
  void trackFrameRate() {}
  void logPerformanceMetrics() {}
  void optimizeWidgetRendering() {}
  void enableHighRefreshRate() {
    // Enable 120Hz+ support for compatible devices
  }
}
```

#### High Refresh Rate Handler
```dart
class RefreshRateHandler {
  Future<void> setOptimalRefreshRate() async {
    // Detect device capabilities and set to maximum supported refresh rate
    // Prioritize 120Hz for compatible devices
  }
  
  Future<double> getDeviceRefreshRate() async {
    // Get device's maximum supported refresh rate
  }
}
```

### 3. Database Cleanup Components

#### Migration Service
```dart
class DatabaseMigrationService {
  Future<void> removeUnusedTables() async {
    // Safely remove caregiver_assignments, care_plans, payments, feedback tables
  }
  
  Future<void> optimizeExistingTables() async {
    // Optimize remaining table structures
  }
}
```

## Data Models

### Core Data Models (Retained)
```dart
class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<DateTime> scheduledTimes;
  final DateTime? lastTaken;
  final int stockCount;
  final DateTime expiryDate;
}

class Appointment {
  final String id;
  final String title;
  final DateTime scheduledTime;
  final String? notes;
  final bool isCompleted;
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role; // elderly or caregiver
  final String? caregiverId; // Direct relationship
}
```

### Removed Data Models
- CaregiverAssignment
- CarePlan
- Payment
- CaregiverFeedback
- AdminDashboard related models

## Error Handling

### Background Service Error Handling
```dart
class BackgroundErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    // Log error without crashing service
    // Implement retry logic for critical operations
    // Send error reports to Firebase Crashlytics
  }
}
```

### Database Error Handling
```dart
class DatabaseErrorHandler {
  static Future<T?> safeQuery<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      // Log error and return null or default value
      return null;
    }
  }
}
```

### UI Error Handling
```dart
class UIErrorHandler {
  static Widget buildErrorWidget(String message) {
    // Return user-friendly error widget
  }
  
  static void showErrorSnackbar(BuildContext context, String message) {
    // Display non-intrusive error message
  }
}
```

## Testing Strategy

### Unit Testing
- Background service functionality
- Database operations
- Notification logic
- Data model validation

### Integration Testing
- Background service with database
- Notification delivery
- Cross-platform compatibility

### Performance Testing
- Frame rate monitoring
- Memory usage tracking
- Battery consumption analysis
- Database query performance

### Migration Testing
- Database cleanup safety
- Data integrity after migrations
- Rollback procedures

## Implementation Phases

### Phase 1: Background Service Fix
1. Add proper entry-point annotations
2. Implement WorkManager configuration
3. Create platform-specific handlers
4. Add comprehensive error handling

### Phase 2: Performance Optimization
1. Move database operations to background isolates
2. Optimize widget rendering
3. Implement lazy loading
4. Add performance monitoring

### Phase 3: Database Cleanup
1. Create migration scripts
2. Remove unused tables safely
3. Update data access patterns
4. Clean up unused code

### Phase 4: Testing & Validation
1. Comprehensive testing across all components
2. Performance validation
3. Cross-platform testing
4. User acceptance testing