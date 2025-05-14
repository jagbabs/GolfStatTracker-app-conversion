enum FairwayHit { yes, no, notApplicable, unknown }
enum GreenInRegulation { yes, no, unknown }
enum PuttCount { one, two, three, four, fiveOrMore }

class HoleScore {
  final int holeNumber;
  final int par; // Par for this specific hole
  final int strokes;
  final FairwayHit fairwayHit;
  final GreenInRegulation greenInRegulation;
  final int putts;
  final List<Penalty> penalties;
  final String notes;

  HoleScore({
    required this.holeNumber,
    required this.par,
    required this.strokes,
    required this.fairwayHit,
    required this.greenInRegulation,
    required this.putts,
    required this.penalties,
    this.notes = '',
  });

  factory HoleScore.fromMap(Map<String, dynamic> map) {
    return HoleScore(
      holeNumber: map['holeNumber'],
      par: map['par'],
      strokes: map['strokes'],
      fairwayHit: FairwayHit.values[map['fairwayHit']],
      greenInRegulation: GreenInRegulation.values[map['greenInRegulation']],
      putts: map['putts'],
      penalties: List<Penalty>.from(
        (map['penalties'] ?? []).map((x) => Penalty.fromMap(x)),
      ),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'strokes': strokes,
      'fairwayHit': fairwayHit.index,
      'greenInRegulation': greenInRegulation.index,
      'putts': putts,
      'penalties': penalties.map((x) => x.toMap()).toList(),
      'notes': notes,
    };
  }

  HoleScore copyWith({
    int? holeNumber,
    int? par,
    int? strokes,
    FairwayHit? fairwayHit,
    GreenInRegulation? greenInRegulation,
    int? putts,
    List<Penalty>? penalties,
    String? notes,
  }) {
    return HoleScore(
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      strokes: strokes ?? this.strokes,
      fairwayHit: fairwayHit ?? this.fairwayHit,
      greenInRegulation: greenInRegulation ?? this.greenInRegulation,
      putts: putts ?? this.putts,
      penalties: penalties ?? this.penalties,
      notes: notes ?? this.notes,
    );
  }

  int get relativeToPar => strokes - par;

  String get scoreLabel {
    final diff = relativeToPar;
    if (diff == 0) {
      return 'Par';
    } else if (diff == 1) {
      return 'Bogey';
    } else if (diff == 2) {
      return 'Double Bogey';
    } else if (diff > 2) {
      return 'Triple Bogey+';
    } else if (diff == -1) {
      return 'Birdie';
    } else if (diff == -2) {
      return 'Eagle';
    } else if (diff < -2) {
      return 'Albatross+';
    }
    return '';
  }
}

class Penalty {
  final PenaltyType type;
  final int count;

  Penalty({
    required this.type,
    required this.count,
  });

  factory Penalty.fromMap(Map<String, dynamic> map) {
    return Penalty(
      type: PenaltyType.values[map['type']],
      count: map['count'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'count': count,
    };
  }
}

enum PenaltyType {
  waterHazard,
  outOfBounds,
  bunker,
  lost,
  unplayable,
  other
}
