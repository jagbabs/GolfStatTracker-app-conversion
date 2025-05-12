import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golf_stat_tracker/models/course.dart';
import 'package:golf_stat_tracker/providers/course_provider.dart';
import 'package:golf_stat_tracker/utils/constants.dart';
import 'package:golf_stat_tracker/widgets/course_card.dart';
import 'package:uuid/uuid.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          final courses = courseProvider.courses;

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.golf_course, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No courses added yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add a new course.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _showAddCourseDialog(context);
                    },
                    child: const Text('Add Course'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                onEdit: () => _showEditCourseDialog(context, course),
                onDelete: () => _confirmDeleteCourse(context, course),
                onViewDetails: () => _showCourseDetailsDialog(context, course),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCourseDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final parController = TextEditingController(text: '72');
    final holeCountController = TextEditingController(text: '18');
    
    // Select random course image from the available ones
    final randomImageIndex = DateTime.now().millisecondsSinceEpoch % Constants.courseImageUrls.length;
    String selectedImageUrl = Constants.courseImageUrls[randomImageIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g., Pebble Beach Golf Links',
                ),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Pebble Beach, CA',
                ),
              ),
              TextField(
                controller: parController,
                decoration: const InputDecoration(
                  labelText: 'Total Par',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: holeCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Holes',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Course Image'),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Constants.courseImageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = Constants.courseImageUrls[index];
                    final isSelected = imageUrl == selectedImageUrl;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImageUrl = imageUrl;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                              );
                            },
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate inputs
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              final par = int.tryParse(parController.text) ?? 72;
              final holeCount = int.tryParse(holeCountController.text) ?? 18;
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a course name')),
                );
                return;
              }
              
              if (location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a location')),
                );
                return;
              }
              
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              courseProvider.addCourse(name, location, par, holeCount, selectedImageUrl);
              
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    final nameController = TextEditingController(text: course.name);
    final locationController = TextEditingController(text: course.location);
    final parController = TextEditingController(text: course.par.toString());
    final holeCountController = TextEditingController(text: course.holeCount.toString());
    String selectedImageUrl = course.imageUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                ),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
              TextField(
                controller: parController,
                decoration: const InputDecoration(
                  labelText: 'Total Par',
                ),
                keyboardType: TextInputType.number,
                enabled: false, // Par is calculated from hole pars
              ),
              TextField(
                controller: holeCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Holes',
                ),
                keyboardType: TextInputType.number,
                enabled: false, // Hole count should not be changed after creation
              ),
              const SizedBox(height: 16),
              const Text('Course Image'),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Constants.courseImageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = Constants.courseImageUrls[index];
                    final isSelected = imageUrl == selectedImageUrl;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImageUrl = imageUrl;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                              );
                            },
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate inputs
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a course name')),
                );
                return;
              }
              
              if (location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a location')),
                );
                return;
              }
              
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              final updatedCourse = course.copyWith(
                name: name,
                location: location,
                imageUrl: selectedImageUrl,
              );
              
              courseProvider.updateCourse(updatedCourse);
              
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCourse(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.name}"? This will also delete all rounds played on this course and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              courseProvider.deleteCourse(course.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${course.name} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCourseDetailsDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    course.imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 150,
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Course details
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Location'),
                  subtitle: Text(course.location),
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Total Par'),
                  subtitle: Text('${course.par}'),
                ),
                ListTile(
                  leading: const Icon(Icons.golf_course),
                  title: const Text('Number of Holes'),
                  subtitle: Text('${course.holeCount}'),
                ),
                
                const Divider(),
                const Text(
                  'Hole Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Hole details table
                DataTable(
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text('Hole')),
                    DataColumn(label: Text('Par')),
                    DataColumn(label: Text('Yards')),
                    DataColumn(label: Text('HCP')),
                  ],
                  rows: course.holePars.map((holePar) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${holePar.holeNumber}')),
                        DataCell(
                          GestureDetector(
                            onTap: () => _editHolePar(context, course, holePar),
                            child: Text(
                              '${holePar.par}',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${holePar.distance}')),
                        DataCell(Text('${holePar.handicap}')),
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
      ),
    );
  }

  void _editHolePar(BuildContext context, Course course, HolePar holePar) {
    final parController = TextEditingController(text: holePar.par.toString());
    final distanceController = TextEditingController(text: holePar.distance.toString());
    final handicapController = TextEditingController(text: holePar.handicap.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hole ${holePar.holeNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: parController,
              decoration: const InputDecoration(
                labelText: 'Par',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(
                labelText: 'Distance (yards)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: handicapController,
              decoration: const InputDecoration(
                labelText: 'Handicap (1-18)',
                hintText: 'Lower number = more difficult hole',
              ),
              keyboardType: TextInputType.number,
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
            onPressed: () {
              // Validate inputs
              final par = int.tryParse(parController.text) ?? 4;
              final distance = int.tryParse(distanceController.text) ?? 400;
              final handicap = int.tryParse(handicapController.text) ?? 9;
              
              if (par < 3 || par > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Par should be between 3 and 5')),
                );
                return;
              }
              
              if (handicap < 1 || handicap > 18) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Handicap should be between 1 and 18')),
                );
                return;
              }
              
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              courseProvider.updateHolePar(
                course.id,
                holePar.holeNumber,
                par,
                distance,
                handicap,
              );
              
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close both dialogs
              
              // Reopen course details with updated data
              _showCourseDetailsDialog(
                context,
                courseProvider.courses.firstWhere((c) => c.id == course.id),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
