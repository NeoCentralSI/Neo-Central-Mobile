import 'api_client.dart';

/// API surface for Yudisium flows on mobile.
///
/// Endpoints (see services/src/routes/yudisiums.route.js):
///   GET  /yudisiums/announcements
///   GET  /yudisiums/me/overview
///   GET  /yudisiums/me/requirements
///   POST /yudisiums/me/requirements/upload  (multipart, fields: file, requirementId)
class YudisiumApiService {
  static final YudisiumApiService _instance = YudisiumApiService._internal();
  factory YudisiumApiService() => _instance;
  YudisiumApiService._internal();

  final ApiClient _api = ApiClient();

  /// GET /announcements — yudisium events whose registration window has
  /// closed, each with the list of appointed / finalized participants.
  Future<List<Map<String, dynamic>>> getYudisiumAnnouncements() async {
    final res = await _api.get('/yudisiums/announcements');
    return _unwrapList(res);
  }

  /// GET /me/overview — student dashboard: current yudisium, checklist,
  /// participant status, CPL scores, requirements, history (rejected attempts).
  Future<Map<String, dynamic>> getStudentYudisiumOverview() async {
    final res = await _api.get('/yudisiums/me/overview');
    return _unwrapMap(res);
  }

  /// GET /me/requirements — per-requirement upload status for the current
  /// participant in the active yudisium period.
  Future<Map<String, dynamic>> getStudentYudisiumRequirements() async {
    final res = await _api.get('/yudisiums/me/requirements');
    return _unwrapMap(res);
  }

  /// POST /me/requirements/upload — multipart upload by student.
  Future<Map<String, dynamic>> uploadStudentYudisiumDocument({
    required String filePath,
    required String fileName,
    required String requirementId,
  }) async {
    final res = await _api.postMultipart(
      '/yudisiums/me/requirements/upload',
      fields: {'requirementId': requirementId},
      filePath: filePath,
      fileName: fileName,
      fileField: 'file',
    );
    return _unwrapMap(res);
  }

  // ── helpers ──────────────────────────────────────────────────

  List<Map<String, dynamic>> _unwrapList(dynamic res) {
    final raw = res is List
        ? res
        : res is Map<String, dynamic>
            ? (res['data'] ?? res['items'] ?? const [])
            : const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Map<String, dynamic> _unwrapMap(dynamic res) {
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return res;
    }
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }
}
