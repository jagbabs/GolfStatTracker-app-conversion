import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/models/round.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/providers/player_provider.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/utils/responsive_helper.dart';
import 'package:golf_stat_tracker/widgets/hole_input_card.dart';
import 'package:intl/intl.dart';

class RoundEntryScreen extends StatefulWidget {
  final String? roundId;

  const RoundEntryScreen({Key? key, this.roundId}) : super(key: key);

  @override
  State<RoundEntryScreen> createState() => _RoundEntryScreenState();
}

class _RoundEntryScreenState extends State<RoundEntryScreen> {
  int _currentHoleIndex = 0;
  late PageController _pageController;
  String? _selectedCourseId;
  bool _isNewRound = true;
  bool _isLoading = true;
  late Round _currentRound;
  final _weatherController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _roundDate;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentHoleIndex);
    _roundDate = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoundData();
    });
  }
  
  Future<void> _loadRoundData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.roundId != null) {
        // Editing an existing round
        final roundProvider = Provider.of<RoundProvider>(context, listen: false);
        final existingRound = await roundProvider.getRound(widget.roundId!);
        
        if (existingRound != null) {
          setState(() {
            _currentRound = existingRound;
            _selectedCourseId = existingRound.courseId;
            _isNewRound = false;
            _weatherController.text = existingRound.weather;
            _notesController.text = existingRound.notes;
            _roundDate = existingRound.date;
            
            // Find the first incomplete hole or last hole
            final firstIncompleteIndex = existingRound.scores.indexWhere(
              (score) => score.strokes == 0,
            );
            
            _currentHoleIndex = firstIncompleteIndex != -1 
                ? firstIncompleteIndex 
                : existingRound.scores.length - 1;
            
            _pageController = PageController(initialPage: _currentHoleIndex);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading round: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _weatherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewRound ? 'New Round' : 'Edit Round'),
        actions: [
          if (!_isNewRound)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmCompleteRound,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isNewRound
              ? _buildNewRoundSetup()
              : _buildRoundEntry(),
      bottomNavigationBar: !_isNewRound
          ? _buildNavigationBar()
          : null,
    );
  }
  
  Widget _buildNewRoundSetup() {
    return Consumer2<CourseProvider, PlayerProvider>(
      builder: (context, courseProvider, playerProvider, child) {
        final courses = courseProvider.courses;
        final currentPlayer = playerProvider.currentPlayer;
        
        if (currentPlayer == null) {
          return const Center(
            child: Text('No player profile found. Create one in the Profile tab.'),
          );
        }
        
        if (courses.isEmpty) {
          return const Center(
            child: Text('No courses available. Add a course in the Course Management screen.'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...courses.map((course) => 
                RadioListTile<String>(
                  title: Text(course.name),
                  subtitle: Text('${course.location} - Par ${course.par}'),
                  value: course.id,
                  groupValue: _selectedCourseId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Round Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(DateFormat.yMMMMd().format(_roundDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _roundDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  
                  if (date != null) {
                    setState(() {
                      _roundDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Weather Conditions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weatherController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Sunny, Windy, etc.',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Additional notes about this round',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedCourseId != null
                    ? () => _startNewRound(currentPlayer.id)
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Start Round'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _startNewRound(String playerId) async {
    if (_selectedCourseId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final roundProvider = Provider.of<RoundProvider>(context, listen: false);
      
      final selectedCourse = courseProvider.courses.firstWhere(
        (course) => course.id == _selectedCourseId,
      );
      
      await roundProvider.startNewRound(playerId, selectedCourse);
      
      // Set additional round details
      if (roundProvider.currentRound != null) {
        await roundProvider.updateRoundDetails(
          roundProvider.currentRound!.id,
          _roundDate,
          _notesController.text,
          _weatherController.text,
        );
        
        setState(() {
          _currentRound = roundProvider.currentRound!;
          _isNewRound = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting round: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildRoundEntry() {
    final holes = _currentRound.scores;
    
    return Column(
      children: [
        // Round summary bar
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentRound.courseName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Score: ${_currentRound.totalScore > 0 ? "${_currentRound.scoreString} (${_currentRound.totalScore})" : "N/A"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Hole indicators
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: holes.length,
            itemBuilder: (context, index) {
              final isCurrentHole = index == _currentHoleIndex;
              final hasScore = holes[index].strokes > 0;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentHoleIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentHole
                        ? Theme.of(context).primaryColor
                        : hasScore
                            ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrentHole
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrentHole
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isCurrentHole ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Hole entry form
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: holes.length,
            onPageChanged: (index) {
              setState(() {
                _currentHoleIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return HoleInputCard(
                holeScore: holes[index],
                roundId: _currentRound.id,
                onScoreUpdated: () {
                  // This will be called when the score is updated
                  // The round provider will handle the update
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavigationBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentHoleIndex > 0 
                ? () {
                    setState(() {
                      _currentHoleIndex--;
                      _pageController.animateToPage(
                        _currentHoleIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
          TextButton(
            onPressed: () {
              _showRoundDetailsDialog();
            },
            child: const Text('Round Details'),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentHoleIndex < _currentRound.scores.length - 1 
                ? () {
                    setState(() {
                      _currentHoleIndex++;
                      _pageController.animateToPage(
                        _currentHoleIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
  
  void _showRoundDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        _weatherController.text = _currentRound.weather;
        _notesController.text = _currentRound.notes;
        
        return AlertDialog(
          title: const Text('Round Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMMd().format(_roundDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _roundDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    
                    if (date != null) {
                      setState(() {
                        _roundDate = date;
                      });
                    }
                  },
                ),
                
                // Weather
                const Text('Weather Conditions'),
                TextField(
                  controller: _weatherController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Sunny, Windy, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Notes
                const Text('Notes'),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes about this round',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateRoundDetails();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _updateRoundDetails() async {
    try {
      final roundProvider = Provider.of<RoundProvider>(context, listen: false);
      
      await roundProvider.updateRoundDetails(
        _currentRound.id,
        _roundDate,
        _notesController.text,
        _weatherController.text,
      );
      
      if (mounted) {
        // Get the updated round
        final updatedRound = await roundProvider.getRound(_currentRound.id);
        if (updatedRound != null) {
          setState(() {
            _currentRound = updatedRound;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating round details: $e')),
        );
      }
    }
  }
  
  void _confirmCompleteRound() {
    // Check if all holes have scores
    final hasIncompleteHoles = _currentRound.scores.any((score) => score.strokes == 0);
    
    if (hasIncompleteHoles) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Round'),
          content: const Text(
            'Some holes have not been scored yet. Do you want to complete this round anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeRound();
              },
              child: const Text('Complete Round'),
            ),
          ],
        ),
      );
    } else {
      _completeRound();
    }
  }
  
  Future<void> _completeRound() async {
    try {
      final roundProvider = Provider.of<RoundProvider>(context, listen: false);
      
      await roundProvider.completeRound(_currentRound.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Round completed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing round: $e')),
        );
      }
    }
  }
}
