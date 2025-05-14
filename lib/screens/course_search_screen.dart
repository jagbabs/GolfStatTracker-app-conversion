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
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for courses: $e')),
        );
      }
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
        final basicTeeBox = TeeBox(
          teeName: 'Standard',
          teeGender: 'male',
          parTotal: 72,
          totalYards: 6500,
          numberOfHoles: 18,
          holes: List.generate(18, (i) => Hole(
            holeNumber: i + 1,
            par: 4,
            yardage: 350,
          )),
        );
        
        courseDetails.tees.male.add(basicTeeBox);
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
      
      // Handle other error types
      if (e.toString().contains('type \'Null\' is not a subtype of type')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The course data format is incompatible. Try a different course.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting course details: $e')),
        );
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
          
          // Results area with loading, error states or content
          Expanded(
            child: LoadingOrError(
              isLoading: _isLoading,
              errorMessage: _error,
              onRetry: _error != null ? _searchCourses : null,
              child: _hasSearched && _searchResults.isEmpty && _selectedCourse == null
                ? const Center(
                    child: Text('No courses found. Try a different search term.'),
                  )
                : const SizedBox.shrink(),
            ),
          ),
          
          // Search results list
          if (!_isLoading && _searchResults.isNotEmpty && _selectedCourse == null)
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          
          // Course details and tee box selection
          if (!_isLoading && _selectedCourse != null)
            Expanded(
              child: SingleChildScrollView(
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
                        'Select Tees',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
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
                            hint: const Text('Select tees'),
                            items: _teeBoxes.map((teeBox) {
                              return DropdownMenuItem<String>(
                                value: teeBox.value,
                                child: Text(teeBox.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              
                              final selectedTeeBox = _teeBoxes.firstWhere(
                                (tb) => tb.value == value,
                              );
                              
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeeBoxDetails() {
    if (_selectedTeeBox == null) return const SizedBox.shrink();
    
    return Card(
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
              'Tee Details',
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, baseFontSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('Par Total:', '${_selectedTeeBox!.parTotal}'),
            _buildDetailRow('Total Yards:', '${_selectedTeeBox!.totalYards}'),
            _buildDetailRow('Course Rating:', '${_selectedTeeBox!.courseRating ?? "N/A"}'),
            _buildDetailRow('Slope Rating:', '${_selectedTeeBox!.slopeRating ?? "N/A"}'),
            _buildDetailRow('Number of Holes:', '${_selectedTeeBox!.numberOfHoles}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}