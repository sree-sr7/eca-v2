import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../database/db_helper.dart';
import '../screens/payment_screen.dart'; // Import the PaymentScreen

class CarePlanSelectionScreen extends StatefulWidget {
  final int userId;

  const CarePlanSelectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CarePlanSelectionScreenState createState() => _CarePlanSelectionScreenState();
}

class _CarePlanSelectionScreenState extends State<CarePlanSelectionScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _carePlans = [];
  bool _isLoading = true;
  int? _selectedPlanId;
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _loadCarePlans();
    _loadUserSelectedPlan();
    _loadUserDetails();
  }

  // Load user details needed for payment
  Future<void> _loadUserDetails() async {
    try {
      final user = await _dbHelper.getUserById(widget.userId);
      if (user != null) {
        setState(() {
          _userDetails = user;
        });
      }
    } catch (e) {
      print('Failed to load user details: $e');
    }
  }

  // Load user's selected plan from the database
  Future<void> _loadUserSelectedPlan() async {
    try {
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
        setState(() {
          _selectedPlanId = payments.first['careplan_id'];
        });
        return;
      }

      // If no payments, check if user has any caregiver assignments
      final assignments = await _dbHelper.getCaregiverAssignments(widget.userId);
      if (assignments.isNotEmpty) {
        // Find active assignments
        final activeAssignments = assignments.where((a) =>
        a['status'] == 'Active' &&
            DateTime.parse(a['end_date']).isAfter(DateTime.now())
        ).toList();

        if (activeAssignments.isNotEmpty) {
          setState(() {
            _selectedPlanId = activeAssignments.first['careplan_id'];
          });
        }
      }
    } catch (e) {
      print('Failed to load user selected plan: $e');
    }
  }

  Future<void> _loadCarePlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plans = await _dbHelper.getCareplans();
      setState(() {
        _carePlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load care plans');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectCarePlan(int planId) async {
    try {
      // Store selection in the payment table with a pending status
      // This serves as a record of the user's selected plan
      final selectedPlan = await _dbHelper.getCareplanById(planId);
      if (selectedPlan != null) {
        // Create a temporary transaction ID
        final tempTransactionId = 'pending_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';

        // Check if a pending payment already exists for this user
        final payments = await _dbHelper.getPayments(widget.userId);
        final pendingPayments = payments.where((p) => p['status'] == 'Pending').toList();

        if (pendingPayments.isNotEmpty) {
          // Update existing pending payment
          await _dbHelper.updatePayment(
              pendingPayments.first['payment_id'],
              {
                'careplan_id': planId,
                'amount': selectedPlan['monthly_rate'],
                'transaction_id': tempTransactionId,
              }
          );
        } else {
          // Insert new pending payment
          await _dbHelper.insertPayment(
              userId: widget.userId,
              careplanId: planId,
              amount: selectedPlan['monthly_rate'],
              transactionId: tempTransactionId,
              paymentMethod: 'pending',
              status: 'Pending'
          );
        }

        setState(() {
          _selectedPlanId = planId;
        });

        _showSuccessSnackBar('Care plan selected successfully!');

        // Navigate to payment screen with necessary parameters
        _navigateToPaymentScreen(planId, selectedPlan['monthly_rate']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select care plan: ${e.toString()}');
    }
  }

  // New method to navigate to payment screen
  void _navigateToPaymentScreen(int careplanId, double amount) {
    if (_userDetails == null) {
      _showErrorSnackBar('Unable to load user details for payment');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: amount,
          userId: widget.userId,
          careplanId: careplanId,
          userEmail: _userDetails!['email'] ?? '',
          userPhone: _userDetails!['phone'] ?? '',
          userName: '${_userDetails!['first_name'] ?? ''} ${_userDetails!['last_name'] ?? ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Care Plan"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gradientBlue,
                AppColors.gradientPink,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _carePlans.isEmpty
          ? _buildEmptyState()
          : _buildCarePlanList(isDarkMode),
      floatingActionButton: _selectedPlanId != null
          ? FloatingActionButton.extended(
        onPressed: () async {
          // Get the selected plan details
          final selectedPlan = _carePlans.firstWhere(
                (plan) => plan['careplan_id'] == _selectedPlanId,
            orElse: () => {'monthly_rate': 0.0},
          );

          // Navigate to payment screen with all required parameters
          _navigateToPaymentScreen(_selectedPlanId!, selectedPlan['monthly_rate'] ?? 0.0);
        },
        label: const Text("Continue to Payment"),
        icon: const Icon(Icons.payment),
        backgroundColor: AppColors.primaryDark,
      )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "No care plans available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please contact administrator to add care plans",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCarePlans,
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _buildCarePlanList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _carePlans.length,
      itemBuilder: (context, index) {
        final plan = _carePlans[index];
        final bool isSelected = _selectedPlanId == plan['careplan_id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primaryDark : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => _selectCarePlan(plan['careplan_id']),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan['careplan_name'] ?? "Unnamed Plan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan['description'] ?? "No description available",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.primaryDark.withOpacity(0.3)
                              : AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "₹${plan['monthly_rate']?.toStringAsFixed(2) ?? '0.00'}/month",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectCarePlan(plan['careplan_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.primaryDark
                              : isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          foregroundColor: isSelected
                              ? Colors.white
                              : isDarkMode
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                        child: Text(isSelected ? "Selected" : "Select Plan"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}