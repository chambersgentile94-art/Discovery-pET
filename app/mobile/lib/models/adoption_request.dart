class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.reportId,
    required this.requesterId,
    this.message,
    required this.status,
    required this.createdAt,
    this.reportTitle,
    this.requesterName,
    this.requesterEmail,
  });

  final String id;
  final String reportId;
  final String requesterId;
  final String? message;
  final String status;
  final DateTime createdAt;
  final String? reportTitle;
  final String? requesterName;
  final String? requesterEmail;

  factory AdoptionRequest.fromMap(Map<String, dynamic> map) {
    final report = map['animal_reports'];
    final requester = map['profiles'];

    String? reportTitle;
    String? requesterName;
    String? requesterEmail;

    if (report is Map<String, dynamic>) {
      reportTitle = report['title'] as String?;
    }

    if (requester is Map<String, dynamic>) {
      requesterName = requester['full_name'] as String?;
      requesterEmail = requester['email'] as String?;
    }

    return AdoptionRequest(
      id: map['id'] as String,
      reportId: map['report_id'] as String,
      requesterId: map['requester_id'] as String,
      message: map['message'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      reportTitle: reportTitle,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
    );
  }
}
