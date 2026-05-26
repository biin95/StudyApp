import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'recent_screen.dart';
import 'favorites_screen.dart';
import 'bilibili_screen.dart';
import 'recruitment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> _entries = [
    {
      'title': '考试大纲',
      'icon': Icons.description,
      'color': Color(0xFFE3F2FD),
      'category': 'exam_outline',
    },
    {
      'title': '知识点',
      'icon': Icons.menu_book,
      'color': Color(0xFFE8F5E9),
      'category': 'knowledge',
    },
    {
      'title': '练习题',
      'icon': Icons.edit_note,
      'color': Color(0xFFFFF3E0),
      'category': 'exercise',
    },
    {
      'title': 'B站',
      'icon': Icons.smart_display,
      'color': Color(0xFFFCE4EC),
      'category': 'bilibili',
    },
    {
      'title': '招考信息',
      'icon': Icons.work,
      'color': Color(0xFFE0F2F1),
      'category': 'recruitment',
    },
    {
      'title': '最近访问',
      'icon': Icons.history,
      'color': Color(0xFFF3E5F5),
      'category': 'recent',
    },
    {
      'title': '收藏',
      'icon': Icons.star,
      'color': Color(0xFFFFFDE7),
      'category': 'favorites',
    },
  ];

  void _onTap(BuildContext context, Map<String, dynamic> entry) {
    final category = entry['category'] as String;

    Widget screen;
    switch (category) {
      case 'exam_outline':
      case 'knowledge':
      case 'exercise':
        screen = CategoryScreen(
          category: category,
          title: entry['title'] as String,
        );
        break;
      case 'bilibili':
        screen = const BilibiliScreen();
        break;
      case 'recruitment':
        screen = const RecruitmentScreen();
        break;
      case 'recent':
        screen = const RecentScreen();
        break;
      case 'favorites':
        screen = const FavoritesScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习资料管理'),
        centerTitle: true,
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
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return GestureDetector(
              onTap: () => _onTap(context, entry),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: entry['color'] as Color,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry['icon'] as IconData,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
