import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../models/caregiver.dart';
import '../widgets/caregiver_card.dart';
import '../database/db_helper.dart';

class CaregiverInformationScreen extends StatefulWidget {
  final int userId;

  const CaregiverInformationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CaregiverInformationScreen> createState() => _CaregiverInformationScreenState();
}

class _CaregiverInformationScreenState extends State<CaregiverInformationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Caregiver> _caregivers = [];
  bool _isLoading = true;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Caregiver> loadedCaregivers = [];
      // Get database instance directly to use raw query
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Direct SQL query to get all active caregivers for this user
      final caregiverResults = await db.rawQuery('''
        SELECT 
          u.user_id, u.first_name, u.last_name, u.phone_number, 
          u.email, u.address, ca.status,
          c.qualification, c.experience, c.specialization
        FROM caregiver_assignments ca
        JOIN users u ON ca.caregiver_id = u.user_id
        LEFT JOIN caregiver c ON u.user_id = c.user_id
        WHERE ca.user_id = ? 
          AND ca.status = 'Active'
          AND (date(ca.end_date) >= date('$now') OR ca.end_date IS NULL)
      ''', [widget.userId]);

      print('Found ${caregiverResults.length} caregivers for user ${widget.userId}');

      // Process each caregiver found
      for (var result in caregiverResults) {
        print('Processing caregiver: ${result['first_name']} ${result['last_name']}');

        loadedCaregivers.add(
          Caregiver(
            id: result['user_id'].toString(),
            name: '${result['first_name']} ${result['last_name']}',
            phone: result['phone_number']?.toString() ?? 'No Phone',
            email: result['email']?.toString() ?? 'No Email',
            address: result['address']?.toString() ?? 'No address provided',
            category: result['specialization']?.toString() ?? 'Caregiver',
            imageUrl: 'assets/images/default_caregiver.jpg',
            specialization: result['qualification']?.toString() ?? 'General Care',
            experience: result['experience']?.toString() ?? '0',
          ),
        );
      }

      // If still empty, try another approach: check if the user has a caregiver_id assigned directly
      if (loadedCaregivers.isEmpty) {
        final userData = await _dbHelper.getUserById(widget.userId);

        if (userData != null && userData['caregiver_id'] != null) {
          final caregiverId = userData['caregiver_id'];
          final caregiverData = await _dbHelper.getUserById(caregiverId);

          if (caregiverData != null) {
            final caregiverProfile = await _dbHelper.getCaregiverProfile(caregiverId);

            loadedCaregivers.add(
              Caregiver(
                id: caregiverData['user_id'].toString(),
                name: '${caregiverData['first_name']} ${caregiverData['last_name']}',
                phone: caregiverData['phone_number']?.toString() ?? 'No Phone',
                email: caregiverData['email']?.toString() ?? 'No Email',
                address: caregiverData['address']?.toString() ?? 'No address provided',
                category: caregiverProfile?['specialization']?.toString() ?? 'Caregiver',
                imageUrl: 'assets/images/default_caregiver.jpg',
                specialization: caregiverProfile?['qualification']?.toString() ?? 'Healthcare',
                experience: caregiverProfile?['experience']?.toString() ?? '0',
              ),
            );
          }
        }
      }

      // Third approach - get ALL assignments without date filtering to see if any exist
      if (loadedCaregivers.isEmpty) {
        final allAssignments = await db.rawQuery('''
          SELECT 
            u.user_id, u.first_name, u.last_name, u.phone_number, 
            u.email, u.address, ca.status,
            c.qualification, c.experience, c.specialization
          FROM caregiver_assignments ca
          JOIN users u ON ca.caregiver_id = u.user_id
          LEFT JOIN caregiver c ON u.user_id = c.user_id
          WHERE ca.user_id = ?
        ''', [widget.userId]);

        print('Found ${allAssignments.length} total assignments for user ${widget.userId}');

        for (var result in allAssignments) {
          loadedCaregivers.add(
            Caregiver(
              id: result['user_id'].toString(),
              name: '${result['first_name']} ${result['last_name']}',
              phone: result['phone_number']?.toString() ?? 'No Phone',
              email: result['email']?.toString() ?? 'No Email',
              address: result['address']?.toString() ?? 'No address provided',
              category: result['specialization']?.toString() ?? 'Caregiver',
              imageUrl: 'assets/images/default_caregiver.jpg',
              specialization: result['qualification']?.toString() ?? 'General Care',
              experience: result['experience']?.toString() ?? '0',
            ),
          );
        }
      }

      setState(() {
        _caregivers.clear();
        _caregivers.addAll(loadedCaregivers);
        _isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading caregivers: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading caregivers: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        title: Text(
          'Caregiver Information',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Caregivers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These are the healthcare professionals and family members who look after you.',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _caregivers.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildCaregiverList(isDarkMode),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Refresh Caregivers',
                icon: Icons.refresh,
                onPressed: _loadCaregivers,
              ),
              const SizedBox(height: 8),
              // Add a diagnostic button just for debugging
              OutlinedButton(
                onPressed: () async {
                  try {
                    final assignments = await _dbHelper.getCaregiverAssignments(widget.userId);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Found ${assignments.length} assignments')),
                      );
                    }

                    for (var assignment in assignments) {
                      print('Assignment: $assignment');

                      // Try to fetch caregiver details directly
                      final caregiverId = assignment['caregiver_id'];
                      if (caregiverId != null) {
                        final caregiverData = await _dbHelper.getUserById(caregiverId);
                        print('Caregiver data: $caregiverData');

                        if (caregiverData != null) {
                          // Try to load this caregiver
                          final List<Caregiver> debugCaregivers = [];
                          debugCaregivers.add(
                            Caregiver(
                              id: caregiverData['user_id'].toString(),
                              name: '${caregiverData['first_name']} ${caregiverData['last_name']}',
                              phone: caregiverData['phone_number']?.toString() ?? 'No Phone',
                              email: caregiverData['email']?.toString() ?? 'No Email',
                              address: caregiverData['address']?.toString() ?? 'No address provided',
                              category: 'Caregiver',
                              imageUrl: 'assets/images/default_caregiver.jpg',
                            ),
                          );

                          setState(() {
                            _caregivers.clear();
                            _caregivers.addAll(debugCaregivers);
                          });
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error checking assignments: $e')),
                      );
                    }
                  }
                },
                child: const Text('Check Assignments (Debug)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDarkMode ? Colors.white30 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No caregivers assigned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact your administrator to assign caregivers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverList(bool isDarkMode) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _caregivers.length,
      itemBuilder: (context, index) {
        final caregiver = _caregivers[index];

        // Create staggered animation for each item
        final Animation<double> animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (1 / _caregivers.length) * index,
            1.0,
            curve: Curves.easeOut,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: CaregiverCard(
              caregiver: caregiver,
              onTap: () {
                _showCaregiverDetails(caregiver);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCaregiverDetails(Caregiver caregiver) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Hero(
                          tag: 'caregiver_image_${caregiver.id}',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              image: DecorationImage(
                                image: AssetImage(caregiver.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          caregiver.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          caregiver.category,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailItem(Icons.phone, "Phone", caregiver.phone, textColor),
                      _buildDetailItem(Icons.email, "Email", caregiver.email, textColor),
                      _buildDetailItem(Icons.location_on, "Address", caregiver.address, textColor),
                      if (caregiver.specialization != null)
                        _buildDetailItem(Icons.medical_services, "Specialization", caregiver.specialization!, textColor),
                      if (caregiver.experience != null)
                        _buildDetailItem(Icons.work, "Experience", "${caregiver.experience} Years", textColor),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: "Call Caregiver",
                        icon: Icons.call,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${caregiver.name}...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}