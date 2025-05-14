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
    return GolfCourse(
      id: json['id'],
      clubName: json['club_name'] ?? 'Unknown Club',
      courseName: json['course_name'] ?? 'Main Course',
      location: Location.fromJson(json['location'] ?? {}),
      holes: (json['holes'] as List<dynamic>?)
              ?.map((h) => Hole.fromJson(h))
              .toList() ?? [],
      tees: TeeBoxes.fromJson(json['tees'] ?? {'male': [], 'female': []}),
    );
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

  SearchResult({required this.courses});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      courses: (json['courses'] as List<dynamic>?)
              ?.map((c) => GolfCourse.fromJson(c))
              .toList() ?? [],
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
    return Hole(
      holeNumber: json['hole_num'] ?? 0,
      par: json['par'] ?? 4,
      yardage: json['yardage'] ?? 0,
      handicap: json['handicap'],
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
    return TeeBoxes(
      male: (json['male'] as List<dynamic>?)
            ?.map((t) => TeeBox.fromJson(t))
            .toList() ?? [],
      female: (json['female'] as List<dynamic>?)
              ?.map((t) => TeeBox.fromJson(t))
              .toList() ?? [],
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