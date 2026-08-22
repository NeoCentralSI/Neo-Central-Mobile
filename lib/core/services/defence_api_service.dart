import 'api_client.dart';

/// API surface for lecturer-facing Sidang TA flows.
///
/// Endpoints (see services/src/routes/thesis-defences.route.js):
///   GET  /thesis-defences?view=examiner_requests    → ExaminerDefenceRequestItem[]
///   GET  /thesis-defences?view=supervised_students  → SupervisedStudentDefenceItem[]
///   POST /thesis-defences/:id/examiners/:examinerId/respond
///   GET  /thesis-defences/:id
///   GET  /thesis-defences/:id/assessment
///   POST /thesis-defences/:id/assessment
///   GET  /thesis-defences/:id/finalization
///   POST /thesis-defences/:id/finalize
///   GET  /thesis-defences/:id/revisions
///   PATCH /thesis-defences/:id/revisions/:revisionId
///   POST /thesis-defences/:id/revisions/finalize
///   POST /thesis-defences/:id/revisions/unfinalize
class DefenceApiService {
  static final DefenceApiService _instance = DefenceApiService._internal();
  factory DefenceApiService() => _instance;
  DefenceApiService._internal();

  final ApiClient _api = ApiClient();

  // ── List views ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExaminerRequests({String? search}) async {
    final res = await _api.get(
      '/thesis-defences',
      queryParams: {
        'view': 'examiner_requests',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _unwrapList(res);
  }

  Future<List<Map<String, dynamic>>> getSupervisedStudentDefences({
    String? search,
  }) async {
    final res = await _api.get(
      '/thesis-defences',
      queryParams: {
        'view': 'supervised_students',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _unwrapList(res);
  }

  // ── Detail ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDefenceDetail(String defenceId) async {
    final res = await _api.get('/thesis-defences/$defenceId');
    return _unwrapMap(res);
  }

  // ── Assessment ───────────────────────────────────────────────

  /// Returns the assessment form for the current user (examiner or supervisor).
  /// Response includes `assessorRole: 'examiner' | 'supervisor'`.
  Future<Map<String, dynamic>> getDefenceAssessment(String defenceId) async {
    final res = await _api.get('/thesis-defences/$defenceId/assessment');
    return _unwrapMap(res);
  }

  /// Submit or save draft assessment.
  /// [scores] — list of `{ assessmentCriteriaId, score }` maps.
  /// [revisionNotes] — for examiner role.
  /// [supervisorNotes] — for supervisor role.
  Future<void> submitDefenceAssessment(
    String defenceId, {
    required List<Map<String, dynamic>> scores,
    String? revisionNotes,
    String? supervisorNotes,
    required bool isDraft,
  }) async {
    await _api.post(
      '/thesis-defences/$defenceId/assessment',
      body: {
        'scores': scores,
        if (revisionNotes != null && revisionNotes.isNotEmpty)
          'revisionNotes': revisionNotes,
        if (supervisorNotes != null && supervisorNotes.isNotEmpty)
          'supervisorNotes': supervisorNotes,
        'isDraft': isDraft,
      },
    );
  }

  // ── Finalization ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getDefenceFinalizationData(String defenceId) async {
    final res = await _api.get('/thesis-defences/$defenceId/finalization');
    return _unwrapMap(res);
  }

  /// Finalize defence result (supervisor only).
  Future<void> finalizeDefence(
    String defenceId, {
    required bool recommendRevision,
  }) async {
    await _api.post(
      '/thesis-defences/$defenceId/finalize',
      body: {'recommendRevision': recommendRevision},
    );
  }

  // ── Revisions ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDefenceRevisions(String defenceId) async {
    final res = await _api.get('/thesis-defences/$defenceId/revisions');
    return _unwrapMap(res);
  }

  Future<void> updateDefenceRevision(
    String defenceId,
    String revisionId, {
    required String action,
    String? description,
    String? revisionAction,
  }) async {
    await _api.patch(
      '/thesis-defences/$defenceId/revisions/$revisionId',
      body: {
        'action': action,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (revisionAction != null && revisionAction.trim().isNotEmpty)
          'revisionAction': revisionAction.trim(),
      },
    );
  }

  Future<void> finalizeDefenceRevisions(String defenceId) async {
    await _api.post('/thesis-defences/$defenceId/revisions/finalize', body: {});
  }

  Future<void> unfinalizeDefenceRevisions(String defenceId) async {
    await _api.post('/thesis-defences/$defenceId/revisions/unfinalize', body: {});
  }

  // ── Student-facing endpoints ─────────────────────────────────

  /// GET /me/overview — registration checklist, milestones, current defence.
  Future<Map<String, dynamic>> getStudentDefenceOverview() async {
    final res = await _api.get('/thesis-defences/me/overview');
    return _unwrapMap(res);
  }

  /// GET /me/history — student's failed/cancelled defence attempts.
  Future<List<Map<String, dynamic>>> getStudentDefenceHistory() async {
    final res = await _api.get('/thesis-defences/me/history');
    return _unwrapList(res);
  }

  /// GET /documents/types — list of expected defence document types.
  Future<List<Map<String, dynamic>>> getDefenceDocumentTypes() async {
    final res = await _api.get('/thesis-defences/documents/types');
    return _unwrapList(res);
  }

  /// POST /:id/documents — multipart upload by student.
  /// Pass `"active"` as [defenceId] when the defence has not been created yet
  /// (backend will auto-create on first upload, matching the web flow).
  Future<Map<String, dynamic>> uploadStudentDocument(
    String defenceId, {
    required String filePath,
    required String fileName,
    required String documentTypeName,
  }) async {
    final res = await _api.postMultipart(
      '/thesis-defences/$defenceId/documents',
      fields: {'documentTypeName': documentTypeName},
      filePath: filePath,
      fileName: fileName,
      fileField: 'file',
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(res);
    }
    return const {};
  }

  /// POST /:id/revisions — student creates a new defence revision item.
  Future<Map<String, dynamic>> createDefenceRevision(
    String defenceId, {
    required String defenceExaminerId,
    required String description,
    String? revisionAction,
  }) async {
    final res = await _api.post(
      '/thesis-defences/$defenceId/revisions',
      body: {
        'defenceExaminerId': defenceExaminerId,
        'description': description.trim(),
        if (revisionAction != null && revisionAction.trim().isNotEmpty)
          'revisionAction': revisionAction.trim(),
      },
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(res);
    }
    return const {};
  }

  /// DELETE /:id/revisions/:revisionId — student deletes a revision item.
  Future<Map<String, dynamic>> deleteDefenceRevision(
    String defenceId,
    String revisionId,
  ) async {
    final res = await _api.delete(
      '/thesis-defences/$defenceId/revisions/$revisionId',
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(res);
    }
    return const {};
  }

  // ── Examiner assignment respond ──────────────────────────────

  Future<Map<String, dynamic>> respondToExaminerAssignment(
    String defenceId,
    String examinerId, {
    required String status,
    String? unavailableReasons,
  }) async {
    final res = await _api.post(
      '/thesis-defences/$defenceId/examiners/$examinerId/respond',
      body: {
        'status': status,
        if (unavailableReasons != null && unavailableReasons.trim().isNotEmpty)
          'unavailableReasons': unavailableReasons.trim(),
      },
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(res);
    }
    return const {};
  }

  // ── Helpers ──────────────────────────────────────────────────

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
      if (data is Map<String, dynamic>) return data;
      return res;
    }
    return const {};
  }
}
