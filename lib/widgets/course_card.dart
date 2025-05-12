import 'package:flutter/material.dart';
import 'package:golf_stat_tracker/models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const CourseCard({
    Key? key,
    required this.course,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image with overlay
          Stack(
            children: [
              Image.network(
                course.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Course name and par
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.location} • Par ${course.par} • ${course.holeCount} Holes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Hole count visualization
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.golf_course, size: 18),
                const SizedBox(width: 8),
                Text('${course.holeCount} Holes'),
                const Spacer(),
                ...List.generate(
                  min(9, course.holeCount),
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (course.holeCount > 9)
                  Text(' + ${course.holeCount - 9}'),
              ],
            ),
          ),
          
          // Action buttons
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              if (onViewDetails != null)
                TextButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                  onPressed: onViewDetails,
                ),
              if (onEdit != null)
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
