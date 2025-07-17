// screens/notifications_alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../widgets/notification_card.dart';
import '../models/notification_model.dart';

class NotificationsAlertsScreen extends StatefulWidget {
  const NotificationsAlertsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsAlertsScreen> createState() => _NotificationsAlertsScreenState();
}

class _NotificationsAlertsScreenState extends State<NotificationsAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Refresh to show filtered notifications when tab changes
      }
    });
    // Simulate loading data
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _notifications = [
        // Medication alerts
        NotificationModel(
          id: '1',
          title: 'Missed Medication',
          message: 'You missed your 10 AM medication: Paracetamol',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.missedMedication,
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          title: 'Medication Reminder',
          message: 'Time to take your evening medication: Aspirin',
          time: DateTime.now().subtract(const Duration(hours: 4)),
          type: NotificationType.medicationReminder,
          isRead: true,
        ),

        // Appointment reminders
        NotificationModel(
          id: '3',
          title: 'Upcoming Appointment',
          message: 'Doctor appointment in 3 days with Dr. Smith at City Hospital',
          time: DateTime.now().subtract(const Duration(hours: 6)),
          type: NotificationType.appointment,
          isRead: false,
        ),

        // Medicine stock/expiry
        NotificationModel(
          id: '4',
          title: 'Medicine Stock Warning',
          message: 'Your Paracetamol stock is low. Only 5 tablets remaining.',
          time: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.medicineStock,
          isRead: true,
        ),
        NotificationModel(
          id: '5',
          title: 'Medicine Expiry Warning',
          message: 'Your Insulin expires in 2 days. Please refill soon.',
          time: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
          type: NotificationType.medicineExpiry,
          isRead: false,
        ),

        // SOS alerts
        NotificationModel(
          id: '6',
          title: 'SOS Alert Sent',
          message: 'Emergency alert sent to your caregiver John Doe.',
          time: DateTime.now().subtract(const Duration(days: 2)),
          type: NotificationType.sos,
          isRead: true,
        ),

        // Additional notifications for testing
        NotificationModel(
          id: '7',
          title: 'Blood Pressure Reading',
          message: 'Your last reading was 130/85 mmHg. This is within normal range.',
          time: DateTime.now().subtract(const Duration(days: 3)),
          type: NotificationType.healthUpdate,
          isRead: true,
        ),
        NotificationModel(
          id: '8',
          title: 'App Update Available',
          message: 'A new version of MediCare is available. Please update for new features.',
          time: DateTime.now().subtract(const Duration(days: 4)),
          type: NotificationType.system,
          isRead: true,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    await _loadNotifications();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'All notifications marked as read',
          style: TextStyle(fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700] : AppColors.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notification) => notification.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Notification deleted',
          style: TextStyle(fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700] : AppColors.primaryColor,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // In a real app, you would restore the deleted notification
            _refreshNotifications();
          },
        ),
      ),
    );
  }

  List<NotificationModel> get _filteredNotifications {
    if (_tabController.index == 0) {
      // All notifications
      return _notifications;
    } else {
      // Unread notifications
      return _notifications.where((notification) => !notification.isRead).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Improved colors for better visibility in dark mode
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Notifications & Alerts',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22, // Increased text size for better readability for elderly
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
        actions: [
          // Mark all as read
          IconButton(
            icon: Icon(
              Icons.check_circle_outline,
              color: isDarkMode ? Colors.white : textColor,
              size: 28, // Larger icon size
            ),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          // Settings
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white : textColor,
              size: 28, // Larger icon size
            ),
            onPressed: () {
              // Navigate to notification settings
              // This will be implemented later
            },
            tooltip: 'Notification settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56), // Increased height for tab bar
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
              labelColor: Colors.blue, // Changed to solid blue for better visibility
              unselectedLabelColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18, // Increased font size
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.accentColor,
          strokeWidth: 3,
        ),
      )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : DefaultTabController(
        length: 2,
        child: TabBarView(
          controller: _tabController,
          // Disable horizontal swipe gestures for tab navigation to prevent conflict with swipe-to-delete
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // All notifications tab
            _buildNotificationsList(_filteredNotifications),
            // Unread notifications tab
            _filteredNotifications.isEmpty
                ? _buildEmptyFilteredState()
                : _buildNotificationsList(_filteredNotifications),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notificationsList) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: AppColors.accentColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: notificationsList.length,
        itemBuilder: (context, index) {
          final notification = notificationsList[index];
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
      ),
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
              size: 100, // Larger icon
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 24, // Larger text for elderly
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
                  fontSize: 18, // Larger text for elderly
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
              size: 100, // Larger icon
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 24, // Larger text for elderly
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
                  fontSize: 18, // Larger text for elderly
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

class AnimatedNotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final int index;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const AnimatedNotificationCard({
    Key? key,
    required this.notification,
    required this.index,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedNotificationCard> createState() => _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<AnimatedNotificationCard> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
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
        child: NotificationCard(
          notification: widget.notification,
          onDismiss: widget.onDismiss,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}