import 'package:flutter/material.dart';
import 'category_screen.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  static const List<Map<String, dynamic>> _subCategories = [
    {
      'title': '习题',
      'icon': Icons.edit_note,
      'color': Color(0xFFFFF3E0),
      'darkColor': Color(0xFF2E2510),
      'category': 'exercise_practice',
    },
    {
      'title': '真题',
      'icon': Icons.quiz,
      'color': Color(0xFFFFF8E1),
      'darkColor': Color(0xFF2E2810),
      'category': 'exercise_real',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习题'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _subCategories.length,
          itemBuilder: (context, index) {
            final entry = _subCategories[index];
            final cardColor = isDark
                ? (entry['darkColor'] as Color)
                : (entry['color'] as Color);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      category: entry['category'] as String,
                      title: entry['title'] as String,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: cardColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry['icon'] as IconData,
                      size: 48,
                      color: isDark
                          ? Colors.white70
                          : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
