import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_report.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String reportImagesBucket = 'report-images';

  Future<List<AnimalReport>> fetchPublicReports() async {
    final response = await _client
        .from('animal_reports')
        .select('*, report_images(image_url, storage_path)')
        .eq('is_public', true)
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
