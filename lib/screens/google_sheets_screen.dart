import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/services/database_manager.dart';
import 'package:golf_stat_tracker/services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';

class GoogleSheetsScreen extends StatefulWidget {
  const GoogleSheetsScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSheetsScreen> createState() => _GoogleSheetsScreenState();
}

class _GoogleSheetsScreenState extends State<GoogleSheetsScreen> {
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _spreadsheetIdController = TextEditingController();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  StorageType _currentStorageType = StorageType.sqlite;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _spreadsheetIdController.dispose();
    super.dispose();
  }
  
  /// Load saved Google Sheets settings
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final clientId = prefs.getString('google_sheets_client_id') ?? '';
      final clientSecret = prefs.getString('google_sheets_client_secret') ?? '';
      final spreadsheetId = prefs.getString('google_sheets_spreadsheet_id') ?? '';
      
      setState(() {
        _clientIdController.text = clientId;
        _clientSecretController.text = clientSecret;
        _spreadsheetIdController.text = spreadsheetId;
      });
      
      final dbManager = DatabaseManager();
      
      setState(() {
        _currentStorageType = dbManager.storageType;
        _isAuthenticated = dbManager.isGoogleAuthenticated();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Save Google Sheets settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('google_sheets_client_id', _clientIdController.text);
    await prefs.setString('google_sheets_client_secret', _clientSecretController.text);
    await prefs.setString('google_sheets_spreadsheet_id', _spreadsheetIdController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }
  
  /// Authenticate with Google
  Future<void> _authenticate() async {
    if (_clientIdController.text.isEmpty || _clientSecretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client ID and client secret')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbManager = DatabaseManager();
      
      // Initialize Google Auth Service
      final authService = dbManager.getGoogleAuthService() ?? GoogleAuthService();
      await authService.initialize(
        clientId: _clientIdController.text,
        clientSecret: _clientSecretController.text,
      );
      
      // Try to authenticate
      final success = await authService.authenticate(context);
      
      setState(() {
        _isAuthenticated = success;
      });
      
      if (success) {
        // Save settings
        await _saveSettings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully authenticated with Google')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to authenticate with Google')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error authenticating: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Initialize Google Sheets as storage
  Future<void> _initializeGoogleSheets() async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please authenticate with Google first')),
      );
      return;
    }
    
    if (_spreadsheetIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a spreadsheet ID')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbManager = DatabaseManager();
      
      final success = await dbManager.initializeGoogleSheets(
        clientId: _clientIdController.text,
        clientSecret: _clientSecretController.text,
        spreadsheetId: _spreadsheetIdController.text,
      );
      
      if (success) {
        setState(() {
          _currentStorageType = StorageType.googleSheets;
        });
        
        // Save settings
        await _saveSettings();
        
        // Reload providers
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        final roundProvider = Provider.of<RoundProvider>(context, listen: false);
        
        // Update providers with new database service
        playerProvider.updateDatabaseService(dbManager.getCurrentDatabase());
        courseProvider.updateDatabaseService(dbManager.getCurrentDatabase());
        roundProvider.updateDatabaseService(dbManager.getCurrentDatabase());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sheets successfully initialized as storage')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize Google Sheets')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing Google Sheets: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Reset to local storage
  Future<void> _resetToLocalStorage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dbManager = DatabaseManager();
      
      // Set storage type back to platform default
      final newStorageType = kIsWeb ? StorageType.webLocal : StorageType.sqlite;
      await dbManager.setStorageType(newStorageType);
      
      setState(() {
        _currentStorageType = newStorageType;
      });
      
      // Reload providers
      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final roundProvider = Provider.of<RoundProvider>(context, listen: false);
      
      // Update providers with new database service
      playerProvider.updateDatabaseService(dbManager.getCurrentDatabase());
      courseProvider.updateDatabaseService(dbManager.getCurrentDatabase());
      roundProvider.updateDatabaseService(dbManager.getCurrentDatabase());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to local storage successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting storage: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Integration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Storage Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Storage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Using: ${_getStorageTypeLabel(_currentStorageType)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Google Authentication: ${_isAuthenticated ? 'Authenticated' : 'Not Authenticated'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isAuthenticated ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Google API Credentials
                  const Text(
                    'Google API Credentials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _clientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Client ID',
                      border: OutlineInputBorder(),
                      helperText: 'Enter your Google API Client ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientSecretController,
                    decoration: const InputDecoration(
                      labelText: 'Client Secret',
                      border: OutlineInputBorder(),
                      helperText: 'Enter your Google API Client Secret',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Authenticate with Google'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Google Sheets Configuration
                  const Text(
                    'Google Sheets Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _spreadsheetIdController,
                    decoration: const InputDecoration(
                      labelText: 'Spreadsheet ID',
                      border: OutlineInputBorder(),
                      helperText: 'Enter the ID of your Google Sheet',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The spreadsheet ID is the value in the URL between "/d/" and "/edit". '
                    'For example, in "https://docs.google.com/spreadsheets/d/abc123xyz/edit", '
                    'the ID is "abc123xyz".',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isAuthenticated ? _initializeGoogleSheets : null,
                    child: const Text('Use Google Sheets as Database'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reset Button
                  if (_currentStorageType == StorageType.googleSheets)
                    ElevatedButton.icon(
                      onPressed: _resetToLocalStorage,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Local Storage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Help Section
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to Set Up Google Sheets Integration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Create a project in the Google Cloud Console\n'
                            '2. Enable the Google Sheets API\n'
                            '3. Create OAuth credentials (Web application type)\n'
                            '4. Add http://localhost:8080/oauth2callback as an authorized redirect URI\n'
                            '5. Create a new Google Sheet and copy its ID from the URL\n'
                            '6. Enter your credentials and spreadsheet ID above\n'
                            '7. Click "Authenticate with Google" and follow the instructions\n'
                            '8. After authentication, click "Use Google Sheets as Database"',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  /// Get a human-readable label for storage type
  String _getStorageTypeLabel(StorageType type) {
    switch (type) {
      case StorageType.sqlite:
        return 'Local Database (SQLite)';
      case StorageType.webLocal:
        return 'Web Storage (Local)';
      case StorageType.googleSheets:
        return 'Google Sheets (Cloud)';
    }
  }
}