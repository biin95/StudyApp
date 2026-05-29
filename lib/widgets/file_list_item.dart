import 'package:flutter/material.dart';
import '../models/file_record.dart';
import '../utils/format_utils.dart';

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
              FormatUtils.getIcon(file.format),
              color: FormatUtils.getColor(file.format),
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
