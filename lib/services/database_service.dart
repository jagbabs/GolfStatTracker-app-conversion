import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/player.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;
  SharedPreferences? _prefs;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _openDatabase();
    await _createTables();
    await _seedInitialData();
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, Constants.databaseName);
    
    return await openDatabase(
      path,
      version: Constants.databaseVersion,
      onCreate: (db, version) async {
        await _createTables();
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle database migrations as app evolves
      },
    );
  }

  Future<void> _createTables() async {
    final db = _database;
    if (db == null) return;

    // Create courses table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${Constants.coursesTable} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      location TEXT NOT NULL,
      par INTEGER NOT NULL,
      holeCount INTEGER NOT NULL,
      imageUrl TEXT,
      holeParsJson TEXT
    )
    ''');

    // Create players table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${Constants.playersTable} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT,
      handicap INTEGER DEFAULT 0,
      avatarUrl TEXT,
      joinDate TEXT
    )
    ''');

    // Create rounds table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${Constants.roundsTable} (
      id TEXT PRIMARY KEY,
      courseId TEXT NOT NULL,
      courseName TEXT NOT NULL,
      playerId TEXT NOT NULL,
      date TEXT NOT NULL,
      scoresJson TEXT,
      totalScore INTEGER NOT NULL,
      totalPar INTEGER NOT NULL,
      notes TEXT,
      weather TEXT,
      isCompleted INTEGER DEFAULT 0,
      FOREIGN KEY (courseId) REFERENCES ${Constants.coursesTable} (id),
      FOREIGN KEY (playerId) REFERENCES ${Constants.playersTable} (id)
    )
    ''');
  }

  Future<void> _seedInitialData() async {
    final isFirstRun = _prefs?.getBool(Constants.prefFirstRunKey) ?? true;
    
    if (isFirstRun) {
      // Create default player
      final uuid = const Uuid();
      final player = Player(
        id: uuid.v4(),
        name: 'Your Name',
        email: '',
        handicap: 0,
        avatarUrl: '',
        joinDate: DateTime.now(),
      );
      
      await savePlayer(player);
      
      // Create sample courses
      final course1 = Course(
        id: uuid.v4(),
        name: 'Pine Valley Golf Club',
        location: 'Pine Valley, NJ',
        par: 72,
        holeCount: 18,
        imageUrl: Constants.courseImageUrls[0],
        holePars: List.generate(18, (index) => 
          HolePar(
            holeNumber: index + 1,
            par: (index % 5 == 4) ? 5 : (index % 5 == 0) ? 3 : 4, // Mix of par 3, 4, 5
            distance: 300 + (index * 30), // Fake distances
            handicap: index + 1,
          )
        ),
      );
      
      final course2 = Course(
        id: uuid.v4(),
        name: 'Augusta National',
        location: 'Augusta, GA',
        par: 72,
        holeCount: 18,
        imageUrl: Constants.courseImageUrls[1],
        holePars: List.generate(18, (index) => 
          HolePar(
            holeNumber: index + 1,
            par: (index % 5 == 4) ? 5 : (index % 5 == 0) ? 3 : 4,
            distance: 310 + (index * 28),
            handicap: 18 - index,
          )
        ),
      );
      
      await saveCourse(course1);
      await saveCourse(course2);
      
      await _prefs?.setBool(Constants.prefFirstRunKey, false);
    }
  }

  // Player Methods
  Future<List<Player>> getPlayers() async {
    final db = _database;
    if (db == null) return [];

    final List<Map<String, dynamic>> playerMaps = await db.query(Constants.playersTable);
    return playerMaps.map((map) => Player.fromMap(map)).toList();
  }

  Future<Player?> getPlayer(String id) async {
    final db = _database;
    if (db == null) return null;

    final List<Map<String, dynamic>> result = await db.query(
      Constants.playersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Player.fromMap(result.first);
  }

  Future<void> savePlayer(Player player) async {
    final db = _database;
    if (db == null) return;

    await db.insert(
      Constants.playersTable,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePlayer(String id) async {
    final db = _database;
    if (db == null) return;

    await db.delete(
      Constants.playersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Course Methods
  Future<List<Course>> getCourses() async {
    final db = _database;
    if (db == null) return [];

    final List<Map<String, dynamic>> courseMaps = await db.query(Constants.coursesTable);
    
    return courseMaps.map((map) {
      List<HolePar> holePars = [];
      
      if (map['holeParsJson'] != null) {
        final List<dynamic> holeParsList = jsonDecode(map['holeParsJson']);
        holePars = holeParsList.map((h) => HolePar.fromMap(h)).toList();
      }
      
      return Course(
        id: map['id'],
        name: map['name'],
        location: map['location'],
        par: map['par'],
        holeCount: map['holeCount'],
        imageUrl: map['imageUrl'] ?? '',
        holePars: holePars,
      );
    }).toList();
  }

  Future<Course?> getCourse(String id) async {
    final db = _database;
    if (db == null) return null;

    final List<Map<String, dynamic>> result = await db.query(
      Constants.coursesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    
    final map = result.first;
    List<HolePar> holePars = [];
    
    if (map['holeParsJson'] != null) {
      final List<dynamic> holeParsList = jsonDecode(map['holeParsJson']);
      holePars = holeParsList.map((h) => HolePar.fromMap(h)).toList();
    }
    
    return Course(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      par: map['par'],
      holeCount: map['holeCount'],
      imageUrl: map['imageUrl'] ?? '',
      holePars: holePars,
    );
  }

  Future<void> saveCourse(Course course) async {
    final db = _database;
    if (db == null) return;

    final holeParJson = jsonEncode(course.holePars.map((h) => h.toMap()).toList());
    
    await db.insert(
      Constants.coursesTable,
      {
        'id': course.id,
        'name': course.name,
        'location': course.location,
        'par': course.par,
        'holeCount': course.holeCount,
        'imageUrl': course.imageUrl,
        'holeParsJson': holeParJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCourse(String id) async {
    final db = _database;
    if (db == null) return;

    await db.delete(
      Constants.coursesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Round Methods
  Future<List<Round>> getRounds({String? playerId}) async {
    final db = _database;
    if (db == null) return [];

    List<Map<String, dynamic>> roundMaps;
    
    if (playerId != null) {
      roundMaps = await db.query(
        Constants.roundsTable,
        where: 'playerId = ?',
        whereArgs: [playerId],
        orderBy: 'date DESC',
      );
    } else {
      roundMaps = await db.query(
        Constants.roundsTable,
        orderBy: 'date DESC',
      );
    }
    
    return roundMaps.map((map) {
      List<HoleScore> scores = [];
      
      if (map['scoresJson'] != null) {
        final List<dynamic> scoresList = jsonDecode(map['scoresJson']);
        scores = scoresList.map((s) => HoleScore.fromMap(s)).toList();
      }
      
      return Round(
        id: map['id'],
        courseId: map['courseId'],
        courseName: map['courseName'],
        playerId: map['playerId'],
        date: DateTime.parse(map['date']),
        scores: scores,
        totalScore: map['totalScore'],
        totalPar: map['totalPar'],
        notes: map['notes'] ?? '',
        weather: map['weather'] ?? '',
        isCompleted: map['isCompleted'] == 1,
      );
    }).toList();
  }

  Future<Round?> getRound(String id) async {
    final db = _database;
    if (db == null) return null;

    final List<Map<String, dynamic>> result = await db.query(
      Constants.roundsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    
    final map = result.first;
    List<HoleScore> scores = [];
    
    if (map['scoresJson'] != null) {
      final List<dynamic> scoresList = jsonDecode(map['scoresJson']);
      scores = scoresList.map((s) => HoleScore.fromMap(s)).toList();
    }
    
    return Round(
      id: map['id'],
      courseId: map['courseId'],
      courseName: map['courseName'],
      playerId: map['playerId'],
      date: DateTime.parse(map['date']),
      scores: scores,
      totalScore: map['totalScore'],
      totalPar: map['totalPar'],
      notes: map['notes'] ?? '',
      weather: map['weather'] ?? '',
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Future<void> saveRound(Round round) async {
    final db = _database;
    if (db == null) return;

    final scoresJson = jsonEncode(round.scores.map((s) => s.toMap()).toList());
    
    await db.insert(
      Constants.roundsTable,
      {
        'id': round.id,
        'courseId': round.courseId,
        'courseName': round.courseName,
        'playerId': round.playerId,
        'date': round.date.toIso8601String(),
        'scoresJson': scoresJson,
        'totalScore': round.totalScore,
        'totalPar': round.totalPar,
        'notes': round.notes,
        'weather': round.weather,
        'isCompleted': round.isCompleted ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRound(String id) async {
    final db = _database;
    if (db == null) return;

    await db.delete(
      Constants.roundsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getPlayerStats(String playerId) async {
    final rounds = await getRounds(playerId: playerId);
    
    if (rounds.isEmpty) {
      return {
        'averageScore': 0,
        'bestScore': 0,
        'roundsPlayed': 0,
        'averagePuttsPerRound': 0,
        'fairwayHitPercentage': 0,
        'girPercentage': 0,
        'parBreakdownPercent': {
          'eagles': 0,
          'birdies': 0,
          'pars': 0,
          'bogeys': 0,
          'doubleBogeys': 0,
          'triplePlus': 0,
        },
      };
    }
    
    final completedRounds = rounds.where((r) => r.isCompleted).toList();
    
    if (completedRounds.isEmpty) {
      return {
        'averageScore': 0,
        'bestScore': 0,
        'roundsPlayed': 0,
        'averagePuttsPerRound': 0,
        'fairwayHitPercentage': 0,
        'girPercentage': 0,
        'parBreakdownPercent': {
          'eagles': 0,
          'birdies': 0,
          'pars': 0,
          'bogeys': 0,
          'doubleBogeys': 0,
          'triplePlus': 0,
        },
      };
    }
    
    final totalScores = completedRounds.fold(0, (sum, round) => sum + round.totalScore);
    final averageScore = totalScores / completedRounds.length;
    
    final bestRound = completedRounds.reduce((a, b) => a.totalScore < b.totalScore ? a : b);
    
    // Calculate putting stats
    int totalPutts = 0;
    int fairwayHits = 0;
    int fairwayAttempts = 0;
    int girHits = 0;
    int totalHoles = 0;
    
    // Par breakdown
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeys = 0;
    int triplePlus = 0;
    
    for (final round in completedRounds) {
      for (final score in round.scores) {
        totalPutts += score.putts;
        totalHoles++;
        
        if (score.fairwayHit != FairwayHit.notApplicable) {
          fairwayAttempts++;
          if (score.fairwayHit == FairwayHit.yes) {
            fairwayHits++;
          }
        }
        
        if (score.greenInRegulation == GreenInRegulation.yes) {
          girHits++;
        }
        
        // Calculate relative to par
        final relativeToPar = score.strokes - score.par;
        if (relativeToPar <= -2) {
          eagles++;
        } else if (relativeToPar == -1) {
          birdies++;
        } else if (relativeToPar == 0) {
          pars++;
        } else if (relativeToPar == 1) {
          bogeys++;
        } else if (relativeToPar == 2) {
          doubleBogeys++;
        } else if (relativeToPar > 2) {
          triplePlus++;
        }
      }
    }
    
    final averagePuttsPerRound = totalPutts / completedRounds.length;
    final fairwayHitPercentage = fairwayAttempts > 0 ? (fairwayHits / fairwayAttempts) * 100 : 0;
    final girPercentage = totalHoles > 0 ? (girHits / totalHoles) * 100 : 0;
    
    // Par breakdown percentages
    final parBreakdownPercent = {
      'eagles': totalHoles > 0 ? (eagles / totalHoles) * 100 : 0,
      'birdies': totalHoles > 0 ? (birdies / totalHoles) * 100 : 0,
      'pars': totalHoles > 0 ? (pars / totalHoles) * 100 : 0,
      'bogeys': totalHoles > 0 ? (bogeys / totalHoles) * 100 : 0,
      'doubleBogeys': totalHoles > 0 ? (doubleBogeys / totalHoles) * 100 : 0,
      'triplePlus': totalHoles > 0 ? (triplePlus / totalHoles) * 100 : 0,
    };
    
    return {
      'averageScore': averageScore,
      'bestScore': bestRound.totalScore,
      'roundsPlayed': completedRounds.length,
      'averagePuttsPerRound': averagePuttsPerRound,
      'fairwayHitPercentage': fairwayHitPercentage,
      'girPercentage': girPercentage,
      'parBreakdownPercent': parBreakdownPercent,
    };
  }
}
