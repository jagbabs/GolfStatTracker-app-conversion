import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/screens/home_screen.dart';
import 'package:golf_stat_tracker/services/api_service.dart';
import 'package:golf_stat_tracker/services/database_manager.dart';
import 'package:golf_stat_tracker/services/golf_course_api_service.dart';
import 'package:golf_stat_tracker/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database manager
  final databaseManager = DatabaseManager();
  
  // Initialize API services
  await ApiService.initialize();
  await GolfCourseApiService.initialize();
  
  // Check if Google Sheets is already set up
  final prefs = await SharedPreferences.getInstance();
  final useGoogleSheets = prefs.getBool('use_google_sheets') ?? false;
  
  if (useGoogleSheets) {
    // Attempt to initialize with Google Sheets
    final clientId = prefs.getString('google_sheets_client_id') ?? '';
    final clientSecret = prefs.getString('google_sheets_client_secret') ?? '';
    final spreadsheetId = prefs.getString('google_sheets_spreadsheet_id') ?? '';
    
    try {
      // Try to initialize Google Sheets
      await databaseManager.initializeGoogleSheets(
        clientId: clientId,
        clientSecret: clientSecret,
        spreadsheetId: spreadsheetId,
      );
    } catch (e) {
      // If fails, fall back to default storage
      debugPrint('Failed to initialize Google Sheets: $e');
      await databaseManager.initialize();
    }
  } else {
    // Use default platform-specific storage
    await databaseManager.initialize();
  }
  
  // Get the initialized database service
  final databaseService = databaseManager.getCurrentDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseManager>.value(value: databaseManager),
        ChangeNotifierProvider(create: (_) => PlayerProvider(databaseService)),
        ChangeNotifierProvider(create: (_) => CourseProvider(databaseService)),
        ChangeNotifierProvider(create: (_) => RoundProvider(databaseService)),
      ],
      child: const GolfStatTracker(),
    ),
  );
}

class GolfStatTracker extends StatelessWidget {
  const GolfStatTracker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Stat Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Apply responsive font scaling
        return MediaQuery(
          // Set the maximum text scaling factor to prevent
          // excessively large text on mobile devices
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
