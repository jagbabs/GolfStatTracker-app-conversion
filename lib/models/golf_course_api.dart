// Golf Course API models
// Based on the original web application's types/golfCourseApi.ts

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
    return SearchResult(
      courses: (json['courses'] as List<dynamic>?)
              ?.map((c) => GolfCourse.fromJson(c))
              .toList() ?? [],
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

  factory TeeBox.fromJson(Map<String, dynamic> json) {
    return TeeBox(
      teeName: json['tee_name'] ?? 'Default',
      teeColor: json['tee_color'],
      teeGender: json['tee_gender'] ?? 'male',
      parTotal: json['par_total'] ?? 72,
      totalYards: json['total_yards'] ?? 6000,
      courseRating: json['course_rating'] != null ? 
                   double.tryParse(json['course_rating'].toString()) : 72.0,
      slopeRating: json['slope_rating'],
      numberOfHoles: json['number_of_holes'] ?? 18,
      holes: (json['holes'] as List<dynamic>?)
              ?.map((h) => Hole.fromJson(h))
              .toList(),
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