import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_record.dart';
import 'database_service.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final DatabaseService _db = DatabaseService();

  static const Map<String, String> categoryFolders = {
    'exam_outline': 'exam_outline',
    'knowledge': 'knowledge',
    'exercise': 'exercise',
  };

  Future<String> getAppDocPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> initDirectories() async {
    final basePath = await getAppDocPath();
    for (final folder in categoryFolders.values) {
      final dir = Directory(p.join(basePath, 'app_documents', folder));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  String _getFormat(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.pdf') return 'pdf';
    if (ext == '.html' || ext == '.htm') return 'html';
    if (ext == '.md') return 'md';
    return 'unknown';
  }

  List<String> get supportedExtensions => ['pdf', 'html', 'htm', 'md'];

  bool isSupportedFile(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(ext);
  }

  Future<List<FileRecord>> importFiles(String category) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final basePath = await getAppDocPath();
    final categoryFolder = categoryFolders[category]!;
    final targetDir = Directory(p.join(basePath, 'app_documents', categoryFolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final List<FileRecord> imported = [];

    for (final file in result.files) {
      if (file.path == null) continue;
      final fileName = file.name;
      if (!isSupportedFile(fileName)) continue;

      final sourceFile = File(file.path!);
      final targetPath = p.join(targetDir.path, fileName);

      // Handle duplicate names
      String finalPath = targetPath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = p.basenameWithoutExtension(fileName);
        final ext = p.extension(fileName);
        finalPath = p.join(targetDir.path, '${nameWithoutExt}_$counter$ext');
        counter++;
      }

      await sourceFile.copy(finalPath);

      final record = FileRecord(
        name: p.basename(finalPath),
        path: p.relative(finalPath, from: basePath),
        category: category,
        format: _getFormat(fileName),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await _db.insertFileRecord(record);
      imported.add(record.copyWith(id: id));
    }

    return imported;
  }

  /// Request storage permission for Android 11+
  /// Returns true if permission is granted, false otherwise.
  /// On Android 11+, opens system settings for user to grant MANAGE_EXTERNAL_STORAGE.
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Check if MANAGE_EXTERNAL_STORAGE is already granted
    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return true;

    // On Android 11+, try request() first (may show dialog on some devices)
    final requestResult = await Permission.manageExternalStorage.request();
    if (requestResult.isGranted) return true;

    // If request didn't work, we need to open system settings
    // Return false - the caller should show a message and open settings
    return false;
  }

  /// Open system settings for the user to grant MANAGE_EXTERNAL_STORAGE.
  /// Call this after requestStoragePermission() returns false.
  Future<void> openStorageSettings() async {
    await openAppSettings();
  }

  /// Check if storage permission is currently granted.
  Future<bool> isStoragePermissionGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.manageExternalStorage.isGranted;
  }

  Future<List<FileRecord>> importFolder(String category) async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result == null) return [];

    final basePath = await getAppDocPath();
    final categoryFolder = categoryFolders[category]!;
    final targetDir = Directory(p.join(basePath, 'app_documents', categoryFolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final List<FileRecord> imported = [];
    final sourceDir = Directory(result);

    if (!await sourceDir.exists()) {
      throw Exception('选择的文件夹不存在: $result');
    }

    try {
      await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path);
        if (!isSupportedFile(fileName)) continue;

        final targetPath = p.join(targetDir.path, fileName);

        // Handle duplicate names
        String finalPath = targetPath;
        int counter = 1;
        while (await File(finalPath).exists()) {
          final nameWithoutExt = p.basenameWithoutExtension(fileName);
          final ext = p.extension(fileName);
          finalPath = p.join(targetDir.path, '${nameWithoutExt}_$counter$ext');
          counter++;
        }

        await entity.copy(finalPath);

        final record = FileRecord(
          name: p.basename(finalPath),
          path: p.relative(finalPath, from: basePath),
          category: category,
          format: _getFormat(fileName),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final id = await _db.insertFileRecord(record);
        imported.add(record.copyWith(id: id));
      }
    } on FileSystemException catch (e) {
      throw Exception('无法读取文件夹内容，请检查存储权限是否已授予: ${e.message}');
    }

    return imported;
  }

  Future<String> getFullFilePath(String relativePath) async {
    final basePath = await getAppDocPath();
    return p.join(basePath, relativePath);
  }

  Future<bool> fileExists(String relativePath) async {
    final fullPath = await getFullFilePath(relativePath);
    return File(fullPath).exists();
  }

  Future<void> deletePhysicalFile(String relativePath) async {
    final fullPath = await getFullFilePath(relativePath);
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
