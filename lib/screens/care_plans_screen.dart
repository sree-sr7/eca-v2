import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../database/db_helper.dart';
import '../screens/payment_screen.dart';

class CarePlansScreen extends StatefulWidget {
  final int userId;
  final bool isEmbedded; // Flag to indicate if this is embedded in admin screen
  final String? userEmail;
  final String? userPhone;
  final String? userName;

  const CarePlansScreen({
    Key? key,
    required this.userId,
    this.isEmbedded = false, // Default to standalone mode
    this.userEmail,
    this.userPhone,
    this.userName,
  }) : super(key: key);

  @override
  State<CarePlansScreen> createState() => _CarePlansScreenState();
}

class _CarePlansScreenState extends State<CarePlansScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _carePlans = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCarePlans = [];

  @override
  void initState() {
    super.initState();
    _loadCarePlans();

    _searchController.addListener(() {
      _filterCarePlans();
    });
  }

  void _filterCarePlans() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCarePlans = List.from(_carePlans);
      } else {
        _filteredCarePlans = _carePlans.where((plan) {
          final name = plan['careplan_name'].toString().toLowerCase();
          final description = plan['description'].toString().toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadCarePlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final carePlans = await _dbHelper.getCareplans();
      setState(() {
        _carePlans = carePlans;
        _filteredCarePlans = List.from(carePlans);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Failed to load care plans: $e");
    }
  }

  void _navigateToPayment(Map<String, dynamic> carePlan) {
    // User info validation
    if (widget.userEmail == null || widget.userPhone == null || widget.userName == null) {
      _showErrorSnackBar("User information is incomplete");
      return;
    }

    // Convert monthly rate to double
    final monthlyRate = carePlan['monthly_rate'] is double
        ? carePlan['monthly_rate']
        : double.parse(carePlan['monthly_rate'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: monthlyRate,
          userId: widget.userId,
          careplanId: carePlan['careplan_id'],
          userEmail: widget.userEmail!,
          userPhone: widget.userPhone!,
          userName: widget.userName!,
        ),
      ),
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only create a Scaffold if this is a standalone screen
    if (!widget.isEmbedded) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
          foregroundColor: isDarkMode ? AppColors.textLight : AppColors.textDark,
          title: const Text(
            "Care Plans Management",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCarePlans,
              tooltip: "Refresh Data",
            ),
          ],
        ),
        body: _buildContent(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCarePlanDialog(context),
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add),
        ),
      );
    } else {
      // If embedded, just return the content
      return Stack(
        children: [
          _buildContent(),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddCarePlanDialog(context),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomTextField(
            controller: _searchController,
            label: "Search Care Plans",
            hintText: "Search by name or description",
            prefixIcon: Icons.search,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCarePlansList(),
        ),
      ],
    );
  }

  Widget _buildCarePlansList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_filteredCarePlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _carePlans.isEmpty ? "No care plans found" : "No matching care plans",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (_carePlans.isEmpty) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: "Add First Care Plan",
                onPressed: () => _showAddCarePlanDialog(context),
                width: 200,
              ),
            ]
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCarePlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCarePlans.length,
        itemBuilder: (context, index) {
          final carePlan = _filteredCarePlans[index];
          return _buildCarePlanCard(carePlan);
        },
      ),
    );
  }

  Widget _buildCarePlanCard(Map<String, dynamic> carePlan) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final monthlyRate = carePlan['monthly_rate'] is double
        ? carePlan['monthly_rate']
        : double.parse(carePlan['monthly_rate'].toString());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            carePlan['careplan_name'] ?? "Unnamed Plan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          subtitle: Text(
            "₹${monthlyRate.toStringAsFixed(2)} per month",
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            child: const Icon(
              Icons.healing,
              color: Colors.white,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.payment, color: Colors.green),
                onPressed: () => _navigateToPayment(carePlan),
                tooltip: "Make Payment",
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.accentColor),
                onPressed: () => _showEditCarePlanDialog(context, carePlan),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.errorColor),
                onPressed: () => _confirmDeleteCarePlan(carePlan),
              ),
            ],
          ),
          children: [
            Text(
              carePlan['description'] ?? "No description provided",
              style: TextStyle(
                color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showCarePlanDetails(context, carePlan),
                  icon: const Icon(Icons.visibility),
                  label: const Text("View Details"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _navigateToPayment(carePlan),
                  icon: const Icon(Icons.payment),
                  label: const Text("Pay Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCarePlanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final rateController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Care Plan"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: "Plan Name",
                  hintText: "Enter care plan name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a plan name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  label: "Description",
                  hintText: "Enter plan description",
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: rateController,
                  label: "Monthly Rate (₹)",
                  hintText: "Enter monthly rate",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a monthly rate';
                    }
                    try {
                      double.parse(value);
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _dbHelper.insertCareplan(
                    careplanName: nameController.text,
                    description: descriptionController.text,
                    monthlyRate: double.parse(rateController.text),
                  );

                  Navigator.pop(context);
                  _loadCarePlans();
                  _showSuccessSnackBar("Care plan added successfully");
                } catch (e) {
                  _showErrorSnackBar("Failed to add care plan: $e");
                }
              }
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }

  void _showEditCarePlanDialog(BuildContext context, Map<String, dynamic> carePlan) {
    final nameController = TextEditingController(text: carePlan['careplan_name']);
    final descriptionController = TextEditingController(text: carePlan['description']);
    final rateController = TextEditingController(
      text: (carePlan['monthly_rate'] is double
          ? carePlan['monthly_rate']
          : double.parse(carePlan['monthly_rate'].toString()))
          .toStringAsFixed(2),
    );
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Care Plan"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: "Plan Name",
                  hintText: "Enter care plan name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a plan name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: descriptionController,
                  label: "Description",
                  hintText: "Enter plan description",
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: rateController,
                  label: "Monthly Rate (₹)",
                  hintText: "Enter monthly rate",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a monthly rate';
                    }
                    try {
                      double.parse(value);
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final updatedData = {
                    'careplan_name': nameController.text,
                    'description': descriptionController.text,
                    'monthly_rate': double.parse(rateController.text),
                  };

                  await _dbHelper.updateCareplan(
                    carePlan['careplan_id'],
                    updatedData,
                  );

                  Navigator.pop(context);
                  _loadCarePlans();
                  _showSuccessSnackBar("Care plan updated successfully");
                } catch (e) {
                  _showErrorSnackBar("Failed to update care plan: $e");
                }
              }
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCarePlan(Map<String, dynamic> carePlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Care Plan"),
        content: Text(
          "Are you sure you want to delete '${carePlan['careplan_name']}'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteCareplan(carePlan['careplan_id']);
                Navigator.pop(context);
                _loadCarePlans();
                _showSuccessSnackBar("Care plan deleted successfully");
              } catch (e) {
                _showErrorSnackBar("Failed to delete care plan: $e");
              }
            },
            child: const Text(
              "DELETE",
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCarePlanDetails(BuildContext context, Map<String, dynamic> carePlan) {
    final monthlyRate = carePlan['monthly_rate'] is double
        ? carePlan['monthly_rate']
        : double.parse(carePlan['monthly_rate'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(carePlan['careplan_name'] ?? "Care Plan Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("ID", "#${carePlan['careplan_id']}"),
            _buildDetailRow("Name", carePlan['careplan_name'] ?? ""),
            _buildDetailRow("Monthly Rate", "₹${monthlyRate.toStringAsFixed(2)}"),
            const SizedBox(height: 8),
            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(carePlan['description'] ?? "No description provided"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPayment(carePlan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Pay Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}