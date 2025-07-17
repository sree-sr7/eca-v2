import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AssignmentCard extends StatelessWidget {
  final String name;
  final int age;
  final int medicationCount;
  final VoidCallback onTap;
  final Color? cardColor;
  final Color? textColor;

  const AssignmentCard({
    Key? key,
    required this.name,
    required this.age,
    required this.medicationCount,
    required this.onTap,
    this.cardColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = cardColor ??
        (isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor);
    final fontColor = textColor ??
        (isDarkMode ? AppColors.textLight : AppColors.textDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar with optimized container
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.accentColor.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: AppColors.accentColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // User details with expanded column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: fontColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildInfoChip(
                            context: context,
                            icon: Icons.calendar_today,
                            label: 'Age: $age',
                            fontColor: fontColor
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                            context: context,
                            icon: Icons.medication,
                            label: 'Medications: $medicationCount',
                            fontColor: fontColor
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: fontColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create info chips with icons
  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color fontColor
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: fontColor.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: fontColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}