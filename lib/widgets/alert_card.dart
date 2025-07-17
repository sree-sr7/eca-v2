// widgets/alert_card.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AlertCard extends StatelessWidget {
  final String type;
  final String userName;
  final String details;
  final DateTime timestamp;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textColor;

  const AlertCard({
    Key? key,
    required this.type,
    required this.userName,
    required this.details,
    required this.timestamp,
    required this.onTap,
    required this.cardColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSOS = type == 'sos';
    final alertColor = isSOS ? AppColors.errorColor : AppColors.warning;
    final alertIcon = isSOS ? Icons.warning_amber : Icons.medication;

    // Format the timestamp as relative time (e.g., "30m ago")
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    String timeAgo;

    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alertIcon,
                    color: alertColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Alert details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isSOS ? 'SOS Alert' : 'Missed Medication',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: alertColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}