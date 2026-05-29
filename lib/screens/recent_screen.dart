import 'package:flutter/material.dart';
import '../models/file_record.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../utils/format_utils.dart';
import '../widgets/empty_state.dart';
import 'file_viewer_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final DatabaseService _db = DatabaseService();
  final FileService _fileService = FileService();
  List<Map<String, dynamic>> _recentItems = [];
  bool _loading = true;

  static const Map<String, String> _categoryLabels = {
    'exam_outline': '考试大纲',
    'knowledge': '知识点',
    'exercise': '练习题',
  };

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    setState(() => _loading = true);
    try {
      final items = await _db.getRecentFilesWithRecords();
      setState(() {
        _recentItems = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatRelativeTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fileDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(fileDate).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '$diff天前';
  }

  Future<void> _openFile(Map<String, dynamic> item) async {
    final filePath = item['path'] as String;
    final exists = await _fileService.fileExists(filePath);

    if (!exists) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('文件已失效'),
            content: const Text('该文件已被删除或移动，无法打开。'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final recentId = item['recent_id'] as int;
                  await _db.removeRecentRecord(recentId);
                  await _loadRecent();
                },
                child: const Text('移除'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final fileRecord = FileRecord(
      id: item['id'] as int,
      name: item['name'] as String,
      path: item['path'] as String,
      category: item['category'] as String,
      format: item['format'] as String,
      isRead: (item['is_read'] as int) == 1,
      isStudied: (item['is_studied'] as int?) == 1,
      isFavorited: (item['is_favorited'] as int) == 1,
      createdAt: item['created_at'] as int,
      lastOpenedAt: item['last_opened_at'] as int?,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(file: fileRecord),
      ),
    );
    _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近访问'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recentItems.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  message: '还没有打开过文件哦',
                )
              : ListView.separated(
                  itemCount: _recentItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _recentItems[index];
                    final category = item['category'] as String;
                    final openedAt = item['opened_at'] as int;

                    return ListTile(
                      leading: Icon(
                        FormatUtils.getIcon(item['format'] as String),
                        color: FormatUtils.getColor(item['format'] as String),
                        size: 32,
                      ),
                      title: Text(
                        item['name'] as String,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_categoryLabels[category] ?? category} · ${_formatRelativeTime(openedAt)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => _openFile(item),
                    );
                  },
                ),
    );
  }
}
