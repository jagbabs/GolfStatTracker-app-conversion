import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/screens/round_entry_screen.dart';
import 'package:golf_stat_tracker/widgets/round_summary_card.dart';
import 'package:intl/intl.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({Key? key}) : super(key: key);

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  String _filterType = 'All'; // 'All', 'Completed', 'In Progress'
  
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
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterType == 'All',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterType = 'All';
                        });
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: _filterType == 'Completed',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterType = 'Completed';
                        });
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('In Progress'),
                    selected: _filterType == 'In Progress',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filterType = 'In Progress';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Rounds list
            Expanded(
              child: FutureBuilder<List<Round>>(
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
                  
                  if (rounds.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.golf_course, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No rounds played yet.',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Start a new round to see your history!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Filter rounds
                  List<Round> filteredRounds = [];
                  if (_filterType == 'Completed') {
                    filteredRounds = rounds.where((r) => r.isCompleted).toList();
                  } else if (_filterType == 'In Progress') {
                    filteredRounds = rounds.where((r) => !r.isCompleted).toList();
                  } else {
                    filteredRounds = rounds;
                  }
                  
                  // Group rounds by month
                  final groupedRounds = <String, List<Round>>{};
                  
                  for (final round in filteredRounds) {
                    final monthYear = DateFormat('MMMM yyyy').format(round.date);
                    
                    if (!groupedRounds.containsKey(monthYear)) {
                      groupedRounds[monthYear] = [];
                    }
                    
                    groupedRounds[monthYear]!.add(round);
                  }
                  
                  final sortedMonths = groupedRounds.keys.toList()
                    ..sort((a, b) {
                      // Sort in descending order (most recent first)
                      final aDate = DateFormat('MMMM yyyy').parse(a);
                      final bDate = DateFormat('MMMM yyyy').parse(b);
                      return bDate.compareTo(aDate);
                    });
                  
                  if (filteredRounds.isEmpty) {
                    return Center(
                      child: Text('No ${_filterType.toLowerCase()} rounds found.'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: sortedMonths.length,
                    itemBuilder: (context, index) {
                      final month = sortedMonths[index];
                      final monthRounds = groupedRounds[month]!;
                      
                      // Sort rounds within month (newest first)
                      monthRounds.sort((a, b) => b.date.compareTo(a.date));
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0, 
                              right: 16.0, 
                              top: 16.0, 
                              bottom: 8.0
                            ),
                            child: Text(
                              month,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ...monthRounds.map((round) {
                            return Dismissible(
                              key: Key(round.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Round'),
                                    content: const Text(
                                      'Are you sure you want to delete this round? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                roundProvider.deleteRound(round.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Round deleted'),
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () {
                                  if (!round.isCompleted) {
                                    roundProvider.setCurrentRound(round);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoundEntryScreen(
                                          roundId: round.id,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showRoundDetailsDialog(context, round);
                                  }
                                },
                                child: RoundSummaryCard(round: round),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showRoundDetailsDialog(BuildContext context, Round round) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(round.courseName),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Round summary
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat.yMMMMd().format(round.date)),
                  ),
                  ListTile(
                    title: const Text('Total Score'),
                    subtitle: Text('${round.totalScore} (${round.scoreString})'),
                  ),
                  ListTile(
                    title: const Text('Front Nine'),
                    subtitle: Text('${round.frontNineScore}'),
                  ),
                  ListTile(
                    title: const Text('Back Nine'),
                    subtitle: Text('${round.backNineScore}'),
                  ),
                  if (round.weather.isNotEmpty)
                    ListTile(
                      title: const Text('Weather'),
                      subtitle: Text(round.weather),
                    ),
                  if (round.notes.isNotEmpty)
                    ListTile(
                      title: const Text('Notes'),
                      subtitle: Text(round.notes),
                    ),
                  
                  const Divider(),
                  const Text(
                    'Hole-by-Hole Scores',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Hole scores table
                  DataTable(
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(label: Text('Hole')),
                      DataColumn(label: Text('Par')),
                      DataColumn(label: Text('Score')),
                      DataColumn(label: Text('+/-')),
                    ],
                    rows: round.scores.map((score) {
                      final relativeToPar = score.relativeToPar;
                      final relativeToParText = relativeToPar == 0
                          ? 'E'
                          : relativeToPar > 0
                              ? '+$relativeToPar'
                              : '$relativeToPar';
                      
                      return DataRow(
                        cells: [
                          DataCell(Text('${score.holeNumber}')),
                          DataCell(Text('${score.par}')),
                          DataCell(Text('${score.strokes}')),
                          DataCell(Text(
                            relativeToParText,
                            style: TextStyle(
                              color: relativeToPar < 0
                                  ? Colors.green
                                  : relativeToPar > 0
                                      ? Colors.red
                                      : null,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
