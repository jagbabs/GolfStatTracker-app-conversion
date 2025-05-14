import 'dart:async';
import 'dart:convert';
import 'package:gsheets/gsheets.dart';
import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/player.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:uuid/uuid.dart';

/// A service that implements database operations using Google Sheets as the backend
class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  late GSheets _gsheets;
  Spreadsheet? _spreadsheet;
  
  // Store worksheets for each data type
  Worksheet? _playersSheet;
  Worksheet? _coursesSheet;
  Worksheet? _roundsSheet;
  Worksheet? _holesSheet;
  
  // Flag to track initialization status
  bool _isInitialized = false;
  
  // Spreadsheet ID - will be set during initialization
  String? _spreadsheetId;
  
  factory GoogleSheetsService() {
    return _instance;
  }
  
  GoogleSheetsService._internal();
  
  bool get isInitialized => _isInitialized;
  
  /// Initialize the Google Sheets connection with credentials
  Future<void> initialize({
    required String credentials,
    required String spreadsheetId,
  }) async {
    try {
      _spreadsheetId = spreadsheetId;
      _gsheets = GSheets(credentials);
      
      // Access the spreadsheet
      _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
      
      // Get or create worksheets for each data type
      _playersSheet = await _getOrCreateWorksheet('Players', [
        'id', 'name', 'email', 'handicap', 'avatarUrl', 'joinDate'
      ]);
      
      _coursesSheet = await _getOrCreateWorksheet('Courses', [
        'id', 'name', 'location', 'par', 'holeCount', 'imageUrl', 'holeParsJson'
      ]);
      
      _roundsSheet = await _getOrCreateWorksheet('Rounds', [
        'id', 'playerId', 'courseId', 'courseName', 'date', 
        'totalScore', 'isCompleted', 'weather', 'notes', 'scoresJson'
      ]);
      
      _holesSheet = await _getOrCreateWorksheet('Holes', [
        'id', 'roundId', 'holeNumber', 'par', 'distance', 'strokes', 
        'putts', 'fairwayHit', 'greenInRegulation'
      ]);
      
      _isInitialized = true;
      debugPrint('Google Sheets Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Google Sheets: $e');
      rethrow;
    }
  }
  
  /// Get or create a worksheet with the given name and headers
  Future<Worksheet> _getOrCreateWorksheet(String title, List<String> headers) async {
    Worksheet? sheet = _spreadsheet?.worksheetByTitle(title);
    
    if (sheet == null) {
      // Create the worksheet if it doesn't exist
      sheet = await _spreadsheet?.addWorksheet(title);
      
      // Add headers to the worksheet
      await sheet?.values.insertRow(1, headers);
    }
    
    return sheet!;
  }
  
  /// Convert a row to a Player object
  Player _rowToPlayer(Map<String, dynamic> row) {
    return Player(
      id: row['id'] ?? const Uuid().v4(),
      name: row['name'] ?? '',
      email: row['email'] ?? '',
      handicap: int.tryParse(row['handicap'] ?? '0') ?? 0,
      avatarUrl: row['avatarUrl'] ?? '',
      joinDate: DateTime.tryParse(row['joinDate'] ?? '') ?? DateTime.now(),
    );
  }
  
  /// Convert a Player object to a row for the sheet
  Map<String, dynamic> _playerToRow(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'email': player.email,
      'handicap': player.handicap.toString(),
      'avatarUrl': player.avatarUrl,
      'joinDate': player.joinDate.toIso8601String(),
    };
  }
  
  /// Convert a row to a Course object
  Course _rowToCourse(Map<String, dynamic> row) {
    final holeParsJson = row['holeParsJson'] ?? '[]';
    List<dynamic> holeParsData = [];
    try {
      holeParsData = jsonDecode(holeParsJson) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing hole pars: $e');
    }
    
    final holePars = holeParsData.map((holeMap) => HolePar(
      holeNumber: holeMap['holeNumber'] ?? 0,
      par: holeMap['par'] ?? 0,
      distance: holeMap['distance'] ?? 0,
      handicap: holeMap['handicap'] ?? 0,
    )).toList();
    
    return Course(
      id: row['id'] ?? const Uuid().v4(),
      name: row['name'] ?? '',
      location: row['location'] ?? '',
      par: int.tryParse(row['par'] ?? '0') ?? 0,
      holeCount: int.tryParse(row['holeCount'] ?? '0') ?? 0,
      imageUrl: row['imageUrl'] ?? '',
      holePars: holePars,
    );
  }
  
  /// Convert a Course object to a row for the sheet
  Map<String, dynamic> _courseToRow(Course course) {
    final holeParsJson = jsonEncode(
      course.holePars.map((holePar) => holePar.toMap()).toList()
    );
    
    return {
      'id': course.id,
      'name': course.name,
      'location': course.location,
      'par': course.par.toString(),
      'holeCount': course.holeCount.toString(),
      'imageUrl': course.imageUrl,
      'holeParsJson': holeParsJson,
    };
  }
  
  /// Convert a row to a Round object
  Round _rowToRound(Map<String, dynamic> row) {
    final scoresJson = row['scoresJson'] ?? '[]';
    List<dynamic> scoresData = [];
    try {
      scoresData = jsonDecode(scoresJson) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing scores: $e');
    }
    
    final scores = scoresData.map((scoreMap) => HoleScore(
      holeNumber: scoreMap['holeNumber'] ?? 0,
      par: scoreMap['par'] ?? 0,
      strokes: scoreMap['strokes'] ?? 0,
      putts: scoreMap['putts'] ?? 0,
      fairwayHit: FairwayHit.values.firstWhere(
        (e) => e.toString() == scoreMap['fairwayHit'],
        orElse: () => FairwayHit.notApplicable,
      ),
      greenInRegulation: GreenInRegulation.values.firstWhere(
        (e) => e.toString() == scoreMap['greenInRegulation'],
        orElse: () => GreenInRegulation.no,
      ),
      penalties: (scoreMap['penalties'] as List<dynamic>?)?.map((penaltyMap) => 
        Penalty(
          type: PenaltyType.values.firstWhere(
            (e) => e.toString() == penaltyMap['type'],
            orElse: () => PenaltyType.other,
          ),
          count: penaltyMap['count'] ?? 1,
        )
      ).toList() ?? [],
      notes: scoreMap['notes'] ?? '',
    )).toList();
    
    // Calculate total score and par from holes
    int totalScore = 0;
    int totalPar = 0;
    for (final score in scores) {
      if (score.strokes > 0) {
        totalScore += score.strokes;
        totalPar += score.par;
      }
    }
    
    return Round(
      id: row['id'] ?? const Uuid().v4(),
      playerId: row['playerId'] ?? '',
      courseId: row['courseId'] ?? '',
      courseName: row['courseName'] ?? '',
      date: DateTime.tryParse(row['date'] ?? '') ?? DateTime.now(),
      isCompleted: row['isCompleted'] == 'true',
      weather: row['weather'] ?? '',
      notes: row['notes'] ?? '',
      scores: scores,
      totalScore: totalScore,
      totalPar: totalPar,
    );
  }
  
  /// Convert a Round object to a row for the sheet
  Map<String, dynamic> _roundToRow(Round round) {
    final scoresJson = jsonEncode(
      round.scores.map((score) => {
        'holeNumber': score.holeNumber,
        'par': score.par,
        'strokes': score.strokes,
        'putts': score.putts,
        'fairwayHit': score.fairwayHit.toString(),
        'greenInRegulation': score.greenInRegulation.toString(),
      }).toList()
    );
    
    return {
      'id': round.id,
      'playerId': round.playerId,
      'courseId': round.courseId,
      'courseName': round.courseName,
      'date': round.date.toIso8601String(),
      'totalScore': round.totalScore.toString(),
      'isCompleted': round.isCompleted.toString(),
      'weather': round.weather,
      'notes': round.notes,
      'scoresJson': scoresJson,
    };
  }
  
  //
  // PLAYER METHODS
  //
  
  /// Get all players from the Players sheet
  Future<List<Player>> getPlayers() async {
    if (!_isInitialized || _playersSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _playersSheet!.values.map.allRows();
    return rows?.map(_rowToPlayer).toList() ?? [];
  }
  
  /// Get a player by ID
  Future<Player?> getPlayer(String id) async {
    if (!_isInitialized || _playersSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _playersSheet!.values.map.allRows();
    final playerRow = rows?.firstWhere(
      (row) => row['id'] == id,
      orElse: () => {},
    );
    
    if (playerRow?.isEmpty ?? true) {
      return null;
    }
    
    return _rowToPlayer(playerRow!);
  }
  
  /// Save a player (create or update)
  Future<void> savePlayer(Player player) async {
    if (!_isInitialized || _playersSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rowData = _playerToRow(player);
    
    // Check if player already exists
    final rows = await _playersSheet!.values.map.allRows();
    final rowIndex = rows?.indexWhere((row) => row['id'] == player.id);
    
    if (rowIndex != null && rowIndex >= 0 && rows != null) {
      // Update existing player (row index + 2 because of header row and 0-indexing)
      await _playersSheet!.values.map.insertRow(rowIndex + 2, rowData);
    } else {
      // Add new player
      await _playersSheet!.values.map.appendRow(rowData);
    }
  }
  
  //
  // COURSE METHODS
  //
  
  /// Get all courses from the Courses sheet
  Future<List<Course>> getCourses() async {
    if (!_isInitialized || _coursesSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _coursesSheet!.values.map.allRows();
    return rows?.map(_rowToCourse).toList() ?? [];
  }
  
  /// Get a course by ID
  Future<Course?> getCourse(String id) async {
    if (!_isInitialized || _coursesSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _coursesSheet!.values.map.allRows();
    final courseRow = rows?.firstWhere(
      (row) => row['id'] == id,
      orElse: () => {},
    );
    
    if (courseRow?.isEmpty ?? true) {
      return null;
    }
    
    return _rowToCourse(courseRow!);
  }
  
  /// Save a course (create or update)
  Future<void> saveCourse(Course course) async {
    if (!_isInitialized || _coursesSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rowData = _courseToRow(course);
    
    // Check if course already exists
    final rows = await _coursesSheet!.values.map.allRows();
    final rowIndex = rows?.indexWhere((row) => row['id'] == course.id);
    
    if (rowIndex != null && rowIndex >= 0 && rows != null) {
      // Update existing course (row index + 2 because of header row and 0-indexing)
      await _coursesSheet!.values.map.insertRow(rowIndex + 2, rowData);
    } else {
      // Add new course
      await _coursesSheet!.values.map.appendRow(rowData);
    }
  }
  
  //
  // ROUND METHODS
  //
  
  /// Get all rounds from the Rounds sheet
  Future<List<Round>> getRounds() async {
    if (!_isInitialized || _roundsSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _roundsSheet!.values.map.allRows();
    return rows?.map(_rowToRound).toList() ?? [];
  }
  
  /// Get rounds for a specific player
  Future<List<Round>> getRoundsByPlayerId(String playerId) async {
    final allRounds = await getRounds();
    return allRounds.where((round) => round.playerId == playerId).toList();
  }
  
  /// Get a round by ID
  Future<Round?> getRound(String id) async {
    if (!_isInitialized || _roundsSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _roundsSheet!.values.map.allRows();
    final roundRow = rows?.firstWhere(
      (row) => row['id'] == id,
      orElse: () => {},
    );
    
    if (roundRow?.isEmpty ?? true) {
      return null;
    }
    
    return _rowToRound(roundRow!);
  }
  
  /// Save a round (create or update)
  Future<void> saveRound(Round round) async {
    if (!_isInitialized || _roundsSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rowData = _roundToRow(round);
    
    // Check if round already exists
    final rows = await _roundsSheet!.values.map.allRows();
    final rowIndex = rows?.indexWhere((row) => row['id'] == round.id);
    
    if (rowIndex != null && rowIndex >= 0 && rows != null) {
      // Update existing round (row index + 2 because of header row and 0-indexing)
      await _roundsSheet!.values.map.insertRow(rowIndex + 2, rowData);
    } else {
      // Add new round
      await _roundsSheet!.values.map.appendRow(rowData);
    }
  }
  
  /// Delete a round by ID
  Future<void> deleteRound(String id) async {
    if (!_isInitialized || _roundsSheet == null) {
      throw Exception('Google Sheets service not initialized');
    }
    
    final rows = await _roundsSheet!.values.map.allRows();
    final rowIndex = rows?.indexWhere((row) => row['id'] == id);
    
    if (rowIndex != null && rowIndex >= 0) {
      // Delete row (row index + 2 because of header row and 0-indexing)
      await _roundsSheet!.deleteRow(rowIndex + 2);
    }
  }
  
  /// Get player statistics from rounds data
  Future<Map<String, dynamic>> getPlayerStats(String playerId) async {
    final rounds = await getRoundsByPlayerId(playerId);
    final completedRounds = rounds.where((r) => r.isCompleted).toList();
    
    if (completedRounds.isEmpty) {
      return {
        'roundsPlayed': 0,
        'averageScore': 0,
        'bestRound': {},
        'fairwayHitPercentage': 0,
        'girPercentage': 0,
        'averagePutts': 0,
        'scoringDistribution': {
          'eagles': 0,
          'birdies': 0,
          'pars': 0,
          'bogeys': 0,
          'doubleBogeys': 0,
          'triplePlus': 0,
        },
      };
    }
    
    // Calculate average score
    final totalScores = completedRounds.fold<int>(
      0, (sum, round) => sum + round.totalScore
    );
    final averageScore = totalScores / completedRounds.length;
    
    // Find best round (lowest score)
    final bestRound = completedRounds.reduce(
      (a, b) => a.totalScore < b.totalScore ? a : b
    );
    
    // Calculate other stats
    int totalPutts = 0;
    int fairwayHits = 0;
    int fairwayAttempts = 0;
    int girHits = 0;
    int totalHoles = 0;
    
    // Scoring distribution
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeys = 0;
    int triplePlus = 0;
    
    for (final round in completedRounds) {
      for (final score in round.scores) {
        if (score.strokes > 0) {
          totalHoles++;
          totalPutts += score.putts;
          
          // Fairways hit (only count par 4s and 5s)
          if (score.par >= 4) {
            fairwayAttempts++;
            if (score.fairwayHit == FairwayHit.yes) {
              fairwayHits++;
            }
          }
          
          // Greens in regulation
          if (score.greenInRegulation == GreenInRegulation.yes) {
            girHits++;
          }
          
          // Scoring distribution
          final relativeToPar = score.strokes - score.par;
          
          if (relativeToPar <= -2) eagles++;
          else if (relativeToPar == -1) birdies++;
          else if (relativeToPar == 0) pars++;
          else if (relativeToPar == 1) bogeys++;
          else if (relativeToPar == 2) doubleBogeys++;
          else if (relativeToPar >= 3) triplePlus++;
        }
      }
    }
    
    final fairwayHitPercentage = fairwayAttempts > 0 
        ? (fairwayHits / fairwayAttempts) * 100 
        : 0.0;
    
    final girPercentage = totalHoles > 0 
        ? (girHits / totalHoles) * 100 
        : 0.0;
    
    final averagePutts = totalHoles > 0 
        ? totalPutts / totalHoles 
        : 0.0;
    
    return {
      'roundsPlayed': completedRounds.length,
      'averageScore': averageScore,
      'bestRound': {
        'id': bestRound.id,
        'course': bestRound.courseName,
        'date': bestRound.date.toIso8601String(),
        'score': bestRound.totalScore,
      },
      'fairwayHitPercentage': fairwayHitPercentage,
      'girPercentage': girPercentage,
      'averagePutts': averagePutts,
      'scoringDistribution': {
        'eagles': eagles,
        'birdies': birdies,
        'pars': pars,
        'bogeys': bogeys,
        'doubleBogeys': doubleBogeys,
        'triplePlus': triplePlus,
      },
    };
  }
}

// Add the missing jsonEncode and jsonDecode imports
import 'dart:convert';