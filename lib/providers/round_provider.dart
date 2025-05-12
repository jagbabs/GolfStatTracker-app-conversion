import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/services/database_service.dart';
import 'package:uuid/uuid.dart';

class RoundProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  List<Round> _rounds = [];
  Round? _currentRound;
  
  RoundProvider(this._databaseService) {
    _loadRounds();
  }
  
  List<Round> get rounds => _rounds;
  Round? get currentRound => _currentRound;
  
  Future<void> _loadRounds() async {
    try {
      _rounds = await _databaseService.getRounds();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rounds: $e');
    }
  }
  
  Future<void> startNewRound(String playerId, Course course) async {
    try {
      final uuid = const Uuid();
      
      // Create initial hole scores based on course pars
      final holeScores = course.holePars.map((holePar) => 
        HoleScore(
          holeNumber: holePar.holeNumber,
          par: holePar.par,
          strokes: 0, // Initial stroke count is 0 (not entered yet)
          fairwayHit: FairwayHit.notApplicable,
          greenInRegulation: GreenInRegulation.no,
          putts: 0,
          penalties: [],
        )
      ).toList();
      
      final newRound = Round(
        id: uuid.v4(),
        courseId: course.id,
        courseName: course.name,
        playerId: playerId,
        date: DateTime.now(),
        scores: holeScores,
        totalScore: 0,
        totalPar: course.par,
        notes: '',
        weather: '',
        isCompleted: false,
      );
      
      await _databaseService.saveRound(newRound);
      _rounds.add(newRound);
      _currentRound = newRound;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting new round: $e');
    }
  }
  
  Future<void> updateHoleScore(
    String roundId,
    int holeNumber,
    int strokes,
    FairwayHit fairwayHit,
    GreenInRegulation greenInRegulation,
    int putts,
    List<Penalty> penalties,
    String notes,
  ) async {
    try {
      // Find the round to update
      final round = _rounds.firstWhere((r) => r.id == roundId);
      
      // Create updated scores list
      final updatedScores = List<HoleScore>.from(round.scores);
      
      // Find the hole score to update
      final holeIndex = updatedScores.indexWhere((s) => s.holeNumber == holeNumber);
      
      if (holeIndex != -1) {
        updatedScores[holeIndex] = updatedScores[holeIndex].copyWith(
          strokes: strokes,
          fairwayHit: fairwayHit,
          greenInRegulation: greenInRegulation,
          putts: putts,
          penalties: penalties,
          notes: notes,
        );
      }
      
      // Calculate total score
      final totalScore = updatedScores
          .where((score) => score.strokes > 0)
          .fold(0, (sum, score) => sum + score.strokes);
      
      // Check if all holes have scores
      final isCompleted = updatedScores.every((score) => score.strokes > 0);
      
      // Create updated round
      final updatedRound = round.copyWith(
        scores: updatedScores,
        totalScore: totalScore,
        isCompleted: isCompleted,
      );
      
      await _databaseService.saveRound(updatedRound);
      
      // Update in the list
      final roundIndex = _rounds.indexWhere((r) => r.id == roundId);
      if (roundIndex != -1) {
        _rounds[roundIndex] = updatedRound;
      }
      
      // Update current round if it's the one being edited
      if (_currentRound?.id == roundId) {
        _currentRound = updatedRound;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating hole score: $e');
    }
  }
  
  Future<void> updateRoundDetails(
    String roundId,
    DateTime date,
    String notes,
    String weather,
  ) async {
    try {
      final round = _rounds.firstWhere((r) => r.id == roundId);
      
      final updatedRound = round.copyWith(
        date: date,
        notes: notes,
        weather: weather,
      );
      
      await _databaseService.saveRound(updatedRound);
      
      final roundIndex = _rounds.indexWhere((r) => r.id == roundId);
      if (roundIndex != -1) {
        _rounds[roundIndex] = updatedRound;
      }
      
      if (_currentRound?.id == roundId) {
        _currentRound = updatedRound;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating round details: $e');
    }
  }
  
  Future<void> completeRound(String roundId) async {
    try {
      final round = _rounds.firstWhere((r) => r.id == roundId);
      
      if (round.scores.any((score) => score.strokes == 0)) {
        throw Exception('Cannot complete round. Some holes have no score.');
      }
      
      final updatedRound = round.copyWith(
        isCompleted: true,
      );
      
      await _databaseService.saveRound(updatedRound);
      
      final roundIndex = _rounds.indexWhere((r) => r.id == roundId);
      if (roundIndex != -1) {
        _rounds[roundIndex] = updatedRound;
      }
      
      if (_currentRound?.id == roundId) {
        _currentRound = updatedRound;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing round: $e');
      rethrow;
    }
  }
  
  Future<void> deleteRound(String id) async {
    try {
      await _databaseService.deleteRound(id);
      
      _rounds.removeWhere((r) => r.id == id);
      
      if (_currentRound?.id == id) {
        _currentRound = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting round: $e');
    }
  }
  
  void setCurrentRound(Round round) {
    _currentRound = round;
    notifyListeners();
  }
  
  Future<List<Round>> getRoundsForPlayer(String playerId) async {
    try {
      return await _databaseService.getRounds(playerId: playerId);
    } catch (e) {
      debugPrint('Error getting rounds for player: $e');
      return [];
    }
  }
  
  Future<Round?> getRound(String id) async {
    try {
      return await _databaseService.getRound(id);
    } catch (e) {
      debugPrint('Error getting round: $e');
      return null;
    }
  }
}
