import 'package:flutter/material.dart';

/// 文件格式相关的工具方法
class FormatUtils {
  /// 根据文件格式返回对应的图标
  static IconData getIcon(String format) {
    switch (format) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'html':
        return Icons.html;
      case 'md':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 根据文件格式返回对应的颜色
  static Color getColor(String format) {
    switch (format) {
      case 'pdf':
        return Colors.red;
      case 'html':
        return Colors.orange;
      case 'md':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
