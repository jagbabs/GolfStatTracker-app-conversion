import 'package:flutter/material.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:intl/intl.dart';

class ScoreChart extends StatelessWidget {
  final List<Round> rounds;
  final Color primaryColor;
  final Color secondaryColor;

  ScoreChart({
    Key? key,
    required this.rounds,
    this.primaryColor = const Color(0xff2e7d32),
    this.secondaryColor = const Color(0xff4caf50),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const Center(
        child: Text('No round data available'),
      );
    }

    // Sort rounds by date (oldest first)
    final sortedRounds = List<Round>.from(rounds)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Find min and max score for scaling
    int minScore = sortedRounds.first.totalScore;
    int maxScore = sortedRounds.first.totalScore;
    
    for (final round in sortedRounds) {
      if (round.totalScore < minScore) minScore = round.totalScore;
      if (round.totalScore > maxScore) maxScore = round.totalScore;
    }
    
    // Add padding to min/max
    minScore = (minScore - 5).clamp(0, 1000);
    maxScore = (maxScore + 5).clamp(0, 1000);
    
    // Calculate score range
    final scoreRange = maxScore - minScore;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scores Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: sortedRounds.length < 2 
                ? Center(
                    child: Text(
                      'Need at least 2 rounds to display trend',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(
                            sortedRounds.length.clamp(0, 10),
                            (index) {
                              final round = sortedRounds[index];
                              // Calculate height percentage based on score
                              final heightPercentage = scoreRange == 0 
                                ? 0.5 
                                : 1 - ((round.totalScore - minScore) / scoreRange);
                              
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            width: 20,
                                            height: (180 * heightPercentage).clamp(20.0, 180.0),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius: BorderRadius.circular(4),
                                              gradient: LinearGradient(
                                                colors: [
                                                  primaryColor,
                                                  secondaryColor,
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        round.totalScore.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        DateFormat.MMMd().format(round.date),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 8),
            if (sortedRounds.isNotEmpty) ...[
              const Divider(),
              Text(
                'Avg Score: ${_calculateAverageScore(sortedRounds).toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Best Score: ${_findBestScore(sortedRounds)}',
                style: TextStyle(color: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateAverageScore(List<Round> rounds) {
    if (rounds.isEmpty) return 0;
    
    final totalScore = rounds.fold<int>(0, (sum, round) => sum + round.totalScore);
    return totalScore / rounds.length;
  }

  String _findBestScore(List<Round> rounds) {
    if (rounds.isEmpty) return 'N/A';
    
    final bestRound = rounds.reduce((a, b) => a.totalScore < b.totalScore ? a : b);
    return '${bestRound.totalScore} (${DateFormat.yMMMd().format(bestRound.date)})';
  }
}
