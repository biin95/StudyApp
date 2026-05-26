class FileRecord {
  final int? id;
  final String name;
  final String path;
  final String category; // exam_outline / knowledge / exercise
  final String format; // pdf / html / md
  final bool isRead;
  final bool isFavorited;
  final int createdAt;
  final int? lastOpenedAt;

  FileRecord({
    this.id,
    required this.name,
    required this.path,
    required this.category,
    required this.format,
    this.isRead = false,
    this.isFavorited = false,
    required this.createdAt,
    this.lastOpenedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'category': category,
      'format': format,
      'is_read': isRead ? 1 : 0,
      'is_favorited': isFavorited ? 1 : 0,
      'created_at': createdAt,
      'last_opened_at': lastOpenedAt,
    };
  }

  factory FileRecord.fromMap(Map<String, dynamic> map) {
    return FileRecord(
      id: map['id'] as int?,
      name: map['name'] as String,
      path: map['path'] as String,
      category: map['category'] as String,
      format: map['format'] as String,
      isRead: (map['is_read'] as int) == 1,
      isFavorited: (map['is_favorited'] as int) == 1,
      createdAt: map['created_at'] as int,
      lastOpenedAt: map['last_opened_at'] as int?,
    );
  }

  FileRecord copyWith({
    int? id,
    String? name,
    String? path,
    String? category,
    String? format,
    bool? isRead,
    bool? isFavorited,
    int? createdAt,
    int? lastOpenedAt,
  }) {
    return FileRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      category: category ?? this.category,
      format: format ?? this.format,
      isRead: isRead ?? this.isRead,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
