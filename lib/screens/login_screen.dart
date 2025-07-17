import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/app_colors.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'caregiver_home_screen.dart';
import 'admin_page.dart';
import '../database/db_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final DBHelper _dbHelper = DBHelper();

  bool _isLoading = false;
  String? _errorMessage;

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

    // Initialize the database and ensure it's created
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Force database initialization
      await _dbHelper.database;
      print("Database initialized successfully");

      // Check if admin exists in database
      final adminUser = await _dbHelper.getUserByEmail("admin@eca.com");
      print("Admin user in database: $adminUser");

      // If admin doesn't exist, try to create one
      if (adminUser == null) {
        print("Admin not found, attempting to create...");
        try {
          await _dbHelper.insertUser(
            firstName: "Admin",
            lastName: "User",
            email: "admin@eca.com",
            phoneNumber: "1234567890",
            password: "***REMOVED***",
            gender: "",
            dateOfBirth: "",
            age: 0,
            address: "",
            bloodGroup: "",
            emergencyContactName: "",
            emergencyContactPhone: "",
            relationship: "",
            chronicConditions: "",
            allergies: "",
            role: "admin",
          );
          print("Admin created successfully");
        } catch (e) {
          print("Failed to create admin: $e");
        }
      }
    } catch (e) {
      print("Database initialization error: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      )
          : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Attempting login with: $email / $password");

      // Get the user with the provided email
      final user = await _dbHelper.getUserByEmail(email);
      print("User found: $user");

      if (user != null && user['password'] == password) {
        // Check user role
        final String userRole = user['role'] ?? '';
        print("User role: $userRole");
        final String firstName = user['first_name'] ?? '';
        final String lastName = user['last_name'] ?? '';
        final String fullName = '$firstName $lastName'.trim();
        final int userId = user['user_id'];

        // Route based on role
        if (userRole == 'admin') {
          print("Navigating to admin screen");
          // Navigate to admin screen - pass userId
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminScreen(userId: userId),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin Login Successful'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (userRole == 'caregiver') {
          print("Navigating to caregiver screen");
          // Navigate to caregiver screen - pass userId
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaregiverHomeScreen(userId: userId),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caregiver Login Successful'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print("Navigating to home screen with name: $fullName and userId: $userId");
          // Navigate to home screen for regular users (elderly)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userName: fullName, userId: userId),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error for invalid credentials
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Login error: $e'); // Add debug print
      // Handle any database errors
      setState(() {
        _errorMessage = 'Login Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Set loading state back to false
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final logoBackgroundColor = isDarkMode ? Colors.black : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // App Logo Section with Pattern Background
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: logoBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Black geometric pattern (would be an actual image in a real app)
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
                    // Login Form Container
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkCardColor : Colors.white,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'user@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            hintText: 'Enter your password',
                          ),
                          const SizedBox(height: 30),
                          // Use a stack to show loading indicator over button when processing
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              PrimaryButton(
                                text: 'Login',
                                onPressed: _isLoading ? () {} : _login,
                              ),
                              if (_isLoading)
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                            ],
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Sign Up - Fix this to use appropriate color in dark mode
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Don\'t have any account? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentColor,
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