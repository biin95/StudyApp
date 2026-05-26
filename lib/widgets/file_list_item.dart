import 'package:flutter/material.dart';
import '../models/file_record.dart';

class FileListItem extends StatelessWidget {
  final FileRecord file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool?>? onSelectionChanged;

  const FileListItem({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
  });

  IconData _getFormatIcon(String format) {
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

  Color _getFormatColor(String format) {
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

  @override
  Widget build(BuildContext context) {
    final bool isStudied = file.isStudied;
    final bool isRead = file.isRead;
    final Color? nameColor = (isRead || isStudied) ? const Color(0xFF999999) : null;

    return ListTile(
      leading: selectionMode
          ? Checkbox(
              value: selected,
              onChanged: onSelectionChanged,
            )
          : Icon(
              _getFormatIcon(file.format),
              color: _getFormatColor(file.format),
              size: 32,
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              style: TextStyle(
                fontSize: 16,
                color: nameColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isStudied)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
            )
          else if (isRead)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.visibility, color: Color(0xFF999999), size: 18),
            ),
          if (file.isFavorited)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
