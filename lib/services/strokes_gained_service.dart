import 'package:flutter/foundation.dart';
import 'package:golf_stat_tracker/models/round.dart';

class StrokesGainedData {
  final double total;
  final double driving;
  final double approach;
  final double shortGame;
  final double putting;
  final DateTime date;
  final String roundId;
  final String userId;

  StrokesGainedData({
    required this.total,
    required this.driving,
    required this.approach,
    required this.shortGame,
    required this.putting,
    required this.date,
    required this.roundId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'driving': driving,
      'approach': approach,
      'shortGame': shortGame,
      'putting': putting,
      'date': date.toIso8601String(),
      'roundId': roundId,
      'userId': userId,
    };
  }

  factory StrokesGainedData.fromMap(Map<String, dynamic> map) {
    return StrokesGainedData(
      total: map['total'] ?? 0.0,
      driving: map['driving'] ?? 0.0,
      approach: map['approach'] ?? 0.0,
      shortGame: map['shortGame'] ?? 0.0,
      putting: map['putting'] ?? 0.0,
      date: DateTime.parse(map['date']),
      roundId: map['roundId'],
      userId: map['userId'],
    );
  }
}

class StrokesGainedService {
  // Baseline values based on real golf data
  // These values represent the expected number of strokes to hole out from various situations
  static final Map<String, Map<int, double>> _baselineValues = {
    // Expected strokes from tee based on distance
    'tee': {
      100: 2.92,
      120: 2.99,
      140: 2.97,
      160: 2.99,
      180: 3.05,
      200: 3.12,
      220: 3.17,
      240: 3.25,
      260: 3.45,
      280: 3.65,
      300: 3.71,
      320: 3.79,
      340: 3.86,
      360: 3.92,
      380: 3.96,
      400: 3.99,
      420: 4.02,
      440: 4.08,
      460: 4.17,
      480: 4.28,
      500: 4.41,
      520: 4.54,
      540: 4.65,
      560: 4.74,
      580: 4.79,
      600: 4.82,
    },
    // Expected strokes from fairway based on distance
    'fairway': {
      20: 2.40,
      40: 2.60,
      60: 2.70,
      80: 2.75,
      100: 2.80,
      120: 2.85,
      140: 2.91,
      160: 2.98,
      180: 3.08,
      200: 3.19,
      220: 3.32,
      240: 3.45,
      260: 3.58,
      280: 3.69,
      300: 3.78,
      320: 3.84,
      340: 3.88,
      360: 3.95,
      380: 4.03,
      400: 4.11,
      420: 4.15,
      440: 4.20,
      460: 4.29,
      480: 4.40,
      500: 4.53,
      520: 4.66,
      540: 4.78,
      560: 4.86,
      580: 4.91,
      600: 4.94,
    },
    // Expected strokes from rough based on distance
    'rough': {
      20: 2.59,
      40: 2.78,
      60: 2.91,
      80: 2.96,
      100: 3.02,
      120: 3.08,
      140: 3.15,
      160: 3.23,
      180: 3.31,
      200: 3.42,
      220: 3.53,
      240: 3.64,
      260: 3.74,
      280: 3.83,
      300: 3.90,
      320: 3.95,
      340: 4.02,
      360: 4.11,
      380: 4.21,
      400: 4.30,
      420: 4.34,
      440: 4.39,
      460: 4.48,
      480: 4.59,
      500: 4.72,
      520: 4.85,
      540: 4.97,
      560: 5.05,
      580: 5.10,
      600: 5.13,
    },
    // Expected strokes from sand based on distance
    'sand': {
      20: 2.53,
      40: 2.82,
      60: 3.15,
      80: 3.24,
      100: 3.23,
      120: 3.21,
      140: 3.22,
      160: 3.28,
      180: 3.40,
      200: 3.55,
      220: 3.70,
      240: 3.84,
      260: 3.93,
      280: 4.00,
      300: 4.04,
      320: 4.12,
      340: 4.26,
      360: 4.41,
      380: 4.55,
      400: 4.69,
      420: 4.73,
      440: 4.78,
      460: 4.87,
      480: 4.98,
      500: 5.11,
      520: 5.24,
      540: 5.36,
      560: 5.44,
      580: 5.49,
      600: 5.52,
    },
    // Expected strokes from recovery areas
    'recovery': {
      100: 3.80,
      120: 3.78,
      140: 3.80,
      160: 3.81,
      180: 3.82,
      200: 3.87,
      220: 3.92,
      240: 3.97,
      260: 4.03,
      280: 4.10,
      300: 4.20,
      320: 4.31,
      340: 4.44,
      360: 4.56,
      380: 4.66,
      400: 4.75,
      420: 4.79,
      440: 4.84,
      460: 4.93,
      480: 5.04,
      500: 5.17,
      520: 5.30,
      540: 5.42,
      560: 5.50,
      580: 5.55,
      600: 5.58,
    },
    // Expected strokes on the green based on distance (in feet)
    'green': {
      3: 1.04,
      4: 1.13,
      5: 1.23,
      6: 1.34,
      7: 1.42,
      8: 1.50,
      9: 1.56,
      10: 1.61,
      15: 1.78,
      20: 1.87,
      30: 1.98,
      40: 2.06,
      50: 2.14,
      60: 2.21,
      90: 2.40,
    }
  };

  // Helper function to get the nearest baseline value
  static double _getNearestValue(int distance, Map<int, double> location) {
    // Find the nearest distance bracket
    final distances = location.keys.toList()..sort();
    
    // Find the closest distance value (rounding down to previous bracket)
    int closestDistance = distances.first;
    for (final dist in distances) {
      if (dist <= distance) {
        closestDistance = dist;
      } else {
        break;
      }
    }
    
    return location[closestDistance] ?? 0.0;
  }

  // Calculate strokes gained for a specific shot
  static double calculateStrokesGained({
    required String shotType,
    required int distanceToTarget,
    required String outcome,
    required int par,
  }) {
    if (distanceToTarget <= 0) return 0;

    // For tee shots
    if (shotType == 'tee') {
      // Get expected strokes from this distance
      final expectedStrokes = _getNearestValue(distanceToTarget, _baselineValues['tee']!);
      
      // Calculate strokes gained based on where the ball landed and its new location
      double nextShotExpectedStrokes = 0;
      
      if (outcome == 'fairway') {
        // Get expected strokes for the next shot from fairway
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.7).round(), _baselineValues['fairway']!);
        return expectedStrokes - nextShotExpectedStrokes - 1; // -1 for the shot just taken
      } 
      else if (outcome == 'rough') {
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.7).round(), _baselineValues['rough']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'bunker') {
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.7).round(), _baselineValues['sand']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'green') {
        // If somehow driver to green, big advantage
        nextShotExpectedStrokes = _getNearestValue(20, _baselineValues['green']!); // Assume 20 feet putt
        return expectedStrokes - nextShotExpectedStrokes - 1;
      }
      else if (outcome == 'hazard') {
        return -1.0; // Penalty
      }
      else if (outcome == 'ob') {
        return -2.0; // Stroke and distance penalty
      }
      
      return 0; // Default if outcome not recognized
    } 
    
    // For approach shots
    else if (shotType == 'approach') {
      // Different sources based on where the shot is played from
      Map<int, double> sourceLocation = _baselineValues['fairway']!; // Default to fairway
      if (outcome == 'rough') sourceLocation = _baselineValues['rough']!;
      else if (outcome == 'bunker' || outcome == 'sand') sourceLocation = _baselineValues['sand']!;
      else if (outcome == 'recovery') sourceLocation = _baselineValues['recovery']!;
      
      // Get expected strokes from this distance
      final expectedStrokes = _getNearestValue(distanceToTarget, sourceLocation);
      
      // Calculate next shot expectation based on outcome
      double nextShotExpectedStrokes = 0;
      
      if (outcome == 'green') {
        // If on green, next shot is a putt
        // Convert from yards to feet (very rough approximation for putt distance)
        final puttDistanceInFeet = (distanceToTarget * 0.3).round().clamp(3, 90); // Scale down and cap at 90 feet
        nextShotExpectedStrokes = _getNearestValue(puttDistanceInFeet, _baselineValues['green']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'fairway') {
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.5).round(), _baselineValues['fairway']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'rough') {
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.5).round(), _baselineValues['rough']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'bunker' || outcome == 'sand') {
        nextShotExpectedStrokes = _getNearestValue((distanceToTarget * 0.5).round(), _baselineValues['sand']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      }
      else if (outcome == 'hazard') {
        return -1.0; // Penalty
      }
      else if (outcome == 'ob') {
        return -2.0; // Stroke and distance penalty
      }
      
      return 0;
    } 
    
    // For short game (chips and bunker shots)
    else if (shotType == 'chip' || shotType == 'bunker') {
      // Source depends on shot type
      final sourceLocation = shotType == 'bunker' ? _baselineValues['sand']! : _baselineValues['recovery']!;
      
      // Expected shots for chip or bunker shot
      // Since our baseline data starts at 20 yards, use that as minimum
      final expectedStrokes = _getNearestValue(distanceToTarget.clamp(20, 600), sourceLocation);
      
      if (outcome == 'green') {
        // If the chip/bunker shot is on the green, outcome depends on proximity
        // Convert yards to feet for putting (approximate)
        final puttDistanceInFeet = (distanceToTarget * 3).clamp(3, 60); // Cap at 60 feet for a chip
        final nextShotExpectedStrokes = _getNearestValue(puttDistanceInFeet, _baselineValues['green']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'holed') {
        // Holed shots are excellent
        return expectedStrokes - 1; // Saved all expected strokes except the one taken
      }
      else {
        // Missing with a chip or bunker shot is bad
        return -0.5;
      }
    } 
    
    // For putts
    else if (shotType == 'putt') {
      // For putts, expected strokes depend on the length in feet
      final expectedStrokes = _getNearestValue(distanceToTarget.clamp(3, 90), _baselineValues['green']!);
      
      if (outcome == 'holed') {
        return expectedStrokes - 1; // Gained whatever was expected minus the one stroke taken
      } 
      else if (outcome == 'good') {
        // Good lag putt left close for next putt
        const nextPuttDistance = 2; // Assume left about 2 feet
        final nextShotExpectedStrokes = _getNearestValue(nextPuttDistance, _baselineValues['green']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      } 
      else if (outcome == 'poor') {
        // Poor putt left work to do
        const nextPuttDistance = 5; // Assume left about 5 feet
        final nextShotExpectedStrokes = _getNearestValue(nextPuttDistance, _baselineValues['green']!);
        return expectedStrokes - nextShotExpectedStrokes - 1;
      }
      
      return 0; // Default for putts
    }
    
    return 0; // Default catch-all
  }

  // Calculate strokes gained for a round with detailed shot data
  static StrokesGainedData calculateRoundStrokesGained(Round round, String userId) {
    // For now, generate estimated strokes gained based on scorecard data
    // In a full implementation, this would use detailed shot-by-shot data
    
    double drivingStrokesGained = 0.0;
    double approachStrokesGained = 0.0;
    double shortGameStrokesGained = 0.0;
    double puttingStrokesGained = 0.0;
    
    // Process each hole's data
    for (final score in round.scores) {
      final par = score.par;
      
      if (score.strokes == 0) continue; // Skip holes not played
      
      // Estimate strokes gained for each shot category based on scoring data
      // Driving
      if (par >= 4) { // Only consider driving on par 4s and 5s
        if (score.fairwayHit == FairwayHit.yes) {
          drivingStrokesGained += 0.2; // Good drive
        } else if (score.fairwayHit == FairwayHit.no) {
          drivingStrokesGained -= 0.2; // Poor drive
        }
      }
      
      // Approach
      if (score.greenInRegulation == GreenInRegulation.yes) {
        approachStrokesGained += 0.3; // Good approach
      } else if (score.greenInRegulation == GreenInRegulation.no) {
        approachStrokesGained -= 0.3; // Poor approach
        // If missed green, add estimated short game contribution
        shortGameStrokesGained += (score.strokes - score.putts - par) < 2 ? 0.2 : -0.2;
      }
      
      // Putting
      final expectedPutts = (score.strokes - (par - 2)).clamp(0, 5);
      if (score.putts < expectedPutts) {
        puttingStrokesGained += (expectedPutts - score.putts) * 0.5; // Good putting
      } else if (score.putts > expectedPutts) {
        puttingStrokesGained -= (score.putts - expectedPutts) * 0.5; // Poor putting
      }
    }
    
    // Adjust based on round total score
    final totalPar = round.scores.fold<int>(0, (sum, score) => sum + score.par);
    final totalScore = round.scores.fold<int>(0, (sum, score) => sum + score.strokes);
    final relativeToPar = totalScore - totalPar;
    
    // Scale strokes gained to make sense with overall score
    final totalStrokesGained = -relativeToPar.toDouble(); // Negative relative to par is positive strokes gained
    
    // Make sure components add up roughly to total, maintaining proportions
    double sum = drivingStrokesGained + approachStrokesGained + shortGameStrokesGained + puttingStrokesGained;
    if (sum == 0) {
      // If all components are 0, distribute evenly
      drivingStrokesGained = totalStrokesGained * 0.25;
      approachStrokesGained = totalStrokesGained * 0.25;
      shortGameStrokesGained = totalStrokesGained * 0.25;
      puttingStrokesGained = totalStrokesGained * 0.25;
    } else {
      // Scale components to match total while preserving proportions
      final scaleFactor = totalStrokesGained / sum;
      drivingStrokesGained *= scaleFactor;
      approachStrokesGained *= scaleFactor;
      shortGameStrokesGained *= scaleFactor;
      puttingStrokesGained *= scaleFactor;
    }
    
    return StrokesGainedData(
      total: totalStrokesGained,
      driving: drivingStrokesGained,
      approach: approachStrokesGained,
      shortGame: shortGameStrokesGained,
      putting: puttingStrokesGained,
      date: round.date,
      roundId: round.id,
      userId: userId,
    );
  }
}