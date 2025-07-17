import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../database/db_helper.dart';
import '../widgets/assignment_summary.dart';
import 'caregiver_assignment_details.dart';

class CaregiverAssignmentSummaryScreen extends StatefulWidget {
  final int userId;
  final int assignmentId;
  final String userName;

  const CaregiverAssignmentSummaryScreen({
    Key? key,
    required this.userId,
    required this.assignmentId,
    required this.userName,
  }) : super(key: key);

  @override
  State<CaregiverAssignmentSummaryScreen> createState() =>
      _CaregiverAssignmentSummaryScreenState();
}

class _CaregiverAssignmentSummaryScreenState
    extends State<CaregiverAssignmentSummaryScreen> {
  final DBHelper _dbHelper = DBHelper();
  bool _isLoading = true;
  Map<String, dynamic>? _assignment;
  Map<String, dynamic>? _caregiver;
  Map<String, dynamic>? _careplan;
  List<Map<String, dynamic>> _medications = [];
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadAssignmentData();
  }

  Future<void> _loadAssignmentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the assignment details
      final assignments = await _dbHelper.getCaregiverAssignments(widget.userId);
      final assignment = assignments.firstWhere(
            (a) => a['assignment_id'] == widget.assignmentId,
        orElse: () => throw Exception('Assignment not found'),
      );
      _assignment = assignment;

      // Get caregiver details
      final caregiver = await _dbHelper.getUserById(assignment['caregiver_id']);
      if (caregiver != null) {
        _caregiver = caregiver;
      }

      // Get careplan details
      final careplan = await _dbHelper.getCareplanById(assignment['careplan_id']);
      if (careplan != null) {
        _careplan = careplan;
      }

      // Get medications for this user
      _medications = await _dbHelper.getMedications(widget.userId);

      // Calculate days remaining in the assignment
      try {
        final endDate = DateTime.parse(assignment['end_date']);
        final now = DateTime.now();
        _daysRemaining = endDate.difference(now).inDays;
        if (_daysRemaining < 0) _daysRemaining = 0;
      } catch (e) {
        print("Error calculating days remaining: $e");
        _daysRemaining = 0;
      }
    } catch (e) {
      _showErrorSnackBar("Failed to load assignment data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navigateToEditAssignment() async {
    if (_caregiver == null || _careplan == null) {
      _showErrorSnackBar("Missing caregiver or care plan data");
      return;
    }

    // Get available caregivers and care plans for editing
    final caregivers = await _dbHelper.getUsersByRole('caregiver');
    final carePlans = await _dbHelper.getCareplans();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverAssignmentDetailsScreen(
          userId: widget.userId,
          userName: widget.userName,
          hasExistingAssignment: true,
          availableCaregivers: caregivers,
          availableCarePlans: carePlans,
        ),
      ),
    );

    if (result == true) {
      _loadAssignmentData(); // Refresh data
      _showSuccessSnackBar("Assignment updated successfully");
    }
  }

  Widget _buildMedicationSection(bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;

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
                'Medications (${_medications.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (_medications.isNotEmpty)
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _medications.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No medications assigned',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          )
              : Column(
            children: _medications
                .take(3) // Show only first 3 medications
                .map(
                  (med) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medication,
                          size: 16,
                          color: AppColors.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['medication_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${med['dosage'] ?? ''} - ${med['frequency'] ?? 'As needed'}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .toList(),
          ),
          if (_medications.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  '+ ${_medications.length - 3} more medications',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingVisits(bool isDarkMode) {
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;

    // For demo purposes, we'll create some upcoming visits
    // In a real app, these would come from the database
    final visits = [
      {
        'date': DateTime.now().add(const Duration(days: 1)),
        'time': '10:00 AM',
        'duration': '1 hour',
      },
      {
        'date': DateTime.now().add(const Duration(days: 3)),
        'time': '2:30 PM',
        'duration': '45 minutes',
      },
    ];

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
          Text(
            'Upcoming Visits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...visits.map(
                (visit) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(visit['date'] as DateTime),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: textColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${visit['time']} (${visit['duration']})',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: textColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ).toList(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to visits screen
              },
              child: Text(
                'Schedule New Visit',
                style: TextStyle(
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: const Text(
          "Assignment Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditAssignment,
            tooltip: "Edit Assignment",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignment == null || _caregiver == null || _careplan == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Assignment not found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Go Back",
              onPressed: () => Navigator.pop(context),
              width: 150,
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.accentColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_assignment!['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _assignment!['status'] ?? 'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_assignment!['status']),
                                ),
                              ),
                            ),
                            if (_daysRemaining > 0 && _assignment!['status'] == 'Active') ...[
                              const SizedBox(width: 8),
                              Text(
                                '$_daysRemaining days remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Assignment summary widget
            AssignmentSummaryWidget(
              caregiverName: "${_caregiver!['first_name']} ${_caregiver!['last_name']}",
              careplanName: _careplan!['careplan_name'] ?? 'Unknown',
              monthlyRate: _careplan!['monthly_rate'] ?? 0.0,
              startDate: _assignment!['start_date'] ?? '',
              endDate: _assignment!['end_date'] ?? '',
              status: _assignment!['status'] ?? 'Active',
              daysRemaining: _daysRemaining,
            ),

            const SizedBox(height: 20),

            // Medications section
            _buildMedicationSection(isDarkMode),

            const SizedBox(height: 20),

            // Upcoming visits
            _buildUpcomingVisits(isDarkMode),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: "Contact Caregiver",
                    onPressed: () {
                      // Contact action
                    },
                    icon: Icons.phone,
                    bgColor: AppColors.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: "View Reports",
                    onPressed: () {
                      // View reports action
                    },
                    icon: Icons.assessment,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_assignment!['status'] == 'Active')
              PrimaryButton(
                text: "End Assignment",
                onPressed: () async {
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("End Assignment"),
                      content: const Text(
                        "Are you sure you want to end this assignment? "
                            "This will mark the assignment as Completed.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("END ASSIGNMENT"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      await _dbHelper.updateCaregiverAssignment(
                        widget.assignmentId,
                        {"status": "Completed"},
                      );
                      _loadAssignmentData();
                      _showSuccessSnackBar("Assignment ended successfully");
                    } catch (e) {
                      _showErrorSnackBar("Failed to end assignment: $e");
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                bgColor: AppColors.errorColor,
                icon: Icons.cancel,
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Inactive':
        return AppColors.warning;
      case 'Completed':
        return isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
      default:
        return isDarkMode ? AppColors.textLight : AppColors.textDark;
    }
  }
}