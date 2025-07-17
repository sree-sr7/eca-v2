# Requirements Document

## Introduction

The Flutter medicine management app has several core issues that need to be addressed for optimal performance and reliability. The background service is failing due to missing entry-point annotations, the UI is experiencing frame drops and performance issues, and the database contains unnecessary tables that should be removed. This comprehensive fix will ensure reliable background processing, smooth UI performance, and a clean, efficient codebase focused on essential elderly care functionality.

## Requirements

### Requirement 1

**User Story:** As an elderly user, I want my medication reminders to work reliably in the background, so that I never miss taking my medications even when the app is not actively open.

#### Acceptance Criteria

1. WHEN the app is minimized or closed THEN the background service SHALL continue running and checking for upcoming medications
2. WHEN a medication is due within 30 minutes THEN the system SHALL send a notification reminder
3. WHEN the background service encounters an error THEN it SHALL log the error and continue operating without crashing
4. WHEN the device is restarted THEN the background service SHALL automatically restart and resume medication monitoring

### Requirement 2

**User Story:** As an elderly user, I want appointment reminders to work in the background with multiple notification timings, so that I don't miss important medical appointments.

#### Acceptance Criteria

1. WHEN an appointment is scheduled THEN the system SHALL send notifications 1 day before, 4 hours before, and 60 minutes before the appointment
2. WHEN the background service is running THEN it SHALL check for upcoming appointments every 15 minutes
3. WHEN appointment data is malformed THEN the system SHALL handle the error gracefully and continue processing other appointments
4. WHEN appointments are missed THEN the system SHALL notify both the user and caregiver

### Requirement 3

**User Story:** As a caregiver, I want to be notified when elderly users miss their medications or appointments, so that I can provide timely assistance.

#### Acceptance Criteria

1. WHEN a medication is missed THEN the system SHALL send a push notification to the caregiver's device via FCM
2. WHEN an appointment is missed THEN the system SHALL notify the caregiver immediately
3. WHEN the background service checks for missed events THEN it SHALL do so every 15 minutes
4. WHEN caregiver notifications fail THEN the system SHALL retry and log the failure
5. WHEN missed events occur THEN they SHALL be synced to Firebase in real-time for cross-device access

### Requirement 4

**User Story:** As a developer, I want the background service to be properly annotated and structured, so that it works correctly in production builds and doesn't cause runtime errors.

#### Acceptance Criteria

1. WHEN the app is built for release THEN all background service entry points SHALL be properly annotated with @pragma('vm:entry-point')
2. WHEN the background service is initialized THEN it SHALL properly configure Android platform
3. WHEN the service encounters Android-specific issues THEN it SHALL handle them appropriately
4. WHEN the service is stopped THEN it SHALL clean up resources properly

### Requirement 5

**User Story:** As a system administrator, I want the background service to be efficient and not drain device battery, so that users can rely on it throughout the day.

#### Acceptance Criteria

1. WHEN the background service runs THEN it SHALL use minimal system resources
2. WHEN no reminders are due THEN the service SHALL remain idle until the next check interval
3. WHEN the service performs database operations THEN it SHALL do so efficiently and close connections properly
4. WHEN the device is in low power mode THEN the service SHALL adapt its behavior accordingly

### Requirement 6

**User Story:** As an elderly user, I want the app to run smoothly without lag or frame drops, so that I can easily navigate and use all features without frustration.

#### Acceptance Criteria

1. WHEN navigating between screens THEN the app SHALL maintain 60fps with no frame drops
2. WHEN scrolling through lists THEN the UI SHALL remain responsive and smooth
3. WHEN loading data THEN the app SHALL show appropriate loading indicators without blocking the UI
4. WHEN performing database operations THEN they SHALL be executed on background threads to avoid UI blocking
5. WHEN rendering complex widgets THEN the app SHALL optimize rendering to prevent jank

### Requirement 7

**User Story:** As a developer, I want to remove unnecessary database tables and features, so that the app has a clean, maintainable codebase focused on essential functionality.

#### Acceptance Criteria

1. WHEN the app starts THEN it SHALL NOT reference caregiver assignments, care plans, payments, or feedback tables
2. WHEN database migrations run THEN they SHALL safely remove unused tables without affecting core functionality
3. WHEN the codebase is reviewed THEN all references to non-essential features SHALL be removed
4. WHEN the app builds THEN it SHALL NOT include unused models, services, or UI components for removed features

### Requirement 8

**User Story:** As an elderly user, I want my medication reminders to work even when I haven't opened the medicine page recently, so that I receive consistent notifications regardless of my app usage patterns.

#### Acceptance Criteria

1. WHEN medications are scheduled THEN reminders SHALL work independently of user navigation patterns
2. WHEN the app is first installed THEN medication reminders SHALL be initialized automatically
3. WHEN medication data is updated THEN the reminder system SHALL refresh without requiring page visits
4. WHEN the background service starts THEN it SHALL access medication data directly from the database

### Requirement 9

**User Story:** As a developer, I want to remove all monetization and agency-related features, so that the app remains focused on personal family caregiving without unnecessary complexity.

#### Acceptance Criteria

1. WHEN the app is reviewed THEN it SHALL NOT contain any Razorpay or payment integration code
2. WHEN the database is cleaned THEN it SHALL NOT contain admin dashboard logic for assignments, payments, or reviews
3. WHEN the UI is reviewed THEN it SHALL NOT contain premium tiers, care levels, or monetization-related screens
4. WHEN the app builds THEN it SHALL only include essential features: medications, appointments, notifications, emergency SOS, offline sync, and basic user profiles

### Requirement 10

**User Story:** As an elderly user, I want to receive alerts for low medication stock and expiring medicines, so that I can refill or replace them before running out.

#### Acceptance Criteria

1. WHEN medication stock falls below 3 doses THEN the system SHALL send a low stock alert
2. WHEN medication expires within 7 days THEN the system SHALL send an expiry warning
3. WHEN medication has expired THEN the system SHALL send an immediate expiry alert
4. WHEN stock or expiry alerts are sent THEN they SHALL also notify the caregiver via FCM

### Requirement 11

**User Story:** As a user, I want to be able to logout from the app securely, so that my personal medical information is protected when I'm not using the device.

#### Acceptance Criteria

1. WHEN the user clicks logout THEN the system SHALL clear all local user data
2. WHEN logout is performed THEN the system SHALL clear Firebase authentication tokens
3. WHEN logout is completed THEN the system SHALL clear FCM device tokens
4. WHEN logout is successful THEN the system SHALL redirect to the login screen

### Requirement 12

**User Story:** As a user with a high refresh rate device, I want the app to run at maximum frame rate (120Hz+), so that I get the smoothest possible experience.

#### Acceptance Criteria

1. WHEN the app starts on a 120Hz+ device THEN it SHALL automatically enable high refresh rate mode
2. WHEN the device supports variable refresh rates THEN the app SHALL use the maximum available rate
3. WHEN the app runs on high refresh rate displays THEN it SHALL maintain consistent frame timing
4. WHEN performance is optimized THEN the app SHALL prioritize 120Hz over 60Hz on compatible devices

### Requirement 13

**User Story:** As a caregiver, I want to receive real-time notifications on my device when emergencies occur, so that I can respond immediately to help the elderly user.

#### Acceptance Criteria

1. WHEN an SOS emergency is triggered THEN the system SHALL send immediate FCM push notifications to all registered caregivers
2. WHEN SOS is activated THEN the system SHALL include location data (if available) in the emergency alert
3. WHEN FCM notifications are sent THEN they SHALL work across different devices and platforms
4. WHEN emergency alerts are triggered THEN they SHALL be stored in Firebase for real-time synchronization

### Requirement 14

**User Story:** As a developer, I want Firebase Cloud Messaging (FCM) properly integrated, so that cross-device notifications work reliably for caregivers who are typically on different devices.

#### Acceptance Criteria

1. WHEN the app initializes THEN it SHALL configure FCM with proper device token management
2. WHEN caregiver devices are registered THEN their FCM tokens SHALL be stored in Firebase
3. WHEN notifications need to be sent THEN the system SHALL use FCM to reach caregiver devices
4. WHEN FCM tokens expire or change THEN the system SHALL automatically update them in Firebase

### Requirement 15

**User Story:** As a developer, I want all dependencies and build configurations updated to current supported versions, so that the app uses modern, secure, and performant libraries without deprecated warnings.

#### Acceptance Criteria

1. WHEN the app builds THEN it SHALL use Java 11+ instead of deprecated Java 8
2. WHEN dependencies are reviewed THEN all outdated packages SHALL be updated to their latest stable versions
3. WHEN the build process runs THEN it SHALL NOT show deprecation warnings for outdated dependencies
4. WHEN Android build configuration is updated THEN it SHALL use current compileSdk and targetSdk versions