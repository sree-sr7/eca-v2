// widgets/notification_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Import the dart:math package for min function
import '../utils/app_colors.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Improved dark mode colors for better visibility
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightCardColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final tertiaryTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        onDismissed: (direction) {
          onDismiss();
        },
        child: GestureDetector(
          onTap: onTap,
          child: Hero(
            tag: 'notification_${notification.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: notification.isRead
                      ? null
                      : Border.all(
                    color: _getNotificationColor(notification.type),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section with icon, title and time
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with colored background
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: isDarkMode
                                  ? _getBrighterColor(_getNotificationColor(notification.type))
                                  : _getNotificationColor(notification.type),
                              size: 28, // Larger icon for better visibility
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title and time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 18, // Larger text for elderly
                                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(notification.time),
                                  style: TextStyle(
                                    fontSize: 14, // Larger text for elderly
                                    color: tertiaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Read/unread indicator
                          if (!notification.isRead)
                            Container(
                              width: 12, // Slightly larger
                              height: 12, // Slightly larger
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? _getBrighterColor(_getNotificationColor(notification.type))
                                    : _getNotificationColor(notification.type),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Message content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 16, // Larger text for elderly
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Action buttons if needed
                    if (_shouldShowActions(notification.type))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (notification.type == NotificationType.medicineStock ||
                                notification.type == NotificationType.medicineExpiry)
                              _buildActionButton(
                                context,
                                'Refill',
                                Icons.add_shopping_cart_outlined,
                                isDarkMode ? Colors.blue[300]! : AppColors.accentColor,
                              ),

                            if (notification.type == NotificationType.appointment)
                              _buildActionButton(
                                context,
                                'View',
                                Icons.event_outlined,
                                isDarkMode ? Colors.blue[300]! : AppColors.accentColor,
                              ),

                            if (notification.type == NotificationType.missedMedication)
                              _buildActionButton(
                                context,
                                'Take Now',
                                Icons.check_circle_outline,
                                isDarkMode ? Colors.green[300]! : AppColors.success,
                              ),

                            if (notification.type == NotificationType.sos)
                              _buildActionButton(
                                context,
                                'View Details',
                                Icons.info_outline,
                                isDarkMode ? Colors.blue[300]! : AppColors.accentColor,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          // Action will be implemented later
        },
        icon: Icon(icon, size: 20), // Slightly larger icon
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16, // Larger text for elderly
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.7), width: 1.5), // Thicker border for better visibility
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16, // Increased padding
            vertical: 10, // Increased padding
          ),
        ),
      ),
    );
  }

  // Helper method to get brighter colors for dark mode
  Color _getBrighterColor(Color color) {
    // Make colors brighter for dark mode to improve visibility
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness(min(hslColor.lightness + 0.3, 0.9)).toColor();
  }

  bool _shouldShowActions(NotificationType type) {
    switch (type) {
      case NotificationType.medicineStock:
      case NotificationType.medicineExpiry:
      case NotificationType.appointment:
      case NotificationType.missedMedication:
      case NotificationType.sos:
        return true;
      default:
        return false;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.missedMedication:
        return AppColors.errorColor;
      case NotificationType.medicationReminder:
        return AppColors.primaryColor;
      case NotificationType.appointment:
        return AppColors.accentColor;
      case NotificationType.medicineStock:
      case NotificationType.medicineExpiry:
        return AppColors.warning;
      case NotificationType.sos:
        return AppColors.errorColor;
      case NotificationType.healthUpdate:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.primaryLight;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.missedMedication:
        return Icons.medication_outlined;
      case NotificationType.medicationReminder:
        return Icons.alarm;
      case NotificationType.appointment:
        return Icons.event_note_outlined;
      case NotificationType.medicineStock:
        return Icons.inventory_2_outlined;
      case NotificationType.medicineExpiry:
        return Icons.warning_amber_outlined;
      case NotificationType.sos:
        return Icons.emergency_outlined;
      case NotificationType.healthUpdate:
        return Icons.monitor_heart_outlined;
      case NotificationType.system:
        return Icons.system_update_outlined;
    }
  }
}