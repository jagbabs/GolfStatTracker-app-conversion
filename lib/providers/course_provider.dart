import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/services/database_service.dart';
import 'package:golf_stat_tracker/services/web_database_service.dart';
import 'package:golf_stat_tracker/services/google_sheets_service.dart';
import 'package:golf_stat_tracker/utils/constants.dart';
import 'package:uuid/uuid.dart';

class CourseProvider with ChangeNotifier {
  dynamic _databaseService; // Can be DatabaseService, WebDatabaseService, or GoogleSheetsService
  List<Course> _courses = [];
  Course? _selectedCourse;
  
  // Method to update the database service when storage type changes
  void updateDatabaseService(dynamic newService) {
    _databaseService = newService;
    _loadCourses();
  }
  
  CourseProvider(this._databaseService) {
    _loadCourses();
  }
  
  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  
  Future<void> _loadCourses() async {
    try {
      _courses = await _databaseService.getCourses();
      if (_courses.isNotEmpty && _selectedCourse == null) {
        _selectedCourse = _courses.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }
  
  Future<void> addCourse(String name, String location, int par, int holeCount, String imageUrl) async {
    try {
      final uuid = const Uuid();
      
      // Generate default hole pars based on total par
      final holePars = _generateDefaultHolePars(holeCount, par);
      
      final newCourse = Course(
        id: uuid.v4(),
        name: name,
        location: location,
        par: par,
        holeCount: holeCount,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : Constants.courseImageUrls[0],
        holePars: holePars,
      );
      
      await _databaseService.saveCourse(newCourse);
      _courses.add(newCourse);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding course: $e');
    }
  }
  
  List<HolePar> _generateDefaultHolePars(int holeCount, int totalPar) {
    // This is a simplistic algorithm to distribute pars
    // Par 4s are most common, followed by par 3s and par 5s
    
    // Start with all par 4s
    List<HolePar> holePars = List.generate(
      holeCount,
      (index) => HolePar(
        holeNumber: index + 1,
        par: 4,
        distance: 350 + (index * 15),
        handicap: index + 1,
      ),
    );
    
    // Calculate total par so far
    int currentTotalPar = holePars.fold(0, (sum, hole) => sum + hole.par);
    
    // If we need to add more par (for a higher total par)
    if (currentTotalPar < totalPar) {
      int parToAdd = totalPar - currentTotalPar;
      
      // Add some par 5s (evenly distributed)
      for (int i = 0; i < parToAdd; i++) {
        if (i >= holeCount) break;
        
        // Choose positions for par 5s (towards the middle of each nine)
        int position = (i % 2 == 0) ? 4 : 13;
        if (position < holeCount) {
          holePars[position] = holePars[position].copyWith(
            par: 5,
            distance: 510 + (position * 15),
          );
        }
      }
    }
    
    // If we need to reduce par (for a lower total par)
    else if (currentTotalPar > totalPar) {
      int parToRemove = currentTotalPar - totalPar;
      
      // Add some par 3s (evenly distributed)
      for (int i = 0; i < parToRemove; i++) {
        if (i >= holeCount) break;
        
        // Choose positions for par 3s (2nd and 5th holes of each nine typically)
        int position = (i % 4 == 0) ? 1 : (i % 4 == 1) ? 6 : (i % 4 == 2) ? 10 : 15;
        if (position < holeCount) {
          holePars[position] = holePars[position].copyWith(
            par: 3,
            distance: 170 + (position * 5),
          );
        }
      }
    }
    
    // Recalculate total par to ensure it matches
    currentTotalPar = holePars.fold(0, (sum, hole) => sum + hole.par);
    
    // Final adjustment if needed
    if (currentTotalPar < totalPar) {
      // Add one more par 5 if needed
      for (int i = 0; i < holeCount; i++) {
        if (holePars[i].par == 4) {
          holePars[i] = holePars[i].copyWith(
            par: 5,
            distance: 510 + (i * 15),
          );
          break;
        }
      }
    } else if (currentTotalPar > totalPar) {
      // Add one more par 3 if needed
      for (int i = 0; i < holeCount; i++) {
        if (holePars[i].par == 4) {
          holePars[i] = holePars[i].copyWith(
            par: 3,
            distance: 170 + (i * 5),
          );
          break;
        }
      }
    }
    
    return holePars;
  }
  
  Future<void> updateCourse(Course course) async {
    try {
      await _databaseService.saveCourse(course);
      
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = course;
      }
      
      if (_selectedCourse?.id == course.id) {
        _selectedCourse = course;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating course: $e');
    }
  }
  
  Future<void> deleteCourse(String id) async {
    try {
      await _databaseService.deleteCourse(id);
      
      _courses.removeWhere((c) => c.id == id);
      
      if (_selectedCourse?.id == id) {
        _selectedCourse = _courses.isNotEmpty ? _courses.first : null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting course: $e');
    }
  }
  
  void selectCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }
  
  Future<void> updateHolePar(String courseId, int holeNumber, int par, int distance, int handicap) async {
    try {
      final course = _courses.firstWhere((c) => c.id == courseId);
      
      final updatedHolePars = List<HolePar>.from(course.holePars);
      final index = updatedHolePars.indexWhere((h) => h.holeNumber == holeNumber);
      
      if (index != -1) {
        updatedHolePars[index] = updatedHolePars[index].copyWith(
          par: par,
          distance: distance,
          handicap: handicap,
        );
      } else {
        updatedHolePars.add(HolePar(
          holeNumber: holeNumber,
          par: par,
          distance: distance,
          handicap: handicap,
        ));
        
        // Sort by hole number
        updatedHolePars.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
      }
      
      // Update total par
      final totalPar = updatedHolePars.fold<int>(0, (sum, hole) => sum + hole.par);
      
      final updatedCourse = course.copyWith(
        holePars: updatedHolePars,
        par: totalPar,
      );
      
      await updateCourse(updatedCourse);
    } catch (e) {
      debugPrint('Error updating hole par: $e');
    }
  }
}
