import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'utils/app_colors.dart';
import 'screens/settings_screen.dart';
import 'services/background_service.dart';
import 'services/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize app settings
  final appSettings = AppSettings();
  await appSettings.loadSettings();

  // Initialize notification services
  final notificationManager = NotificationManager();
  await notificationManager.initialize();

  // Initialize background service for notifications
  final backgroundService = BackgroundService();
  await backgroundService.initializeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        Provider.value(value: notificationManager),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        dialogBackgroundColor: Colors.white,
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
        dialogBackgroundColor: AppColors.darkCardColor,
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
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.textSize,
          ),
          child: child!,
        );
      },
      home: const LoginScreen(),
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