import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/models/golf_course_api.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/services/golf_course_api_service.dart';
import 'package:golf_stat_tracker/utils/responsive_helper.dart';
import 'package:golf_stat_tracker/widgets/error_handler.dart';
import 'package:provider/provider.dart';

class CourseSearchScreen extends StatefulWidget {
  final Function(Course)? onCourseSelected;

  const CourseSearchScreen({Key? key, this.onCourseSelected}) : super(key: key);

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<GolfCourse> _searchResults = [];
  GolfCourse? _selectedCourse;
  List<FormattedTeeBox> _teeBoxes = [];
  TeeBox? _selectedTeeBox;
  
  @override
  void initState() {
    super.initState();
    // Set focus to search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _initializeGolfApi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  // Initialize Golf API
  Future<void> _initializeGolfApi() async {
    await GolfCourseApiService.initialize();
  }
  
  // Show dialog to request API key
  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Golf Course API Key Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To search for golf courses, you need to provide a Golf Course API key.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your Golf Course API key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiKey = apiKeyController.text.trim();
                if (apiKey.isNotEmpty) {
                  await GolfCourseApiService.setApiKey(apiKey);
                  Navigator.of(context).pop();
                  
                  // Retry the search
                  _searchCourses();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  // Search for courses
  Future<void> _searchCourses() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _selectedCourse = null;
      _teeBoxes = [];
      _selectedTeeBox = null;
    });
    
    try {
      final results = await GolfCourseApiService.searchGolfCourses(query);
      
      // We now have a default API key, but still check just in case
      if (results.missingApiKey) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key configuration issue. Using default key.')),
        );
        
        // Try to set the default key again and retry
        await GolfCourseApiService.setApiKey("2TKYWN63GCQPMDXU6Q6XNUFEPA");
        
        // Retry the search after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          _searchCourses();
        });
        return;
      }
      
      setState(() {
        _searchResults = results.courses;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error searching for courses: $e');
      setState(() {
        _isLoading = false;
        _error = 'Could not search for courses. Please check your internet connection and try again.';
      });
    }
  }

  // Get course details and tee boxes
  Future<void> _selectCourse(GolfCourse course) async {
    setState(() {
      _isLoading = true;
      _selectedCourse = course;
      _teeBoxes = [];
      _selectedTeeBox = null;
    });
    
    try {
      // Check if course ID is valid before proceeding
      if (course.id <= 0) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid course ID. Please select a different course.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      final courseDetails = await GolfCourseApiService.getGolfCourseById(course.id);
      
      // Ensure we have a valid course object
      if (courseDetails.holes.isEmpty && (courseDetails.tees.male.isEmpty && courseDetails.tees.female.isEmpty)) {
        // We have a course but it doesn't have holes or tees - create basic tee box
        final defaultHoles = List.generate(18, (i) => Hole(
          holeNumber: i + 1,
          par: i % 9 == 0 ? 5 : (i % 9 == 8 ? 3 : 4), // Create a mix of par 3, 4, 5
          yardage: i % 9 == 0 ? 500 : (i % 9 == 8 ? 180 : 370), // Realistic yardages
          handicap: i + 1,
        ));
        
        // Calculate total par and yardage
        int totalPar = defaultHoles.fold(0, (sum, hole) => sum + hole.par);
        int totalYards = defaultHoles.fold(0, (sum, hole) => sum + hole.yardage);
        
        // Create different tee box options
        final mensTeeBox = TeeBox(
          teeName: 'Men\'s',
          teeColor: 'blue',
          teeGender: 'male',
          parTotal: totalPar,
          totalYards: totalYards,
          courseRating: 72.0,
          slopeRating: 128,
          numberOfHoles: 18,
          holes: defaultHoles,
        );
        
        final womensTeeBox = TeeBox(
          teeName: 'Women\'s',
          teeColor: 'red',
          teeGender: 'female',
          parTotal: totalPar,
          totalYards: (totalYards * 0.9).round(), // Slightly shorter
          courseRating: 72.0,
          slopeRating: 125,
          numberOfHoles: 18,
          holes: defaultHoles,
        );
        
        // Add both tee options
        courseDetails.tees.male.add(mensTeeBox);
        courseDetails.tees.female.add(womensTeeBox);
      }
      
      final teeBoxes = GolfCourseApiService.getFormattedTeeBoxes(courseDetails);
      
      setState(() {
        _selectedCourse = courseDetails;
        _teeBoxes = teeBoxes;
        _isLoading = false;
        
        // Auto-select the first tee box if available
        if (teeBoxes.isNotEmpty) {
          _selectedTeeBox = teeBoxes.first.data;
        }
      });
    } catch (e) {
      debugPrint('Error selecting course: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error loading course details. Please try a different course.';
      });
      
      // Check if error is due to missing API key
      if (e.toString().contains('API key not configured')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API key configuration issue. Using default key.')),
          );
        }
        
        // Try to set the default key again
        await GolfCourseApiService.setApiKey("2TKYWN63GCQPMDXU6Q6XNUFEPA");
        
        // Retry after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _selectCourse(course);
          }
        });
        return;
      }
    }
  }

  // Save the selected course to the app's course list
  void _saveCourse() {
    if (_selectedCourse == null || _selectedTeeBox == null) return;
    
    // Convert API course to local course format
    final course = GolfCourseApiService.convertToLocalCourse(_selectedCourse!, _selectedTeeBox!);
    
    // Save to provider
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.addCourseObject(course);
    
    // Call the callback if provided
    if (widget.onCourseSelected != null) {
      widget.onCourseSelected!(course);
    }
    
    // Provide feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    }
    
    // Go back to previous screen
    Navigator.of(context).pop();
  }

  // Build the main content based on current state
  Widget _buildMainContent() {
    // Show no results message when search was performed but no courses found
    if (_hasSearched && _searchResults.isEmpty && _selectedCourse == null) {
      return const Center(
        child: Text('No courses found. Try a different search term.'),
      );
    }
    
    // Show search results list
    if (_searchResults.isNotEmpty && _selectedCourse == null) {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final course = _searchResults[index];
          return ListTile(
            title: Text(course.clubName),
            subtitle: Text(
              [
                course.courseName != 'Main Course' ? course.courseName : null,
                course.location.city,
                course.location.state,
                course.location.country,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              _selectCourse(course);
            },
          );
        },
      );
    }
    
    // Show course details and tee box selection
    if (_selectedCourse != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course details
            Text(
              _selectedCourse!.clubName,
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedCourse!.courseName,
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              [
                _selectedCourse!.location.city,
                _selectedCourse!.location.state,
                _selectedCourse!.location.country,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
            const SizedBox(height: 24),
            
            // Tee box selection
            if (_teeBoxes.isNotEmpty) ...[
              Text(
                'Select Tee Box',
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTeeBox != null 
                        ? _teeBoxes.firstWhere(
                            (tb) => tb.data == _selectedTeeBox, 
                            orElse: () => _teeBoxes.first
                          ).value
                        : null,
                    hint: const Text('Select a tee box'),
                    icon: const Icon(Icons.golf_course, color: Colors.green),
                    items: _teeBoxes.map((teeBox) {
                      // Get the tee color for visual indication
                      Color teeColor = _getTeeBoxColor(teeBox.data.teeColor);
                      
                      return DropdownMenuItem<String>(
                        value: teeBox.value,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: teeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300, 
                                  width: 1
                                ),
                              ),
                            ),
                            Expanded(child: Text(teeBox.label)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      
                      final selectedTeeBox = _teeBoxes.firstWhere(
                        (tb) => tb.value == value,
                      );
                      
                      // Add haptic feedback when selecting
                      HapticFeedback.selectionClick();
                      
                      setState(() {
                        _selectedTeeBox = selectedTeeBox.data;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tee box details
              if (_selectedTeeBox != null) ...[
                _buildTeeBoxDetails(),
                const SizedBox(height: 32),
                
                // Save button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveCourse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Save Course'),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    }
    
    // Default empty state - show instructions
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for a golf course above',
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 18),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the name of a golf course to find it in our database',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeeBoxDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tee Box Details',
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getTeeBoxColor(_selectedTeeBox!.teeColor),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Name:', _selectedTeeBox!.teeName),
                _buildDetailRow('Color:', _getTeeDisplayColor(_selectedTeeBox!.teeColor)),
                _buildDetailRow('Gender:', _selectedTeeBox!.teeGender == 'male' ? 'Men' : 'Women'),
                _buildDetailRow('Par Total:', '${_selectedTeeBox!.parTotal}'),
                _buildDetailRow('Total Yards:', '${_selectedTeeBox!.totalYards} yards'),
                _buildDetailRow('Course Rating:', _selectedTeeBox!.courseRating != null 
                    ? '${_selectedTeeBox!.courseRating?.toStringAsFixed(1)}' : 'N/A'),
                _buildDetailRow('Slope Rating:', '${_selectedTeeBox!.slopeRating ?? "N/A"}'),
                _buildDetailRow('Number of Holes:', '${_selectedTeeBox!.numberOfHoles}'),
                
                if (_selectedTeeBox!.holes != null && _selectedTeeBox!.holes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildHolesSummary(_selectedTeeBox!.holes!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Display a summary of front 9, back 9, and total pars/yardages
  Widget _buildHolesSummary(List<Hole> holes) {
    int frontPar = 0, backPar = 0;
    int frontYards = 0, backYards = 0;
    
    // Calculate front 9 and back 9 totals
    for (int i = 0; i < holes.length; i++) {
      if (i < 9) {
        frontPar += holes[i].par;
        frontYards += holes[i].yardage;
      } else if (i < 18) {
        backPar += holes[i].par;
        backYards += holes[i].yardage;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Summary',
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            _buildTableRow(['', 'Front 9', 'Back 9', 'Total'], isHeader: true),
            _buildTableRow([
              'Par', 
              '$frontPar', 
              holes.length > 9 ? '$backPar' : 'N/A', 
              '${_selectedTeeBox!.parTotal}'
            ]),
            _buildTableRow([
              'Yardage', 
              '$frontYards', 
              holes.length > 9 ? '$backYards' : 'N/A', 
              '${_selectedTeeBox!.totalYards}'
            ]),
          ],
        ),
      ],
    );
  }
  
  // Helper for building table rows
  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: isHeader 
          ? BoxDecoration(color: Colors.grey.shade200) 
          : null,
      children: cells.map((cell) => 
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell,
            style: isHeader 
                ? const TextStyle(fontWeight: FontWeight.bold) 
                : null,
            textAlign: TextAlign.center,
          ),
        )
      ).toList(),
    );
  }
  
  // Convert tee color string to actual color
  Color _getTeeBoxColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'black': return Colors.black;
      case 'blue': return Colors.blue;
      case 'white': return Colors.grey.shade300;
      case 'red': return Colors.red;
      case 'gold': return Colors.amber;
      case 'green': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  // Get a display name for the tee color
  String _getTeeDisplayColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return 'Not specified';
    }
    
    // Capitalize first letter of each word
    return colorName.split(' ').map((word) => 
      word.isNotEmpty 
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : ''
    ).join(' ');
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Golf Course'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for a golf course',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Enter course name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: ResponsiveHelper.value(
                            context,
                            mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        onSubmitted: (_) => _searchCourses(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchCourses,
                      style: ElevatedButton.styleFrom(
                        padding: ResponsiveHelper.value(
                          context,
                          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Main content area with loading, error states or content
          Expanded(
            child: LoadingOrError(
              isLoading: _isLoading,
              errorMessage: _error,
              onRetry: _error != null ? _searchCourses : null,
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }
}