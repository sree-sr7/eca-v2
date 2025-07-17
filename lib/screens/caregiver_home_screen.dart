import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/assignment_card.dart';
import '../widgets/alert_card.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../models/caregiver_notification.dart';
import '../screens/caregiver_profile_screen.dart';
import '../screens/settings_screen.dart';
import '../repository/caregiver_notification_repository.dart';

class CaregiverHomeScreen extends StatefulWidget {
  final int userId;

  const CaregiverHomeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> with SingleTickerProviderStateMixin {
  bool _isAvailable = true;
  late TabController _tabController;
  final DBHelper _dbHelper = DBHelper();
  final CaregiverNotificationRepository _notificationRepository = CaregiverNotificationRepository();
  String _caregiverName = "Caregiver";
  String _caregiverId = "";

  // Database-backed data
  List<Map<String, dynamic>> _assignedUsers = [];
  List<CaregiverNotification> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadCaregiverInfo(),
        _loadAssignedUsers(),
        _loadAlerts(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCaregiverInfo() async {
    try {
      final caregiverData = await _dbHelper.getUserById(widget.userId);
      if (caregiverData != null) {
        setState(() {
          _caregiverName = "${caregiverData['first_name']} ${caregiverData['last_name']}";
          _caregiverId = "CG${caregiverData['user_id']}";
        });
      }

      final profile = await _dbHelper.getCaregiverProfile(widget.userId);
      if (profile != null) {
        setState(() {
          _isAvailable = profile['availability'] == 'available';
        });
      }
    } catch (e) {
      throw Exception("Error loading caregiver info: $e");
    }
  }

  Future<void> _loadAssignedUsers() async {
    try {
      final assignments = await _dbHelper.getCaregiverClients(widget.userId);
      List<Map<String, dynamic>> users = [];

      for (var assignment in assignments) {
        final userId = assignment['user_id'];
        final userData = await _dbHelper.getUserById(userId);

        if (userData != null) {
          final medications = await _dbHelper.getMedications(userId);

          users.add({
            'id': userData['user_id'].toString(),
            'name': "${userData['first_name']} ${userData['last_name']}",
            'age': userData['age'] ?? 0,
            'medications': medications.length,
            'medicationsList': medications,
            'allergies': userData['allergies'] ?? 'None listed',
            'chronicConditions': userData['chronic_conditions'] ?? 'None listed',
            'bloodGroup': userData['blood_group'] ?? 'Not specified',
            'emergencyContact': userData['emergency_contact_name'] != null ?
            "${userData['emergency_contact_name']} (${userData['emergency_contact_phone'] ?? 'No phone'})" :
            'Not specified',
            'address': userData['address'] ?? 'Not specified',
          });
        }
      }

      setState(() => _assignedUsers = users);
    } catch (e) {
      throw Exception("Error loading assigned users: $e");
    }
  }

  Future<void> _loadAlerts() async {
    try {
      // Using the new repository to get notifications
      final notifications = await _notificationRepository.getNotifications(widget.userId);
      setState(() => _alerts = notifications);
    } catch (e) {
      throw Exception("Error loading alerts: $e");
    }
  }

  Future<void> _updateAvailabilityStatus(bool isAvailable) async {
    try {
      final caregiverProfile = await _dbHelper.getCaregiverProfile(widget.userId);
      if (caregiverProfile != null) {
        await _dbHelper.updateCaregiverProfile(
            caregiverProfile['caregiver_id'],
            {'availability': isAvailable ? 'available' : 'unavailable'}
        );
        setState(() => _isAvailable = isAvailable);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update availability status');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;
    final subTextColor = isDarkMode ? AppColors.textLight.withOpacity(0.7) : AppColors.textDark.withOpacity(0.7);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: backgroundColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User header
                  _buildUserHeader(user, textColor, subTextColor),
                  const SizedBox(height: 24),

                  // Medical information
                  _buildSectionTitle('Medical Information'),
                  const SizedBox(height: 8),
                  _buildDetailItem('Chronic Conditions', user['chronicConditions'], Icons.medical_services, textColor, subTextColor),
                  const Divider(),
                  _buildDetailItem('Allergies', user['allergies'], Icons.warning_amber, textColor, subTextColor),
                  const SizedBox(height: 24),

                  // Medications section
                  _buildSectionTitle('Medications (${user['medicationsList'].length})'),
                  const SizedBox(height: 8),
                  _buildMedicationsList(user['medicationsList'], textColor, subTextColor),
                  const SizedBox(height: 24),

                  // Contact information
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 8),
                  _buildDetailItem('Address', user['address'], Icons.home, textColor, subTextColor),
                  const Divider(),
                  _buildDetailItem('Emergency Contact', user['emergencyContact'], Icons.emergency, textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Close button
                  _buildCloseButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // UI Component Methods
  Widget _buildUserHeader(Map<String, dynamic> user, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: AppColors.accentColor, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Age: ${user['age']} • Blood Group: ${user['bloodGroup']}',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.accentColor,
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, color: subTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList(List medicationsList, Color textColor, Color subTextColor) {
    if (medicationsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No medications scheduled',
          style: TextStyle(fontSize: 16, color: subTextColor, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicationsList.length > 5 ? 5 : medicationsList.length,
      itemBuilder: (context, index) {
        final med = medicationsList[index];
        final isTaken = med['taken'] == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTaken ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTaken ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isTaken ? Icons.check_circle : Icons.access_time,
                color: isTaken ? AppColors.success : AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 2),
                    Text('${med['dosage']} • ${med['reminder_time']} • ${med['frequency']}',
                        style: TextStyle(fontSize: 14, color: subTextColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Stock: ${med['stock']}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subTextColor)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDrawer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Drawer(
      backgroundColor: backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home (Dashboard)',
            isSelected: true,
            onTap: () => Navigator.pop(context),
            textColor: textColor,
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => CaregiverProfileScreen(userId: widget.userId),
              )).then((_) => _loadData());
            },
            textColor: textColor,
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              // Get the AppSettings instance from the provider
              final appSettings = Provider.of<AppSettings>(context, listen: false);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => SettingsScreen(settings: appSettings),
              ));
            },
            textColor: textColor,
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => Navigator.pop(context),
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientBlue, AppColors.gradientPink],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35, color: AppColors.accentColor),
          ),
          const SizedBox(height: 10),
          Text(_caregiverName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('ID: $_caregiverId',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    bool isSelected = false,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.accentColor : textColor.withOpacity(0.7)),
      title: Text(title, style: TextStyle(
        color: isSelected ? AppColors.accentColor : textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      onTap: onTap,
      selected: isSelected,
    );
  }

  Widget _buildAssignedUsersTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    if (_assignedUsers.isEmpty) {
      return _buildEmptyState(Icons.people_outline, 'No assigned users', textColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _assignedUsers.length,
      itemBuilder: (context, index) {
        final user = _assignedUsers[index];
        return AssignmentCard(
          name: user['name'],
          age: user['age'],
          medicationCount: user['medications'],
          onTap: () => _showUserDetailsDialog(user),
          cardColor: cardColor,
          textColor: textColor,
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    if (_alerts.isEmpty) {
      return _buildEmptyState(Icons.notifications_none, 'No alerts', textColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];

        // Extract user name from notification if possible
        String userName = 'User';
        String details = alert.message;

        // If message contains a username part (before " - "), extract it
        if (alert.message.contains(' - ')) {
          final parts = alert.message.split(' - ');
          userName = parts[0];
          // Join the remaining parts back together
          details = parts.sublist(1).join(' - ');
        }

        return AlertCard(
          type: _getAlertTypeString(alert.type),
          userName: userName,
          details: details,
          timestamp: alert.createdAt,
          onTap: () async {
            try {
              await _notificationRepository.markAsRead(alert.id);
              _loadAlerts();
            } catch (e) {
              print("Error marking notification as read: $e");
            }
          },
          cardColor: cardColor,
          textColor: textColor,
        );
      },
    );
  }

// Helper method to convert NotificationType to string
  String _getAlertTypeString(NotificationType type) {
    switch (type) {
      case NotificationType.missedMedication:
        return 'missed';
      case NotificationType.upcomingAppointment:
        return 'appointment';
      case NotificationType.lowStock:
        return 'stock';
      case NotificationType.expiringMedication:
        return 'expiry';
      case NotificationType.other:
        return 'general';
    }
  }

  Widget _buildEmptyState(IconData icon, String message, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accentColor),
          SizedBox(height: 16),
          Text('Loading data...'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
            'Caregiver Dashboard',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
      ),
      drawer: _buildDrawer(),
      body: _isLoading ? _buildLoadingIndicator() : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Text(
                        'Availability:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isAvailable,
                      activeColor: AppColors.success,
                      onChanged: (bool value) => _updateAvailabilityStatus(value),
                    ),
                    Text(
                        _isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          color: _isAvailable ? AppColors.success : AppColors.errorColor,
                          fontWeight: FontWeight.bold,
                        )
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentColor,
                  labelColor: AppColors.accentColor,
                  unselectedLabelColor: textColor.withOpacity(0.7),
                  tabs: const [
                    Tab(icon: Icon(Icons.people), text: 'Assigned Users'),
                    Tab(icon: Icon(Icons.notifications_active), text: 'Alerts'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssignedUsersTab(),
                    _buildAlertsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}