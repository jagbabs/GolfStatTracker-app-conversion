class Constants {
  // App Info
  static const String appName = 'Golf Stat Tracker';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'golf_stat_tracker.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String coursesTable = 'courses';
  static const String holesTable = 'holes';
  static const String playersTable = 'players';
  static const String roundsTable = 'rounds';
  static const String scoresTable = 'scores';
  
  // Default Values
  static const int defaultHoleCount = 18;
  static const int defaultPar = 72;
  
  // Navigation 
  static const String homeRoute = '/';
  static const String roundEntryRoute = '/round_entry';
  static const String roundHistoryRoute = '/round_history';
  static const String courseManagementRoute = '/course_management';
  static const String playerProfileRoute = '/player_profile';
  static const String statisticsRoute = '/statistics';
  
  // Image URLs - Using the provided stock photos
  static const List<String> courseImageUrls = [
    'https://pixabay.com/get/gf2c376ff1fe20e74f4e50a7bf73226fa7d16b71903a5dd2108c2f50eed6c7e4307a62f16131e757b4606e3d44be669f4dbb58813bb255040ebb20459c18ed599_1280.jpg',
    'https://pixabay.com/get/gb21bcbe55dba3cad722c0d34b10dfcba1e0d9035ae09b5cc5540b805a956b32803bb7a9daeb92c3785a1d480e26505da81a77bab33a86b689ced94dca428de62_1280.jpg',
    'https://pixabay.com/get/g4389c38e0a0d5dd91b2251c9bec944364dac8a941c16b328b784297a0ba0e4999ba94e6ad0f37d9be5a739d970485d245e0dfa4eceddaa25ad2b70b67f872970_1280.jpg',
    'https://pixabay.com/get/gb6073eeafc66dba110f9c6a5550be9222c748ff4bacb829be10856947f02b3354fbdce260525ad6374f650b563d04dcbbdf57e74c69cedcac7478d60e64dc0a9_1280.jpg'
  ];
  
  static const List<String> scorecardImageUrls = [
    'https://pixabay.com/get/g483f27aaa39325a66ef93b441540431f4a1e1e5ad3904fc10fa37478a4438a676b3f176c72a535a470c685053f7ce4b471722b404761e536eea03bc1ec10184a_1280.jpg',
    'https://pixabay.com/get/g0b9a7e7098437922d1edd0c6fbc82a83c219296d4f526440bed1fd19698ceb5ef52001d42f2648e4eeb72dc8726b79f1af40b672009414d10c96cfbd1a91186a_1280.jpg'
  ];
  
  // Error Messages
  static const String errorLoadingData = 'Error loading data. Please try again.';
  static const String errorSavingData = 'Error saving data. Please try again.';
  static const String errorDeletingData = 'Error deleting data. Please try again.';
  
  // Shared Preferences Keys
  static const String prefPlayerKey = 'current_player';
  static const String prefThemeKey = 'app_theme';
  static const String prefFirstRunKey = 'first_run';
}
