import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/screens/home_screen.dart';
import 'package:golf_stat_tracker/services/database_service.dart';
import 'package:golf_stat_tracker/services/web_database_service.dart';
import 'package:golf_stat_tracker/utils/theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the appropriate database service based on platform
  late final dynamic databaseService;
  
  if (kIsWeb) {
    // Use web-compatible database service for web platform
    databaseService = WebDatabaseService();
  } else {
    // Use SQLite database service for native platforms
    databaseService = DatabaseService();
  }
  
  await databaseService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
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
      home: const HomeScreen(),
    );
  }
}
