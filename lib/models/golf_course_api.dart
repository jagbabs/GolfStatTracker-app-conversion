// Golf Course API models
// Based on the original web application's types/golfCourseApi.ts

import 'package:flutter/foundation.dart';

class GolfCourse {
  final int id;
  final String clubName;
  final String courseName;
  final Location location;
  final List<Hole> holes;
  final TeeBoxes tees;

  GolfCourse({
    required this.id,
    required this.clubName,
    required this.courseName,
    required this.location,
    required this.holes,
    required this.tees,
  });

  factory GolfCourse.fromJson(Map<String, dynamic> json) {
    // Safely convert id to int, handling null or non-int values
    int id = 0;
    try {
      if (json['id'] != null) {
        if (json['id'] is int) {
          id = json['id'];
        } else if (json['id'] is String) {
          id = int.tryParse(json['id']) ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error parsing course id: $e');
    }
    
    return GolfCourse(
      id: id,
      clubName: json['club_name'] ?? 'Unknown Club',
      courseName: json['course_name'] ?? 'Main Course',
      location: Location.fromJson(json['location'] ?? {}),
      holes: _parseHoles(json),
      tees: TeeBoxes.fromJson(json['tees'] ?? {'male': [], 'female': []}),
    );
  }
  
  // Helper method to safely parse holes
  static List<Hole> _parseHoles(Map<String, dynamic> json) {
    try {
      if (json['holes'] is List) {
        return (json['holes'] as List)
            .map((h) => Hole.fromJson(h is Map<String, dynamic> ? h : {}))
            .toList();
      }
    } catch (e) {
      debugPrint('Error parsing holes: $e');
    }
    return [];
  }

  factory GolfCourse.empty() {
    return GolfCourse(
      id: 0,
      clubName: '',
      courseName: '',
      location: Location(city: '', state: '', country: ''),
      holes: [],
      tees: TeeBoxes(male: [], female: []),
    );
  }
}

class SearchResult {
  final List<GolfCourse> courses;
  final bool missingApiKey;

  SearchResult({
    required this.courses,
    this.missingApiKey = false,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    List<GolfCourse> courses = [];
    
    try {
      // Check if courses field exists and is a list
      if (json['courses'] != null && json['courses'] is List) {
        courses = (json['courses'] as List)
            .map((c) {
              try {
                // Filter out any items that are not maps
                if (c is Map<String, dynamic>) {
                  return GolfCourse.fromJson(c);
                } else {
                  debugPrint('Skipping invalid course entry: $c');
                  return null;
                }
              } catch (e) {
                debugPrint('Error parsing course in search results: $e');
                return null;
              }
            })
            .where((c) => c != null) // Remove null entries
            .cast<GolfCourse>() // Cast remaining entries to GolfCourse
            .toList();
      } else {
        debugPrint('No valid courses found in search results or malformed response');
      }
    } catch (e) {
      debugPrint('Error parsing search results: $e');
    }
    
    return SearchResult(
      courses: courses,
      missingApiKey: json['missingApiKey'] == true,
    );
  }

  factory SearchResult.empty() {
    return SearchResult(courses: []);
  }
}

class Location {
  final String? city;
  final String? state;
  final String? country;

  Location({
    this.city,
    this.state,
    this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }
}

class Hole {
  final int holeNumber;
  final int par;
  final int yardage;
  final int? handicap;

  Hole({
    required this.holeNumber,
    required this.par,
    required this.yardage,
    this.handicap,
  });

  factory Hole.fromJson(Map<String, dynamic> json) {
    // Safely parse integer values with fallbacks
    int holeNumber = 0;
    int par = 4;
    int yardage = 0;
    int? handicap;
    
    try {
      // Hole number
      if (json['hole_num'] != null) {
        if (json['hole_num'] is int) {
          holeNumber = json['hole_num'];
        } else if (json['hole_num'] is String) {
          holeNumber = int.tryParse(json['hole_num']) ?? 0;
        }
      }
      
      // Par
      if (json['par'] != null) {
        if (json['par'] is int) {
          par = json['par'];
        } else if (json['par'] is String) {
          par = int.tryParse(json['par']) ?? 4;
        }
      }
      
      // Yardage
      if (json['yardage'] != null) {
        if (json['yardage'] is int) {
          yardage = json['yardage'];
        } else if (json['yardage'] is String) {
          yardage = int.tryParse(json['yardage']) ?? 0;
        }
      }
      
      // Handicap
      if (json['handicap'] != null) {
        if (json['handicap'] is int) {
          handicap = json['handicap'];
        } else if (json['handicap'] is String) {
          handicap = int.tryParse(json['handicap']);
        }
      }
    } catch (e) {
      debugPrint('Error parsing hole data: $e');
    }
    
    return Hole(
      holeNumber: holeNumber,
      par: par,
      yardage: yardage,
      handicap: handicap,
    );
  }
}

class TeeBoxes {
  final List<TeeBox> male;
  final List<TeeBox> female;

  TeeBoxes({
    required this.male,
    required this.female,
  });
  
  // Convert to JSON format for serialization
  Map<String, dynamic> toJson() {
    return {
      'male': male.map((tee) => tee.toJson()).toList(),
      'female': female.map((tee) => tee.toJson()).toList(),
    };
  }

  factory TeeBoxes.fromJson(Map<String, dynamic> json) {
    List<TeeBox> maleTees = [];
    List<TeeBox> femaleTees = [];
    
    try {
      if (json['male'] is List) {
        maleTees = (json['male'] as List)
            .map((t) => TeeBox.fromJson(t is Map<String, dynamic> ? t : {}))
            .toList();
      }
      
      if (json['female'] is List) {
        femaleTees = (json['female'] as List)
            .map((t) => TeeBox.fromJson(t is Map<String, dynamic> ? t : {}))
            .toList();
      }
    } catch (e) {
      debugPrint('Error parsing tee boxes: $e');
    }
    
    return TeeBoxes(
      male: maleTees,
      female: femaleTees,
    );
  }
}

class TeeBox {
  final String teeName;
  final String? teeColor;
  final String teeGender;
  final int parTotal;
  final int totalYards;
  final double? courseRating;
  final int? slopeRating;
  final int numberOfHoles;
  final List<Hole>? holes;

  TeeBox({
    required this.teeName,
    this.teeColor,
    required this.teeGender,
    required this.parTotal,
    required this.totalYards,
    this.courseRating,
    this.slopeRating,
    required this.numberOfHoles,
    this.holes,
  });
  
  // Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'tee_name': teeName,
      'tee_color': teeColor,
      'tee_gender': teeGender,
      'par_total': parTotal,
      'total_yards': totalYards,
      'course_rating': courseRating,
      'slope_rating': slopeRating,
      'number_of_holes': numberOfHoles,
      'holes': holes?.map((h) => h.toJson()).toList(),
    };
  }

  factory TeeBox.fromJson(Map<String, dynamic> json) {
    String teeName = 'Default';
    String teeGender = 'male';
    int parTotal = 72;
    int totalYards = 6000;
    double? courseRating;
    int? slopeRating;
    int numberOfHoles = 18;
    List<Hole>? holesList;
    
    try {
      // Parse string values with fallbacks
      teeName = json['tee_name'] ?? 'Default';
      teeGender = json['tee_gender'] ?? 'male';
      
      // Parse integer values
      if (json['par_total'] != null) {
        if (json['par_total'] is int) {
          parTotal = json['par_total'];
        } else if (json['par_total'] is String) {
          parTotal = int.tryParse(json['par_total']) ?? 72;
        }
      }
      
      if (json['total_yards'] != null) {
        if (json['total_yards'] is int) {
          totalYards = json['total_yards'];
        } else if (json['total_yards'] is String) {
          totalYards = int.tryParse(json['total_yards']) ?? 6000;
        }
      }
      
      if (json['number_of_holes'] != null) {
        if (json['number_of_holes'] is int) {
          numberOfHoles = json['number_of_holes'];
        } else if (json['number_of_holes'] is String) {
          numberOfHoles = int.tryParse(json['number_of_holes']) ?? 18;
        }
      }
      
      // Parse course rating (double)
      if (json['course_rating'] != null) {
        if (json['course_rating'] is double) {
          courseRating = json['course_rating'];
        } else {
          courseRating = double.tryParse(json['course_rating'].toString());
        }
      }
      
      // Parse slope rating (int)
      if (json['slope_rating'] != null) {
        if (json['slope_rating'] is int) {
          slopeRating = json['slope_rating'];
        } else if (json['slope_rating'] is String) {
          slopeRating = int.tryParse(json['slope_rating']);
        }
      }
      
      // Parse holes
      if (json['holes'] is List) {
        holesList = (json['holes'] as List)
            .map((h) => Hole.fromJson(h is Map<String, dynamic> ? h : {}))
            .toList();
      }
    } catch (e) {
      debugPrint('Error parsing tee box: $e');
    }
    
    return TeeBox(
      teeName: teeName,
      teeColor: json['tee_color'],
      teeGender: teeGender,
      parTotal: parTotal,
      totalYards: totalYards,
      courseRating: courseRating,
      slopeRating: slopeRating,
      numberOfHoles: numberOfHoles,
      holes: holesList,
    );
  }
}

// Class for formatting tee boxes with selection data
class FormattedTeeBox {
  final String label;
  final String value;
  final TeeBox data;

  FormattedTeeBox({
    required this.label,
    required this.value,
    required this.data,
  });
}