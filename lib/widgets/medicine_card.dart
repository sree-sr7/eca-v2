import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../utils/app_colors.dart';

class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onTakenChanged;

  const MedicineCard({
    Key? key,
    required this.medicine,
    required this.onDelete,
    required this.onEdit,
    required this.onTakenChanged,
  }) : super(key: key);

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    // Status colors
    final warningColor = AppColors.warning;
    final expiryColor = widget.medicine.isExpired ? AppColors.errorColor :
    (widget.medicine.isExpiringSoon ? warningColor : Colors.green);
    final stockColor = widget.medicine.isLowStock ? warningColor : Colors.green;

    // Calculate next dose time
    final nextDose = widget.medicine.nextScheduledTime;
    final isTimeSoon = nextDose != null &&
        nextDose.difference(DateTime.now()).inHours < 4 &&
        !widget.medicine.isTaken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        border: isTimeSoon ? Border.all(
          color: AppColors.accentColor,
          width: 2,
        ) : null,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: widget.medicine.color.withOpacity(0.2),
                  child: Icon(widget.medicine.icon, color: widget.medicine.color),
                ),
                if (isTimeSoon)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.medicine.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.medicine.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.medicine.scheduleDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.medicine.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Dosage: ${widget.medicine.dosage}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Frequency: ${widget.medicine.frequency}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                if (widget.medicine.timeOfDay != null)
                  Row(
                    children: [
                      Text(
                        'Time: ${widget.medicine.formattedTime}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      if (isTimeSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            trailing: InkWell(
              onTap: () => widget.onTakenChanged(!widget.medicine.isTaken),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.medicine.isTaken
                      ? AppColors.success.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: widget.medicine.isTaken
                    ? Icon(Icons.check_circle, color: AppColors.success)
                    : Icon(Icons.circle_outlined, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                            size: 16,
                            color: stockColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${widget.medicine.stock}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                          if (widget.medicine.isLowStock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: warningColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Low',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_available,
                            size: 16,
                            color: expiryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${widget.medicine.expiryDate.toIso8601String().split('T')[0]}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                          if (widget.medicine.isExpired || widget.medicine.isExpiringSoon) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: expiryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.medicine.isExpired ? 'Expired' : 'Soon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: expiryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons row - Optimized for better FAB compatibility
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.accentColor,
                      onPressed: widget.onEdit,
                      tooltip: 'Edit medication',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      visualDensity: VisualDensity.compact,
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.errorColor,
                      onPressed: widget.onDelete,
                      tooltip: 'Delete medication',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      visualDensity: VisualDensity.compact,
                    ),
                    // Expand button - Optimized placement
                    IconButton(
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      tooltip: _expanded ? 'Show less' : 'Show more',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (widget.medicine.notes != null && widget.medicine.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.medicine.notes!,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildNextScheduleInfo(context, textColor),
          ],
          // Add sufficient bottom padding to ensure the expanded card content doesn't overlap with the FAB
          SizedBox(height: _expanded ? 24 : 8),
        ],
      ),
    );
  }

  Widget _buildNextScheduleInfo(BuildContext context, Color textColor) {
    final nextDose = widget.medicine.nextScheduledTime;
    if (nextDose == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final difference = nextDose.difference(now);

    String timeMessage;
    if (difference.isNegative) {
      timeMessage = 'Overdue';
    } else if (difference.inHours < 1) {
      timeMessage = 'In less than an hour';
    } else if (difference.inHours < 24) {
      timeMessage = 'In ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inDays < 7) {
      timeMessage = 'In ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else {
      timeMessage = 'On ${nextDose.toIso8601String().split('T')[0]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: textColor.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Next dose:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.medicine.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  difference.isNegative ? Icons.warning : Icons.access_time,
                  color: difference.isNegative ? AppColors.warning : widget.medicine.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeMessage,
                        style: TextStyle(
                          color: difference.isNegative ? AppColors.warning : widget.medicine.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!difference.isNegative)
                        Text(
                          'at ${nextDose.hour.toString().padLeft(2, '0')}:${nextDose.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (difference.isNegative && !widget.medicine.isTaken)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () => widget.onTakenChanged(true),
                    child: const Text('Mark Taken'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}