import 'package:flutter/material.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:intl/intl.dart';

class RoundSummaryCard extends StatelessWidget {
  final Round round;
  final VoidCallback? onTap;

  const RoundSummaryCard({
    Key? key,
    required this.round,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course name and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      round.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(round.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Score and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sports_golf,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        round.isCompleted
                            ? 'Completed'
                            : 'In Progress',
                        style: TextStyle(
                          color: round.isCompleted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  _buildScoreDisplay(context),
                ],
              ),
              const SizedBox(height: 16),
              
              // Front/Back nine scores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNineHoleScore('Front 9', round.frontNineScore, round.getParForHoles(1, 9)),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildNineHoleScore('Back 9', round.backNineScore, round.getParForHoles(10, 18)),
                ],
              ),
              
              // Weather and notes if available
              if (round.weather.isNotEmpty || round.notes.isNotEmpty) ...[
                const Divider(height: 24),
                if (round.weather.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        round.weather,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                if (round.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          round.notes,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context) {
    if (!round.isCompleted || round.totalScore == 0) {
      return const Text('N/A');
    }

    final scoreString = round.scoreString;
    final totalScore = round.totalScore;
    
    final Color scoreColor = round.relativeToPar < 0
        ? Colors.green
        : round.relativeToPar > 0
            ? Colors.red
            : Colors.black;
    
    return Row(
      children: [
        Text(
          scoreString,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalScore)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNineHoleScore(String label, int score, int par) {
    if (score == 0) {
      return Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text('-'),
        ],
      );
    }

    final diff = score - par;
    final diffStr = diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff');
    
    final Color scoreColor = diff < 0
        ? Colors.green
        : diff > 0
            ? Colors.red
            : Colors.black;
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              '$score',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              diffStr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scoreColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
