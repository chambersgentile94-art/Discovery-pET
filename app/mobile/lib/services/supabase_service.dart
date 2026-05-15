import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_report.dart';
import '../models/report_update.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String reportImagesBucket = 'report-images';

  String get _reportSelect => '*, report_images(image_url, storage_path)';

  Future<List<AnimalReport>> fetchPublicReports() async {
    final response = await _client
        .from('animal_reports')
        .select(_reportSelect)
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return response
        .map<AnimalReport>((item) => AnimalReport.fromMap(item))
        .toList();
  }

  Future<List<AnimalReport>> fetchReportsByUser(String userId) async {
    final response = await _client
        .from('animal_reports')
        .select(_reportSelect)
        .eq('created_by', userId)
        .order('created_at', ascending: false);

    return response
        .map<AnimalReport>((item) => AnimalReport.fromMap(item))
        .toList();
  }

  Future<String> createReport({
    required String createdBy,
    required AnimalReport report,
  }) async {
    final response = await _client
        .from('animal_reports')
        .insert(report.toInsertMap(createdBy: createdBy))
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    await _client
        .from('animal_reports')
        .update({'status': status})
        .eq('id', reportId);
  }

  Future<void> closeOwnReport({
    required String reportId,
  }) async {
    await _client
        .from('animal_reports')
        .update({
          'status': 'closed_unresolved',
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reportId);
  }

  Future<List<ReportUpdate>> fetchReportUpdates(String reportId) async {
    final response = await _client
        .from('report_updates')
        .select()
        .eq('report_id', reportId)
        .order('created_at', ascending: false);

    return response
        .map<ReportUpdate>((item) => ReportUpdate.fromMap(item))
        .toList();
  }

  Future<void> createReportUpdate({
    required String reportId,
    required String userId,
    required String comment,
    String? oldStatus,
    String? newStatus,
  }) async {
    await _client.from('report_updates').insert({
      'report_id': reportId,
      'user_id': userId,
      'comment': comment,
      'old_status': oldStatus,
      'new_status': newStatus,
    });
  }

  Future<void> flagReport({
    required String reportId,
    required String userId,
    required String reason,
  }) async {
    await _client.from('report_flags').insert({
      'report_id': reportId,
      'user_id': userId,
      'reason': reason,
    });
  }

  Future<String> uploadReportImage({
    required String reportId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final normalizedExtension = fileExtension.replaceAll('.', '').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$reportId/$timestamp.$normalizedExtension';

    await _client.storage.from(reportImagesBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(normalizedExtension),
            upsert: false,
          ),
        );

    final imageUrl = _client.storage.from(reportImagesBucket).getPublicUrl(storagePath);

    await _client.from('report_images').insert({
      'report_id': reportId,
      'image_url': imageUrl,
      'storage_path': storagePath,
    });

    return imageUrl;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
