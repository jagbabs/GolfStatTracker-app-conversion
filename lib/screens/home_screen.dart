import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/screens/course_management_screen.dart';
import 'package:golf_stat_tracker/screens/player_profile_screen.dart';
import 'package:golf_stat_tracker/screens/round_entry_screen.dart';
import 'package:golf_stat_tracker/screens/round_history_screen.dart';
import 'package:golf_stat_tracker/screens/statistics_screen.dart';
import 'package:golf_stat_tracker/utils/constants.dart';
import 'package:golf_stat_tracker/widgets/round_summary_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardTab(),
    const RoundHistoryScreen(),
    const StatisticsScreen(),
    const PlayerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Golf Stat Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoundEntryScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

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

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner with Course Image
              Stack(
                children: [
                  // Background Image
                  Image.network(
                    Constants.courseImageUrls[0],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                  // Dark overlay for better text readability
                  Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  // Welcome Text
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${currentPlayer.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Handicap: ${currentPlayer.handicap}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Current Round Section (if any)
              FutureBuilder<List<Round>>(
                future: roundProvider.getRoundsForPlayer(currentPlayer.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final rounds = snapshot.data ?? [];
                  final unfinishedRounds = rounds
                      .where((round) => !round.isCompleted)
                      .toList();

                  if (unfinishedRounds.isNotEmpty) {
                    final currentRound = unfinishedRounds.first;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Continue Your Round',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              roundProvider.setCurrentRound(currentRound);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoundEntryScreen(
                                    roundId: currentRound.id,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentRound.courseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Started on: ${DateFormat.yMMMd().format(currentRound.date)}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Current score: ${currentRound.totalScore > 0 ? '${currentRound.scoreString} (${currentRound.totalScore})' : 'Not started'}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${currentRound.scores.where((s) => s.strokes > 0).length} of ${currentRound.scores.length} holes completed',
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        roundProvider.setCurrentRound(currentRound);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RoundEntryScreen(
                                              roundId: currentRound.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Continue Round'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start a New Round',
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
                                const Text(
                                  'Ready to hit the course?',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RoundEntryScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Start New Round'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Recent Rounds Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Rounds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Round>>(
                      future: roundProvider.getRoundsForPlayer(currentPlayer.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final rounds = snapshot.data ?? [];
                        final completedRounds = rounds
                            .where((round) => round.isCompleted)
                            .toList();

                        if (completedRounds.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No completed rounds yet. Start playing to see your history!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        // Show last 3 completed rounds
                        final recentRounds = completedRounds.take(3).toList();
                        return Column(
                          children: recentRounds.map((round) => 
                            RoundSummaryCard(round: round)
                          ).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Quick Stats Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
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
                        
                        if (stats['roundsPlayed'] == 0) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No stats available yet. Complete a round to see your statistics!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildStatRow(
                                  'Rounds Played', 
                                  '${stats['roundsPlayed']}',
                                ),
                                _buildStatRow(
                                  'Average Score', 
                                  '${stats['averageScore'].toStringAsFixed(1)}',
                                ),
                                _buildStatRow(
                                  'Best Score', 
                                  '${stats['bestScore']}',
                                ),
                                _buildStatRow(
                                  'Avg. Putts/Round', 
                                  '${stats['averagePuttsPerRound'].toStringAsFixed(1)}',
                                ),
                                _buildStatRow(
                                  'Fairways Hit', 
                                  '${stats['fairwayHitPercentage'].toStringAsFixed(1)}%',
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    // Find the parent StatefulWidget to change the tab
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const HomeScreen(initialTab: 2), // 2 is the index for the Stats tab
                                      ),
                                    );
                                  },
                                  child: const Text('View Detailed Stats'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
}
