class Player {
  final String id;
  final String name;
  final String email;
  final int handicap;
  final String avatarUrl;
  final DateTime joinDate;

  Player({
    required this.id,
    required this.name,
    required this.email,
    required this.handicap,
    required this.avatarUrl,
    required this.joinDate,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      handicap: map['handicap'],
      avatarUrl: map['avatarUrl'],
      joinDate: DateTime.parse(map['joinDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'handicap': handicap,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? email,
    int? handicap,
    String? avatarUrl,
    DateTime? joinDate,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      handicap: handicap ?? this.handicap,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}
