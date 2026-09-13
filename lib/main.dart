import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'database/db_helper.dart';
import 'screens/initial_admin_setup_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_colors.dart';
import 'screens/settings_screen.dart';
import 'services/background_service.dart';
import 'services/notification_manager.dart';
import 'services/widget_optimization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Initialize app settings
  final appSettings = AppSettings();
  await appSettings.loadSettings();

  // Initialize notification services
  final notificationManager = NotificationManager();
  await notificationManager.initialize();

  // Initialize background service for notifications
  final backgroundService = BackgroundReminderService();
  await backgroundService.initialize();

  // Initialize widget optimization service for high refresh rate support
  final widgetOptimizationService = WidgetOptimizationService();
  await widgetOptimizationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        Provider.value(value: notificationManager),
        Provider.value(value: widgetOptimizationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      title: 'Health Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCardColor,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.accentColor,
        ),
        textTheme: getAdjustedTextTheme(ThemeData.light().textTheme, settings),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardColor,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        dialogTheme: DialogThemeData(backgroundColor: AppColors.darkCardColor),
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryColor,
          secondary: AppColors.accentColor,
        ),
        textTheme: getAdjustedTextTheme(ThemeData.dark().textTheme, settings),
      ),
      themeMode: settings.themeMode,
      builder: (context, child) {
        return MediaQuery(
          // Apply the text scaling factor to the entire app
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settings.textSize)),
          child: child!,
        );
      },
      home: const StartupGate(),
    );
  }

  // Helper method to adjust text theme based on settings
  TextTheme getAdjustedTextTheme(TextTheme base, AppSettings settings) {
    // Apply high contrast if enabled
    if (settings.highContrastMode) {
      return base.copyWith(
        bodyLarge: base.bodyLarge?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: base.bodySmall?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.titleSmall?.copyWith(
          color: settings.darkModeEnabled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return base;
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final DBHelper _dbHelper = DBHelper();
  late Future<bool> _adminExists;

  @override
  void initState() {
    super.initState();
    _adminExists = _checkForAdmin();
  }

  Future<bool> _checkForAdmin() => _dbHelper.hasAdminUser();

  void _retry() {
    setState(() {
      _adminExists = _checkForAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminExists,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to initialize the local database.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return snapshot.data == true
            ? const LoginScreen()
            : const InitialAdminSetupScreen();
      },
    );
  }
}
