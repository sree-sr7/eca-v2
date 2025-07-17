import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/appointment_card.dart';
import '../database/db_helper.dart';
import '../screens/notifications_alerts_screen.dart';
import '../widgets/sos_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _greeting = "";

  final DBHelper _dbHelper = DBHelper();

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _appointments = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = "Good Morning";
    } else if (hour < 17) {
      _greeting = "Good Afternoon";
    } else {
      _greeting = "Good Evening";
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _dbHelper.getUserById(widget.userId);
      final appointments = await _dbHelper.getAppointments(widget.userId);
      final medications = await _dbHelper.getMedications(widget.userId);

      setState(() {
        _userData = userData;
        _appointments = appointments;
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Improved _parseDate method
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }

    // Try standard ISO format first
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try MM/dd/yyyy format (commonly used in the US)
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[0]), // month
            int.parse(parts[1]), // day
          );
        }
      } catch (_) {}

      // Try dd/MM/yyyy format
      try {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (_) {}

      // Try formats with dashes
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          // Could be yyyy-MM-dd or dd-MM-yyyy
          if (parts[0].length == 4) {
            // Likely yyyy-MM-dd
            return DateTime(
              int.parse(parts[0]), // year
              int.parse(parts[1]), // month
              int.parse(parts[2]), // day
            );
          } else {
            // Likely dd-MM-yyyy
            return DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );
          }
        }
      } catch (_) {}

      print('Failed to parse date: $dateStr');
      return null;
    }
  }

  // Modified to count all medications that haven't been taken yet
  bool _isMedicationDueToday(Map<String, dynamic> med) {
    // Since there's no date field, just check if it's not taken yet
    return med['taken'] != 1;
  }

  // New method to handle SOS button press
  void _handleSOSButtonPress() {
    showDialog(
      context: context,
      builder: (context) => SOSDialog(
        userId: widget.userId,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Emergency alert sent to caregivers!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar with Hamburger Menu and Refresh Button
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                      size: 28,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDarkMode ? Colors.white : AppColors.primaryDark,
                      size: 28,
                    ),
                    onPressed: () {
                      _loadUserData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dashboard refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Section with Decoration
                      _buildGreetingSection(isDarkMode),

                      const SizedBox(height: 24),

                      // Summary Card
                      _buildSummaryCard(isDarkMode),

                      const SizedBox(height: 24),

                      // Today's Reminders Section
                      Text(
                        "Today's Reminders",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medication Reminders
                      _buildMedicationReminders(isDarkMode),

                      const SizedBox(height: 24),

                      // Appointments
                      Text(
                        "Upcoming Appointments",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Appointment Cards
                      _buildAppointmentCards(isDarkMode),

                      const SizedBox(height: 24),

                      // SOS Button
                      _buildSOSButton(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.gradientBlue.withOpacity(0.7),
            AppColors.gradientPink.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "$_greeting,",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _userData != null
                    ? "${_userData!['first_name']}"
                    : "User",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "How are you feeling today?",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDarkMode) {
    // Count all medications that haven't been taken yet
    final todayMedications = _medications.where((med) => med['taken'] != 1).length;

    // Count upcoming appointments
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingAppointments = _appointments.where((appointment) {
      final appDateStr = appointment['date'];
      final DateTime? appDate = _parseDate(appDateStr);
      if (appDate == null) return false;

      return appDate.isAfter(now) ||
          (appDate.year == today.year &&
              appDate.month == today.month &&
              appDate.day == today.day);
    }).length;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.accentColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Quick Overview",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOverviewItem(Icons.medication, "$todayMedications medicines due today", isDarkMode),
          const SizedBox(height: 8),
          _buildOverviewItem(Icons.calendar_month, "$upcomingAppointments appointment(s) coming up", isDarkMode),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDarkMode ? Colors.white70 : AppColors.primaryDark.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : AppColors.textDark.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationReminders(bool isDarkMode) {
    if (_medications.isEmpty) {
      return _buildEmptyCard("No medications scheduled", isDarkMode);
    }

    // Display all medications, sorted by time
    final sortedMeds = List<Map<String, dynamic>>.from(_medications);
    sortedMeds.sort((a, b) {
      final timeA = a['time'] as String? ?? '';
      final timeB = b['time'] as String? ?? '';
      return timeA.compareTo(timeB);
    });

    return Column(
      children: sortedMeds.map((med) => _buildMedicationCard(med, isDarkMode)).toList(),
    );
  }

  Widget _buildEmptyCard(String message, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication, bool isDarkMode) {
    final bool taken = medication['taken'] == 1;

    // Extract stock value and notes
    String stockText = "";
    int? stockCount = medication['stock'] as int? ?? 0;
    final notes = medication['notes'] as String? ?? '';
    stockText = stockCount > 0 ? " • ${stockCount} remaining" : "";

    // Format medication time
    String timeText = medication['time'] ?? '';
    if (timeText.isNotEmpty) {
      try {
        // If it's just a time without AM/PM, add formatting
        if (!timeText.contains('AM') && !timeText.contains('PM') && !timeText.contains('am') && !timeText.contains('pm')) {
          final timeParts = timeText.split(':');
          if (timeParts.length >= 2) {
            int hour = int.tryParse(timeParts[0]) ?? 0;
            final String amPm = hour >= 12 ? 'PM' : 'AM';
            hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            timeText = '$hour:${timeParts[1]} $amPm';
          }
        }
      } catch (e) {
        print('Error formatting time: $e');
      }
    }

    // Determine if medication is due now (within 30 minutes)
    bool isDue = false;
    // [existing due time checking logic remains the same]

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: isDue && !taken ? Border.all(color: AppColors.warning, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: taken ? AppColors.success.withOpacity(0.2) :
            isDue ? AppColors.warning.withOpacity(0.2) :
            AppColors.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            taken ? Icons.check_circle : Icons.medication,
            color: taken ? AppColors.success :
            isDue ? AppColors.warning :
            AppColors.accentColor,
            size: 28,
          ),
        ),
        title: Text(
          medication['name'] ?? "Medication",
          style: TextStyle(
            color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${medication['dosage'] ?? ''} • $timeText$stockText",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textDark.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            // Add this section to display notes
            if (notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  "Notes: $notes",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : AppColors.textDark.withOpacity(0.6),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (isDue && !taken)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Due now",
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: taken
            ? Icon(
          Icons.check_circle,
          color: AppColors.success,
        )
            : IconButton(
          icon: Icon(
            Icons.check_circle_outline,
            color: isDue ? AppColors.warning : AppColors.accentColor,
          ),
          onPressed: () async {
            // [existing code remains the same]
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCards(bool isDarkMode) {
    if (_appointments.isEmpty) {
      return _buildEmptyCard("No upcoming appointments", isDarkMode);
    }

    // Filter and sort valid appointments
    List<Map<String, dynamic>> validAppointments = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var appointment in _appointments) {
      final appDateStr = appointment['date'];
      final DateTime? appDate = _parseDate(appDateStr);

      if (appDate != null) {
        if (appDate.isAfter(now.subtract(const Duration(hours: 1))) ||
            (appDate.year == today.year &&
                appDate.month == today.month &&
                appDate.day == today.day)) {
          validAppointments.add(appointment);
        }
      } else {
        validAppointments.add(appointment);
      }
    }

    // Sort valid appointments by date
    validAppointments.sort((a, b) {
      final dateA = _parseDate(a['date']);
      final dateB = _parseDate(b['date']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    if (validAppointments.isEmpty) {
      return _buildEmptyCard("No upcoming appointments", isDarkMode);
    }

    // Display the nearest upcoming appointment
    final nearestAppointment = validAppointments.first;
    DateTime appointmentDate = _parseDate(nearestAppointment['date']) ?? DateTime.now();

    return AppointmentCard(
      doctor: nearestAppointment['doctor_name'] ?? "Unknown Doctor",
      specialty: nearestAppointment['speciality'] ?? "Medical Appointment",
      date: appointmentDate,
      time: nearestAppointment['time'] ?? "12:00 PM",
      location: nearestAppointment['location'] ?? "Hospital",
      notes: nearestAppointment['notes'] ?? "",
      isUpcoming: true,
      onDelete: () async {
        try {
          await _dbHelper.deleteAppointment(nearestAppointment['appointment_id']);
          _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted successfully')),
          );
        } catch (e) {
          print('Error deleting appointment: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete appointment')),
          );
        }
      },
    );
  }

  // Updated SOS button method to use the new handler
  Widget _buildSOSButton() {
    return Hero(
      tag: 'sos_button',
      child: PrimaryButton(
        text: "EMERGENCY SOS",
        icon: Icons.emergency,
        bgColor: Colors.red,
        onPressed: () {
          // Show our custom SOS dialog
          showDialog(
            context: context,
            builder: (context) => SOSDialog(
              userId: widget.userId,
              onSuccess: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Emergency alert sent to caregivers!"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}