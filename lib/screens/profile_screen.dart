import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../database/db_helper.dart'; // Import the DBHelper

class ProfileScreen extends StatefulWidget {
  final int userId; // Add userId parameter

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Text controllers for profile fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _chronicConditionsController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isEditMode = false;
  bool _isLoading = true;
  final DBHelper _dbHelper = DBHelper();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with empty data
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _dobController = TextEditingController();
    _genderController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _allergiesController = TextEditingController();
    _emergencyContactNameController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();
    _addressController = TextEditingController();
    _chronicConditionsController = TextEditingController();

    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load user data from database
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _dbHelper.getUserById(widget.userId);
      if (userData != null) {
        setState(() {
          _userData = userData;
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone_number'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _dobController.text = userData['date_of_birth'] ?? '';
          _genderController.text = userData['gender'] ?? '';
          _bloodGroupController.text = userData['blood_group'] ?? '';
          _allergiesController.text = userData['allergies'] ?? '';
          _emergencyContactNameController.text = userData['emergency_contact_name'] ?? '';
          _emergencyContactPhoneController.text = userData['emergency_contact_phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _chronicConditionsController.text = userData['chronic_conditions'] ?? '';

          // Height and weight are not in the database, but we'll keep them for UI purposes
          _heightController.text = '';
          _weightController.text = '';

          _isLoading = false;
        });
        _animationController.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _addressController.dispose();
    _chronicConditionsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveProfile() async {
    HapticFeedback.mediumImpact();

    if (_userData == null) return;

    try {
      // Validate inputs
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name fields cannot be empty')),
        );
        return;
      }

      // Prepare data for update
      final updatedData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'date_of_birth': _dobController.text,
        'gender': _genderController.text,
        'blood_group': _bloodGroupController.text,
        'allergies': _allergiesController.text,
        'emergency_contact_name': _emergencyContactNameController.text,
        'emergency_contact_phone': _emergencyContactPhoneController.text,
        'address': _addressController.text,
        'chronic_conditions': _chronicConditionsController.text,
      };

      // Update user data in the database
      await _dbHelper.updateUser(widget.userId, updatedData);

      setState(() {
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: textColor,
            ),
            onPressed: _isEditMode ? _saveProfile : _toggleEditMode,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(isDarkMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Personal Information', isDarkMode),
                  const SizedBox(height: 16),
                  _buildPersonalInfoSection(cardColor, isDarkMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Medical Information', isDarkMode),
                  const SizedBox(height: 16),
                  _buildMedicalInfoSection(cardColor, isDarkMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Emergency Contact', isDarkMode),
                  const SizedBox(height: 16),
                  _buildEmergencyContactSection(cardColor, isDarkMode),
                  const SizedBox(height: 24),
                  if (_isEditMode) ...[
                    PrimaryButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      bgColor: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    return Hero(
      tag: 'profile_header',
      child: Center(
        child: Column(
          children: [
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: _isEditMode ? () {
                  // Here you would implement image picking functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker would open here')),
                  );
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.gradientBlue, AppColors.gradientPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_firstNameController.text} ${_lastNameController.text}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : AppColors.textDark,
      ),
    );
  }

  Widget _buildPersonalInfoSection(Color cardColor, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isEditMode) ...[
              CustomTextField(
                controller: _firstNameController,
                label: 'First Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                label: 'Last Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ageController,
                label: 'Age',
                prefixIcon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _dobController,
                label: 'Date of Birth',
                prefixIcon: Icons.calendar_today,
                //readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _genderController,
                label: 'Gender',
                prefixIcon: Icons.people,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                prefixIcon: Icons.home,
                maxLines: 2,
              ),
            ] else ...[
              _buildInfoRow('First Name', _firstNameController.text, Icons.person, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Last Name', _lastNameController.text, Icons.person, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Email', _emailController.text, Icons.email, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Phone', _phoneController.text, Icons.phone, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Age', _ageController.text, Icons.cake, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Birth Date', _dobController.text, Icons.calendar_today, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Gender', _genderController.text, Icons.people, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Address', _addressController.text, Icons.home, isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection(Color cardColor, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isEditMode) ...[
              CustomTextField(
                controller: _bloodGroupController,
                label: 'Blood Type',
                prefixIcon: Icons.water_drop,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _heightController,
                label: 'Height',
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _weightController,
                label: 'Weight',
                prefixIcon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _allergiesController,
                label: 'Allergies',
                prefixIcon: Icons.health_and_safety,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _chronicConditionsController,
                label: 'Chronic Conditions',
                prefixIcon: Icons.medical_services,
                maxLines: 3,
              ),
            ] else ...[
              _buildInfoRow('Blood Type', _bloodGroupController.text, Icons.water_drop, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Height', _heightController.text, Icons.height, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Weight', _weightController.text, Icons.monitor_weight, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Allergies', _allergiesController.text, Icons.health_and_safety, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Chronic Conditions', _chronicConditionsController.text, Icons.medical_services, isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection(Color cardColor, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isEditMode) ...[
              CustomTextField(
                controller: _emergencyContactNameController,
                label: 'Emergency Contact Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emergencyContactPhoneController,
                label: 'Emergency Contact Phone',
                prefixIcon: Icons.phone_enabled,
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              _buildInfoRow('Emergency Contact', _emergencyContactNameController.text, Icons.person_outline, isDarkMode),
              const Divider(height: 24),
              _buildInfoRow('Emergency Phone', _emergencyContactPhoneController.text, Icons.phone_enabled, isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? AppColors.accentColor : AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not specified' : value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}