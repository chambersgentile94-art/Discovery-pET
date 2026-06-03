import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adoption_request.dart';
import '../models/alert_event.dart';
import '../models/alert_preference.dart';
import '../models/animal_report.dart';
import '../models/report_flag.dart';
import '../models/report_update.dart';
import '../models/user_profile.dart';

class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String reportImagesBucket = 'report-images';

  String get _reportSelect => '*, report_images(image_url, storage_path)';

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromMap(response);
  }

  Future<void> updateCurrentProfile({
    required String fullName,
    required String phone,
    required String city,
    required String role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    final normalizedRole = role == 'admin' ? 'user' : role;

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim().isEmpty ? null : phone.trim(),
      'city': city.trim().isEmpty ? null : city.trim(),
      'role': normalizedRole,
    }).eq('id', user.id);
  }

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

  Future<void> hideReport({
    required String reportId,
  }) async {
    await _client
        .from('animal_reports')
        .update({
          'is_public': false,
          'status': 'invalid',
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

  Future<List<ReportFlag>> fetchPendingFlags() async {
    final response = await _client
        .from('report_flags')
        .select('*, animal_reports(title, category, urgency)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return response
        .map<ReportFlag>((item) => ReportFlag.fromMap(item))
        .toList();
  }

  Future<void> updateFlagStatus({
    required String flagId,
    required String status,
  }) async {
    await _client
        .from('report_flags')
        .update({'status': status})
        .eq('id', flagId);
  }

  Future<void> createAdoptionRequest({
    required String reportId,
    required String requesterId,
    required String message,
  }) async {
    await _client.from('adoption_requests').insert({
      'report_id': reportId,
      'requester_id': requesterId,
      'message': message,
    });
  }

  Future<List<AdoptionRequest>> fetchAdoptionRequestsForMyReports(String ownerId) async {
    final response = await _client
        .from('adoption_requests')
        .select('*, animal_reports!inner(title, created_by), profiles(full_name, email)')
        .eq('animal_reports.created_by', ownerId)
        .order('created_at', ascending: false);

    return response
        .map<AdoptionRequest>((item) => AdoptionRequest.fromMap(item))
        .toList();
  }

  Future<void> updateAdoptionRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _client
        .from('adoption_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<AlertPreference?> fetchCurrentAlertPreference() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('alert_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return AlertPreference.fromMap(response);
  }

  Future<void> upsertAlertPreference(AlertPreference preference) async {
    await _client.from('alert_preferences').upsert(
          preference.toUpsertMap(),
          onConflict: 'user_id',
        );
  }

  Future<List<AlertEvent>> fetchCurrentUserAlertEvents() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('alert_events')
        .select('*, animal_reports($_reportSelect)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response
        .map<AlertEvent>((item) => AlertEvent.fromMap(item))
        .toList();
  }

  Future<int> fetchCurrentUserPendingAlertCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('alert_events')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .count(CountOption.exact);

    return response.count;
  }

  Future<int> recalculateCurrentUserAlertEvents() async {
    final response = await _client.rpc('recalculate_my_alert_events');
    if (response is int) return response;
    if (response is num) return response.toInt();
    return 0;
  }

  Future<void> updateAlertEventStatus({
    required String eventId,
    required String status,
  }) async {
    await _client.from('alert_events').update({
      'status': status,
      if (status == 'seen' || status == 'dismissed')
        'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<void> markAllCurrentUserAlertEventsAsSeen() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('alert_events')
        .update({
          'status': 'seen',
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('status', 'pending');
  }

  Future<void> upsertCurrentUserDevice({
    required String pushToken,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('user_devices').upsert(
      {
        'user_id': user.id,
        'platform': platform,
        'device_id': deviceId,
        'push_token': pushToken,
        'app_version': appVersion,
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'push_token',
    );
  }

  Future<void> deactivateCurrentUserDeviceToken(String pushToken) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('user_devices')
        .update({
          'is_active': false,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('push_token', pushToken);
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
