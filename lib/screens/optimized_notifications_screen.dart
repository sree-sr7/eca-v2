import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../widgets/optimized_notification_card.dart';
import '../models/notification_model.dart';
import '../utils/performance_optimizer.dart';

/// Optimized notifications screen with performance improvements and lazy loading
class OptimizedNotificationsScreen extends StatefulWidget {
  const OptimizedNotificationsScreen({super.key});

  @override
  State<OptimizedNotificationsScreen> createState() =>
      _OptimizedNotificationsScreenState();
}

class _OptimizedNotificationsScreenState
    extends State<OptimizedNotificationsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  late LazyLoadingController<NotificationModel> _lazyController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize lazy loading controller
    _lazyController = LazyLoadingController<NotificationModel>(
      itemsPerPage: 20,
      loadItems: _loadNotificationPage,
    );

    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lazyController.dispose();
    PerformanceOptimizer.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {}); // Refresh filtered notifications when tab changes
    }
  }

  Future<List<NotificationModel>> _loadNotificationPage(
    int page,
    int limit,
  ) async {
    // Simulate API call with pagination
    await Future.delayed(const Duration(milliseconds: 500));

    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, _notifications.length);

    if (startIndex >= _notifications.length) {
      return [];
    }

    return _notifications.sublist(startIndex, endIndex);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _notifications = _generateSampleNotifications();
      _isLoading = false;
    });

    // Load first page
    await _lazyController.refresh();
  }

  List<NotificationModel> _generateSampleNotifications() {
    return [
      // Generate more notifications for testing lazy loading
      ...List.generate(50, (index) {
        final types = NotificationType.values;
        final type = types[index % types.length];

        return NotificationModel(
          id: 'notification_$index',
          title: _getTitleForType(type, index),
          message: _getMessageForType(type, index),
          time: DateTime.now().subtract(Duration(hours: index)),
          type: type,
          isRead: index % 3 == 0, // Make some notifications read
        );
      }),
    ];
  }

  String _getTitleForType(NotificationType type, int index) {
    switch (type) {
      case NotificationType.missedMedication:
        return 'Missed Medication';
      case NotificationType.medicationReminder:
        return 'Medication Reminder';
      case NotificationType.appointment:
        return 'Upcoming Appointment';
      case NotificationType.medicineStock:
        return 'Medicine Stock Warning';
      case NotificationType.medicineExpiry:
        return 'Medicine Expiry Warning';
      case NotificationType.sos:
        return 'SOS Alert Sent';
      case NotificationType.healthUpdate:
        return 'Health Update';
      case NotificationType.system:
        return 'System Notification';
    }
  }

  String _getMessageForType(NotificationType type, int index) {
    switch (type) {
      case NotificationType.missedMedication:
        return 'You missed your medication: Medicine ${index + 1}';
      case NotificationType.medicationReminder:
        return 'Time to take your medication: Medicine ${index + 1}';
      case NotificationType.appointment:
        return 'Appointment with Dr. Smith in ${index + 1} days';
      case NotificationType.medicineStock:
        return 'Medicine ${index + 1} stock is low. Only ${10 - (index % 10)} tablets remaining.';
      case NotificationType.medicineExpiry:
        return 'Medicine ${index + 1} expires in ${index % 7 + 1} days. Please refill soon.';
      case NotificationType.sos:
        return 'Emergency alert sent to your caregiver.';
      case NotificationType.healthUpdate:
        return 'Your health metrics have been updated.';
      case NotificationType.system:
        return 'System update notification ${index + 1}.';
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

    await _loadNotifications();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _lazyController.items) {
        notification.isRead = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All notifications marked as read',
            style: TextStyle(fontSize: 16),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : AppColors.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteNotification(String id) {
    setState(() {
      _lazyController.items.removeWhere(
        (notification) => notification.id == id,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Notification deleted',
            style: TextStyle(fontSize: 16),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : AppColors.primaryColor,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: _refreshNotifications,
          ),
        ),
      );
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_tabController.index == 0) {
      return _lazyController.items;
    } else {
      return _lazyController.items
          .where((notification) => !notification.isRead)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor, textColor, isDarkMode),
      body:
          _isLoading
              ? const OptimizedLoadingIndicator(
                message: 'Loading notifications...',
              )
              : _lazyController.items.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    Color backgroundColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      title: Text(
        'Notifications & Alerts',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.check_circle_outline,
            color: isDarkMode ? Colors.white : textColor,
            size: 28,
          ),
          onPressed: _markAllAsRead,
          tooltip: 'Mark all as read',
        ),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: isDarkMode ? Colors.white : textColor,
            size: 28,
          ),
          onPressed: () {
            // Navigate to notification settings
          },
          tooltip: 'Notification settings',
        ),
      ],
      bottom: _buildTabBar(isDarkMode),
    );
  }

  PreferredSizeWidget _buildTabBar(bool isDarkMode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentColor,
          labelColor: Colors.blue,
          unselectedLabelColor:
              isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          tabs: const [Tab(text: 'All'), Tab(text: 'Unread')],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // All notifications tab
        _buildNotificationsTab(_lazyController.items),
        // Unread notifications tab
        _filteredNotifications.isEmpty
            ? _buildEmptyFilteredState()
            : _buildNotificationsTab(_filteredNotifications),
      ],
    );
  }

  Widget _buildNotificationsTab(List<NotificationModel> notifications) {
    return OptimizedListView<NotificationModel>(
      items: notifications,
      onRefresh: _refreshNotifications,
      lazyController: _lazyController,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, notification, index) {
        return AnimatedNotificationCard(
          notification: notification,
          index: index,
          onDismiss: () => _deleteNotification(notification.id),
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 100,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'You don\'t have any notifications at the moment. They will appear here when available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'You have no unread notifications. Pull down to refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated notification card with staggered animation
class AnimatedNotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final int index;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const AnimatedNotificationCard({
    super.key,
    required this.notification,
    required this.index,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<AnimatedNotificationCard> createState() =>
      _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<AnimatedNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: 50 * (widget.index % 10)), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: OptimizedNotificationCard(
          notification: widget.notification,
          onDismiss: widget.onDismiss,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
