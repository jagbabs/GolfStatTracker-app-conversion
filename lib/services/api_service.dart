import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A service that handles direct API calls to external services
/// Simulating the server-side API routes in the original application
class ApiService {
  // Base URLs for external APIs
  static const String _golfCourseApiUrl = 'https://api.golfcourseapi.com/v1';
  
  // API keys (stored securely)
  static String? _golfCourseApiKey;
  
  // Check if API keys are set
  static bool get isGolfCourseApiConfigured => _golfCourseApiKey != null && _golfCourseApiKey!.isNotEmpty;
  
  // Initialize the API service by loading API keys from secure storage
  static Future<void> initialize() async {
    await _loadApiKeys();
  }
  
  // Load API keys from secure storage
  static Future<void> _loadApiKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _golfCourseApiKey = prefs.getString('golf_course_api_key');
      
      debugPrint('Golf Course API configured: ${isGolfCourseApiConfigured}');
    } catch (e) {
      debugPrint('Error loading API keys: $e');
    }
  }
  
  // Save the Golf Course API key
  static Future<void> setGolfCourseApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('golf_course_api_key', apiKey);
      _golfCourseApiKey = apiKey;
      
      debugPrint('Golf Course API key saved successfully');
    } catch (e) {
      debugPrint('Error saving API key: $e');
      rethrow;
    }
  }
  
  // Get headers for Golf Course API requests
  static Map<String, String> _getGolfApiHeaders() {
    return {
      'Authorization': 'Key $_golfCourseApiKey',
      'Content-Type': 'application/json',
    };
  }
  
  // Search for golf courses - simulating the /api/golf-api/search route
  static Future<Map<String, dynamic>> searchGolfCourses(String query) async {
    try {
      if (!isGolfCourseApiConfigured) {
        return _handleApiKeyMissing('Golf Course API key not configured');
      }
      
      debugPrint('Searching golf courses with query: $query');
      final apiUrl = '$_golfCourseApiUrl/search?search_query=${Uri.encodeComponent(query)}';
      debugPrint('API request URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: _getGolfApiHeaders(),
      );
      
      if (response.statusCode != 200) {
        debugPrint('API responded with status: ${response.statusCode}');
        debugPrint('Error text: ${response.body}');
        
        return {
          'message': 'Golf course search failed: ${response.reasonPhrase}',
          'courses': [],
        };
      }
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error searching for golf courses: $e');
      
      return {
        'message': 'Error searching for golf courses: $e',
        'courses': [],
      };
    }
  }
  
  // Get golf course details - simulating the /api/golf-api/courses/:id route
  static Future<Map<String, dynamic>> getGolfCourseById(int courseId) async {
    try {
      if (!isGolfCourseApiConfigured) {
        return _handleApiKeyMissing('Golf Course API key not configured');
      }
      
      debugPrint('Fetching golf course with ID: $courseId');
      final response = await http.get(
        Uri.parse('$_golfCourseApiUrl/courses/$courseId'),
        headers: _getGolfApiHeaders(),
      );
      
      if (response.statusCode != 200) {
        debugPrint('API responded with status: ${response.statusCode}');
        debugPrint('Error text: ${response.body}');
        
        return {
          'message': 'Failed to get golf course details: ${response.reasonPhrase}',
        };
      }
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error getting golf course details: $e');
      
      return {
        'message': 'Error getting golf course details: $e',
      };
    }
  }
  
  // Handle missing API key error
  static Map<String, dynamic> _handleApiKeyMissing(String message) {
    debugPrint('API key missing: $message');
    return {
      'message': message,
      'courses': [],
      'missingApiKey': true,
    };
  }
}