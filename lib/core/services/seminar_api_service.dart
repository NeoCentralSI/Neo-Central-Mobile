import 'api_client.dart';

/// API surface for lecturer-facing Seminar Hasil flows.
///
/// Mirrors web hooks in `useThesisSeminar*` (see `website/src/hooks/thesis-seminar`)
/// and routes in `services/src/routes/thesis-seminars.route.js`.
class SeminarApiService {
  static final SeminarApiService _instance = SeminarApiService._internal();
  factory SeminarApiService() => _instance;
  SeminarApiService._internal();

  final ApiClient _api = ApiClient();

  // ─── List views (lecturer) ──────────────────────────────────────

  /// "Menguji Mahasiswa" tab data — seminars where the current lecturer
  /// has been assigned as examiner.
  Future<List<Map<String, dynamic>>> getExaminerRequests({String? search}) async {
    final res = await _api.get(
      '/thesis-seminars',
      queryParams: {
        'view': 'examiner_requests',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _unwrapList(res);
  }

  /// "Mahasiswa Bimbingan" tab data — seminars where the current lecturer
  /// is a supervisor (Pembimbing 1 / 2 / etc.).
  Future<List<Map<String, dynamic>>> getSupervisedStudentSeminars({
    String? search,
  }) async {
    final res = await _api.get(
      '/thesis-seminars',
      queryParams: {
        'view': 'supervised_students',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _unwrapList(res);
  }

  /// Accept / reject an examiner assignment.
  /// [status] must be `'available'` or `'unavailable'`.
  Future<Map<String, dynamic>> respondToExaminerAssignment(
    String seminarId,
    String examinerId, {
    required String status,
    String? unavailableReasons,
  }) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/examiners/$examinerId/respond',
      body: {
        'status': status,
        if (unavailableReasons != null && unavailableReasons.trim().isNotEmpty)
          'unavailableReasons': unavailableReasons.trim(),
      },
    );
    return _unwrapMap(res);
  }

  // ─── Detail ─────────────────────────────────────────────────────

  /// Full seminar detail used by the detail screen tabs.
  /// Returns the mapped object from `getSeminarDetail` (core.service.js).
  Future<Map<String, dynamic>> getSeminarDetail(String seminarId) async {
    final res = await _api.get('/thesis-seminars/$seminarId');
    return _unwrapMap(res);
  }

  // ─── Assessment ─────────────────────────────────────────────────

  /// GET /:id/assessment — examiner assessment form + criteria.
  Future<Map<String, dynamic>> getAssessment(String seminarId) async {
    final res = await _api.get('/thesis-seminars/$seminarId/assessment');
    return _unwrapMap(res);
  }

  /// POST /:id/assessment — examiner submits/saves their scores.
  Future<Map<String, dynamic>> submitAssessment(
    String seminarId, {
    required List<Map<String, dynamic>> scores,
    String? revisionNotes,
    required bool isDraft,
  }) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/assessment',
      body: {
        'scores': scores,
        if (revisionNotes != null && revisionNotes.trim().isNotEmpty)
          'revisionNotes': revisionNotes.trim(),
        'isDraft': isDraft,
      },
    );
    return _unwrapMap(res);
  }

  /// GET /:id/finalization — supervisor rekap + per-examiner scores matrix.
  Future<Map<String, dynamic>> getFinalizationData(String seminarId) async {
    final res = await _api.get('/thesis-seminars/$seminarId/finalization');
    return _unwrapMap(res);
  }

  /// POST /:id/finalize — supervisor sets passed / passed_with_revision / failed.
  Future<Map<String, dynamic>> finalizeSeminar(
    String seminarId, {
    required bool recommendRevision,
  }) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/finalize',
      body: {'recommendRevision': recommendRevision},
    );
    return _unwrapMap(res);
  }

  // ─── Audience (Peserta) ─────────────────────────────────────────

  /// GET /:id/audiences — list of registered audience members.
  Future<List<Map<String, dynamic>>> getAudiences(String seminarId) async {
    final res = await _api.get('/thesis-seminars/$seminarId/audiences');
    return _unwrapList(res);
  }

  /// PATCH /:id/audiences/:studentId — supervisor approves/unapproves presence.
  /// [action] is `'approve'` or `'unapprove'`.
  Future<Map<String, dynamic>> updateAudience(
    String seminarId,
    String studentId, {
    required String action,
  }) async {
    final res = await _api.patch(
      '/thesis-seminars/$seminarId/audiences/$studentId',
      body: {'action': action},
    );
    return _unwrapMap(res);
  }

  // ─── Revisions ──────────────────────────────────────────────────

  /// GET /:id/revisions — revision board.
  Future<Map<String, dynamic>> getRevisions(String seminarId) async {
    final res = await _api.get('/thesis-seminars/$seminarId/revisions');
    return _unwrapMap(res);
  }

  /// PATCH /:id/revisions/:revisionId — multi-action revision update.
  /// [action] is one of: `save_action`, `submit`, `cancel_submit`,
  /// `approve`, `unapprove`.
  Future<Map<String, dynamic>> updateRevision(
    String seminarId,
    String revisionId, {
    required String action,
    String? description,
    String? revisionAction,
  }) async {
    final res = await _api.patch(
      '/thesis-seminars/$seminarId/revisions/$revisionId',
      body: {
        'action': action,
        if (description != null) 'description': description,
        if (revisionAction != null) 'revisionAction': revisionAction,
      },
    );
    return _unwrapMap(res);
  }

  /// POST /:id/revisions/finalize — supervisor finalises the revision board.
  Future<Map<String, dynamic>> finalizeRevisions(String seminarId) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/revisions/finalize',
    );
    return _unwrapMap(res);
  }

  /// POST /:id/revisions/unfinalize — supervisor undoes revision finalisation.
  Future<Map<String, dynamic>> unfinalizeRevisions(String seminarId) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/revisions/unfinalize',
    );
    return _unwrapMap(res);
  }

  // ─── Helpers ────────────────────────────────────────────────────

  // Backend returns either a bare list or `{ data: [...] }`.
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

  // Backend returns either a bare map or `{ data: {...} }`.
  Map<String, dynamic> _unwrapMap(dynamic res) {
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(res);
    }
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }
}
