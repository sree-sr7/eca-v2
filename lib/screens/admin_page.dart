import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../database/db_helper.dart';
import 'admin_components.dart';
import 'care_plans_screen.dart'; // Import the standalone care plans screen
import 'caregiver_assignments_screen.dart'; // Import the new assignments screen

class AdminScreen extends StatefulWidget {
  final int userId;

  const AdminScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  final TextEditingController _searchUserController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, dynamic>? _adminData;

  // Define the navigation items
  final List<Map<String, dynamic>> _navigationItems = [
    {'title': 'Users', 'icon': Icons.people},
    {'title': 'Care Plans', 'icon': Icons.healing},
    {'title': 'Assignments', 'icon': Icons.assignment}, // Added Assignments
    {'title': 'Statistics', 'icon': Icons.bar_chart},
  ];

  // Track the selected navigation item
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadUsers();

    _searchUserController.addListener(() {
      _filterUsers();
    });
  }

  Future<void> _loadAdminData() async {
    try {
      final adminData = await _dbHelper.getUserById(widget.userId);
      setState(() {
        _adminData = adminData;
      });
    } catch (e) {
      _showErrorSnackBar("Failed to load admin data: $e");
    }
  }

  void _filterUsers() {
    final query = _searchUserController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final fullName = "${user['first_name']} ${user['last_name']}".toLowerCase();
          final email = user['email'].toString().toLowerCase();
          return fullName.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _dbHelper.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = List.from(users);
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      _showErrorSnackBar("Failed to load users: $e");
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

  @override
  void dispose() {
    _searchUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: isDarkMode ? AppColors.textLight : AppColors.textDark,
        title: Text(
          _navigationItems[_selectedIndex]['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedIndex == 0) {
                _loadUsers();
              } else if (_selectedIndex == 3) {
                _loadUsers();
              }
            },
            tooltip: "Refresh Data",
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showAdminProfileDialog(context, _adminData);
            },
            tooltip: "Admin Profile",
          ),
        ],
      ),
      drawer: _buildDrawer(context, isDarkMode),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDarkMode) {
    return Drawer(
      backgroundColor: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (_adminData?['first_name']?[0] ?? "A").toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            accountName: Text(
              _adminData != null
                  ? "${_adminData!['first_name']} ${_adminData!['last_name']}"
                  : "Admin User",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              _adminData?['email'] ?? "admin@example.com",
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected
                        ? AppColors.primaryColor
                        : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primaryColor
                          : isDarkMode ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                  tileColor: isSelected
                      ? (isDarkMode ? AppColors.primaryColor.withOpacity(0.1) : AppColors.primaryColor.withOpacity(0.05))
                      : Colors.transparent,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              // Add settings navigation or dialog here
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorColor),
            title: const Text(
              "Logout",
              style: TextStyle(color: AppColors.errorColor),
            ),
            onTap: () {
              Navigator.pop(context);
              // Add logout logic here
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildUsersTab();
      case 1:
      // Use the standalone CarePlansScreen
        return CarePlansScreen(
          userId: widget.userId,
          isEmbedded: true, // Pass a flag to indicate this is embedded in admin screen
        );
      case 2:
      // Return the caregiver assignments screen
        return CaregiverAssignmentsScreen(
          userId: widget.userId,
          isEmbedded: true,
        );
      case 3:
        return buildStatisticsTab(context, _users);
      default:
        return _buildUsersTab();
    }
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
            "No matching users found",
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No users found",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Refresh",
              onPressed: _loadUsers,
              width: 150,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomTextField(
            controller: _searchUserController,
            label: "Search Users",
            hintText: "Search by name or email",
            prefixIcon: Icons.search,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: _filteredUsers.isEmpty
                ? buildNoSearchResults(context)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return buildUserCard(
                  context,
                  user,
                  onDelete: () => _confirmDeleteUser(user),
                  onEdit: () => _showEditUserDialog(user),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text(
            "Are you sure you want to delete ${user['first_name']} ${user['last_name']}? This action cannot be undone."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['user_id']);
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

  Future<void> _deleteUser(int userId) async {
    try {
      await _dbHelper.deleteUser(userId);
      _loadUsers(); // Refresh the list
      _showSuccessSnackBar("User deleted successfully");
    } catch (e) {
      _showErrorSnackBar("Failed to delete user: $e");
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    // This would be a form to edit user details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit User"),
        content: const Text(
            "Here you would implement a form to edit user details. "
                "This would be similar to your signup form but pre-filled with user data."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  // Updated Statistics Tab with Responsive Layout
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
    final screenWidth = MediaQuery.of(context).size.width;
    final compactMode = screenWidth < 360; // Adjust based on actual device testing

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: compactMode ? 12.0 : 16.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Users Stat Card
          buildStatCard(
            title: "Total Users",
            value: totalUsers.toString(),
            icon: Icons.people,
            color: AppColors.primaryColor,
            context: context,
          ),
          const SizedBox(height: 20),

          // Demographics Section
          Text(
            "User Demographics",
            style: TextStyle(
              fontSize: compactMode ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Demographics in a more compact layout
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  title: "Male",
                  value: "$maleUsers",
                  icon: Icons.male,
                  color: Colors.blue,
                  context: context,
                ),
              ),
              SizedBox(width: compactMode ? 8 : 12),
              Expanded(
                child: _buildCompactStatCard(
                  title: "Female",
                  value: "$femaleUsers",
                  icon: Icons.female,
                  color: Colors.pink,
                  context: context,
                ),
              ),
              SizedBox(width: compactMode ? 8 : 12),
              Expanded(
                child: _buildCompactStatCard(
                  title: "Other",
                  value: "$otherUsers",
                  icon: Icons.person,
                  color: Colors.purple,
                  context: context,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Age Statistics Section
          Text(
            "Age Statistics",
            style: TextStyle(
              fontSize: compactMode ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Average Age Card
          buildStatCard(
            title: "Average Age",
            value: avgAge,
            icon: Icons.calendar_today,
            color: Colors.teal,
            context: context,
          ),

          const SizedBox(height: 12),

          // Age Range in a more compact layout
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  title: "Under 30",
                  value: "$usersUnder30",
                  icon: Icons.child_care,
                  color: Colors.green,
                  context: context,
                ),
              ),
              SizedBox(width: compactMode ? 8 : 12),
              Expanded(
                child: _buildCompactStatCard(
                  title: "30-60",
                  value: "$users30to60",
                  icon: Icons.person,
                  color: Colors.amber,
                  context: context,
                ),
              ),
              SizedBox(width: compactMode ? 8 : 12),
              Expanded(
                child: _buildCompactStatCard(
                  title: "Over 60",
                  value: "$usersOver60",
                  icon: Icons.elderly,
                  color: Colors.indigo,
                  context: context,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Health Condition Statistics Section
          Text(
            "Health Conditions",
            style: TextStyle(
              fontSize: compactMode ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Chronic Conditions Card
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

          const SizedBox(height: 12),

          // Allergies Card
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

          const SizedBox(height: 20),

          // Emergency Contacts Section
          Text(
            "Emergency Contacts",
            style: TextStyle(
              fontSize: compactMode ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Emergency Contacts Card
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

          // Add padding at the bottom for better scrolling
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // New helper method for more compact stat cards
  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final compactMode = screenWidth < 360;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(compactMode ? 8.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color.withOpacity(0.8),
                  size: compactMode ? 16 : 20,
                ),
                SizedBox(width: compactMode ? 4 : 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compactMode ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(height: compactMode ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: compactMode ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated buildStatCard with responsive design
  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final compactMode = screenWidth < 360;

    return Card(
      elevation: 2,
      color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(compactMode ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: compactMode ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  color: color.withOpacity(0.8),
                  size: compactMode ? 20 : 24,
                ),
              ],
            ),
            SizedBox(height: compactMode ? 8 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: compactMode ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}