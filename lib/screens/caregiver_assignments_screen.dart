import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../database/db_helper.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import 'caregiver_assignment_details.dart';

class CaregiverAssignmentsScreen extends StatefulWidget {
  final int userId;
  final bool isEmbedded;

  const CaregiverAssignmentsScreen({
    Key? key,
    required this.userId,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<CaregiverAssignmentsScreen> createState() => _CaregiverAssignmentsScreenState();
}

class _CaregiverAssignmentsScreenState extends State<CaregiverAssignmentsScreen> {
  final DBHelper _dbHelper = DBHelper();
  bool _isLoading = true;

  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  List<Map<String, dynamic>> _allCaregivers = [];
  Map<int, Map<String, dynamic>?> _assignmentCache = {};

  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Active', 'Inactive', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      _filterPatients();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load patients (users with role 'patient')
      final patients = await _dbHelper.getUsersByRole('elderly');

      // Load caregivers for later use
      final caregivers = await _dbHelper.getUsersByRole('caregiver');

      // Initialize assignment cache
      Map<int, Map<String, dynamic>?> assignmentCache = {};

      // Pre-load active assignments for each patient
      for (var patient in patients) {
        final assignments = await _dbHelper.getCaregiverAssignments(patient['user_id']);

        // Get the active assignment if it exists
        final activeAssignment = assignments
            .where((a) => a['status'] == 'Active')
            .toList();

        if (activeAssignment.isNotEmpty) {
          assignmentCache[patient['user_id']] = activeAssignment.first;
        } else {
          assignmentCache[patient['user_id']] = null;
        }
      }

      setState(() {
        _allPatients = patients;
        _filteredPatients = List.from(patients);
        _allCaregivers = caregivers;
        _assignmentCache = assignmentCache;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar("Failed to load data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        // First filter by search text
        final fullName = "${patient['first_name']} ${patient['last_name']}".toLowerCase();
        final matchesSearch = query.isEmpty || fullName.contains(query);

        // Then filter by status if not "All"
        if (_statusFilter == 'All') {
          return matchesSearch;
        } else {
          final assignment = _assignmentCache[patient['user_id']];
          final status = assignment?['status'] ?? 'No Assignment';
          return matchesSearch && status == _statusFilter;
        }
      }).toList();
    });
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

  Future<void> _navigateToAssignmentDetails(Map<String, dynamic> patient) async {
    final hasExistingAssignment = _assignmentCache[patient['user_id']] != null;

    try {
      // Get available care plans for the selection - ensure they have unique IDs
      final carePlans = await _dbHelper.getCareplans();

      // Ensure caregivers have unique user_ids for the dropdown selection
      final uniqueCaregivers = _ensureUniqueItems(_allCaregivers, 'user_id');

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaregiverAssignmentDetailsScreen(
            userId: patient['user_id'],
            userName: "${patient['first_name']} ${patient['last_name']}",
            hasExistingAssignment: hasExistingAssignment,
            availableCaregivers: uniqueCaregivers,
            availableCarePlans: carePlans,
          ),
        ),
      );

      if (result == true) {
        _loadData(); // Refresh data after changes
        _showSuccessSnackBar("Assignment updated successfully");
      }
    } catch (e) {
      _showErrorSnackBar("Error loading assignment details: $e");
    }
  }

  // Helper method to ensure unique items by a specific key
  List<Map<String, dynamic>> _ensureUniqueItems(List<Map<String, dynamic>> items, String keyField) {
    final seen = <dynamic>{};
    return items.where((item) {
      final key = item[keyField];
      final isUnique = !seen.contains(key);
      if (isUnique) {
        seen.add(key);
      }
      return isUnique;
    }).toList();
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
      case 'No Assignment':
        return isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;
      default:
        return isDarkMode ? AppColors.textLight : AppColors.textDark;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: !widget.isEmbedded ? AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: isDarkMode ? AppColors.textLight : AppColors.textDark,
        title: const Text(
          "Caregiver Assignments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Refresh Data",
          ),
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: "Search Patients",
                  hintText: "Search by name",
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _statusFilter,
                      hint: Text(
                        'Filter by status',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      icon: Icon(
                        Icons.filter_list,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      items: _statusOptions.map<DropdownMenuItem<String>>(
                            (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status != 'All'
                                  ? _getStatusColor(status)
                                  : (isDarkMode ? AppColors.textLight : AppColors.textDark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _statusFilter = newValue;
                            _filterPatients();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_alt,
                  title: "Total Patients",
                  value: _allPatients.length.toString(),
                  color: AppColors.primaryColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.assignment_turned_in,
                  title: "Active Assignments",
                  value: _assignmentCache.values
                      .where((assignment) => assignment != null && assignment['status'] == 'Active')
                      .length
                      .toString(),
                  color: AppColors.success,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Patient list
          Expanded(
            child: _filteredPatients.isEmpty
                ? Center(
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
                    "No patients found",
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                final assignment = _assignmentCache[patient['user_id']];

                return _buildPatientCard(
                  patient: patient,
                  assignment: assignment,
                  isDarkMode: isDarkMode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard({
    required Map<String, dynamic> patient,
    required Map<String, dynamic>? assignment,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;

    // Determine assignment status
    final assignmentStatus = assignment?['status'] ?? 'No Assignment';

    // Find assigned caregiver if an assignment exists
    String caregiverName = 'Not Assigned';
    if (assignment != null) {
      final caregiverId = assignment['caregiver_id'];
      final caregiver = _allCaregivers.firstWhere(
            (c) => c['user_id'] == caregiverId,
        orElse: () => {'first_name': 'Unknown', 'last_name': 'Caregiver'},
      );
      caregiverName = "${caregiver['first_name']} ${caregiver['last_name']}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToAssignmentDetails(patient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${patient['first_name']} ${patient['last_name']}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(assignmentStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              assignmentStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(assignmentStatus),
                              ),
                            ),
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
                if (assignment != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Caregiver",
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_pin,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  caregiverName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Assignment Date",
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  assignment['start_date'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}