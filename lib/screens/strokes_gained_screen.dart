import 'package:flutter/material.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/services/strokes_gained_service.dart';
import 'package:golf_stat_tracker/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StrokesGainedScreen extends StatefulWidget {
  const StrokesGainedScreen({Key? key}) : super(key: key);

  @override
  State<StrokesGainedScreen> createState() => _StrokesGainedScreenState();
}

class _StrokesGainedScreenState extends State<StrokesGainedScreen> {
  int _selectedTimePeriod = 0; // 0 = all time, 30 = last 30 days, 90 = last 90 days
  int _selectedChartIndex = 0; // 0 = total, 1 = components
  
  List<StrokesGainedData> _strokesGainedData = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateStrokesGained();
    });
  }
  
  // Calculate strokes gained for all rounds in the selected time period
  void _calculateStrokesGained() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final roundProvider = Provider.of<RoundProvider>(context, listen: false);
    
    if (playerProvider.currentPlayer == null) return;
    
    final playerId = playerProvider.currentPlayer!.id;
    final rounds = roundProvider.rounds;
    
    // Filter rounds by time period if needed
    final filteredRounds = _filterRoundsByTimePeriod(rounds);
    
    // Calculate strokes gained for each round
    final data = filteredRounds.map((round) {
      return StrokesGainedService.calculateRoundStrokesGained(round, playerId);
    }).toList();
    
    setState(() {
      _strokesGainedData = data;
    });
  }
  
  // Filter rounds by selected time period
  List<Round> _filterRoundsByTimePeriod(List<Round> rounds) {
    if (_selectedTimePeriod == 0) {
      return rounds; // All time
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedTimePeriod));
    return rounds.where((round) => round.date.isAfter(cutoffDate)).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strokes Gained'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Period:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('All Time'),
                    ),
                    ButtonSegment<int>(
                      value: 30,
                      label: Text('30 Days'),
                    ),
                    ButtonSegment<int>(
                      value: 90,
                      label: Text('90 Days'),
                    ),
                  ],
                  selected: {_selectedTimePeriod},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedTimePeriod = selected.first;
                    });
                    _calculateStrokesGained();
                  },
                ),
              ],
            ),
          ),
          
          // Summary stats
          if (_strokesGainedData.isNotEmpty) ...[
            _buildStrokesGainedSummary(),
            
            // Chart type selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Total'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Components'),
                      ),
                    ],
                    selected: {_selectedChartIndex},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selectedChartIndex = selected.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Charts
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _selectedChartIndex == 0
                    ? _buildTotalStrokesGainedChart()
                    : _buildComponentsChart(),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'No rounds found for this time period.\nPlay a round to see strokes gained statistics.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Summary of strokes gained stats
  Widget _buildStrokesGainedSummary() {
    if (_strokesGainedData.isEmpty) return const SizedBox.shrink();
    
    // Calculate averages
    final int roundsCount = _strokesGainedData.length;
    final double avgTotal = _calculateAverage(
      _strokesGainedData.map((d) => d.total).toList(),
    );
    final double avgDriving = _calculateAverage(
      _strokesGainedData.map((d) => d.driving).toList(),
    );
    final double avgApproach = _calculateAverage(
      _strokesGainedData.map((d) => d.approach).toList(),
    );
    final double avgShortGame = _calculateAverage(
      _strokesGainedData.map((d) => d.shortGame).toList(),
    );
    final double avgPutting = _calculateAverage(
      _strokesGainedData.map((d) => d.putting).toList(),
    );
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Strokes Gained (${roundsCount} rounds)',
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildStrokesGainedRow('Total:', avgTotal),
            _buildStrokesGainedRow('Driving:', avgDriving),
            _buildStrokesGainedRow('Approach:', avgApproach),
            _buildStrokesGainedRow('Short Game:', avgShortGame),
            _buildStrokesGainedRow('Putting:', avgPutting),
          ],
        ),
      ),
    );
  }
  
  // Build a row for strokes gained stat
  Widget _buildStrokesGainedRow(String label, double value) {
    final valueColor = value >= 0 ? Colors.green : Colors.red;
    final valueSign = value >= 0 ? '+' : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$valueSign${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build chart for total strokes gained by round
  Widget _buildTotalStrokesGainedChart() {
    if (_strokesGainedData.isEmpty) return const SizedBox.shrink();
    
    // Sort by date (oldest to newest)
    final sortedData = List<StrokesGainedData>.from(_strokesGainedData)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Create spots for line chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedData[i].total));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Total Strokes Gained by Round',
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < sortedData.length && value.toInt() % 5 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(sortedData[value.toInt()].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
              ],
              minY: _findMinY(spots),
              maxY: _findMaxY(spots),
            ),
          ),
        ),
      ],
    );
  }
  
  // Build chart for strokes gained components
  Widget _buildComponentsChart() {
    if (_strokesGainedData.isEmpty) return const SizedBox.shrink();
    
    // Calculate averages for each component
    final double avgDriving = _calculateAverage(
      _strokesGainedData.map((d) => d.driving).toList(),
    );
    final double avgApproach = _calculateAverage(
      _strokesGainedData.map((d) => d.approach).toList(),
    );
    final double avgShortGame = _calculateAverage(
      _strokesGainedData.map((d) => d.shortGame).toList(),
    );
    final double avgPutting = _calculateAverage(
      _strokesGainedData.map((d) => d.putting).toList(),
    );
    
    // Create data for bar chart
    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: avgDriving,
            color: avgDriving >= 0 ? Colors.green : Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: avgApproach,
            color: avgApproach >= 0 ? Colors.green : Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: avgShortGame,
            color: avgShortGame >= 0 ? Colors.green : Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: avgPutting,
            color: avgPutting >= 0 ? Colors.green : Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Strokes Gained by Component',
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: _findMaxComponent([avgDriving, avgApproach, avgShortGame, avgPutting]) * 1.2,
              minY: _findMinComponent([avgDriving, avgApproach, avgShortGame, avgPutting]) * 1.2,
              barGroups: barGroups,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Driving'),
                          );
                        case 1:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Approach'),
                          );
                        case 2:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Short'),
                          );
                        case 3:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Putting'),
                          );
                        default:
                          return const SizedBox();
                      }
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper function to calculate average of a list of values
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }
  
  // Helper function to find minimum Y value for chart scaling
  double _findMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return -1;
    double min = spots.first.y;
    for (final spot in spots) {
      if (spot.y < min) min = spot.y;
    }
    return min < 0 ? min * 1.2 : min * 0.8;
  }
  
  // Helper function to find maximum Y value for chart scaling
  double _findMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    double max = spots.first.y;
    for (final spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max > 0 ? max * 1.2 : max * 0.8;
  }
  
  // Helper function to find minimum component value for chart scaling
  double _findMinComponent(List<double> values) {
    if (values.isEmpty) return -1;
    double min = values.first;
    for (final value in values) {
      if (value < min) min = value;
    }
    return min;
  }
  
  // Helper function to find maximum component value for chart scaling
  double _findMaxComponent(List<double> values) {
    if (values.isEmpty) return 1;
    double max = values.first;
    for (final value in values) {
      if (value > max) max = value;
    }
    return max;
  }
}