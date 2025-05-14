import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/golf_course_api.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/services/api_service.dart';

class GolfCourseApiService {
  // Initialize the service
  static Future<void> initialize() async {
    await ApiService.initialize();
  }
  
  // Check if API is configured
  static bool get isApiConfigured => ApiService.isGolfCourseApiConfigured;
  
  // Set API key
  static Future<void> setApiKey(String apiKey) async {
    await ApiService.setGolfCourseApiKey(apiKey);
  }
  
  // Request API key from user if not configured
  static void requestApiKey(Function(String) onApiKeyEntered) {
    // This would typically show a dialog to request the API key
    // For now, we'll just pass this through to the caller
    onApiKeyEntered('');
  }
  
  // Search for golf courses by name
  static Future<SearchResult> searchGolfCourses(String query) async {
    try {
      final response = await ApiService.searchGolfCourses(query);
      
      // Check if API key is missing
      if (response['missingApiKey'] == true) {
        return SearchResult(
          courses: [],
          missingApiKey: true,
        );
      }
      
      return SearchResult.fromJson(response);
    } catch (e) {
      debugPrint('Error searching for golf courses: $e');
      return SearchResult.empty();
    }
  }
  
  // Get detailed information about a specific golf course
  static Future<GolfCourse> getGolfCourseById(int id) async {
    try {
      debugPrint('Fetching detailed info for course ID: $id');
      final response = await ApiService.getGolfCourseById(id);
      
      // Check if API key is missing
      if (response['missingApiKey'] == true) {
        throw Exception('Golf Course API key not configured');
      }
      
      debugPrint('Retrieved data for ${response['club_name'] ?? 'Unknown Course'}');
      debugPrint('Course has tee boxes: ${response['tees'] != null}');
      
      return GolfCourse.fromJson(response);
    } catch (e) {
      debugPrint('Error getting golf course details: $e');
      throw Exception('Could not load course details: $e');
    }
  }
  
  // Get a list of tee boxes available for a course
  static List<FormattedTeeBox> getFormattedTeeBoxes(GolfCourse course) {
    final List<FormattedTeeBox> teeBoxes = [];
    
    debugPrint('Formatting tee boxes for course: ${course.clubName}');
    debugPrint('Raw tees data: ${jsonEncode(course.tees)}');
    
    try {
      // Add male tee boxes
      if (course.tees.male.isNotEmpty) {
        debugPrint('Found ${course.tees.male.length} men\'s tee boxes');
        for (int i = 0; i < course.tees.male.length; i++) {
          final tee = course.tees.male[i];
          
          teeBoxes.add(
            FormattedTeeBox(
              label: '${tee.teeName} (Men)',
              value: 'male-${tee.teeName}',
              data: tee,
            ),
          );
        }
      } else {
        debugPrint('No men\'s tee boxes found or data is malformed');
      }
      
      // Add female tee boxes
      if (course.tees.female.isNotEmpty) {
        debugPrint('Found ${course.tees.female.length} women\'s tee boxes');
        for (int i = 0; i < course.tees.female.length; i++) {
          final tee = course.tees.female[i];
          
          teeBoxes.add(
            FormattedTeeBox(
              label: '${tee.teeName} (Women)',
              value: 'female-${tee.teeName}',
              data: tee,
            ),
          );
        }
      } else {
        debugPrint('No women\'s tee boxes found or data is malformed');
      }
      
      // If no tee boxes were found, create a default one
      if (teeBoxes.isEmpty && course.holes.isNotEmpty) {
        debugPrint('No tee boxes found, creating a default tee box from hole data');
        
        // Calculate par total and total yards
        int parTotal = 0;
        int totalYards = 0;
        for (final hole in course.holes) {
          parTotal += hole.par;
          totalYards += hole.yardage;
        }
        
        // Create a default tee box using the course holes
        final defaultTeeBox = TeeBox(
          teeName: 'Default',
          teeColor: 'White',
          teeGender: 'male',
          parTotal: parTotal,
          totalYards: totalYards,
          courseRating: 72.0,
          slopeRating: 113,
          numberOfHoles: course.holes.length,
          holes: course.holes,
        );
        
        teeBoxes.add(
          FormattedTeeBox(
            label: 'Default Tees (Men)',
            value: 'male-Default',
            data: defaultTeeBox,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error formatting tee boxes: $e');
    }
    
    debugPrint('Returning ${teeBoxes.length} formatted tee boxes');
    return teeBoxes;
  }
  
  // Convert API course and tee box data to local course data format
  static Course convertToLocalCourse(GolfCourse apiCourse, TeeBox selectedTeeBox) {
    final holePars = selectedTeeBox.holes != null && selectedTeeBox.holes!.isNotEmpty 
        ? selectedTeeBox.holes!.map((h) => HolePar(
            holeNumber: h.holeNumber,
            par: h.par,
            distance: h.yardage,
            handicap: h.handicap ?? h.holeNumber,
          )).toList()
        : List.generate(
            selectedTeeBox.numberOfHoles,
            (i) => HolePar(
              holeNumber: i + 1,
              par: 4, // Default par 4
              distance: 300, // Default distance
              handicap: i + 1,
            ),
          );
    
    return Course(
      id: apiCourse.id.toString(),
      name: '${apiCourse.clubName} - ${apiCourse.courseName}',
      location: apiCourse.location.city != null && apiCourse.location.state != null
          ? '${apiCourse.location.city}, ${apiCourse.location.state}'
          : 'Unknown Location',
      imageUrl: null, // Image URL not provided by API
      holePars: holePars,
      par: selectedTeeBox.parTotal,
      holeCount: selectedTeeBox.numberOfHoles,
    );
  }
  
  // Format hole details for use in the application's Round model
  static List<HoleScore> formatHoleDetails(List<Hole> holes, String roundId) {
    return holes.map((hole) => HoleScore(
      holeNumber: hole.holeNumber,
      par: hole.par,
      strokes: 0,
      putts: 0,
      fairwayHit: FairwayHit.unknown,
      greenInRegulation: GreenInRegulation.unknown,
      penalties: 0,
    )).toList();
  }
}