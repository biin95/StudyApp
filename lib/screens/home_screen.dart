import 'dart:math';
import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'recent_screen.dart';
import 'favorites_screen.dart';
import 'bilibili_screen.dart';
import 'recruitment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // App 启动时随机选一条，之后不变，直到下次重新打开 APP
  static final String _quote =
      _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];

  static const List<Map<String, dynamic>> _entries = [
    {
      'title': '考试大纲',
      'icon': Icons.description,
      'color': Color(0xFFE3F2FD),
      'darkColor': Color(0xFF1A2A3A),
      'category': 'exam_outline',
    },
    {
      'title': '知识点',
      'icon': Icons.menu_book,
      'color': Color(0xFFE8F5E9),
      'darkColor': Color(0xFF1A2E1A),
      'category': 'knowledge',
    },
    {
      'title': '习题',
      'category': 'exercise_practice',
      'icon': Icons.edit_note,
      'color': Color(0xFFFFF3E0),
      'darkColor': Color(0xFF2E2510),
    },
    {
      'title': '真题',
      'category': 'exercise_real',
      'icon': Icons.quiz,
      'color': Color(0xFFFFF8E1),
      'darkColor': Color(0xFF2E2810),
    },
    {
      'title': 'B站',
      'icon': Icons.smart_display,
      'color': Color(0xFFFCE4EC),
      'darkColor': Color(0xFF2E1A20),
      'category': 'bilibili',
    },
    {
      'title': '招考信息',
      'icon': Icons.work,
      'color': Color(0xFFE0F2F1),
      'darkColor': Color(0xFF1A2E2A),
      'category': 'recruitment',
    },
    {
      'title': '最近访问',
      'icon': Icons.history,
      'color': Color(0xFFF3E5F5),
      'darkColor': Color(0xFF2A1A2E),
      'category': 'recent',
    },
    {
      'title': '收藏',
      'icon': Icons.star,
      'color': Color(0xFFFFFDE7),
      'darkColor': Color(0xFF2E2A10),
      'category': 'favorites',
    },
  ];

  static const List<String> _motivationalQuotes = [
    '学而不思则罔，思而不学则殆。——孔子',
    '书山有路勤为径，学海无涯苦作舟。——韩愈',
    '千里之行，始于足下。——老子',
    '业精于勤，荒于嬉；行成于思，毁于随。——韩愈',
    '不积跬步，无以至千里；不积小流，无以成江海。——荀子',
    '天道酬勤，功不唐捐。',
    '只要功夫深，铁杵磨成针。',
    '一日读书一日功，一日不读十日空。',
    '宝剑锋从磨砺出，梅花香自苦寒来。',
    '世上无难事，只怕有心人。',
    '活到老，学到老。',
    '知之为知之，不知为不知，是知也。——孔子',
    '三人行，必有我师焉。——孔子',
    '读万卷书，行万里路。——刘彝',
    '黑发不知勤学早，白首方悔读书迟。——颜真卿',
    'The secret of getting ahead is getting started. (千里之行，始于足下。)',
    'Success is the sum of small efforts repeated day in and day out. (成功是日复一日的小努力累积而成。)',
    'The more you learn, the more you earn. (学得越多，收获越多。)',
    'Don\'t watch the clock; do what it does. Keep going. (别看钟表，学它一样，不断前行。)',
    'Every expert was once a beginner. (每个专家都曾是初学者。)',
    'Learning is a treasure that will follow its owner everywhere. (学问是随身之宝。)',
    'No pain, no gain. (不劳无获。)',
    'Practice makes perfect. (熟能生巧。)',
    'The best time to plant a tree was 20 years ago. The second best time is now. (种树最好的时间是二十年前，其次是现在。)',
    'Education is the most powerful weapon which you can use to change the world. (教育是改变世界最有力的武器。)',
    'A journey of a thousand miles begins with a single step. (千里之行，始于足下。)',
    'Rome wasn\'t built in a day. (罗马不是一天建成的。)',
    'Where there is a will, there is a way. (有志者事竟成。)',
    'It always seems impossible until it\'s done. (在完成之前，一切看起来都不可能。)',
    '今日事，今日毕。',
  ];

  void _onTap(BuildContext context, Map<String, dynamic> entry) {
    final category = entry['category'] as String;

    Widget screen;
    switch (category) {
      case 'exam_outline':
      case 'knowledge':
      case 'exercise':
      case 'exercise_practice':
      case 'exercise_real':
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习资料管理'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 励志语录
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _quote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            // 网格
            Expanded(
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
                  final cardColor = isDark
                      ? (entry['darkColor'] as Color)
                      : (entry['color'] as Color);
                  return GestureDetector(
                    onTap: () => _onTap(context, entry),
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
          ],
        ),
      ),
    );
  }
}
