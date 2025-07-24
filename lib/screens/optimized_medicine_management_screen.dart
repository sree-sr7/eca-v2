import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_app/utils/app_colors.dart' as app_colors;
import '../widgets/optimized_medicine_card.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';
import 'medicine_form_screen.dart';
import '../repository/medicine_repository.dart';
import '../database/db_helper.dart';
import '../utils/performance_optimizer.dart';

/// Optimized medicine management screen with performance improvements
class OptimizedMedicineManagementScreen extends StatefulWidget {
  final int userId;

  const OptimizedMedicineManagementScreen({super.key, required this.userId});

  @override
  State<OptimizedMedicineManagementScreen> createState() =>
      _OptimizedMedicineManagementScreenState();
}

class _OptimizedMedicineManagementScreenState
    extends State<OptimizedMedicineManagementScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  final _notificationService = NotificationService();
  late MedicineRepository _medicineRepository;
  final _dbHelper = DBHelper();

  // Performance optimization
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _medicineRepository = MedicineRepository(
      dbHelper: _dbHelper,
      userId: widget.userId,
    );
    _initializeNotifications();

    // Add search listener with debouncing
    _searchController.addListener(_onSearchChanged);

    // Load data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicines();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    PerformanceOptimizer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    PerformanceOptimizer.debounceSearch(() {
      if (mounted) {
        _filterMedicines();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadMedicines() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading medicines for user ${widget.userId}');
      final medicines = await _medicineRepository.getAllMedicines();
      debugPrint('Loaded ${medicines.length} medicines from database');

      if (!mounted) return;

      setState(() {
        _medicines = medicines;
        _filterMedicines();

        // Schedule notifications for medicines in background
        PerformanceOptimizer.scheduleExpensiveOperation(() {
          for (final medicine in _medicines) {
            _scheduleNotificationsForMedicine(medicine);
          }
        });
      });
    } catch (e) {
      debugPrint('Error in _loadMedicines: $e');
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

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = List.from(_medicines);
      } else {
        _filteredMedicines =
            _medicines.where((medicine) {
              return medicine.name.toLowerCase().contains(query);
            }).toList();
      }
    });
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
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMedicines();
    }
  }

  Future<void> _navigateToEditMedicine(Medicine medicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NewMedicineFormScreen(
              medicine: medicine,
              userId: widget.userId,
            ),
      ),
    );

    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      _loadMedicines();
    }
  }

  Future<void> _deleteMedicine(String id) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      // Cancel notifications for this medicine
      await _notificationService.cancelNotificationsForMedicine(id);

      final result = await _medicineRepository.deleteMedicine(id);
      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine deleted successfully'),
              backgroundColor: app_colors.AppColors.success,
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 300));
        _loadMedicines();
      } else {
        throw Exception('Failed to delete medicine');
      }
    } catch (e) {
      debugPrint('Error in _deleteMedicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medicine: $e'),
            backgroundColor: app_colors.AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Medicine'),
                content: const Text(
                  'Are you sure you want to delete this medicine?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: app_colors.AppColors.errorColor),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _markAsTaken(Medicine medicine, bool isTaken) async {
    try {
      debugPrint(
        'Marking medicine ${medicine.name} (${medicine.id}) as ${isTaken ? 'taken' : 'not taken'}',
      );

      final success = await _medicineRepository.updateMedicineTakenStatus(
        medicine.id,
        isTaken,
      );

      if (success) {
        setState(() {
          final index = _medicines.indexWhere((m) => m.id == medicine.id);
          if (index != -1) {
            _medicines[index] = medicine.copyWith(isTaken: isTaken);
            _filterMedicines();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTaken
                    ? 'Medicine marked as taken'
                    : 'Medicine marked as not taken',
              ),
              backgroundColor:
                  isTaken
                      ? app_colors.AppColors.success
                      : app_colors.AppColors.accentColor,
            ),
          );
        }

        if (isTaken && medicine.stock > 0) {
          await _reduceStock(medicine);
        }
      } else {
        debugPrint(
          'Failed to update medicine taken status. Medicine ID: ${medicine.id}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update medicine status'),
              backgroundColor: app_colors.AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _markAsTaken: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating medicine status: $e'),
            backgroundColor: app_colors.AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reduceStock(Medicine medicine) async {
    if (medicine.stock <= 0) return;

    final updatedMedicine = medicine.copyWith(stock: medicine.stock - 1);

    try {
      debugPrint(
        'Reducing stock for ${medicine.name} from ${medicine.stock} to ${updatedMedicine.stock}',
      );
      final success = await _medicineRepository.updateMedicine(updatedMedicine);

      if (success) {
        setState(() {
          final index = _medicines.indexWhere((m) => m.id == medicine.id);
          if (index != -1) {
            _medicines[index] = updatedMedicine;
            _filterMedicines();
          }
        });

        if (updatedMedicine.stock < 10 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Low stock alert: Only ${updatedMedicine.stock} units of ${updatedMedicine.name} left',
              ),
              backgroundColor: app_colors.AppColors.warningColor,
            ),
          );
        }
      } else {
        debugPrint('Failed to update medicine stock');
      }
    } catch (e) {
      debugPrint('Error updating medicine stock: $e');
    }
  }

  Future<void> _refreshMedicines() async {
    await _notificationService.cancelAllNotifications();
    await _loadMedicines();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicines refreshed'),
          backgroundColor: app_colors.AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode
            ? app_colors.AppColors.darkBackground
            : app_colors.AppColors.lightBackground;
    final cardColor =
        isDarkMode
            ? app_colors.AppColors.darkCardColor
            : app_colors.AppColors.lightCardColor;
    final textColor =
        isDarkMode
            ? app_colors.AppColors.textLight
            : app_colors.AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor, isDarkMode),
      body: _buildBody(cardColor, textColor),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(Color backgroundColor, bool isDarkMode) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
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
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToAddMedicine,
      backgroundColor: app_colors.AppColors.accentColor,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody(Color cardColor, Color textColor) {
    return Column(
      children: [
        _buildSearchBar(cardColor),
        _buildTabBar(textColor),
        Expanded(
          child:
              _isLoading
                  ? const OptimizedLoadingIndicator(
                    message: 'Loading medicines...',
                  )
                  : _buildTabBarView(textColor),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medicines...',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterMedicines();
                      },
                    )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: app_colors.AppColors.accentColor,
        labelColor: textColor,
        tabs: const [Tab(text: 'All Medicines'), Tab(text: 'Low Stock')],
      ),
    );
  }

  Widget _buildTabBarView(Color textColor) {
    final lowStockMedicines =
        _filteredMedicines.where((m) => m.stock < 10).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        // All medicines tab
        _buildMedicinesList(_filteredMedicines, textColor),
        // Low stock tab
        _buildMedicinesList(lowStockMedicines, textColor, isLowStockTab: true),
      ],
    );
  }

  Widget _buildMedicinesList(
    List<Medicine> medicines,
    Color textColor, {
    bool isLowStockTab = false,
  }) {
    if (medicines.isEmpty) {
      return _buildEmptyState(textColor, isLowStockTab);
    }

    return OptimizedListView<Medicine>(
      items: medicines,
      onRefresh: _refreshMedicines,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemBuilder: (context, medicine, index) {
        return OptimizedMedicineCard(
          medicine: medicine,
          onDelete: () => _deleteMedicine(medicine.id),
          onEdit: () => _navigateToEditMedicine(medicine),
          onTakenChanged: (isTaken) => _markAsTaken(medicine, isTaken),
        );
      },
    );
  }

  Widget _buildEmptyState(Color textColor, bool isLowStockTab) {
    if (isLowStockTab) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'No medicines with low stock',
              style: TextStyle(
                fontSize: 18,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

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
              color: textColor.withValues(alpha: 0.7),
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
