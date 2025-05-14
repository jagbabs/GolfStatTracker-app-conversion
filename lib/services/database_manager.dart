import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/services/database_service.dart';
import 'package:golf_stat_tracker/services/web_database_service.dart';
import 'package:golf_stat_tracker/services/google_sheets_service.dart';
import 'package:golf_stat_tracker/services/google_auth_service.dart';

/// Storage provider type enum
enum StorageType {
  sqlite,     // Native SQLite database for mobile
  webLocal,   // SharedPreferences for web
  googleSheets // Google Sheets for cross-platform cloud storage
}

/// A service that manages different database backends
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  
  // Database instances
  DatabaseService? _sqliteService;
  WebDatabaseService? _webService;
  GoogleSheetsService? _sheetsService;
  GoogleAuthService? _authService;
  
  // Current storage type
  StorageType _storageType = kIsWeb ? StorageType.webLocal : StorageType.sqlite;
  bool _isInitialized = false;
  
  factory DatabaseManager() {
    return _instance;
  }
  
  DatabaseManager._internal();
  
  // Getters
  StorageType get storageType => _storageType;
  bool get isInitialized => _isInitialized;
  bool get usingGoogleSheets => _storageType == StorageType.googleSheets;
  
  /// Initialize the database manager and set up the preferred storage type
  Future<void> initialize({StorageType? preferredStorageType}) async {
    // Set storage type based on preference, defaulting to platform-specific
    _storageType = preferredStorageType ?? (kIsWeb ? StorageType.webLocal : StorageType.sqlite);
    
    // Initialize appropriate service
    await _initializeStorage();
    
    _isInitialized = true;
    debugPrint('Database Manager initialized with storage type: $_storageType');
  }
  
  /// Change the storage type
  Future<void> setStorageType(StorageType type) async {
    if (_storageType == type) return;
    
    _storageType = type;
    await _initializeStorage();
    
    debugPrint('Changed storage type to: $type');
  }
  
  /// Initialize the appropriate storage service
  Future<void> _initializeStorage() async {
    switch (_storageType) {
      case StorageType.sqlite:
        _sqliteService ??= DatabaseService();
        await _sqliteService!.initialize();
        break;
        
      case StorageType.webLocal:
        _webService ??= WebDatabaseService();
        await _webService!.initialize();
        break;
        
      case StorageType.googleSheets:
        _sheetsService ??= GoogleSheetsService();
        _authService ??= GoogleAuthService();
        // Google Sheets requires authentication before it can be initialized
        // This will be handled separately in the Google Sheets setup screen
        break;
    }
  }
  
  /// Initialize Google Sheets service with credentials and spreadsheet ID
  Future<bool> initializeGoogleSheets({
    required String clientId,
    required String clientSecret,
    required String spreadsheetId,
  }) async {
    try {
      _authService ??= GoogleAuthService();
      await _authService!.initialize(
        clientId: clientId,
        clientSecret: clientSecret,
      );
      
      _sheetsService ??= GoogleSheetsService();
      
      // If we're authenticated, initialize the sheets service
      if (_authService!.isAuthenticated) {
        final credentials = _authService!.getCredentialsJson();
        await _sheetsService!.initialize(
          credentials: credentials,
          spreadsheetId: spreadsheetId,
        );
        
        // Set storage type to Google Sheets
        _storageType = StorageType.googleSheets;
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error initializing Google Sheets: $e');
      return false;
    }
  }
  
  /// Get the current database service based on storage type
  dynamic getCurrentDatabase() {
    switch (_storageType) {
      case StorageType.sqlite:
        return _sqliteService;
      case StorageType.webLocal:
        return _webService;
      case StorageType.googleSheets:
        return _sheetsService;
    }
  }
  
  // Google Auth helpers
  
  /// Check if Google auth is initialized
  bool isGoogleAuthInitialized() {
    return _authService != null;
  }
  
  /// Check if user is authenticated with Google
  bool isGoogleAuthenticated() {
    return _authService?.isAuthenticated ?? false;
  }
  
  /// Get Google Auth Service
  GoogleAuthService? getGoogleAuthService() {
    return _authService;
  }
}