import 'package:golf_stat_tracker/models/hole.dart';

class Round {
  final String id;
  final String courseId;
  final String courseName;
  final String playerId;
  final DateTime date;
  final List<HoleScore> scores;
  final int totalScore;
  final int totalPar;
  final String notes;
  final String weather;
  final bool isCompleted;

  Round({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.playerId,
    required this.date,
    required this.scores,
    required this.totalScore,
    required this.totalPar,
    required this.notes,
    required this.weather,
    required this.isCompleted,
  });

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      id: map['id'],
      courseId: map['courseId'],
      courseName: map['courseName'],
      playerId: map['playerId'],
      date: DateTime.parse(map['date']),
      scores: List<HoleScore>.from(
        (map['scores'] ?? []).map((x) => HoleScore.fromMap(x)),
      ),
      totalScore: map['totalScore'],
      totalPar: map['totalPar'],
      notes: map['notes'] ?? '',
      weather: map['weather'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'playerId': playerId,
      'date': date.toIso8601String(),
      'scores': scores.map((x) => x.toMap()).toList(),
      'totalScore': totalScore,
      'totalPar': totalPar,
      'notes': notes,
      'weather': weather,
      'isCompleted': isCompleted,
    };
  }

  Round copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? playerId,
    DateTime? date,
    List<HoleScore>? scores,
    int? totalScore,
    int? totalPar,
    String? notes,
    String? weather,
    bool? isCompleted,
  }) {
    return Round(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      playerId: playerId ?? this.playerId,
      date: date ?? this.date,
      scores: scores ?? this.scores,
      totalScore: totalScore ?? this.totalScore,
      totalPar: totalPar ?? this.totalPar,
      notes: notes ?? this.notes,
      weather: weather ?? this.weather,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  int get relativeToPar => totalScore - totalPar;

  String get scoreString {
    final diff = relativeToPar;
    if (diff == 0) {
      return 'E';
    } else if (diff > 0) {
      return '+$diff';
    } else {
      return '$diff';
    }
  }

  int get frontNineScore {
    return scores
        .where((score) => score.holeNumber <= 9)
        .fold(0, (sum, score) => sum + score.strokes);
  }

  int get backNineScore {
    return scores
        .where((score) => score.holeNumber > 9)
        .fold(0, (sum, score) => sum + score.strokes);
  }

  int getParForHoles(int start, int end) {
    return scores
        .where((score) => score.holeNumber >= start && score.holeNumber <= end)
        .fold(0, (sum, score) => sum + score.par);
  }
}
