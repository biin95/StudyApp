import 'package:flutter/material.dart';
import '../models/file_record.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/file_list_item.dart';
import 'file_viewer_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _db = DatabaseService();
  final FileService _fileService = FileService();
  List<FileRecord> _favorites = [];
  bool _loading = true;

  static const Map<String, String> _categoryLabels = {
    'exam_outline': '考试大纲',
    'knowledge': '知识点',
    'exercise': '练习题',
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      final files = await _db.getFavoritedFiles();
      setState(() {
        _favorites = files;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openFile(FileRecord file) async {
    final exists = await _fileService.fileExists(file.path);
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件已失效')),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(file: file),
      ),
    );
    _loadFavorites();
  }

  void _showLongPressMenu(FileRecord file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('取消收藏'),
              onTap: () async {
                Navigator.pop(context);
                await _db.toggleFavorite(file.id!, false);
                await _loadFavorites();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消收藏')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const EmptyState(
                  icon: Icons.star_border,
                  message: '还没有收藏文件哦',
                )
              : ListView.separated(
                  itemCount: _favorites.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = _favorites[index];
                    return FileListItem(
                      file: file,
                      onTap: () => _openFile(file),
                      onLongPress: () => _showLongPressMenu(file),
                    );
                  },
                ),
    );
  }
}
