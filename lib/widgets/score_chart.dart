import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:intl/intl.dart';

class ScoreChart extends StatelessWidget {
  final List<Round> rounds;
  final double minY;
  final double maxY;
  final Color lineColor;
  final Color gradientColor;

  ScoreChart({
    Key? key,
    required this.rounds,
    this.minY = 0,
    this.maxY = 120,
    this.lineColor = const Color(0xff2e7d32), // Match primary green
    this.gradientColor = const Color(0xff4caf50), // Match secondary green
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

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedRounds.length) {
                  return const SizedBox.shrink();
                }
                
                // Show date for first, last, and some points in between
                if (index == 0 || 
                    index == sortedRounds.length - 1 || 
                    index == (sortedRounds.length / 2).floor()) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat.MMMd().format(sortedRounds[index].date),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        minX: 0,
        maxX: (sortedRounds.length - 1).toDouble(),
        minY: _calculateMinY(sortedRounds),
        maxY: _calculateMaxY(sortedRounds),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final round = sortedRounds[spot.x.toInt()];
                return LineTooltipItem(
                  '${round.totalScore} (${round.scoreString})\n${DateFormat.yMMMd().format(round.date)}',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedRounds.length, (index) {
              return FlSpot(
                index.toDouble(),
                sortedRounds[index].totalScore.toDouble(),
              );
            }),
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  gradientColor.withOpacity(0.3),
                  gradientColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMinY(List<Round> rounds) {
    if (rounds.isEmpty) return minY;
    
    final minScore = rounds
        .map((round) => round.totalScore)
        .reduce((value, element) => value < element ? value : element);
    
    // Return 5 less than the minimum score or the provided minY, whichever is smaller
    return (minScore - 5).toDouble() < minY ? (minScore - 5).toDouble() : minY;
  }

  double _calculateMaxY(List<Round> rounds) {
    if (rounds.isEmpty) return maxY;
    
    final maxScore = rounds
        .map((round) => round.totalScore)
        .reduce((value, element) => value > element ? value : element);
    
    // Return 5 more than the maximum score or the provided maxY, whichever is larger
    return (maxScore + 5).toDouble() > maxY ? (maxScore + 5).toDouble() : maxY;
  }
}
