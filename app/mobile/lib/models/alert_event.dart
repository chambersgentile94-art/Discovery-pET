import 'animal_report.dart';

class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.alertPreferenceId,
    required this.userId,
    required this.reportId,
    required this.distanceKm,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.report,
  });

  final String id;
  final String alertPreferenceId;
  final String userId;
  final String reportId;
  final double distanceKm;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final AnimalReport? report;

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    final reportMap = map['animal_reports'];

    return AlertEvent(
      id: map['id'] as String,
      alertPreferenceId: map['alert_preference_id'] as String,
      userId: map['user_id'] as String,
      reportId: map['report_id'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] == null ? null : DateTime.parse(map['read_at'] as String),
      report: reportMap is Map<String, dynamic>
          ? AnimalReport.fromMap(reportMap)
          : null,
    );
  }

  bool get isPending => status == 'pending';
}
