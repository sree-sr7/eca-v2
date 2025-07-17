import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../repository/medicine_repository.dart';
import '../database/db_helper.dart';
import '../utils/app_colors.dart';

class NewMedicineFormScreen extends StatefulWidget {
  final Medicine? medicine;
  final int userId;

  const NewMedicineFormScreen({
    Key? key,
    this.medicine,
    required this.userId,
  }) : super(key: key);

  @override
  State<NewMedicineFormScreen> createState() => _NewMedicineFormScreenState();
}

class _NewMedicineFormScreenState extends State<NewMedicineFormScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Medicine data
  late String _name = '';
  late String _dosage = '';
  late String _frequency = '';
  late int _stock = 0;
  late String _notes = ''; // Added notes field
  // Add this after the other state variables
  late String _scheduleType = 'daily'; // Options: daily, weekly, monthly
  //List<bool> _selectedDays = List.generate(7, (_) => false); // For weekly schedule (7 days)
  //late int _monthlyDay = 1; // For monthly schedule (day of month)
  late DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  TimeOfDay? _selectedTime;

  // Services
  late final MedicineRepository _medicineRepository;
  final _dbHelper = DBHelper();

  bool _isEditing = false;
  String? _medicineId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _medicineRepository = MedicineRepository(
      dbHelper: _dbHelper,
      userId: widget.userId,
    );

    // Initialize form fields if editing existing medicine
    if (widget.medicine != null) {
      _isEditing = true;
      _medicineId = widget.medicine!.id;
      _name = widget.medicine!.name;
      _dosage = widget.medicine!.dosage;
      _frequency = widget.medicine!.frequency;
      _stock = widget.medicine!.stock;
      _expiryDate = widget.medicine!.expiryDate;
      _selectedTime = widget.medicine!.timeOfDay;
      _notes = widget.medicine!.notes ?? ''; // Initialize notes field

      // Initialize schedule type fields
      if (widget.medicine!.scheduleType != null) {
        _scheduleType = widget.medicine!.scheduleType;
      }
    }
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accentColor,
              onPrimary: Colors.white,
              surface: isDarkMode ? Colors.grey[850]! : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // Time picker function
  Future<void> _selectTime(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accentColor,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Save medicine function
  Future<void> _saveMedicine() async {
    // Check form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Save form values
    _formKey.currentState!.save();

    // Don't allow double submissions
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create medicine object
      // Modify the medicine object creation in the _saveMedicine method
      final medicine = Medicine(
        id: _isEditing ? _medicineId! : '',
        name: _name,
        dosage: _dosage,
        frequency: _frequency,
        stock: _stock,
        expiryDate: _expiryDate,
        timeOfDay: _selectedTime,
        notes: _notes, // Add notes field
        color: _isEditing
            ? widget.medicine!.color
            : Colors.primaries[DateTime.now().millisecond % Colors.primaries.length],
        icon: _isEditing
            ? widget.medicine!.icon
            : Icons.medication_rounded,
        isTaken: _isEditing ? widget.medicine!.isTaken : false,
        // Add new fields:
        scheduleType: _scheduleType,
        //selectedDays: _scheduleType == 'weekly' ? _selectedDays : null,
        //monthlyDay: _scheduleType == 'monthly' ? _monthlyDay : null,
      );

      bool success = false;

      // Update or insert medicine
      if (_isEditing) {
        success = await _medicineRepository.updateMedicine(medicine);
      } else {
        success = await _medicineRepository.insertMedicine(medicine);
      }

      if (success) {
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} ${_isEditing ? 'updated' : 'added'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // Return to previous screen
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to ${_isEditing ? 'update' : 'save'} medicine');
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );

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
    final hintColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Medicine Details' : 'Add New Medicine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(
                        labelText: 'Medicine Name',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        hintText: 'E.g., Paracetamol',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.medication_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medicine name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dosage field
                    TextFormField(
                      initialValue: _dosage,
                      decoration: InputDecoration(
                        labelText: 'Dosage',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        hintText: 'E.g., 500mg',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _dosage = value!;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Frequency field
                    TextFormField(
                      initialValue: _frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        hintText: 'E.g., Twice a day',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter frequency';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _frequency = value!;
                      },
                    ),

                    // Add this after the frequency field and before the stock field
                    const SizedBox(height: 16),

                    // Schedule type selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'daily', label: Text('Daily')),
                            ButtonSegment(value: 'weekly', label: Text('Weekly')),
                            ButtonSegment(value: 'monthly', label: Text('Monthly')),
                          ],
                          selected: {_scheduleType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _scheduleType = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock field
                    TextFormField(
                      initialValue: _stock.toString(),
                      decoration: InputDecoration(
                        labelText: 'Current Stock',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        hintText: 'E.g., 30',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter current stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _stock = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes field (added)
                    TextFormField(
                      initialValue: _notes,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        hintText: 'E.g., Take with food, side effects, etc.',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 3,
                      onSaved: (value) {
                        _notes = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiry date field
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _expiryDate.toIso8601String().split('T')[0],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder time field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedTime != null
                                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Set reminder time (optional)',
                                  style: TextStyle(
                                    color: _selectedTime != null
                                        ? textColor
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveMedicine,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Save'),
                          ),
                        ),
                      ],
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