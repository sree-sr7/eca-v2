import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/sos_service.dart';

class SOSDialog extends StatefulWidget {
  final int userId;
  final Function? onSuccess;
  final Function? onCancel;

  const SOSDialog({
    Key? key,
    required this.userId,
    this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  _SOSDialogState createState() => _SOSDialogState();
}

class _SOSDialogState extends State<SOSDialog> {
  bool _isLoading = false;
  final SOSService _sosService = SOSService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? AppColors.darkCardColor : Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 8),
          Text(
            "Send Emergency Alert",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accentColor),
          SizedBox(height: 16),
          Text(
            "Sending emergency alert...",
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      )
          : Text(
        "This will send an urgent alert with your current location to all your emergency contacts.",
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: _isLoading
          ? []
          : [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (widget.onCancel != null) widget.onCancel!();
          },
          child: Text(
            "CANCEL",
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.primaryDark,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            setState(() {
              _isLoading = true;
            });

            bool success = await _sosService.sendSOSAlert(widget.userId);

            if (mounted) {
              Navigator.pop(context);
              if (success && widget.onSuccess != null) widget.onSuccess!();
            }
          },
          child: const Text("SEND ALERT"),
        ),
      ],
    );
  }
}