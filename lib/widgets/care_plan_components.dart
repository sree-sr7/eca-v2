import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../screens/payment_screen.dart';

// This widget displays a care plan preview/summary card for listings
Widget buildCarePlanPreviewCard({
  required BuildContext context,
  required Map<String, dynamic> carePlan,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onView,
  required Function(Map<String, dynamic>) onPay, // Added payment callback
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final monthlyRate = carePlan['monthly_rate'] is double
      ? carePlan['monthly_rate']
      : double.parse(carePlan['monthly_rate'].toString());

  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.medical_services_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        carePlan['careplan_name'] ?? "Unnamed Plan",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? AppColors.textLight : AppColors.textDark,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "₹${monthlyRate.toStringAsFixed(2)} / month",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _truncateText(carePlan['description'] ?? "No description", 60),
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.payment, color: Colors.green),
            onPressed: () => onPay(carePlan),
            tooltip: "Make Payment",
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: AppColors.primaryColor),
            onPressed: onView,
            tooltip: "View Details",
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accentColor),
            onPressed: onEdit,
            tooltip: "Edit",
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.errorColor),
            onPressed: onDelete,
            tooltip: "Delete",
          ),
        ],
      ),
    ),
  );
}

// This widget displays care plan details in a more comprehensive format
Widget buildCarePlanDetailsCard({
  required BuildContext context,
  required Map<String, dynamic> carePlan,
  required Function(Map<String, dynamic>) onPay, // Added payment callback
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final monthlyRate = carePlan['monthly_rate'] is double
      ? carePlan['monthly_rate']
      : double.parse(carePlan['monthly_rate'].toString());

  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carePlan['careplan_name'] ?? "Unnamed Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plan ID: #${carePlan['careplan_id']}",
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            context: context,
            title: "Monthly Cost",
            value: "₹${monthlyRate.toStringAsFixed(2)}",
            icon: Icons.currency_rupee,
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            "Description",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            carePlan['description'] ?? "No description provided",
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onPay(carePlan),
              icon: const Icon(Icons.payment),
              label: const Text("Make Payment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper widget to display information in a row format
Widget buildInfoRow({
  required BuildContext context,
  required String title,
  required String value,
  required IconData icon,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.accentColor,
        ),
        const SizedBox(width: 8),
        Text(
          "$title: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper function to truncate long text
String _truncateText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

// Example usage in a screen/page where care plans are displayed
class CarePlanListingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> carePlans; // Your care plan data
  final int userId;
  final String userEmail;
  final String userPhone;
  final String userName;

  const CarePlanListingScreen({
    Key? key,
    required this.carePlans,
    required this.userId,
    required this.userEmail,
    required this.userPhone,
    required this.userName,
  }) : super(key: key);

  void _navigateToPayment(BuildContext context, Map<String, dynamic> carePlan) {
    // Convert monthly rate to double
    final monthlyRate = carePlan['monthly_rate'] is double
        ? carePlan['monthly_rate']
        : double.parse(carePlan['monthly_rate'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: monthlyRate,
          userId: userId,
          careplanId: carePlan['careplan_id'],
          userEmail: userEmail,
          userPhone: userPhone,
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Plans'),
      ),
      body: ListView.builder(
        itemCount: carePlans.length,
        itemBuilder: (context, index) {
          final carePlan = carePlans[index];
          return buildCarePlanPreviewCard(
            context: context,
            carePlan: carePlan,
            onEdit: () {
              // Your edit function
            },
            onDelete: () {
              // Your delete function
            },
            onView: () {
              // Your view function
            },
            onPay: (carePlan) => _navigateToPayment(context, carePlan),
          );
        },
      ),
    );
  }
}