import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_report.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AnimalReport>> fetchPublicReports() async {
    final response = await _client
        .from('animal_reports')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return response
        .map<AnimalReport>((item) => AnimalReport.fromMap(item))
        .toList();
  }

  Future<void> createReport({
    required String createdBy,
    required AnimalReport report,
  }) async {
    await _client.from('animal_reports').insert(
          report.toInsertMap(createdBy: createdBy),
        );
  }
}
