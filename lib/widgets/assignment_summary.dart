import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AssignmentSummaryWidget extends StatelessWidget {
  final String caregiverName;
  final String careplanName;
  final double monthlyRate;
  final String startDate;
  final String endDate;
  final String status;
  final int daysRemaining;

  const AssignmentSummaryWidget({
    Key? key,
    required this.caregiverName,
    required this.careplanName,
    required this.monthlyRate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.daysRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    Color statusColor;
    switch (status) {
      case 'Active':
        statusColor = AppColors.success;
        break;
      case 'Inactive':
        statusColor = AppColors.warning;
        break;
      case 'Completed':
        statusColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
        break;
      default:
        statusColor = textColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assignment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Caregiver',
            caregiverName,
            Icons.person,
            AppColors.accentColor,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            'Care Plan',
            careplanName,
            Icons.medical_services,
            AppColors.primaryColor,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            context,
            'Monthly Rate',
            '\$${monthlyRate.toStringAsFixed(2)}',
            Icons.attach_money,
            AppColors.success,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  context,
                  'Start Date',
                  startDate,
                  Icons.calendar_today,
                  AppColors.accentColor,
                ),
              ),
              Expanded(
                child: _buildDetailRow(
                  context,
                  'End Date',
                  endDate,
                  Icons.event,
                  AppColors.warningColor,
                ),
              ),
            ],
          ),
          if (status == 'Active' && daysRemaining > 0) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    '$daysRemaining days remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color iconColor,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}