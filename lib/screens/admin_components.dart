import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';

// User related components
void showAdminProfileDialog(BuildContext context, Map<String, dynamic>? adminData) {
  if (adminData == null) return;

  // Calculate age from date of birth if available
  String age = "Not available";
  if (adminData['date_of_birth'] != null && adminData['date_of_birth'].toString().isNotEmpty) {
    try {
      final birthDate = DateTime.parse(adminData['date_of_birth']);
      final today = DateTime.now();
      int calculatedAge = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }
      age = calculatedAge.toString();
    } catch (e) {
      // If date parsing fails, leave as "Not available"
    }
  }

  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
      title: Text("Admin Profile",
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildAdminProfileItem("Name", "${adminData['first_name']} ${adminData['last_name']}", isDarkMode),
          buildAdminProfileItem("Email", adminData['email'] ?? "Not available", isDarkMode),
          buildAdminProfileItem("ID", adminData['user_id'].toString(), isDarkMode),
          buildAdminProfileItem("Role", adminData['role'] ?? "Admin", isDarkMode),
          buildAdminProfileItem("Age", age, isDarkMode),
          if (adminData['date_of_birth'] != null)
            buildAdminProfileItem("Date of Birth", adminData['date_of_birth'], isDarkMode),
          if (adminData['phone_number'] != null)
            buildAdminProfileItem("Phone", adminData['phone_number'], isDarkMode),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("CLOSE",
            style: TextStyle(
              color: AppColors.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper widget for admin profile details
Widget buildAdminProfileItem(String label, String value, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildNoSearchResults(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 64,
          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          "No users match your search",
          style: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget buildUserDetailItem(BuildContext context, String label, String value) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis, // Add overflow handling
            maxLines: 1, // Limit to one line
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis, // Add overflow handling
            maxLines: 2, // Allow two lines for value
          ),
        ),
      ],
    ),
  );
}

Widget buildUserCard(
    BuildContext context,
    Map<String, dynamic> user, {
      required VoidCallback onDelete,
      required VoidCallback onEdit,
    }) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  // Calculate age from date of birth if available
  String age = "N/A";
  if (user['date_of_birth'] != null && user['date_of_birth'].toString().isNotEmpty) {
    try {
      final birthDate = DateTime.parse(user['date_of_birth']);
      final today = DateTime.now();
      int calculatedAge = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }
      age = "$calculatedAge years";
    } catch (e) {
      // If date parsing fails, leave as "N/A"
    }
  }

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
          "${user['first_name']} ${user['last_name']}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? AppColors.textLight : AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis, // Add overflow handling
          maxLines: 1, // Limit to one line
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? "No email",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis, // Add overflow handling
              maxLines: 1, // Limit to one line
            ),
            Text(
              "Age: $age",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis, // Add overflow handling
              maxLines: 1, // Limit to one line
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            (user['first_name']?[0] ?? "?").toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.accentColor),
          onPressed: onEdit,
        ),
        children: [
          buildUserDetailItem(context, "Phone", user['phone_number'] ?? "Not provided"),
          buildUserDetailItem(context, "Gender", user['gender'] ?? "Not provided"),
          buildUserDetailItem(context, "Date of Birth", user['date_of_birth'] ?? "Not provided"),
          buildUserDetailItem(context, "Age", age),
          buildUserDetailItem(context, "Address", user['address'] ?? "Not provided"),
          buildUserDetailItem(context, "Blood Group", user['blood_group'] ?? "Not provided"),

          const Divider(height: 24),
          const Text(
            "Emergency Contact",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          buildUserDetailItem(context, "Name", user['emergency_contact_name'] ?? "Not provided"),
          buildUserDetailItem(context, "Phone", user['emergency_contact_phone'] ?? "Not provided"),
          buildUserDetailItem(context, "Relationship", user['relationship'] ?? "Not provided"),

          const Divider(height: 24),
          const Text(
            "Medical Information",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          buildUserDetailItem(context, "Chronic Conditions", user['chronic_conditions'] ?? "None"),
          buildUserDetailItem(context, "Allergies", user['allergies'] ?? "None"),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppColors.errorColor),
                label: const Text(
                  "Delete User",
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Statistics related components
Widget buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required BuildContext context,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Card(
    elevation: 2,
    color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              Icon(
                icon,
                color: color.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildStatisticsTab(BuildContext context, List<Map<String, dynamic>> users) {
  // Simple statistics about your users
  final totalUsers = users.length;
  final maleUsers = users.where((user) => user['gender'] == 'Male').length;
  final femaleUsers = users.where((user) => user['gender'] == 'Female').length;
  final otherUsers = totalUsers - maleUsers - femaleUsers;

  // Age statistics
  int usersWithAge = 0;
  int totalAge = 0;
  int usersUnder30 = 0;
  int users30to60 = 0;
  int usersOver60 = 0;

  // Calculate age statistics
  for (var user in users) {
    if (user['date_of_birth'] != null && user['date_of_birth'].toString().isNotEmpty) {
      try {
        final birthDate = DateTime.parse(user['date_of_birth']);
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        usersWithAge++;
        totalAge += age;

        if (age < 30) {
          usersUnder30++;
        } else if (age <= 60) {
          users30to60++;
        } else {
          usersOver60++;
        }
      } catch (e) {
        // Skip if date parsing fails
      }
    }
  }

  // Calculate average age
  final avgAge = usersWithAge > 0 ? (totalAge / usersWithAge).toStringAsFixed(1) : "N/A";

  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildStatCard(
          title: "Total Users",
          value: totalUsers.toString(),
          icon: Icons.people,
          color: AppColors.primaryColor,
          context: context,
        ),
        const SizedBox(height: 16),

        const Text(
          "User Demographics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildStatCard(
                title: "Male",
                value: "$maleUsers",
                icon: Icons.male,
                color: Colors.blue,
                context: context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildStatCard(
                title: "Female",
                value: "$femaleUsers",
                icon: Icons.female,
                color: Colors.pink,
                context: context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildStatCard(
                title: "Other",
                value: "$otherUsers",
                icon: Icons.person,
                color: Colors.purple,
                context: context,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Age Statistics
        const Text(
          "Age Statistics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        buildStatCard(
          title: "Average Age",
          value: avgAge,
          icon: Icons.calendar_today,
          color: Colors.teal,
          context: context,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: buildStatCard(
                title: "Under 30",
                value: "$usersUnder30",
                icon: Icons.child_care,
                color: Colors.green,
                context: context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildStatCard(
                title: "30-60",
                value: "$users30to60",
                icon: Icons.person,
                color: Colors.amber,
                context: context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildStatCard(
                title: "Over 60",
                value: "$usersOver60",
                icon: Icons.elderly,
                color: Colors.indigo,
                context: context,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Health Condition Statistics
        const Text(
          "Health Conditions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Count users with chronic conditions
        buildStatCard(
          title: "With Chronic Conditions",
          value: "${users.where((user) =>
          user['chronic_conditions'] != null &&
              user['chronic_conditions'] != 'None' &&
              user['chronic_conditions'].toString().isNotEmpty
          ).length}",
          icon: Icons.medical_services,
          color: Colors.orange,
          context: context,
        ),

        const SizedBox(height: 16),

        // Count users with allergies
        buildStatCard(
          title: "With Allergies",
          value: "${users.where((user) =>
          user['allergies'] != null &&
              user['allergies'] != 'None' &&
              user['allergies'].toString().isNotEmpty
          ).length}",
          icon: Icons.warning_amber,
          color: Colors.red,
          context: context,
        ),

        const SizedBox(height: 24),
        const Text(
          "Emergency Contacts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        buildStatCard(
          title: "With Emergency Contacts",
          value: "${users.where((user) =>
          user['emergency_contact_name'] != null &&
              user['emergency_contact_name'].toString().isNotEmpty
          ).length}",
          icon: Icons.contact_phone,
          color: Colors.green,
          context: context,
        ),
      ],
    ),
  );
}