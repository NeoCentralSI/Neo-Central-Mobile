import 'api_client.dart';

/// API service for lecturer-facing thesis guidance endpoints.
///
/// Base path: /thesisGuidance/lecturer
class LecturerApiService {
  static final LecturerApiService _instance = LecturerApiService._(ApiClient());
  factory LecturerApiService() => _instance;
  LecturerApiService._(this._api);

  /// For tests.
  LecturerApiService.withClient(ApiClient api) : _api = api;

  final ApiClient _api;
  static const _base = '/thesisGuidance/lecturer';

  // ── My Students ─────────────────────────────────────────────

  /// GET /thesisGuidance/lecturer/my-students
  /// Returns list of students supervised by this lecturer.
  Future<List<dynamic>> getMyStudents() async {
    final res = await _api.get('$_base/my-students');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('students') && res['students'] is List) {
        return res['students'] as List;
      }
      if (res.containsKey('data') && res['data'] is List) {
        return res['data'] as List;
      }
      if (res.containsKey('items') && res['items'] is List) {
        return res['items'] as List;
      }
    }
    return [];
  }

  /// GET /thesisGuidance/lecturer/my-students/:thesisId
  /// Returns detailed info for a specific student's thesis.
  /// Unwraps the `data` envelope if present.
  Future<Map<String, dynamic>> getStudentDetail(String thesisId) async {
    final res = await _api.get('$_base/my-students/$thesisId');
    if (res is Map<String, dynamic>) {
      // Backend wraps response in {"success":true,"data":{...}}
      if (res.containsKey('data') && res['data'] is Map) {
        return res['data'] as Map<String, dynamic>;
      }
      return res;
    }
    return {};
  }

  // ── Guidance Requests ───────────────────────────────────────

  /// GET /thesisGuidance/lecturer/requests?page=&pageSize=
  /// Pending guidance requests. The backend pages the list (at most 50 per
  /// page), so every page is read. Response: `{ total, totalPages, requests }`.
  Future<List<dynamic>> getRequests() =>
      _readAllPages('$_base/requests', 'requests');

  /// PATCH /thesisGuidance/lecturer/requests/:guidanceId/approve
  /// Approves a guidance request.
  Future<Map<String, dynamic>> approveGuidanceRequest(
    String guidanceId, {
    String? feedback,
  }) async {
    final body = <String, dynamic>{};
    if (feedback != null && feedback.trim().isNotEmpty) {
      body['feedback'] = feedback;
    }
    final res = await _api.patch(
      '$_base/requests/$guidanceId/approve',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// PATCH /thesisGuidance/lecturer/requests/:guidanceId/reject
  /// Rejects a guidance request.
  Future<Map<String, dynamic>> rejectGuidanceRequest(
    String guidanceId, {
    String? feedback,
  }) async {
    final body = <String, dynamic>{};
    if (feedback != null && feedback.trim().isNotEmpty) {
      body['feedback'] = feedback;
    }
    final res = await _api.patch(
      '$_base/requests/$guidanceId/reject',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// GET /thesisGuidance/lecturer/scheduled?page=&pageSize=
  /// Response: `{ total, totalPages, guidances }`.
  Future<List<dynamic>> getScheduledGuidances() =>
      _readAllPages('$_base/scheduled', 'guidances');

  // ── Session Summary Approval ────────────────────────────────

  /// GET /thesisGuidance/lecturer/pending-approval?page=&pageSize=
  /// Session summaries waiting for approval.
  /// Response: `{ total, page, pageSize, guidances }`.
  Future<List<dynamic>> getPendingApproval() =>
      _readAllPages('$_base/pending-approval', 'guidances');

  // ── Guidance History for a Student ──────────────────────────

  /// GET /thesisGuidance/lecturer/guidance-history/:studentId
  /// Response: `{ count, items }`.
  Future<List<dynamic>> getGuidanceHistory(String studentId) async {
    final res = await _api.get('$_base/guidance-history/$studentId');
    if (res is Map && res['items'] is List) return res['items'] as List;
    return [];
  }

  // ── Progress ────────────────────────────────────────────────

  /// GET /thesisGuidance/lecturer/progress
  /// Response: `{ totalComponents, items: [{ thesisId, validated, total }] }`.
  Future<List<dynamic>> getProgress() async {
    final res = await _api.get('$_base/progress');
    if (res is Map && res['items'] is List) return res['items'] as List;
    return [];
  }

  /// GET /thesisGuidance/lecturer/progress/:studentId
  /// Returns detailed milestone progress for a specific student.
  Future<Map<String, dynamic>> getStudentProgressDetail(
    String studentId,
  ) async {
    final res = await _api.get('$_base/progress/$studentId');
    return res as Map<String, dynamic>;
  }

  /// PATCH /thesisGuidance/lecturer/progress/:studentId/final-approval
  /// Approves the student's 100% completion for seminar readiness.
  Future<void> finalApproval(String studentId) async {
    await _api.patch('$_base/progress/$studentId/final-approval', body: {});
  }

  // ── Session Summary Actions ─────────────────────────────────

  /// PUT /thesisGuidance/lecturer/guidance/:guidanceId/approve-summary
  /// Approves a session summary (1-click).
  Future<Map<String, dynamic>> approveSessionSummary(String guidanceId) async {
    final res = await _api.put('$_base/guidance/$guidanceId/approve-summary');
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  // ── Guidance Detail ─────────────────────────────────────────

  /// GET /thesisGuidance/lecturer/guidance/:guidanceId
  /// Returns full detail for a guidance session.
  Future<Map<String, dynamic>> getGuidanceDetail(String guidanceId) async {
    final res = await _api.get('$_base/guidance/$guidanceId');
    if (res is Map<String, dynamic>) {
      if (res.containsKey('guidance') && res['guidance'] is Map) {
        return res['guidance'] as Map<String, dynamic>;
      }
      return res;
    }
    return {};
  }

  // ── Milestones ──────────────────────────────────────────────

  /// GET /milestones/thesis/:thesisId
  /// Returns milestones for a specific thesis.
  Future<List<dynamic>> getMilestonesForThesis(String thesisId) async {
    final res = await _api.get('/milestones/thesis/$thesisId');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('milestones') && res['milestones'] is List) {
        return res['milestones'] as List;
      }
      if (res.containsKey('data') && res['data'] is List) {
        return res['data'] as List;
      }
    }
    return [];
  }

  /// GET /milestones/supervisor/pending-review
  /// Returns all pending_review milestones for the authenticated supervisor
  /// in a single backend query (replaces the old N+1 client-side aggregation).
  Future<List<Map<String, dynamic>>> getPendingReviewMilestones() async {
    final res = await _api.get('/milestones/supervisor/pending-review');
    if (res is Map && res.containsKey('data') && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  /// POST /milestones/:milestoneId/validate
  /// Supervisor approves a milestone.
  Future<Map<String, dynamic>> validateMilestone(
    String milestoneId, {
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (notes != null && notes.trim().isNotEmpty) {
      body['supervisorNotes'] = notes;
    }
    final res = await _api.post(
      '/milestones/$milestoneId/validate',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// POST /milestones/:milestoneId/request-revision
  /// Supervisor requests revision on a milestone.
  Future<Map<String, dynamic>> requestMilestoneRevision(
    String milestoneId,
    String revisionNotes,
  ) async {
    final res = await _api.post(
      '/milestones/$milestoneId/request-revision',
      body: {'revisionNotes': revisionNotes},
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// POST /thesisGuidance/lecturer/my-students/:thesisId/send-warning
  /// Sends a warning notification to the student.
  Future<void> sendWarningNotification(String thesisId) async {
    await _api.post('$_base/my-students/$thesisId/send-warning', body: {});
  }

  /// Reads every page of a paged list endpoint (page size 50, the backend
  /// maximum), stopping at `totalPages` or at a short page.
  Future<List<dynamic>> _readAllPages(String path, String key) async {
    const pageSize = 50;
    const maxPages = 20;
    final all = <dynamic>[];
    for (var page = 1; page <= maxPages; page++) {
      final res = await _api.get(
        path,
        queryParams: {'page': '$page', 'pageSize': '$pageSize'},
      );
      if (res is! Map) break;
      final items = res[key];
      if (items is! List) break;
      all.addAll(items);
      final totalPages = res['totalPages'];
      final total = res['total'];
      if (totalPages is num && page >= totalPages) break;
      if (total is num && all.length >= total) break;
      if (items.length < pageSize) break;
    }
    return all;
  }
}
