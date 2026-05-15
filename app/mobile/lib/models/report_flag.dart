class ReportFlag {
  const ReportFlag({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reportTitle,
    this.reportCategory,
    this.reportUrgency,
  });

  final String id;
  final String reportId;
  final String userId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reportTitle;
  final String? reportCategory;
  final String? reportUrgency;

  factory ReportFlag.fromMap(Map<String, dynamic> map) {
    final report = map['animal_reports'];
    String? title;
    String? category;
    String? urgency;

    if (report is Map<String, dynamic>) {
      title = report['title'] as String?;
      category = report['category'] as String?;
      urgency = report['urgency'] as String?;
    }

    return ReportFlag(
      id: map['id'] as String,
      reportId: map['report_id'] as String,
      userId: map['user_id'] as String,
      reason: map['reason'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      reportTitle: title,
      reportCategory: category,
      reportUrgency: urgency,
    );
  }
}
