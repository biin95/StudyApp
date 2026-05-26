import 'package:flutter/material.dart';
import '../models/file_record.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../widgets/file_list_item.dart';
import '../widgets/empty_state.dart';
import 'file_viewer_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String title;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseService _db = DatabaseService();
  final FileService _fileService = FileService();
  List<FileRecord> _files = [];
  bool _loading = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final files = await _db.getFileRecordsByCategory(widget.category);
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _importFiles() async {
    setState(() => _importing = true);
    try {
      final imported = await _fileService.importFiles(widget.category);
      if (imported.isNotEmpty) {
        await _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${imported.length} 个文件')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未选择文件或文件格式不支持')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  Future<void> _importFolder() async {
    // Check permission first
    final hasPermission = await _fileService.requestStoragePermission();
    if (!hasPermission) {
      // Need to open settings for user to grant permission
      if (!mounted) return;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('需要存储权限'),
          content: const Text('导入文件夹需要访问设备存储的权限。\n\n请点击"去设置"按钮，在设置页面找到"允许管理所有文件"或"存储"权限并开启。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去设置'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await _fileService.openStorageSettings();
        // After user comes back from settings, check again
        final granted = await _fileService.isStoragePermissionGranted();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未获得存储权限，无法导入文件夹')),
            );
          }
          return;
        }
      } else {
        return;
      }
    }

    setState(() => _importing = true);
    try {
      final imported = await _fileService.importFolder(widget.category);
      if (imported.isNotEmpty) {
        await _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${imported.length} 个文件')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到支持的文件（PDF、HTML、MD）')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('导入文件'),
              subtitle: const Text('选择 PDF、HTML、MD 文件'),
              onTap: () {
                Navigator.pop(context);
                _importFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('导入文件夹'),
              subtitle: const Text('导入文件夹中所有支持的文件'),
              onTap: () {
                Navigator.pop(context);
                _importFolder();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLongPressMenu(FileRecord file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                file.isFavorited ? Icons.star_border : Icons.star,
                color: file.isFavorited ? null : const Color(0xFFFFD700),
              ),
              title: Text(file.isFavorited ? '取消收藏' : '收藏'),
              onTap: () async {
                Navigator.pop(context);
                await _db.toggleFavorite(file.id!, !file.isFavorited);
                await _loadFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FileRecord file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${file.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fileService.deletePhysicalFile(file.path);
              await _db.deleteFileRecord(file.id!);
              await _loadFiles();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('文件已删除')),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openFile(FileRecord file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(file: file),
      ),
    );
    // Refresh list when coming back (read status may have changed)
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _importing
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在导入文件...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : _files.isEmpty
                  ? const EmptyState(
                      icon: Icons.folder_open,
                      message: '还没有文件哦，点击右下角按钮导入',
                    )
                  : ListView.separated(
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return FileListItem(
                          file: file,
                          onTap: () => _openFile(file),
                          onLongPress: () => _showLongPressMenu(file),
                        );
                      },
                    ),
      floatingActionButton: _importing
          ? null
          : FloatingActionButton(
              onPressed: _showImportOptions,
              child: const Icon(Icons.add),
            ),
    );
  }
}
