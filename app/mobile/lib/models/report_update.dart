class ReportUpdate {
  const ReportUpdate({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.comment,
    this.oldStatus,
    this.newStatus,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String userId;
  final String comment;
  final String? oldStatus;
  final String? newStatus;
  final DateTime createdAt;

  factory ReportUpdate.fromMap(Map<String, dynamic> map) {
    return ReportUpdate(
      id: map['id'] as String,
      reportId: map['report_id'] as String,
      userId: map['user_id'] as String,
      comment: (map['comment'] ?? '') as String,
      oldStatus: map['old_status'] as String?,
      newStatus: map['new_status'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
