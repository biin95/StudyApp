class RecentRecord {
  final int? id;
  final int fileId;
  final int openedAt;

  RecentRecord({
    this.id,
    required this.fileId,
    required this.openedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_id': fileId,
      'opened_at': openedAt,
    };
  }

  factory RecentRecord.fromMap(Map<String, dynamic> map) {
    return RecentRecord(
      id: map['id'] as int?,
      fileId: map['file_id'] as int,
      openedAt: map['opened_at'] as int,
    );
  }
}
