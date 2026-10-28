import '../../../core/services/api_client.dart';
import 'announcement_models.dart';

/// Endpoints used by Pengumuman and the Seminar Hasil detail opened from it.
///
/// Every endpoint answers `{ success, data }`; errors carry the backend
/// `message`, which the screens show unchanged.
class AnnouncementApiService {
  AnnouncementApiService({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  static Object? _data(Object? response) =>
      response is Map ? response['data'] : null;

  static String? _message(Object? response) {
    final data = _data(response);
    final message = data is Map ? data['message'] : null;
    return message is String && message.trim().isNotEmpty ? message : null;
  }

  /// GET /thesis-seminars/announcements
  Future<List<SeminarAnnouncement>> getSeminarAnnouncements() async {
    final data = _data(await _api.get('/thesis-seminars/announcements'));
    if (data is! List) return const [];
    return data
        .map(SeminarAnnouncement.tryParse)
        .whereType<SeminarAnnouncement>()
        .toList();
  }

  /// POST /thesis-seminars/:id/audience-register (student only).
  /// Returns the backend confirmation, if any.
  Future<String?> registerAsAudience(String seminarId) async => _message(
    await _api.post('/thesis-seminars/$seminarId/audience-register'),
  );

  /// DELETE /thesis-seminars/:id/audience-register (student only).
  Future<String?> unregisterFromAudience(String seminarId) async => _message(
    await _api.delete('/thesis-seminars/$seminarId/audience-register'),
  );

  /// GET /thesis-seminars/:id
  Future<SeminarDetail> getSeminarDetail(String seminarId) async =>
      SeminarDetail.fromJson(
        _data(await _api.get('/thesis-seminars/$seminarId')),
      );

  /// GET /thesis-seminars/:id/audiences
  Future<List<SeminarAudience>> getAudiences(String seminarId) async {
    final data = _data(await _api.get('/thesis-seminars/$seminarId/audiences'));
    if (data is! List) return const [];
    return data.map(SeminarAudience.fromJson).toList();
  }

  /// PATCH /thesis-seminars/:id/audiences/:studentId with `approve` or
  /// `unapprove` (the seminar's supervisors only, as on web).
  Future<void> setAudiencePresence(
    String seminarId,
    String studentId, {
    required bool present,
  }) async {
    await _api.patch(
      '/thesis-seminars/$seminarId/audiences/$studentId',
      body: {'action': present ? 'approve' : 'unapprove'},
    );
  }

  /// GET /yudisiums/announcements
  Future<List<YudisiumAnnouncement>> getYudisiumAnnouncements() async {
    final data = _data(await _api.get('/yudisiums/announcements'));
    if (data is! List) return const [];
    return data
        .map(YudisiumAnnouncement.tryParse)
        .whereType<YudisiumAnnouncement>()
        .toList();
  }
}
