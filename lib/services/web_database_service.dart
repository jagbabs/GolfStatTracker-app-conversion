import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/player.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/utils/constants.dart';

/// A version of DatabaseService that uses SharedPreferences for web
/// This is a temporary solution for web since SQLite is not supported natively
class WebDatabaseService {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  SharedPreferences? _prefs;

  // Storage keys
  static const String _keyPlayers = 'players';
  static const String _keyCourses = 'courses';
  static const String _keyRounds = 'rounds';

  factory WebDatabaseService() {
    return _instance;
  }

  WebDatabaseService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedInitialData();
  }

  Future<void> _seedInitialData() async {
    // Check if we have already initialized the data
    final hasData = _prefs?.getBool('initialized') ?? false;
    if (hasData) {
      return;
    }

    // Create a sample player if none exists
    final players = await getPlayers();
    if (players.isEmpty) {
      final player = Player(
        id: const Uuid().v4(),
        name: 'Sample Player',
        handicap: 15,
        email: 'player@example.com',
        photoUrl: Constants.defaultPlayerImageUrl,
      );
      await savePlayer(player);
    }

    // Create some sample courses if none exist
    final courses = await getCourses();
    if (courses.isEmpty) {
      final course1 = Course(
        id: const Uuid().v4(),
        name: 'Pebble Beach Golf Links',
        location: 'Pebble Beach, CA',
        imageUrl: Constants.courseImageUrls[0],
        holePars: List.generate(
          18,
          (index) => HolePar(
            holeNumber: index + 1,
            par: index % 3 == 0 ? 5 : (index % 3 == 1 ? 4 : 3),
            distance: 100 + (index * 20),
            handicap: index + 1,
          ),
        ),
        par: 72,
        slope: 144,
        rating: 74.7,
      );

      final course2 = Course(
        id: const Uuid().v4(),
        name: 'Augusta National',
        location: 'Augusta, GA',
        imageUrl: Constants.courseImageUrls[1],
        holePars: List.generate(
          18,
          (index) => HolePar(
            holeNumber: index + 1,
            par: index % 3 == 0 ? 5 : (index % 3 == 1 ? 4 : 3),
            distance: 150 + (index * 25),
            handicap: index + 1,
          ),
        ),
        par: 72,
        slope: 148,
        rating: 76.2,
      );

      await saveCourse(course1);
      await saveCourse(course2);
    }

    // Mark as initialized
    await _prefs?.setBool('initialized', true);
  }

  // Player methods
  Future<List<Player>> getPlayers() async {
    final playersJson = _prefs?.getStringList(_keyPlayers) ?? [];
    return playersJson.map((p) => Player.fromMap(jsonDecode(p))).toList();
  }

  Future<Player?> getPlayer(String id) async {
    final players = await getPlayers();
    return players.firstWhere((p) => p.id == id, orElse: () => null as Player);
  }

  Future<void> savePlayer(Player player) async {
    final players = await getPlayers();
    final index = players.indexWhere((p) => p.id == player.id);
    
    if (index >= 0) {
      players[index] = player;
    } else {
      players.add(player);
    }

    await _prefs?.setStringList(
      _keyPlayers,
      players.map((p) => jsonEncode(p.toMap())).toList(),
    );
  }

  // Course methods
  Future<List<Course>> getCourses() async {
    final coursesJson = _prefs?.getStringList(_keyCourses) ?? [];
    return coursesJson.map((c) => Course.fromMap(jsonDecode(c))).toList();
  }

  Future<Course?> getCourse(String id) async {
    final courses = await getCourses();
    return courses.firstWhere((c) => c.id == id, orElse: () => null as Course);
  }

  Future<void> saveCourse(Course course) async {
    final courses = await getCourses();
    final index = courses.indexWhere((c) => c.id == course.id);
    
    if (index >= 0) {
      courses[index] = course;
    } else {
      courses.add(course);
    }

    await _prefs?.setStringList(
      _keyCourses,
      courses.map((c) => jsonEncode(c.toMap())).toList(),
    );
  }

  // Round methods
  Future<List<Round>> getRounds() async {
    final roundsJson = _prefs?.getStringList(_keyRounds) ?? [];
    return roundsJson.map((r) => Round.fromMap(jsonDecode(r))).toList();
  }

  Future<List<Round>> getRoundsByPlayerId(String playerId) async {
    final rounds = await getRounds();
    return rounds.where((r) => r.playerId == playerId).toList();
  }

  Future<Round?> getRound(String id) async {
    final rounds = await getRounds();
    return rounds.firstWhere((r) => r.id == id, orElse: () => null as Round);
  }

  Future<void> saveRound(Round round) async {
    final rounds = await getRounds();
    final index = rounds.indexWhere((r) => r.id == round.id);
    
    if (index >= 0) {
      rounds[index] = round;
    } else {
      rounds.add(round);
    }

    await _prefs?.setStringList(
      _keyRounds,
      rounds.map((r) => jsonEncode(r.toMap())).toList(),
    );
  }

  Future<void> deleteRound(String id) async {
    final rounds = await getRounds();
    final newRounds = rounds.where((r) => r.id != id).toList();
    
    await _prefs?.setStringList(
      _keyRounds,
      newRounds.map((r) => jsonEncode(r.toMap())).toList(),
    );
  }

  // Stats methods
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
    
    final totalScores = completedRounds.fold<int>(0, (sum, round) => sum + round.totalScore);
    final averageScore = totalScores / completedRounds.length;
    
    final bestRound = completedRounds.reduce((a, b) => a.totalScore < b.totalScore ? a : b);
    
    // Calculate putting stats
    int totalPutts = 0;
    int fairwayHits = 0;
    int fairwayAttempts = 0;
    int girHits = 0;
    int totalHoles = 0;
    
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
    
    // Calculate scoring distribution
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeys = 0;
    int triplePlus = 0;
    
    for (final round in completedRounds) {
      for (final score in round.scores) {
        if (score.strokes > 0) {
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