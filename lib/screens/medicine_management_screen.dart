import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_app/utils/app_colors.dart' as app_colors;
import '../widgets/medicine_card.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import 'medicine_form_screen.dart';
import '../repository/medicine_repository.dart';
import '../database/db_helper.dart';

class MedicineManagementScreen extends StatefulWidget {
  final int userId;

  const MedicineManagementScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MedicineManagementScreen> createState() => _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  final _notificationService = NotificationService();
  late MedicineRepository _medicineRepository;
  final _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _medicineRepository = MedicineRepository(dbHelper: _dbHelper, userId: widget.userId);
    _initializeNotifications();

    // Add a slight delay to ensure the screen is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicines();
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading medicines for user ${widget.userId}');
      final medicines = await _medicineRepository.getAllMedicines();
      print('Loaded ${medicines.length} medicines from database');

      if (!mounted) return;

      setState(() {
        _medicines = medicines;

        // Debug output
        for (var med in _medicines) {
          print('Medicine: ${med.name}, ID: ${med.id}, Stock: ${med.stock}, Taken: ${med.isTaken}');
        }

        // Schedule notifications for medicines
        for (final medicine in _medicines) {
          _scheduleNotificationsForMedicine(medicine);
        }
      });
    } catch (e) {
      print('Error in _loadMedicines: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medicines: $e'),
          backgroundColor: app_colors.AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleNotificationsForMedicine(Medicine medicine) {
    _notificationService.scheduleMedicineReminder(medicine);
    _notificationService.scheduleExpiryAlert(medicine);
    _notificationService.scheduleLowStockAlert(medicine);
  }

  Future<void> _navigateToAddMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMedicineFormScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      // Use a slight delay to ensure database operations complete
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMedicines();
    }
  }

  Future<void> _navigateToEditMedicine(Medicine medicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMedicineFormScreen(medicine: medicine, userId: widget.userId),
      ),
    );

    if (result == true) {
      // Use a slight delay to ensure database operations complete
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMedicines();
    }
  }

  Future<void> _deleteMedicine(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Cancel notifications for this medicine
              await _notificationService.cancelNotificationsForMedicine(id);

              try {
                final result = await _medicineRepository.deleteMedicine(id);
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine deleted successfully'),
                      backgroundColor: app_colors.AppColors.success,
                    ),
                  );

                  // Reload medicines after a small delay
                  await Future.delayed(const Duration(milliseconds: 300));
                  _loadMedicines();
                } else {
                  throw Exception('Failed to delete medicine');
                }
              } catch (e) {
                print('Error in _deleteMedicine: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting medicine: $e'),
                    backgroundColor: app_colors.AppColors.errorColor,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: app_colors.AppColors.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsTaken(Medicine medicine, bool isTaken) async {
    try {
      print('Marking medicine ${medicine.name} (${medicine.id}) as ${isTaken ? 'taken' : 'not taken'}');

      // Update the medicine taken status
      final success = await _medicineRepository.updateMedicineTakenStatus(medicine.id, isTaken);

      if (success) {
        // Update local state if successful
        setState(() {
          final index = _medicines.indexWhere((m) => m.id == medicine.id);
          if (index != -1) {
            _medicines[index] = medicine.copyWith(isTaken: isTaken);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTaken ? 'Medicine marked as taken' : 'Medicine marked as not taken'),
            backgroundColor: isTaken ? app_colors.AppColors.success : app_colors.AppColors.accentColor,
          ),
        );

        // If the medicine was taken, consider reducing stock
        if (isTaken && medicine.stock > 0) {
          await _reduceStock(medicine);
        }
      } else {
        print('Failed to update medicine taken status. Medicine ID: ${medicine.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update medicine status'),
            backgroundColor: app_colors.AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      print('Error in _markAsTaken: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating medicine status: $e'),
          backgroundColor: app_colors.AppColors.errorColor,
        ),
      );
    }
  }

  // Reduce medicine stock by 1 when taken
  Future<void> _reduceStock(Medicine medicine) async {
    if (medicine.stock <= 0) return;

    final updatedMedicine = medicine.copyWith(
      stock: medicine.stock - 1,
    );

    try {
      print('Reducing stock for ${medicine.name} from ${medicine.stock} to ${updatedMedicine.stock}');
      final success = await _medicineRepository.updateMedicine(updatedMedicine);
      if (success) {
        setState(() {
          final index = _medicines.indexWhere((m) => m.id == medicine.id);
          if (index != -1) {
            _medicines[index] = updatedMedicine;
          }
        });

        // If stock is low after reduction, show alert
        if (updatedMedicine.stock < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Low stock alert: Only ${updatedMedicine.stock} units of ${updatedMedicine.name} left'),
              backgroundColor: app_colors.AppColors.warningColor,
            ),
          );
        }
      } else {
        print('Failed to update medicine stock');
      }
    } catch (e) {
      print('Error updating medicine stock: $e');
    }
  }

  List<Medicine> _getFilteredMedicines() {
    if (_searchController.text.isEmpty) {
      return _medicines;
    }

    return _medicines.where((medicine) {
      return medicine.name.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  Future<void> _refreshMedicines() async {
    // Cancel all existing notifications
    await _notificationService.cancelAllNotifications();

    // Force refresh from database
    await _loadMedicines();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicines refreshed'),
        backgroundColor: app_colors.AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? app_colors.AppColors.darkBackground : app_colors.AppColors.lightBackground;
    final cardColor = isDarkMode ? app_colors.AppColors.darkCardColor : app_colors.AppColors.lightCardColor;
    final textColor = isDarkMode ? app_colors.AppColors.textLight : app_colors.AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
        title: const Text('Medicine Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMedicines,
          ),
        ],
      ),
      body: _buildMedicineList(cardColor, textColor),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMedicine,
        backgroundColor: app_colors.AppColors.accentColor,
        child: const Icon(Icons.add),
      ),
      // Changed: Move the FAB to the center-bottom instead of bottom-right corner
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMedicineList(Color cardColor, Color textColor) {
    final filteredMedicines = _getFilteredMedicines();
    final lowStockMedicines = filteredMedicines.where((m) => m.stock < 10).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
                    : null,
              ),
            ),
          ),
        ),

        // Tab bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            indicatorColor: app_colors.AppColors.accentColor,
            labelColor: textColor,
            tabs: const [
              Tab(text: 'All Medicines'),
              Tab(text: 'Low Stock'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : TabBarView(
            controller: _tabController,
            children: [
              // All medicines tab
              filteredMedicines.isEmpty
                  ? _buildEmptyState(textColor)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
                itemCount: filteredMedicines.length,
                itemBuilder: (context, index) {
                  return MedicineCard(
                    medicine: filteredMedicines[index],
                    onDelete: () => _deleteMedicine(filteredMedicines[index].id),
                    onEdit: () => _navigateToEditMedicine(filteredMedicines[index]),
                    onTakenChanged: (isTaken) => _markAsTaken(filteredMedicines[index], isTaken),
                  );
                },
              ),

              // Low stock tab
              lowStockMedicines.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'No medicines with low stock',
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
                itemCount: lowStockMedicines.length,
                itemBuilder: (context, index) {
                  return MedicineCard(
                    medicine: lowStockMedicines[index],
                    onDelete: () => _deleteMedicine(lowStockMedicines[index].id),
                    onEdit: () => _navigateToEditMedicine(lowStockMedicines[index]),
                    onTakenChanged: (isTaken) => _markAsTaken(lowStockMedicines[index], isTaken),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No medicines found',
            style: TextStyle(
              fontSize: 18,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _navigateToAddMedicine,
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: app_colors.AppColors.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}