import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../utils/app_colors.dart';
import '../utils/performance_optimizer.dart';

/// Optimized medicine card with performance improvements and lazy loading
class OptimizedMedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onTakenChanged;

  const OptimizedMedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
    required this.onEdit,
    required this.onTakenChanged,
  });

  @override
  State<OptimizedMedicineCard> createState() => _OptimizedMedicineCardState();
}

class _OptimizedMedicineCardState extends State<OptimizedMedicineCard>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = false;

  // Keep alive to prevent unnecessary rebuilds
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final cacheKey = 'medicine_card_${widget.medicine.id}_$_expanded';

    return PerformanceOptimizer.getCachedWidget(cacheKey, () => _buildCard());
  }

  Widget _buildCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    // Pre-calculate expensive values
    final warningColor = AppColors.warning;
    final expiryColor =
        widget.medicine.isExpired
            ? AppColors.errorColor
            : (widget.medicine.isExpiringSoon ? warningColor : Colors.green);
    final stockColor = widget.medicine.isLowStock ? warningColor : Colors.green;

    final nextDose = widget.medicine.nextScheduledTime;
    final isTimeSoon =
        nextDose != null &&
        nextDose.difference(DateTime.now()).inHours < 4 &&
        !widget.medicine.isTaken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Reduced animation duration
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        border:
            isTimeSoon
                ? Border.all(color: AppColors.accentColor, width: 2)
                : null,
      ),
      child: Column(
        children: [
          _buildMainContent(isDarkMode, cardColor, textColor, isTimeSoon),
          _buildStatusRow(textColor, stockColor, expiryColor, warningColor),
          if (_expanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context, textColor, isDarkMode),
          ],
          SizedBox(height: _expanded ? 24 : 8),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    bool isTimeSoon,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: _buildLeadingIcon(cardColor, isTimeSoon),
      title: _buildTitle(textColor),
      subtitle: _buildSubtitle(textColor, isTimeSoon),
      trailing: _buildTrailingButton(),
    );
  }

  Widget _buildLeadingIcon(Color cardColor, bool isTimeSoon) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: widget.medicine.color.withValues(alpha: 0.2),
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
                border: Border.all(color: cardColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(Color textColor) {
    return Row(
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
            color: widget.medicine.color.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildSubtitle(Color textColor, bool isTimeSoon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Dosage: ${widget.medicine.dosage}',
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 2),
        Text(
          'Frequency: ${widget.medicine.frequency}',
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 2),
        if (widget.medicine.timeOfDay != null)
          Row(
            children: [
              Text(
                'Time: ${widget.medicine.formattedTime}',
                style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
              if (isTimeSoon) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withValues(alpha: 0.2),
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
    );
  }

  Widget _buildTrailingButton() {
    return InkWell(
      onTap: () => widget.onTakenChanged(!widget.medicine.isTaken),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:
              widget.medicine.isTaken
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child:
            widget.medicine.isTaken
                ? Icon(Icons.check_circle, color: AppColors.success)
                : Icon(Icons.circle_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusRow(
    Color textColor,
    Color stockColor,
    Color expiryColor,
    Color warningColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusItem(
                  Icons.inventory_2_outlined,
                  'Stock: ${widget.medicine.stock}',
                  stockColor,
                  textColor,
                  widget.medicine.isLowStock ? 'Low' : null,
                  warningColor,
                ),
                const SizedBox(height: 4),
                _buildStatusItem(
                  Icons.event_available,
                  'Expires: ${widget.medicine.expiryDate.toIso8601String().split('T')[0]}',
                  expiryColor,
                  textColor,
                  widget.medicine.isExpired
                      ? 'Expired'
                      : (widget.medicine.isExpiringSoon ? 'Soon' : null),
                  expiryColor,
                ),
              ],
            ),
          ),
          _buildActionButtons(textColor),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
    String? badge,
    Color? badgeColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: textColor.withValues(alpha: 0.8))),
        if (badge != null && badgeColor != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          Icons.edit_outlined,
          AppColors.accentColor,
          widget.onEdit,
          'Edit medication',
        ),
        _buildActionButton(
          Icons.delete_outline,
          AppColors.errorColor,
          widget.onDelete,
          'Delete medication',
        ),
        _buildActionButton(
          _expanded ? Icons.expand_less : Icons.expand_more,
          textColor.withValues(alpha: 0.6),
          () => setState(() => _expanded = !_expanded),
          _expanded ? 'Show less' : 'Show more',
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      iconSize: 20,
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    Color textColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        if (widget.medicine.notes != null && widget.medicine.notes!.isNotEmpty)
          _buildNotesSection(textColor, isDarkMode),
        _buildNextScheduleInfo(context, textColor),
      ],
    );
  }

  Widget _buildNotesSection(Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes,
                size: 16,
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.medicine.notes!,
              style: TextStyle(color: textColor.withValues(alpha: 0.8)),
            ),
          ),
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
      timeMessage =
          'In ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inDays < 7) {
      timeMessage =
          'In ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
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
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Next dose:',
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.medicine.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  difference.isNegative ? Icons.warning : Icons.access_time,
                  color:
                      difference.isNegative
                          ? AppColors.warning
                          : widget.medicine.color,
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
                          color:
                              difference.isNegative
                                  ? AppColors.warning
                                  : widget.medicine.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!difference.isNegative)
                        Text(
                          'at ${nextDose.hour.toString().padLeft(2, '0')}:${nextDose.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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
