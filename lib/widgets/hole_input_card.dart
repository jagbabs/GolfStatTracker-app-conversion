import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/hole.dart';
import 'package:golf_stat_tracker/providers/round_provider.dart';
import 'package:golf_stat_tracker/utils/responsive_helper.dart';

class HoleInputCard extends StatefulWidget {
  final HoleScore holeScore;
  final String roundId;
  final VoidCallback? onScoreUpdated;

  const HoleInputCard({
    Key? key,
    required this.holeScore,
    required this.roundId,
    this.onScoreUpdated,
  }) : super(key: key);

  @override
  State<HoleInputCard> createState() => _HoleInputCardState();
}

class _HoleInputCardState extends State<HoleInputCard> {
  late int _strokes;
  late bool _fairwayHit;
  late bool _greenInRegulation;
  late int _putts;
  late List<Penalty> _penalties;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _strokes = widget.holeScore.strokes;
    
    // Convert FairwayHit enum to bool
    _fairwayHit = widget.holeScore.fairwayHit == FairwayHit.yes;
    
    // Convert GreenInRegulation enum to bool
    _greenInRegulation = widget.holeScore.greenInRegulation == GreenInRegulation.yes;
    
    _putts = widget.holeScore.putts;
    _penalties = List.from(widget.holeScore.penalties);
    _notesController = TextEditingController(text: widget.holeScore.notes);
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPar3 = widget.holeScore.par == 3;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hole header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hole ${widget.holeScore.holeNumber}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Par ${widget.holeScore.par}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _strokes > 0
                      ? '$_strokes ${_getScoreLabel()}'
                      : 'Enter Score',
                  style: TextStyle(
                    color: _strokes > 0 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Strokes input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Strokes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      // Check if we're on mobile for proper sizing
                      final isMobile = ResponsiveHelper.isMobile(context);
                      final buttonSize = isMobile ? 42.0 : 32.0;
                      
                      // Wrap in a horizontal scrollable view to handle small screens 
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            10,
                            (index) {
                              final strokeCount = index + 1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(buttonSize/2),
                                  onTap: () {
                                    // Add haptic feedback for better mobile experience
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _strokes = strokeCount;
                                    });
                                    _saveHoleScore();
                                  },
                                  child: Container(
                                    width: buttonSize,
                                    height: buttonSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _strokes == strokeCount
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                                      // Add shadow for better visibility
                                      boxShadow: _strokes == strokeCount ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$strokeCount',
                                      style: TextStyle(
                                        color: _strokes == strokeCount
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fairway hit input - not shown for par 3
          if (!isPar3)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fairway Hit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _fairwayHit = true;
                              });
                              _saveHoleScore();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _fairwayHit
                                    ? Colors.green
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Yes',
                                style: TextStyle(
                                  color: _fairwayHit ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _fairwayHit = false;
                              });
                              _saveHoleScore();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_fairwayHit && _strokes > 0
                                    ? Colors.red
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'No',
                                style: TextStyle(
                                  color: !_fairwayHit && _strokes > 0
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // GIR input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Green in Regulation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _greenInRegulation = true;
                            });
                            _saveHoleScore();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _greenInRegulation
                                  ? Colors.green
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                color: _greenInRegulation ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _greenInRegulation = false;
                            });
                            _saveHoleScore();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_greenInRegulation && _strokes > 0
                                  ? Colors.red
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'No',
                              style: TextStyle(
                                color: !_greenInRegulation && _strokes > 0
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Putts input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Putts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      // Use responsive sizing for mobile 
                      final isMobile = ResponsiveHelper.isMobile(context);
                      final buttonSize = isMobile ? 42.0 : 32.0;
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            6,
                            (index) {
                              final puttCount = index;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(buttonSize/2),
                                  onTap: () {
                                    // Add haptic feedback
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _putts = puttCount;
                                    });
                                    _saveHoleScore();
                                  },
                                  child: Container(
                                    width: buttonSize,
                                    height: buttonSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _putts == puttCount
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                                      // Add shadow for better touch feedback
                                      boxShadow: _putts == puttCount ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$puttCount',
                                      style: TextStyle(
                                        color: _putts == puttCount
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this hole...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _saveHoleScore(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (_strokes == 0) return Colors.grey.shade300;
    
    final relativeToPar = _strokes - widget.holeScore.par;
    
    if (relativeToPar <= -2) return Colors.deepPurple; // Eagle or better
    if (relativeToPar == -1) return Colors.indigo; // Birdie
    if (relativeToPar == 0) return Colors.green; // Par
    if (relativeToPar == 1) return Colors.orange; // Bogey
    if (relativeToPar == 2) return Colors.deepOrange; // Double bogey
    return Colors.red; // Triple or worse
  }

  String _getScoreLabel() {
    if (_strokes == 0) return '';
    
    final relativeToPar = _strokes - widget.holeScore.par;
    
    if (relativeToPar <= -2) return 'Eagle+';
    if (relativeToPar == -1) return 'Birdie';
    if (relativeToPar == 0) return 'Par';
    if (relativeToPar == 1) return 'Bogey';
    if (relativeToPar == 2) return 'Double';
    return 'Triple+';
  }

  void _saveHoleScore() {
    // If the round provider has been disposed, don't save
    if (!mounted) return;
    
    final roundProvider = Provider.of<RoundProvider>(context, listen: false);
    
    roundProvider.updateHoleScore(
      widget.roundId,
      widget.holeScore.holeNumber,
      _strokes,
      _fairwayHit ? FairwayHit.yes : FairwayHit.no,
      _greenInRegulation ? GreenInRegulation.yes : GreenInRegulation.no,
      _putts,
      _penalties,
      _notesController.text,
    );
    
    if (widget.onScoreUpdated != null) {
      widget.onScoreUpdated!();
    }
  }
}