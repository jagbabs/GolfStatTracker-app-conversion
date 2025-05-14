import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/player.dart';
import 'package:golf_stat_tracker/services/database_service.dart';
import 'package:golf_stat_tracker/services/web_database_service.dart';
import 'package:golf_stat_tracker/services/google_sheets_service.dart';
import 'package:uuid/uuid.dart';

class PlayerProvider with ChangeNotifier {
  dynamic _databaseService; // Can be DatabaseService, WebDatabaseService, or GoogleSheetsService
  List<Player> _players = [];
  Player? _currentPlayer;
  
  // Method to update the database service when storage type changes
  void updateDatabaseService(dynamic newService) {
    _databaseService = newService;
    _loadPlayers();
  }
  
  PlayerProvider(this._databaseService) {
    _loadPlayers();
  }
  
  List<Player> get players => _players;
  Player? get currentPlayer => _currentPlayer;
  
  Future<void> _loadPlayers() async {
    try {
      _players = await _databaseService.getPlayers();
      if (_players.isNotEmpty && _currentPlayer == null) {
        _currentPlayer = _players.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading players: $e');
    }
  }
  
  Future<void> addPlayer(String name, String email) async {
    try {
      final uuid = const Uuid();
      final newPlayer = Player(
        id: uuid.v4(),
        name: name,
        email: email,
        handicap: 0,
        avatarUrl: '',
        joinDate: DateTime.now(),
      );
      
      await _databaseService.savePlayer(newPlayer);
      _players.add(newPlayer);
      
      if (_players.length == 1) {
        _currentPlayer = newPlayer;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding player: $e');
    }
  }
  
  Future<void> updatePlayer(Player player) async {
    try {
      await _databaseService.savePlayer(player);
      
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _players[index] = player;
      }
      
      if (_currentPlayer?.id == player.id) {
        _currentPlayer = player;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating player: $e');
    }
  }
  
  Future<void> deletePlayer(String id) async {
    try {
      await _databaseService.deletePlayer(id);
      
      _players.removeWhere((p) => p.id == id);
      
      if (_currentPlayer?.id == id) {
        _currentPlayer = _players.isNotEmpty ? _players.first : null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting player: $e');
    }
  }
  
  void setCurrentPlayer(Player player) {
    _currentPlayer = player;
    notifyListeners();
  }
  
  Future<void> updateHandicap(String id, int handicap) async {
    try {
      final player = _players.firstWhere((p) => p.id == id);
      final updatedPlayer = player.copyWith(handicap: handicap);
      
      await updatePlayer(updatedPlayer);
    } catch (e) {
      debugPrint('Error updating handicap: $e');
    }
  }
  
  Future<Map<String, dynamic>> getPlayerStats() async {
    if (_currentPlayer == null) {
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
    
    return await _databaseService.getPlayerStats(_currentPlayer!.id);
  }
}
