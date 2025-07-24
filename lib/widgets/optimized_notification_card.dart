import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../utils/app_colors.dart';
import '../models/notification_model.dart';
import '../utils/performance_optimizer.dart';

/// Optimized notification card with performance improvements
class OptimizedNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const OptimizedNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cacheKey =
        'notification_card_${notification.id}_${notification.isRead}';

    return PerformanceOptimizer.getCachedWidget(
      cacheKey,
      () => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Pre-calculate colors to avoid repeated theme lookups
    final cardColor =
        isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightCardColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final tertiaryTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    final notificationColor = _getNotificationColor(notification.type);
    final brighterColor =
        isDarkMode ? _getBrighterColor(notificationColor) : notificationColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: _buildDismissBackground(),
        onDismissed: (direction) => onDismiss(),
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border:
                      notification.isRead
                          ? null
                          : Border.all(color: notificationColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      brighterColor,
                      textColor,
                      tertiaryTextColor,
                      isDarkMode,
                    ),
                    _buildMessage(secondaryTextColor),
                    if (_shouldShowActions(notification.type))
                      _buildActions(context, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      decoration: BoxDecoration(
        color: AppColors.errorColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
    );
  }

  Widget _buildHeader(
    Color brighterColor,
    Color textColor,
    Color tertiaryTextColor,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brighterColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: brighterColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        notification.isRead ? FontWeight.w600 : FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(notification.time),
                  style: TextStyle(fontSize: 14, color: tertiaryTextColor),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: brighterColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        notification.message,
        style: TextStyle(fontSize: 16, color: secondaryTextColor, height: 1.4),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDarkMode) {
    return Padding(
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
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          // Action implementation will be added later
        },
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Color _getBrighterColor(Color color) {
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
