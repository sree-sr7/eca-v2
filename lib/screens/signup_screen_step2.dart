import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/app_colors.dart';
import '../database/db_helper.dart';

class SignupScreenStep2 extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String gender;
  final String dateofBirth;
  final int age; // Added age field
  final String role;
  final DBHelper dbHelper;

  const SignupScreenStep2({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.gender,
    required this.dateofBirth,
    required this.age, // Added age parameter
    required this.role,
    required this.dbHelper,
  }) : super(key: key);

  @override
  State<SignupScreenStep2> createState() => _SignupScreenStep2State();
}

class _SignupScreenStep2State extends State<SignupScreenStep2> with SingleTickerProviderStateMixin {
  // Step 2 controllers (only for elderly role)
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _emergencyRelationController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _chronicConditionsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    // Set default status bar color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _updateStatusBarColor() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      )
          : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.grey[200],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarColor();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _chronicConditionsController.dispose();
    _allergiesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _validateStep2() {
    // Validate all fields
    if (_emergencyNameController.text.isEmpty ||
        _emergencyPhoneController.text.isEmpty ||
        _emergencyRelationController.text.isEmpty ||
        _bloodGroupController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showNotification('Please fill all required fields');
      return false;
    }

    // Phone validation (basic)
    if (_emergencyPhoneController.text.length < 10) {
      _showNotification('Please enter a valid emergency contact phone number');
      return false;
    }

    return true;
  }

  void _completeSignup() async {
    if (_validateStep2()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Insert the new elderly user into the database with all fields
        final userId = await widget.dbHelper.insertUser(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
          phoneNumber: widget.phoneNumber,
          password: widget.password,
          gender: widget.gender,
          dateOfBirth: widget.dateofBirth,
          age: widget.age,
          address: _addressController.text,
          bloodGroup: _bloodGroupController.text,
          emergencyContactName: _emergencyNameController.text,
          emergencyContactPhone: _emergencyPhoneController.text,
          relationship: _emergencyRelationController.text,
          chronicConditions: _chronicConditionsController.text,
          allergies: _allergiesController.text,
          role: widget.role,
        );

        if (userId > 0) {
          _showNotification('Registration successful!', isError: false);
          // Add delay before navigation for user to see success message
          await Future.delayed(const Duration(seconds: 2));
          // Navigate to login screen or home page
          // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _showNotification('Registration failed. Please try again.');
        }
      } catch (e) {
        _showNotification('Error: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStepIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDarkMode ? Colors.black : Colors.black;
    final inactiveColor = isDarkMode ? Colors.grey[700] : AppColors.inactiveStepColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, false),
          _buildStepLine(true, inactiveColor),
          _buildStepCircle(2, true),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDarkMode ? Colors.black : Colors.black;
    final inactiveColor = isDarkMode ? Colors.grey[700] : AppColors.inactiveStepColor;
    final textColor = isActive
        ? Colors.white
        : (isDarkMode ? Colors.white70 : Colors.black54);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive, Color? inactiveColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDarkMode ? Colors.black : Colors.black;

    return Container(
      width: 70,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? activeColor : inactiveColor,
    );
  }

  Widget _buildForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical & Emergency Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _addressController,
          label: 'Home Address',
          hintText: 'Enter your home address',
          prefixIcon: Icons.home_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _bloodGroupController,
          label: 'Blood Group',
          hintText: 'A+, B-, O+, etc.',
          prefixIcon: Icons.bloodtype_outlined,
        ),
        const SizedBox(height: 24),
        Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyNameController,
          label: 'Emergency Contact Name',
          hintText: 'Jane Doe',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyPhoneController,
          label: 'Emergency Contact Phone',
          hintText: '(555) 123-4567',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyRelationController,
          label: 'Relationship',
          hintText: 'Daughter, Son, Friend, etc.',
          prefixIcon: Icons.family_restroom_outlined,
        ),
        const SizedBox(height: 24),
        Text(
          'Health Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _chronicConditionsController,
          label: 'Chronic Conditions',
          hintText: 'Diabetes, Hypertension, etc. (Enter "None" if not applicable)',
          prefixIcon: Icons.medical_services_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _allergiesController,
          label: 'Allergies',
          hintText: 'Medications, Foods, etc. (Enter "None" if not applicable)',
          prefixIcon: Icons.warning_amber_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Complete Registration',
          onPressed: _completeSignup,
          isLoading: _isLoading,
          bgColor: Colors.black,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Go Back',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDarkMode ? AppColors.darkCardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final logoBackgroundColor = isDarkMode ? Colors.black : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      )
          : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.grey[200],
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.grey[200],
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: textColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Medical Information',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo Section with Pattern Background
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: logoBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Black geometric pattern
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.black : Colors.black87,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/pattern.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Elderly Care Logo centered
                          Center(
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Heart shape (representing care)
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.red.shade300,
                                      size: 40,
                                    ),
                                    // Person icon (representing elderly)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Icon(
                                        Icons.accessibility_new,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Step Indicator
                    _buildStepIndicator(),

                    // Form Container
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: _buildForm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}