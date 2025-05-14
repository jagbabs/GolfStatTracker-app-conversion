import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A service that handles Google OAuth authentication
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  
  // OAuth configuration
  String _clientId = '';
  String _clientSecret = '';
  final String _redirectUri = 'http://localhost:8080/oauth2callback';
  
  // Token storage
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiryTime;
  
  // Auth state
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  
  factory GoogleAuthService() {
    return _instance;
  }
  
  GoogleAuthService._internal();
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  String? get accessToken => _accessToken;
  
  /// Initialize the Google Auth Service with client credentials
  Future<void> initialize({
    required String clientId,
    required String clientSecret,
  }) async {
    _clientId = clientId;
    _clientSecret = clientSecret;
    
    // Try to load saved tokens
    await _loadTokens();
    
    // Check if we need to refresh token
    if (_accessToken != null && _expiryTime != null) {
      if (_expiryTime!.isBefore(DateTime.now())) {
        if (_refreshToken != null) {
          await _refreshAccessToken();
        } else {
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = true;
      }
    } else {
      _isAuthenticated = false;
    }
    
    debugPrint('Google Auth Service initialized. Authenticated: $_isAuthenticated');
  }
  
  /// Start the OAuth authentication flow
  Future<bool> authenticate(BuildContext context) async {
    if (_isAuthenticating) return false;
    
    _isAuthenticating = true;
    
    try {
      // Create OAuth request URL
      final String authUrl = 'https://accounts.google.com/o/oauth2/auth?'
          'client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
          '&response_type=code'
          '&scope=${Uri.encodeComponent("https://www.googleapis.com/auth/spreadsheets")}'
          '&access_type=offline'
          '&prompt=consent';
      
      // Launch URL in browser
      final Uri uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show dialog to get the auth code
        final String? authCode = await _showAuthCodeDialog(context);
        
        if (authCode != null && authCode.isNotEmpty) {
          // Exchange auth code for tokens
          final result = await _exchangeAuthCode(authCode);
          _isAuthenticated = result;
          return result;
        }
      } else {
        debugPrint('Could not launch URL: $authUrl');
        return false;
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
    
    return false;
  }
  
  /// Show a dialog to get the authorization code from the user
  Future<String?> _showAuthCodeDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String authCode = '';
        
        return AlertDialog(
          title: const Text('Enter Authorization Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'After signing in with Google, you will receive an authorization code. '
                'Please copy and paste it here:',
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  authCode = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Paste authorization code here',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(authCode);
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Exchange the auth code for access and refresh tokens
  Future<bool> _exchangeAuthCode(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'code': authCode,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
      );
      
      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        _accessToken = tokenData['access_token'];
        _refreshToken = tokenData['refresh_token'];
        
        // Calculate expiry time
        final expiresIn = tokenData['expires_in'] as int;
        _expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
        
        // Save tokens
        await _saveTokens();
        
        return true;
      } else {
        debugPrint('Error exchanging auth code: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error exchanging auth code: $e');
      return false;
    }
  }
  
  /// Refresh the access token using the refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      
      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        _accessToken = tokenData['access_token'];
        
        // Calculate expiry time
        final expiresIn = tokenData['expires_in'] as int;
        _expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
        
        // Save tokens
        await _saveTokens();
        
        _isAuthenticated = true;
        return true;
      } else {
        debugPrint('Error refreshing token: ${response.body}');
        _isAuthenticated = false;
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      _isAuthenticated = false;
      return false;
    }
  }
  
  /// Save tokens to shared preferences
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_accessToken != null) {
      await prefs.setString('google_access_token', _accessToken!);
    }
    
    if (_refreshToken != null) {
      await prefs.setString('google_refresh_token', _refreshToken!);
    }
    
    if (_expiryTime != null) {
      await prefs.setString('google_token_expiry', _expiryTime!.toIso8601String());
    }
  }
  
  /// Load tokens from shared preferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    _accessToken = prefs.getString('google_access_token');
    _refreshToken = prefs.getString('google_refresh_token');
    
    final expiryString = prefs.getString('google_token_expiry');
    if (expiryString != null) {
      _expiryTime = DateTime.tryParse(expiryString);
    }
  }
  
  /// Sign out and clear tokens
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('google_access_token');
    await prefs.remove('google_refresh_token');
    await prefs.remove('google_token_expiry');
    
    _accessToken = null;
    _refreshToken = null;
    _expiryTime = null;
    _isAuthenticated = false;
  }
  
  /// Get credentials JSON for the GSheets library
  String getCredentialsJson() {
    return json.encode({
      'type': 'authorized_user',
      'client_id': _clientId,
      'client_secret': _clientSecret,
      'refresh_token': _refreshToken,
    });
  }
}