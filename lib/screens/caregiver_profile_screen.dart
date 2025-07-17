import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../database/db_helper.dart';

class CaregiverProfileScreen extends StatefulWidget {
  final int userId;

  const CaregiverProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final DBHelper _dbHelper = DBHelper();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // User profile data
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phoneNumber = '';
  int _age = 0;
  String _address = '';

  // Caregiver specific data
  String _qualification = '';
  int _experience = 0;
  String _specialization = '';
  String _availability = 'available';

  // Controllers
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _qualificationController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load basic user information
      final userData = await _dbHelper.getUserById(widget.userId);
      if (userData != null) {
        setState(() {
          _firstName = userData['first_name'] ?? '';
          _lastName = userData['last_name'] ?? '';
          _email = userData['email'] ?? '';
          _phoneNumber = userData['phone_number'] ?? '';
          _age = userData['age'] ?? 0;
          _address = userData['address'] ?? '';
        });
      }

      // Load caregiver specific information
      final caregiverData = await _dbHelper.getCaregiverProfile(widget.userId);
      if (caregiverData != null) {
        setState(() {
          _qualification = caregiverData['qualification'] ?? '';
          _experience = caregiverData['experience'] ?? 0;
          _specialization = caregiverData['specialization'] ?? '';
          _availability = caregiverData['availability'] ?? 'available';
        });

        _qualificationController.text = _qualification;
        _experienceController.text = _experience.toString();
        _specializationController.text = _specialization;
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final caregiverData = await _dbHelper.getCaregiverProfile(widget.userId);

      if (caregiverData == null) {
        // Create new caregiver profile
        await _dbHelper.insertCaregiverProfile(
          userId: widget.userId,
          qualification: _qualificationController.text.trim(),
          experience: int.parse(_experienceController.text.trim()),
          specialization: _specializationController.text.trim(),
          availability: _availability,
        );
      } else {
        // Update existing caregiver profile
        final caregiverId = caregiverData['caregiver_id'];
        await _dbHelper.updateCaregiverProfile(
          caregiverId,
          {
            'qualification': _qualificationController.text.trim(),
            'experience': int.parse(_experienceController.text.trim()),
            'specialization': _specializationController.text.trim(),
            'availability': _availability,
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Caregiver Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: textColor),
            onPressed: () {
              // Show help information
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile Information'),
                  content: const Text(
                      'Update your professional details here. This information will be visible to patients and administrators.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic profile card
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.accentColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              size: 35,
                              color: AppColors.accentColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_firstName $_lastName',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Caregiver',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.email, 'Email', _email, textColor),
                      _buildInfoRow(Icons.phone, 'Phone', _phoneNumber, textColor),
                      _buildInfoRow(Icons.person_outline, 'Age', _age.toString(), textColor),
                      if (_address.isNotEmpty)
                        _buildInfoRow(Icons.location_on, 'Address', _address, textColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Professional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              // Professional info form
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Qualification
                        TextFormField(
                          controller: _qualificationController,
                          decoration: InputDecoration(
                            labelText: 'Qualification',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.school, color: AppColors.accentColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your qualification';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Experience
                        TextFormField(
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Experience (years)',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.timer, color: AppColors.accentColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your experience';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Specialization
                        TextFormField(
                          controller: _specializationController,
                          decoration: InputDecoration(
                            labelText: 'Specialization',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.medical_services, color: AppColors.accentColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your specialization';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Availability
                        Text(
                          'Availability Status',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Radio(
                              value: 'available',
                              groupValue: _availability,
                              activeColor: AppColors.accentColor,
                              onChanged: (value) {
                                setState(() {
                                  _availability = value.toString();
                                });
                              },
                            ),
                            Text(
                              'Available',
                              style: TextStyle(color: textColor),
                            ),
                            const SizedBox(width: 16),
                            Radio(
                              value: 'unavailable',
                              groupValue: _availability,
                              activeColor: AppColors.accentColor,
                              onChanged: (value) {
                                setState(() {
                                  _availability = value.toString();
                                });
                              },
                            ),
                            Text(
                              'Unavailable',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor, // FIXED: Changed from 'primary' to 'backgroundColor'
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.accentColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}