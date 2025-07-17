import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../screens/medicine_management_screen.dart';
import '../screens/doctor_appointment_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/caregiver_information_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/notifications_alerts_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/care_plan_selection_screen.dart';
import '../database/db_helper.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const HomeScreen({Key? key, this.userName = "User", required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper(); // Add this to access the database
  int _activeCareplanId = 1; // Default value, should be fetched from DB
  String _userEmail = "";
  String _userPhone = "";
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data on initialization
  Future<void> _loadUserData() async {
    try {
      final userData = await _dbHelper.getUserById(widget.userId);
      if (userData != null) {
        setState(() {
          _userEmail = userData['email'] ?? "";
          _userPhone = userData['phone_number'] ?? "";
          _userName = "${userData['first_name']} ${userData['last_name']}";
        });
      }

      // Get the active careplan ID if available
      final assignments = await _dbHelper.getCaregiverAssignments(widget.userId);
      if (assignments.isNotEmpty) {
        for (var assignment in assignments) {
          if (assignment['status'] == 'Active') {
            setState(() {
              _activeCareplanId = assignment['careplan_id'];
            });
            break;
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: DashboardScreen(userId: widget.userId),
      ),
      drawer: _buildDrawer(context, isDarkMode),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Patient",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.medication,
            title: "Medication Management",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineManagementScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_month,
            title: "Appointment Management",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorAppointmentScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: "Profile",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: "Settings",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              final appSettings = Provider.of<AppSettings>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(settings: appSettings),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.medical_services,
            title: "Select Care Plan",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              // Make sure you've created this screen file and class
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarePlanSelectionScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: "Caregiver Information",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaregiverInformationScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.payment,
            title: "Make Payment",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    userId: widget.userId,
                    careplanId: _activeCareplanId,
                    userEmail: _userEmail,
                    userPhone: _userPhone,
                    userName: _userName,
                  ),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: "Payment History",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentHistoryScreen(userId: widget.userId),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.notifications_active,
            title: "Notifications & Alerts",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsAlertsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: "Help & Support",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Help & Support coming soon")),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: "Logout",
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : AppColors.primaryDark,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : AppColors.textDark,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}