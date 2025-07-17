import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/appointment_card.dart';
import '../database/db_helper.dart';
import '../services/notification_manager.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? initialAppointment;

  const DoctorAppointmentScreen({
    Key? key,
    required this.userId,
    this.initialAppointment,
  }) : super(key: key);

  @override
  State<DoctorAppointmentScreen> createState() => _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DBHelper _dbHelper = DBHelper();
  final NotificationManager _notificationManager = NotificationManager();

  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  List<Map<String, dynamic>> _filteredUpcomingAppointments = [];
  List<Map<String, dynamic>> _filteredPastAppointments = [];
  bool _isLoading = true;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Controllers for add/edit appointment form
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize notification manager
    _initializeNotifications();

    _loadAppointments();

    // Jump to proper tab if initialAppointment is provided
    if (widget.initialAppointment != null) {
      // Initialize form fields with initial appointment data if provided
      Future.delayed(Duration.zero, () {
        _processInitialAppointment();
      });
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationManager.initialize();
  }

  void _processInitialAppointment() {
    if (widget.initialAppointment != null) {
      try {
        final appointmentDate = DateFormat('yyyy-MM-dd').parse(widget.initialAppointment!['date']);
        final now = DateTime.now();

        // Set the tab controller to the appropriate tab based on appointment date
        if (appointmentDate.isAfter(now) ||
            (appointmentDate.day == now.day &&
                appointmentDate.month == now.month &&
                appointmentDate.year == now.year)) {
          _tabController.animateTo(0); // Upcoming tab
        } else {
          _tabController.animateTo(1); // Past tab
        }
      } catch (e) {
        print('Error processing initial appointment: $e');
      }
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allAppointments = await _dbHelper.getAppointments(widget.userId);

      print('Fetched ${allAppointments.length} appointments from database');

      final now = DateTime.now();
      final upcoming = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];

      for (var appointment in allAppointments) {
        try {
          // Make sure date is properly formatted
          String dateStr = appointment['date'];
          if (!dateStr.contains('-')) {
            // If date is in another format, try to convert it
            final parsedDate = DateTime.parse(dateStr);
            dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);
          }

          final appointmentDate = DateFormat('yyyy-MM-dd').parse(dateStr);
          final appointmentDateTime = DateTime(
              appointmentDate.year,
              appointmentDate.month,
              appointmentDate.day,
              23, 59, 59
          );

          final nowDate = DateTime(now.year, now.month, now.day);

          if (appointmentDateTime.isAfter(nowDate) || appointmentDateTime.isAtSameMomentAs(nowDate)) {
            upcoming.add(appointment);
          } else {
            past.add(appointment);
          }
        } catch (e) {
          print('Error processing appointment date: $e');
          print('Problematic appointment: ${appointment['appointment_id']}, Date: ${appointment['date']}');
        }
      }

      // Sort appointments by date
      upcoming.sort((a, b) {
        try {
          final aDate = DateFormat('yyyy-MM-dd').parse(a['date']);
          final bDate = DateFormat('yyyy-MM-dd').parse(b['date']);
          return aDate.compareTo(bDate);
        } catch (e) {
          return 0;
        }
      });

      past.sort((a, b) {
        try {
          final aDate = DateFormat('yyyy-MM-dd').parse(a['date']);
          final bDate = DateFormat('yyyy-MM-dd').parse(b['date']);
          return bDate.compareTo(aDate); // Reverse sort for past appointments
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _upcomingAppointments = upcoming;
        _pastAppointments = past;
        _filteredUpcomingAppointments = upcoming;
        _filteredPastAppointments = past;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load appointments'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _filterAppointments(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUpcomingAppointments = _upcomingAppointments;
        _filteredPastAppointments = _pastAppointments;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      _filteredUpcomingAppointments = _upcomingAppointments.where((appointment) {
        return appointment['doctor_name'].toLowerCase().contains(lowerCaseQuery) ||
            (appointment['specialty'] ?? '').toLowerCase().contains(lowerCaseQuery) ||
            (appointment['location'] ?? '').toLowerCase().contains(lowerCaseQuery) ||
            (appointment['notes'] ?? '').toLowerCase().contains(lowerCaseQuery);
      }).toList();

      _filteredPastAppointments = _pastAppointments.where((appointment) {
        return appointment['doctor_name'].toLowerCase().contains(lowerCaseQuery) ||
            (appointment['specialty'] ?? '').toLowerCase().contains(lowerCaseQuery) ||
            (appointment['location'] ?? '').toLowerCase().contains(lowerCaseQuery) ||
            (appointment['notes'] ?? '').toLowerCase().contains(lowerCaseQuery);
      }).toList();
    });
  }

  Future<void> _deleteAppointment(int appointmentId) async {
    try {
      // Cancel notifications before deleting appointment
      await _notificationManager.cancelAppointmentNotifications(appointmentId);

      await _dbHelper.deleteAppointment(appointmentId);
      _loadAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment deleted'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      print('Error deleting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete appointment'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _updateAppointment(int appointmentId) async {
    try {
      // Cancel existing notifications first
      await _notificationManager.cancelAppointmentNotifications(appointmentId);

      await _dbHelper.updateAppointment(
        appointmentId: appointmentId,
        doctorName: _doctorNameController.text,
        date: _dateController.text,
        time: _timeController.text,
        specialty: _specialtyController.text,
        location: _locationController.text,
        notes: _notesController.text,
      );

      // After updating in database, reload the appointments and reschedule notifications
      await _loadAppointments();
      await _notificationManager.scheduleAppointmentNotifications(widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update appointment'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _showAddAppointmentModal({Map<String, dynamic>? appointment}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isEditing = appointment != null;

    // Clear form fields first
    _doctorNameController.clear();
    _specialtyController.clear();
    _dateController.clear();
    _timeController.clear();
    _locationController.clear();
    _notesController.clear();
    _statusController.text = 'Scheduled';

    // Fill form fields if editing
    if (isEditing) {
      _doctorNameController.text = appointment['doctor_name'] ?? '';
      _specialtyController.text = appointment['specialty'] ?? '';
      _dateController.text = appointment['date'] ?? '';
      _timeController.text = appointment['time'] ?? '';
      _locationController.text = appointment['location'] ?? '';
      _notesController.text = appointment['notes'] ?? '';
      _statusController.text = appointment['status'] ?? 'Scheduled';
    }

    // Use a barrier to ensure the modal bottom sheet is properly displayed
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Appointment' : 'Add New Appointment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: isDarkMode ? Colors.white : AppColors.textDark,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Form fields
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _doctorNameController,
                            label: "Doctor's Name",
                            hintText: "Enter doctor's full name",
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Doctor's name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _specialtyController,
                            label: "Specialty / Purpose",
                            hintText: "Enter specialty or visit purpose",
                            prefixIcon: Icons.medical_services,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _dateController,
                            label: "Date",
                            hintText: "Select appointment date",
                            prefixIcon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Date is required";
                              }
                              return null;
                            },
                            onTap: () async {
                              // Default to current date if no date is selected
                              DateTime initialDate;

                              try {
                                // Try to parse the existing date if available
                                if (_dateController.text.isNotEmpty) {
                                  DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);

                                  // If editing and the date is in the past, set initialDate to today
                                  // This ensures the picker opens with today's date, not a past date
                                  if (parsedDate.isBefore(DateTime.now())) {
                                    initialDate = DateTime.now();
                                  } else {
                                    initialDate = parsedDate;
                                  }
                                } else {
                                  initialDate = DateTime.now();
                                }
                              } catch (e) {
                                // If date parsing fails, default to current date
                                initialDate = DateTime.now();
                              }

                              // Use FocusScope to dismiss keyboard before showing date picker
                              FocusScope.of(context).unfocus();

                              // Show date picker with improved theming
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                // Always use current date as firstDate, regardless if adding or editing
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDarkMode
                                          ? ColorScheme.dark(
                                        primary: AppColors.accentColor,
                                        onPrimary: Colors.white,
                                        surface: AppColors.darkCardColor,
                                        onSurface: Colors.white,
                                      )
                                          : ColorScheme.light(
                                        primary: AppColors.accentColor,
                                        onPrimary: Colors.white,
                                        surface: AppColors.lightCardColor,
                                        onSurface: AppColors.textDark,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDarkMode ? Colors.white : AppColors.accentColor,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setModalState(() {
                                  _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _timeController,
                            label: "Time",
                            hintText: "Select appointment time",
                            prefixIcon: Icons.access_time,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Time is required";
                              }
                              return null;
                            },
                            onTap: () async {
                              // Initialize with current time if empty
                              TimeOfDay initialTime = TimeOfDay.now();

                              // Try to parse existing time if available
                              if (_timeController.text.isNotEmpty) {
                                try {
                                  // Handle 12-hour format
                                  if (_timeController.text.contains('PM') || _timeController.text.contains('AM')) {
                                    final timeParts = _timeController.text.split(' ');
                                    final timeOnly = timeParts[0];
                                    final amPm = timeParts[1];
                                    final hourMinute = timeOnly.split(':');
                                    var hour = int.parse(hourMinute[0]);
                                    final minute = int.parse(hourMinute[1]);
                                    if (amPm == 'PM' && hour < 12) hour += 12;
                                    if (amPm == 'AM' && hour == 12) hour = 0;
                                    initialTime = TimeOfDay(hour: hour, minute: minute);
                                  }
                                  // Handle 24-hour format
                                  else {
                                    final parts = _timeController.text.split(':');
                                    final hour = int.parse(parts[0]);
                                    final minute = int.parse(parts[1]);
                                    initialTime = TimeOfDay(hour: hour, minute: minute);
                                  }
                                } catch (e) {
                                  // Default to current time if parsing fails
                                  initialTime = TimeOfDay.now();
                                }
                              }

                              // Dismiss keyboard before showing time picker
                              FocusScope.of(context).unfocus();

                              // Show time picker with improved theming
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDarkMode
                                          ? ColorScheme.dark(
                                        primary: AppColors.accentColor,
                                        onPrimary: Colors.white,
                                        surface: AppColors.darkCardColor,
                                        onSurface: Colors.white,
                                      )
                                          : ColorScheme.light(
                                        primary: AppColors.accentColor,
                                        onPrimary: Colors.white,
                                        surface: AppColors.lightCardColor,
                                        onSurface: AppColors.textDark,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDarkMode ? Colors.white : AppColors.accentColor,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setModalState(() {
                                  _timeController.text = picked.format(context);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _locationController,
                            label: "Location",
                            hintText: "Enter clinic or hospital name",
                            prefixIcon: Icons.location_on,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _notesController,
                            label: "Notes",
                            hintText: "Enter any additional notes",
                            prefixIcon: Icons.note,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: isEditing ? "Update Appointment" : "Save Appointment",
                            icon: isEditing ? Icons.update : Icons.save,
                            bgColor: AppColors.accentColor,
                            onPressed: () async {
                              // Validate inputs
                              if (_doctorNameController.text.isEmpty ||
                                  _dateController.text.isEmpty ||
                                  _timeController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: AppColors.errorColor,
                                  ),
                                );
                                return;
                              }

                              // Validate date is not in the past
                              try {
                                final selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
                                final today = DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                );

                                if (selectedDate.isBefore(today)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a current or future date'),
                                      backgroundColor: AppColors.errorColor,
                                    ),
                                  );
                                  return;
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid date format'),
                                    backgroundColor: AppColors.errorColor,
                                  ),
                                );
                                return;
                              }

                              // Save to database
                              try {
                                if (isEditing) {
                                  await _updateAppointment(appointment['appointment_id']);
                                } else {
                                  final int appointmentId = await _dbHelper.insertAppointment(
                                    userId: widget.userId,
                                    doctorName: _doctorNameController.text,
                                    date: _dateController.text,
                                    time: _timeController.text,
                                    status: _statusController.text,
                                    specialty: _specialtyController.text,
                                    location: _locationController.text,
                                    notes: _notesController.text,
                                  );

                                  // Schedule notifications for the new appointment
                                  await _notificationManager.scheduleAppointmentNotifications(widget.userId);

                                  print('Added appointment with ID: $appointmentId');
                                }

                                // Reload appointments
                                _loadAppointments();

                                Navigator.pop(context);

                                // Show confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? 'Appointment updated successfully' : 'Appointment added successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } catch (e) {
                                print('Error ${isEditing ? "updating" : "adding"} appointment: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to ${isEditing ? "update" : "add"} appointment'),
                                    backgroundColor: AppColors.errorColor,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
        elevation: 0,
        title: Text(
          'Doctor Appointments',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Keep only the test notification button
          IconButton(
            icon: const Icon(Icons.notifications_active),
            color: isDarkMode ? Colors.white70 : Colors.black54,
            onPressed: () async {
              await _notificationManager.showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDarkMode ? AppColors.darkCardColor : AppColors.lightCardColor,
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search appointments',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _filterAppointments,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accentColor,
                    labelColor: AppColors.accentColor,
                    unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming appointments tab
                  _buildAppointmentList(_filteredUpcomingAppointments, isUpcoming: true),

                  // Past appointments tab
                  _buildAppointmentList(_filteredPastAppointments, isUpcoming: false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentColor,
        onPressed: _showAddAppointmentModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentList(List<Map<String, dynamic>> appointments, {required bool isUpcoming}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming appointments' : 'No past appointments',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (isUpcoming)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Tap the + button to add a new appointment',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];

        // Parse date from database format
        DateTime appointmentDate;
        try {
          appointmentDate = DateFormat('yyyy-MM-dd').parse(appointment['date']);
        } catch (e) {
          print('Error parsing date: ${appointment['date']} - $e');
          // Fallback to today's date if parsing fails
          appointmentDate = DateTime.now();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppointmentCard(
            doctor: appointment['doctor_name'] ?? 'Unknown Doctor',
            specialty: appointment['specialty'] ?? '',
            date: appointmentDate,
            time: appointment['time'] ?? '12:00',
            location: appointment['location'] ?? '',
            notes: appointment['notes'] ?? '',
            isUpcoming: isUpcoming,
            onDelete: isUpcoming ? () => _deleteAppointment(appointment['appointment_id']) : null,
            onEdit: isUpcoming ? () => _showAddAppointmentModal(appointment: appointment) : null,
          ),
        );
      },
    );
  }
}