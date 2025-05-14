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
  late FairwayHit _fairwayHit;
  late GreenInRegulation _greenInRegulation;
  late int _putts;
  late List<Penalty> _penalties;
  late TextEditingController _notesController;
  
  @override
  void initState() {
    super.initState();
    _initializeFromHoleScore();
  }
  
  @override
  void didUpdateWidget(HoleInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holeScore != widget.holeScore) {
      _initializeFromHoleScore();
    }
  }
  
  void _initializeFromHoleScore() {
    _strokes = widget.holeScore.strokes;
    _fairwayHit = widget.holeScore.fairwayHit;
    _greenInRegulation = widget.holeScore.greenInRegulation;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      10,
                      (index) {
                        final strokeCount = index + 1;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _strokes = strokeCount;
                            });
                            _saveHoleScore();
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _strokes == strokeCount
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fairway hit input (not for par 3)
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
                        _buildRadioButton<FairwayHit>(
                          value: FairwayHit.yes,
                          groupValue: _fairwayHit,
                          label: 'Yes',
                          onChanged: (value) {
                            setState(() {
                              _fairwayHit = value!;
                            });
                            _saveHoleScore();
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildRadioButton<FairwayHit>(
                          value: FairwayHit.no,
                          groupValue: _fairwayHit,
                          label: 'No',
                          onChanged: (value) {
                            setState(() {
                              _fairwayHit = value!;
                            });
                            _saveHoleScore();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (!isPar3) const SizedBox(height: 16),
          
          // Green in regulation input
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
                  const SizedBox(height: 4),
                  Text(
                    'Par ${widget.holeScore.par}: On green in ${widget.holeScore.par - 2} shots',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRadioButton<GreenInRegulation>(
                        value: GreenInRegulation.yes,
                        groupValue: _greenInRegulation,
                        label: 'Yes',
                        onChanged: (value) {
                          setState(() {
                            _greenInRegulation = value!;
                          });
                          _saveHoleScore();
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildRadioButton<GreenInRegulation>(
                        value: GreenInRegulation.no,
                        groupValue: _greenInRegulation,
                        label: 'No',
                        onChanged: (value) {
                          setState(() {
                            _greenInRegulation = value!;
                          });
                          _saveHoleScore();
                        },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _putts = index;
                            });
                            _saveHoleScore();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _putts == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$index',
                              style: TextStyle(
                                color: _putts == index
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Penalties
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Penalties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddPenaltyDialog,
                        child: const Text('Add Penalty'),
                      ),
                    ],
                  ),
                  if (_penalties.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: _penalties.map((penalty) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_getPenaltyName(penalty.type)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _penalties.remove(penalty);
                              });
                              _saveHoleScore();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text('No penalties'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notes
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
                      hintText: 'Add notes about this hole (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      // Debounce to avoid too many saves
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (value == _notesController.text) {
                          _saveHoleScore();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioButton<T>({
    required T value,
    required T groupValue,
    required String label,
    required ValueChanged<T?>? onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
        GestureDetector(
          onTap: () {
            onChanged?.call(value);
          },
          child: Text(label),
        ),
      ],
    );
  }

  void _showAddPenaltyDialog() {
    PenaltyType? selectedPenalty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Penalty'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: PenaltyType.values.map((type) {
                return RadioListTile<PenaltyType>(
                  title: Text(_getPenaltyName(type)),
                  value: type,
                  groupValue: selectedPenalty,
                  onChanged: (value) {
                    setState(() {
                      selectedPenalty = value;
                    });
                  },
                );
              }).toList(),
            );
          },
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
              if (selectedPenalty != null) {
                setState(() {
                  _penalties.add(Penalty(
                    type: selectedPenalty!,
                    count: 1,
                  ));
                });
                _saveHoleScore();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _getPenaltyName(PenaltyType type) {
    switch (type) {
      case PenaltyType.waterHazard:
        return 'Water Hazard';
      case PenaltyType.outOfBounds:
        return 'Out of Bounds';
      case PenaltyType.bunker:
        return 'Bunker';
      case PenaltyType.lost:
        return 'Lost Ball';
      case PenaltyType.unplayable:
        return 'Unplayable Lie';
      case PenaltyType.other:
        return 'Other Penalty';
    }
  }

  Color _getScoreColor() {
    if (_strokes == 0) return Colors.grey.shade300;
    
    final relativeToPar = _strokes - widget.holeScore.par;
    
    if (relativeToPar <= -2) return Colors.purple;
    if (relativeToPar == -1) return Colors.blue;
    if (relativeToPar == 0) return Colors.green;
    if (relativeToPar == 1) return Colors.orange;
    if (relativeToPar == 2) return Colors.deepOrange;
    return Colors.red;
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
      _fairwayHit,
      _greenInRegulation,
      _putts,
      _penalties,
      _notesController.text,
    );
    
    if (widget.onScoreUpdated != null) {
      widget.onScoreUpdated!();
    }
  }
}
