import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/widgets/stat_card.dart';
import 'package:golf_stat_tracker/widgets/score_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, RoundProvider>(
      builder: (context, playerProvider, roundProvider, child) {
        final currentPlayer = playerProvider.currentPlayer;
        
        if (currentPlayer == null) {
          return const Center(
            child: Text('No player profile found. Create one in the Profile tab.'),
          );
        }
        
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Scoring'),
                Tab(text: 'Trends'),
              ],
              labelColor: Theme.of(context).primaryColor,
              indicatorColor: Theme.of(context).primaryColor,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(playerProvider),
                  _buildScoringTab(playerProvider, roundProvider),
                  _buildTrendsTab(playerProvider, roundProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewTab(PlayerProvider playerProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: playerProvider.getPlayerStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final stats = snapshot.data ?? {};
        final roundsPlayed = stats['roundsPlayed'] ?? 0;
        
        if (roundsPlayed == 0) {
          return _buildNoStatsView();
        }
        
        final parBreakdown = stats['parBreakdownPercent'] as Map<String, dynamic>? ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key stats row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Rounds',
                      value: '$roundsPlayed',
                      icon: Icons.sports_golf,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Avg Score',
                      value: '${stats['averageScore']?.toStringAsFixed(1) ?? "N/A"}',
                      icon: Icons.score,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Best',
                      value: '${stats['bestScore'] ?? "N/A"}',
                      icon: Icons.emoji_events,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Shot statistics
              const Text(
                'Shot Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatProgressBar(
                        'Fairways Hit',
                        stats['fairwayHitPercentage'] ?? 0,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildStatProgressBar(
                        'Greens in Regulation',
                        stats['girPercentage'] ?? 0,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Avg. Putts per Round',
                        '${stats['averagePuttsPerRound']?.toStringAsFixed(1) ?? "N/A"}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Par breakdown
              const Text(
                'Scoring Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatProgressBar(
                        'Eagles or Better',
                        parBreakdown['eagles'] ?? 0,
                        Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildStatProgressBar(
                        'Birdies',
                        parBreakdown['birdies'] ?? 0,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildStatProgressBar(
                        'Pars',
                        parBreakdown['pars'] ?? 0,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatProgressBar(
                        'Bogeys',
                        parBreakdown['bogeys'] ?? 0,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildStatProgressBar(
                        'Double Bogeys',
                        parBreakdown['doubleBogeys'] ?? 0,
                        Colors.deepOrange,
                      ),
                      const SizedBox(height: 12),
                      _buildStatProgressBar(
                        'Triple Bogeys+',
                        parBreakdown['triplePlus'] ?? 0,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoringTab(PlayerProvider playerProvider, RoundProvider roundProvider) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        roundProvider.getRoundsForPlayer(playerProvider.currentPlayer!.id),
        playerProvider.getPlayerStats(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final data = snapshot.data;
        if (data == null || data.isEmpty || data.length < 2) {
          return _buildNoStatsView();
        }
        
        final rounds = data[0] as List;
        final stats = data[1] as Map<String, dynamic>;
        
        if (rounds.isEmpty) {
          return _buildNoStatsView();
        }
        
        final completedRounds = rounds.where((r) => r.isCompleted).toList();
        if (completedRounds.isEmpty) {
          return _buildNoStatsView();
        }
        
        // Get last 10 rounds for chart
        final recentRounds = completedRounds.take(10).toList().reversed.toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent scores chart
              const Text(
                'Recent Scores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 200,
                    child: ScoreChart(rounds: recentRounds.cast<Round>()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Front/Back nine performance
              const Text(
                'Front vs. Back Nine',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Front Nine'),
                          Text(
                            '${_calculateAverageFrontNine(completedRounds).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Back Nine'),
                          Text(
                            '${_calculateAverageBackNine(completedRounds).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Par performance
              const Text(
                'Performance by Par',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildParPerformanceRow('Par 3', _calculateAverageParPerformance(completedRounds, 3)),
                      const Divider(),
                      _buildParPerformanceRow('Par 4', _calculateAverageParPerformance(completedRounds, 4)),
                      const Divider(),
                      _buildParPerformanceRow('Par 5', _calculateAverageParPerformance(completedRounds, 5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab(PlayerProvider playerProvider, RoundProvider roundProvider) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        roundProvider.getRoundsForPlayer(playerProvider.currentPlayer!.id),
        playerProvider.getPlayerStats(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final data = snapshot.data;
        if (data == null || data.isEmpty || data.length < 2) {
          return _buildNoStatsView();
        }
        
        final rounds = data[0] as List;
        
        if (rounds.isEmpty || rounds.length < 5) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Not enough data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Play at least 5 rounds to see trends',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final completedRounds = rounds.where((r) => r.isCompleted).toList();
        
        if (completedRounds.length < 5) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Not enough data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete at least 5 rounds to see trends',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Calculate trends
        final scoreTrend = _calculateTrend(completedRounds, (round) => round.totalScore.toDouble());
        final puttsTrend = _calculateTrend(
          completedRounds,
          (round) => round.scores.fold(0, (sum, score) => sum + score.putts).toDouble(),
        );
        final fairwaysTrend = _calculateTrend(
          completedRounds,
          (round) {
            final fairwayShots = round.scores.where((s) => s.fairwayHit != null).length;
            if (fairwayShots == 0) return 0.0;
            final fairwaysHit = round.scores.where((s) => s.fairwayHit == FairwayHit.yes).length;
            return (fairwaysHit / fairwayShots) * 100;
          },
        );
        final girTrend = _calculateTrend(
          completedRounds,
          (round) {
            final totalHoles = round.scores.length;
            if (totalHoles == 0) return 0.0;
            final girsHit = round.scores.where((s) => s.greenInRegulation == GreenInRegulation.yes).length;
            return (girsHit / totalHoles) * 100;
          },
        );
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTrendCard(
                'Total Score',
                scoreTrend,
                isLowerBetter: true,
              ),
              _buildTrendCard(
                'Putts per Round',
                puttsTrend,
                isLowerBetter: true,
              ),
              _buildTrendCard(
                'Fairways Hit %',
                fairwaysTrend,
                isLowerBetter: false,
              ),
              _buildTrendCard(
                'Greens in Regulation %',
                girTrend,
                isLowerBetter: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generateAnalysis(scoreTrend, puttsTrend, fairwaysTrend, girTrend),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Focus Areas:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_generateFocusAreas(puttsTrend, fairwaysTrend, girTrend)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoStatsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Statistics Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a round to see your statistics',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Change to the first tab (home)
              final bottomNavBar = Navigator.of(context).widget as Scaffold;
              if (bottomNavBar.bottomNavigationBar is BottomNavigationBar) {
                final navBar = bottomNavBar.bottomNavigationBar as BottomNavigationBar;
                navBar.onTap!(0); // Navigate to home tab
              }
            },
            child: const Text('Start a Round'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParPerformanceRow(String parType, double avgRelativeToPar) {
    final formattedValue = avgRelativeToPar == 0
        ? 'Even'
        : avgRelativeToPar > 0
            ? '+${avgRelativeToPar.toStringAsFixed(2)}'
            : avgRelativeToPar.toStringAsFixed(2);
    
    final valueColor = avgRelativeToPar < 0
        ? Colors.green
        : avgRelativeToPar > 0
            ? Colors.red
            : Colors.black;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            parType,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, double trendValue, {required bool isLowerBetter}) {
    // Determine if trend is positive (improving) or negative (declining)
    final bool isImproving = isLowerBetter ? trendValue < 0 : trendValue > 0;
    final bool isSignificant = trendValue.abs() > 0.5;
    
    // Choose color and icon based on trend
    final Color trendColor = isImproving 
        ? Colors.green 
        : (trendValue == 0 ? Colors.grey : Colors.red);
    
    final IconData trendIcon = isImproving
        ? (isSignificant ? Icons.trending_up : Icons.trending_up)
        : (trendValue == 0 ? Icons.trending_flat : Icons.trending_down);
    
    // Format trend value for display
    final String trendDisplay = trendValue == 0
        ? 'No change'
        : (trendValue > 0 ? '+' : '') + trendValue.toStringAsFixed(2);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Text(
                  trendDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  trendIcon,
                  color: trendColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageFrontNine(List rounds) {
    if (rounds.isEmpty) return 0;
    
    final totalFrontNine = rounds.fold<int>(0, (sum, round) => sum + (round.frontNineScore as int));
    return totalFrontNine / rounds.length;
  }

  double _calculateAverageBackNine(List rounds) {
    if (rounds.isEmpty) return 0;
    
    final totalBackNine = rounds.fold<int>(0, (sum, round) => sum + (round.backNineScore as int));
    return totalBackNine / rounds.length;
  }

  double _calculateAverageParPerformance(List rounds, int par) {
    if (rounds.isEmpty) return 0;
    
    double totalRelativeToPar = 0;
    int totalHolesOfThisPar = 0;
    
    for (final round in rounds) {
      for (final score in round.scores) {
        if (score.par == par) {
          totalRelativeToPar += (score.strokes - score.par);
          totalHolesOfThisPar++;
        }
      }
    }
    
    if (totalHolesOfThisPar == 0) return 0;
    return totalRelativeToPar / totalHolesOfThisPar;
  }

  double _calculateTrend(List rounds, double Function(dynamic round) extractor) {
    if (rounds.length < 5) return 0;
    
    // Use last 5 rounds to calculate trend
    final recentRounds = rounds.take(5).toList();
    final values = recentRounds.map(extractor).toList();
    
    // Simple linear regression to find slope (trend)
    // x: 0, 1, 2, 3, 4 (Round indexes)
    // y: values from rounds
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    
    for (int i = 0; i < values.length; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }
    
    final n = values.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    return slope;
  }

  String _generateAnalysis(double scoreTrend, double puttsTrend, double fairwaysTrend, double girTrend) {
    if (scoreTrend < -0.5) {
      return 'Your scores are trending down nicely! Keep up the good work.';
    } else if (scoreTrend > 0.5) {
      return 'Your scores have been trending higher recently. Let\'s focus on improving key areas.';
    } else {
      return 'Your scores have been consistent lately. Let\'s work on specific areas to improve.';
    }
  }

  List<Widget> _generateFocusAreas(double puttsTrend, double fairwaysTrend, double girTrend) {
    final List<Widget> focusAreas = [];
    
    // Add focus areas based on trends
    if (puttsTrend > 0.2) {
      focusAreas.add(
        const ListTile(
          leading: Icon(Icons.flag, color: Colors.red),
          title: Text('Putting'),
          subtitle: Text('Work on distance control and reading greens'),
          dense: true,
        ),
      );
    }
    
    if (fairwaysTrend < -0.5) {
      focusAreas.add(
        const ListTile(
          leading: Icon(Icons.flag, color: Colors.red),
          title: Text('Tee Shots'),
          subtitle: Text('Focus on accuracy off the tee'),
          dense: true,
        ),
      );
    }
    
    if (girTrend < -0.5) {
      focusAreas.add(
        const ListTile(
          leading: Icon(Icons.flag, color: Colors.red),
          title: Text('Approach Shots'),
          subtitle: Text('Practice distance control with your irons'),
          dense: true,
        ),
      );
    }
    
    // If no specific areas to focus on
    if (focusAreas.isEmpty) {
      focusAreas.add(
        const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Overall Game'),
          subtitle: Text('Keep practicing consistently across all areas'),
          dense: true,
        ),
      );
    }
    
    return focusAreas;
  }
}
