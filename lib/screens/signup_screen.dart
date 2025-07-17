import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/app_colors.dart';
import '../database/db_helper.dart';
import 'signup_screen_step2.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  // Step 1 controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController(); // New age controller
  String _selectedGender = '';
  String _selectedRole = 'elderly'; // Default role set to 'elderly'

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Create an instance of DBHelper
  final DBHelper _dbHelper = DBHelper();

  // Gender options
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  // Role options
  final List<String> _roleOptions = ['elderly', 'caregiver', 'admin'];

  bool get _isElderlyRole => _selectedRole == 'elderly';

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _ageController.dispose(); // Dispose age controller
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

  bool _validateStep1() {
    // Basic validation for all roles
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedGender.isEmpty ||
        _dobController.text.isEmpty ||
        _ageController.text.isEmpty) { // Added age validation
      _showNotification('Please fill all required fields');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showNotification('Passwords do not match');
      return false;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showNotification('Please enter a valid email address');
      return false;
    }

    // Phone validation (basic)
    if (_phoneController.text.length < 10) {
      _showNotification('Please enter a valid phone number');
      return false;
    }

    // Age validation (ensure it's a number)
    if (int.tryParse(_ageController.text) == null) {
      _showNotification('Please enter a valid age');
      return false;
    }

    return true;
  }

  void _signup() async {
    if (_validateStep1()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if email already exists in the database
        final existingUser = await _dbHelper.getUserByEmail(_emailController.text);
        if (existingUser != null) {
          _showNotification('Email already registered. Please use a different email.');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // For non-elderly roles, complete registration here
        if (!_isElderlyRole) {
          // Make sure age is parsed as int for the database
          final int age = int.tryParse(_ageController.text) ?? 0;

          // Insert the new user into the database
          final userId = await _dbHelper.insertUser(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
            gender: _selectedGender,
            dateOfBirth: _dobController.text, // Changed from dob to dateOfBirth
            age: int.parse(_ageController.text), // Passing age as int
            address: '',
            bloodGroup: '',
            emergencyContactName: '',
            emergencyContactPhone: '',
            relationship: '',
            chronicConditions: '',
            allergies: '',
            role: _selectedRole,
          );

          if (userId > 0) {
            _showNotification('Registration successful!', isError: false);
            // Add delay before navigation for user to see success message
            await Future.delayed(const Duration(seconds: 2));
            // Navigate to login screen or home page
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          } else {
            _showNotification('Registration failed. Please try again.');
          }
        } else {
          // For elderly role, navigate to step 2
          // Make sure age is parsed as int for passing to next screen
          final int age = int.tryParse(_ageController.text) ?? 0;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupScreenStep2(
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                email: _emailController.text,
                phoneNumber: _phoneController.text,
                password: _passwordController.text,
                gender: _selectedGender,
                dateofBirth: _dobController.text, // Changed from dob to dateOfBirth
                age: int.parse(_ageController.text), // Pass age as int
                role: _selectedRole,
                dbHelper: _dbHelper,
              ),
            ),
          );
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
    // For non-elderly roles, only show step 1 as active
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDarkMode ? Colors.grey[700] : AppColors.inactiveStepColor;

    if (!_isElderlyRole) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, true),
          _buildStepLine(false, inactiveColor),
          _buildStepCircle(2, false),
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

  Widget _buildGenderSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Gender',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? Colors.transparent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select gender',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              value: _selectedGender.isEmpty ? null : _selectedGender,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              elevation: 16,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
              items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(value),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Role',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? Colors.transparent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedRole,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              elevation: 16,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
              items: _roleOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      value[0].toUpperCase() + value.substring(1), // Capitalize first letter
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final regularTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final linkColor = AppColors.accentColor;

    // Different button text for different roles
    final buttonText = _isElderlyRole ? 'Continue' : 'Sign Up';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                label: 'First name',
                hintText: 'John',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                label: 'Last name',
                hintText: 'Doe',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        const SizedBox(height: 16),
        _buildRoleSelector(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _dobController,
                label: 'Date of Birth',
                hintText: 'MM/DD/YYYY',
                keyboardType: TextInputType.datetime,
                prefixIcon: Icons.calendar_today_outlined,
                onTap: () async {
                  // Hide keyboard
                  FocusScope.of(context).requestFocus(FocusNode());

                  // Show date picker with theme
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1950),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: isDarkMode
                            ? ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Colors.green, // Date selection color
                            onPrimary: Colors.white, // Selected date text color
                            surface: Colors.grey[800]!, // Dialog background
                            onSurface: Colors.white, // Calendar text color
                          ),
                          dialogBackgroundColor: Colors.grey[900],
                        )
                            : ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.black, // Date selection color
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    // Calculate age from DOB
                    final today = DateTime.now();
                    int age = today.year - picked.year;
                    if (today.month < picked.month ||
                        (today.month == picked.month && today.day < picked.day)) {
                      age--;
                    }

                    setState(() {
                      _dobController.text = "${picked.month}/${picked.day}/${picked.year}";
                      _ageController.text = age.toString(); // Auto-fill age field
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: CustomTextField(
                controller: _ageController,
                label: 'Age',
                hintText: '65',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'johndoe@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: '(555) 123-4567',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          isPassword: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          isPassword: true,
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: buttonText,
          onPressed: _signup,
          isLoading: _isLoading,
          bgColor: Colors.black,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: regularTextColor,
                ),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: linkColor,
                    ),
                  ),
                ],
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
            'Create Account',
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