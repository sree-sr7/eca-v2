import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/settings_tile.dart';
import '../widgets/primary_button.dart';

// Settings provider to manage app-wide settings
class AppSettings extends ChangeNotifier {
  bool _darkModeEnabled = false;
  bool _highContrastMode = false;
  double _textSize = 1.0;

  // Getters
  bool get darkModeEnabled => _darkModeEnabled;
  bool get highContrastMode => _highContrastMode;
  double get textSize => _textSize;

  // Fixed themeMode to respect the setting rather than system preference
  ThemeMode get themeMode => _darkModeEnabled ? ThemeMode.dark : ThemeMode.light;

  // Initialize settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkModeEnabled = prefs.getBool('darkMode') ?? false;
    _highContrastMode = prefs.getBool('highContrast') ?? false;
    _textSize = prefs.getDouble('textSize') ?? 1.0;
    notifyListeners();
  }

  // Update dark mode setting
  void setDarkMode(bool value) async {
    _darkModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  // Update high contrast setting
  void setHighContrast(bool value) async {
    _highContrastMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', value);
    notifyListeners();
  }

  // Update text size setting
  void setTextSize(double value) async {
    _textSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textSize', value);
    notifyListeners();
  }
}

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({Key? key, required this.settings}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // Notification settings
  bool _medicationReminders = true;
  bool _appointmentReminders = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.settings.darkModeEnabled;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          "Settings",
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : AppColors.textDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
        children: [
          const SizedBox(height: 8),

          // App Preferences Section
          SettingsSection(
            title: "APP PREFERENCES",
            children: [
              SettingsSwitchTile(
                icon: Icons.dark_mode,
                title: "Dark Mode",
                subtitle: "Use dark theme for better visibility at night",
                value: widget.settings.darkModeEnabled,
                iconColor: Colors.purple,
                onChanged: (value) {
                  widget.settings.setDarkMode(value);
                },
              ),

              SettingsTile(
                icon: Icons.text_fields,
                title: "Text Size",
                subtitle: "Adjust the text size throughout the app",
                iconColor: Colors.blue,
                onTap: () {
                  _showTextSizeDialog();
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.text_decrease,
                      size: 18,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: widget.settings.textSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        activeColor: AppColors.accentColor,
                        onChanged: (value) {
                          widget.settings.setTextSize(value);
                        },
                      ),
                    ),
                    Icon(
                      Icons.text_increase,
                      size: 20,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ],
                ),
              ),

              SettingsSwitchTile(
                icon: Icons.contrast,
                title: "High Contrast Mode",
                subtitle: "Enhance visibility with higher contrast",
                value: widget.settings.highContrastMode,
                iconColor: Colors.orange,
                onChanged: (value) {
                  widget.settings.setHighContrast(value);
                },
              ),
            ],
          ),

          // Notification Settings
          SettingsSection(
            title: "NOTIFICATION SETTINGS",
            children: [
              SettingsSwitchTile(
                icon: Icons.medication,
                title: "Medication Reminders",
                subtitle: "Get notified when it's time for medication",
                value: _medicationReminders,
                iconColor: Colors.red,
                onChanged: (value) {
                  setState(() => _medicationReminders = value);
                },
              ),

              SettingsSwitchTile(
                icon: Icons.calendar_today,
                title: "Appointment Reminders",
                subtitle: "Get notified about upcoming appointments",
                value: _appointmentReminders,
                iconColor: Colors.green,
                onChanged: (value) {
                  setState(() => _appointmentReminders = value);
                },
              ),
            ],
          ),

          // Help & Support
          SettingsSection(
            title: "HELP & SUPPORT",
            children: [
              SettingsTile(
                icon: Icons.help,
                title: "FAQs / How-to Guide",
                subtitle: "Learn how to use the app",
                iconColor: Colors.blue,
                onTap: () {
                  // Navigate to FAQ page
                },
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),

              SettingsTile(
                icon: Icons.support_agent,
                title: "Contact Support",
                subtitle: "Get help with any issues",
                iconColor: Colors.purple,
                onTap: () {
                  // Show support options
                },
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout Button
          PrimaryButton(
            text: "Logout",
            icon: Icons.logout,
            bgColor: Colors.red,
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
          ),

          const SizedBox(height: 16),

          // App Version
          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to adjust text size
  void _showTextSizeDialog() {
    final isDarkMode = widget.settings.darkModeEnabled;
    showDialog(
      context: context,
      builder: (context) {
        double tempTextSize = widget.settings.textSize;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkCardColor : Colors.white,
              title: Text(
                "Adjust Text Size",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Sample Text",
                    style: TextStyle(
                      fontSize: 16 * tempTextSize,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "A",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: tempTextSize,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          activeColor: AppColors.accentColor,
                          onChanged: (value) {
                            setState(() {
                              tempTextSize = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        "A",
                        style: TextStyle(
                          fontSize: 24,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.settings.setTextSize(tempTextSize);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Apply",
                    style: TextStyle(
                      color: AppColors.accentColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    final isDarkMode = widget.settings.darkModeEnabled;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkCardColor : Colors.white,
          title: Text(
            "Logout",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // In a real app, perform logout and navigate to login screen
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}

// SettingsSection widget
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// SettingsTile widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

// SettingsSwitchTile widget
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color iconColor;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentColor,
          ),
        ],
      ),
    );
  }
}