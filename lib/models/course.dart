class Course {
  final String id;
  final String name;
  final String location;
  final int par;
  final int holeCount;
  final String imageUrl;
  final List<HolePar> holePars;

  Course({
    required this.id,
    required this.name,
    required this.location,
    required this.par,
    required this.holeCount,
    required this.imageUrl,
    required this.holePars,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      par: map['par'],
      holeCount: map['holeCount'],
      imageUrl: map['imageUrl'],
      holePars: List<HolePar>.from(
        (map['holePars'] ?? []).map((x) => HolePar.fromMap(x)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'par': par,
      'holeCount': holeCount,
      'imageUrl': imageUrl,
      'holePars': holePars.map((x) => x.toMap()).toList(),
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? location,
    int? par,
    int? holeCount,
    String? imageUrl,
    List<HolePar>? holePars,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      par: par ?? this.par,
      holeCount: holeCount ?? this.holeCount,
      imageUrl: imageUrl ?? this.imageUrl,
      holePars: holePars ?? this.holePars,
    );
  }
}

class HolePar {
  final int holeNumber;
  final int par;
  final int distance;
  final int handicap; // Hole difficulty ranking 1-18

  HolePar({
    required this.holeNumber,
    required this.par,
    required this.distance,
    required this.handicap,
  });

  factory HolePar.fromMap(Map<String, dynamic> map) {
    return HolePar(
      holeNumber: map['holeNumber'],
      par: map['par'],
      distance: map['distance'],
      handicap: map['handicap'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'distance': distance,
      'handicap': handicap,
    };
  }

  HolePar copyWith({
    int? holeNumber,
    int? par,
    int? distance,
    int? handicap,
  }) {
    return HolePar(
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      distance: distance ?? this.distance,
      handicap: handicap ?? this.handicap,
    );
  }
}
