import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../database/db_helper.dart';

class CaregiverAssignmentDetailsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final bool hasExistingAssignment;
  final List<Map<String, dynamic>> availableCaregivers;
  final List<Map<String, dynamic>> availableCarePlans;

  const CaregiverAssignmentDetailsScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.hasExistingAssignment,
    required this.availableCaregivers,
    required this.availableCarePlans,
  }) : super(key: key);

  @override
  State<CaregiverAssignmentDetailsScreen> createState() =>
      _CaregiverAssignmentDetailsScreenState();
}

class _CaregiverAssignmentDetailsScreenState
    extends State<CaregiverAssignmentDetailsScreen> {
  final DBHelper _dbHelper = DBHelper();
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic>? _existingAssignment;
  Map<String, dynamic>? _existingPayment;

  // Use integer IDs instead of full maps for selected values
  int? _selectedCaregiverId;
  int? _selectedCareplanId;

  // Getter methods to retrieve the full objects when needed
  Map<String, dynamic>? get _selectedCaregiver =>
      _selectedCaregiverId != null ?
      widget.availableCaregivers.firstWhere((c) => c['user_id'] == _selectedCaregiverId,
          orElse: () => {}) : null;

  Map<String, dynamic>? get _selectedCareplan =>
      _selectedCareplanId != null ?
      widget.availableCarePlans.firstWhere((p) => p['careplan_id'] == _selectedCareplanId,
          orElse: () => {}) : null;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Assignment status options
  final List<String> _statusOptions = ['Active', 'Inactive', 'Completed'];
  String _selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get existing assignments for this user
      final assignments = await _dbHelper.getCaregiverAssignments(widget.userId);

      // Check if user has any payments with a care plan
      final payments = await _dbHelper.getPayments(widget.userId);
      if (payments.isNotEmpty) {
        // Find the most recent payment
        payments.sort((a, b) {
          final aDate = a['paid_at'] != null ? DateTime.parse(a['paid_at']) : DateTime(1970);
          final bDate = b['paid_at'] != null ? DateTime.parse(b['paid_at']) : DateTime(1970);
          return bDate.compareTo(aDate); // Most recent first
        });

        // Get the care plan ID from the most recent payment
        _existingPayment = payments.first;
        if (_selectedCareplanId == null) {
          _selectedCareplanId = _existingPayment!['careplan_id'];
        }
      }

      if (assignments.isNotEmpty) {
        // Get the active assignment if it exists
        final activeAssignment = assignments
            .where((a) => a['status'] == 'Active')
            .toList();

        if (activeAssignment.isNotEmpty) {
          _existingAssignment = activeAssignment.first;

          // Set selected IDs
          _selectedCaregiverId = _existingAssignment!['caregiver_id'];

          // Only set careplan from assignment if not already set from payment
          if (_selectedCareplanId == null) {
            _selectedCareplanId = _existingAssignment!['careplan_id'];
          }

          // Set dates
          try {
            _startDate = DateTime.parse(_existingAssignment!['start_date']);
            _endDate = DateTime.parse(_existingAssignment!['end_date']);

            _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
            _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
          } catch (e) {
            // Handle date parsing errors
            print("Error parsing dates: $e");
          }

          // Set status
          _selectedStatus = _existingAssignment!['status'] ?? 'Active';
        }
      }
    } catch (e) {
      _showErrorSnackBar("Failed to load assignment data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate(bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStartDate
        ? _startDate ?? now
        : _endDate ?? ((_startDate != null) ? _startDate!.add(const Duration(days: 30)) : now.add(const Duration(days: 30)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStartDate ? now : (_startDate ?? now),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);

          // If end date is before start date, update end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 30));
            _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _saveAssignment() async {
    // Validate inputs
    if (_selectedCaregiverId == null) {
      _showErrorSnackBar("Please select a caregiver");
      return;
    }

    if (_selectedCareplanId == null) {
      _showErrorSnackBar("Please select a care plan");
      return;
    }

    if (_startDate == null) {
      _showErrorSnackBar("Please select a start date");
      return;
    }

    if (_endDate == null) {
      _showErrorSnackBar("Please select an end date");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create or update payment record
      final selectedPlan = await _dbHelper.getCareplanById(_selectedCareplanId!);
      if (selectedPlan != null) {
        // Create a transaction ID if needed
        final tempTransactionId = 'assignment_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';

        if (_existingPayment != null) {
          // Update existing payment - use 'Paid' instead of 'Active'
          await _dbHelper.updatePayment(
              _existingPayment!['payment_id'],
              {
                'careplan_id': _selectedCareplanId,
                'amount': selectedPlan['monthly_rate'],
                'status': 'Paid', // Changed from 'Active' to 'Paid' to match constraint
              }
          );
        } else {
          // Insert new payment record - use 'Paid' instead of 'Active'
          await _dbHelper.insertPayment(
              userId: widget.userId,
              careplanId: _selectedCareplanId!,
              amount: selectedPlan['monthly_rate'],
              transactionId: tempTransactionId,
              paymentMethod: 'system',
              status: 'Paid' // Changed from 'Active' to 'Paid' to match constraint
          );
        }
      }

      if (_existingAssignment != null) {
        // Update existing assignment
        await _dbHelper.updateCaregiverAssignment(
          _existingAssignment!['assignment_id'],
          {
            "caregiver_id": _selectedCaregiverId,
            "careplan_id": _selectedCareplanId,
            "start_date": DateFormat('yyyy-MM-dd').format(_startDate!),
            "end_date": DateFormat('yyyy-MM-dd').format(_endDate!),
            "status": _selectedStatus,
          },
        );
      } else {
        // Create new assignment
        await _dbHelper.insertCaregiverAssignment(
          userId: widget.userId,
          caregiverId: _selectedCaregiverId!,
          careplanId: _selectedCareplanId!,
          startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
          status: _selectedStatus,
        );
      }

      // Return success to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar("Failed to save assignment: $e");
      setState(() {
        _isSaving = false;
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

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        title: Text(
          widget.hasExistingAssignment ? "Manage Assignment" : "New Assignment",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Container(
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
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.hasExistingAssignment
                              ? "Has active assignment"
                              : "No active assignment",
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.hasExistingAssignment
                                ? AppColors.success
                                : textColor.withOpacity(0.7),
                          ),
                        ),
                        if (_existingPayment != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Payment Status: ${_existingPayment!['status']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: _existingPayment!['status'] == 'Paid'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Assignment Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Caregiver selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Caregiver",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: Text(
                        'Select a caregiver',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      value: _selectedCaregiverId,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      items: widget.availableCaregivers
                          .map<DropdownMenuItem<int>>(
                            (caregiver) => DropdownMenuItem(
                          value: caregiver['user_id'],
                          child: Text(
                            "${caregiver['first_name']} ${caregiver['last_name']}",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedCaregiverId = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Care plan selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Care Plan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    if (_existingPayment != null)
                      Text(
                        "(Set from payment history)",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: Text(
                        'Select a care plan',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      value: _selectedCareplanId,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      items: widget.availableCarePlans
                          .map<DropdownMenuItem<int>>(
                            (plan) => DropdownMenuItem(
                          value: plan['careplan_id'],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  plan['careplan_name'],
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "\$${plan['monthly_rate'].toStringAsFixed(2)}/mo",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedCareplanId = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date range selection
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _startDateController,
                    label: "Start Date",
                    hintText: "YYYY-MM-DD",
                    prefixIcon: Icons.calendar_today,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _endDateController,
                    label: "End Date",
                    hintText: "YYYY-MM-DD",
                    prefixIcon: Icons.calendar_today,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status selection (for existing assignments)
            if (_existingAssignment != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assignment Status",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        items: _statusOptions
                            .map<DropdownMenuItem<String>>(
                              (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStatus = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Submit button
            PrimaryButton(
              text: _existingAssignment != null ? "Update Assignment" : "Create Assignment",
              onPressed: _saveAssignment,
              isLoading: _isSaving,
              icon: _existingAssignment != null ? Icons.update : Icons.add,
            ),

            const SizedBox(height: 16),

            // Delete button (for existing assignments)
            if (_existingAssignment != null)
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
                      _isSaving = true;
                    });

                    try {
                      await _dbHelper.updateCaregiverAssignment(
                        _existingAssignment!['assignment_id'],
                        {"status": "Completed"},
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      _showErrorSnackBar("Failed to end assignment: $e");
                      setState(() {
                        _isSaving = false;
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

  Color _getStatusColor(String status) {
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