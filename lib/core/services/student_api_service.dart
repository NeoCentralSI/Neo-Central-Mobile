import 'api_client.dart';

/// API service for student-facing thesis guidance endpoints.
///
/// Base path: /thesisGuidance/student
class StudentApiService {
  static final StudentApiService _instance = StudentApiService._internal();
  factory StudentApiService() => _instance;
  StudentApiService._internal();

  final ApiClient _api = ApiClient();
  static const _base = '/thesisGuidance/student';

  // ── Dashboard ───────────────────────────────────────────────

  /// GET /thesisGuidance/student/my-thesis
  /// Returns thesis detail (title, supervisors, deadline, status).
  Future<Map<String, dynamic>> getMyThesis() async {
    final res = await _api.get('$_base/my-thesis');
    return res as Map<String, dynamic>;
  }

  /// GET /thesisGuidance/student/progress
  /// Returns milestone progress + guidance session count.
  Future<Map<String, dynamic>> getProgress() async {
    final res = await _api.get('$_base/progress');
    return res as Map<String, dynamic>;
  }

  // ── Guidance History ────────────────────────────────────────

  /// GET /thesisGuidance/student/history
  /// Returns list of all guidance sessions with status.
  Future<List<dynamic>> getGuidanceHistory() async {
    final res = await _api.get('$_base/history');
    if (res is List) {
      return res;
    }
    if (res is Map && res.containsKey('items')) {
      return res['items'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  // ── Guidance List ───────────────────────────────────────────

  /// GET /thesisGuidance/student/guidance
  /// Returns list of all guidance sessions (pending, scheduled, completed).
  Future<List<dynamic>> getMyGuidances() async {
    final res = await _api.get('$_base/guidance');
    if (res is List) {
      return res;
    }
    if (res is Map && res.containsKey('guidances')) {
      return res['guidances'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  // ── Supervisors ─────────────────────────────────────────────

  /// GET /thesisGuidance/student/supervisors
  /// Returns supervisors assigned to this student's thesis + thesisId.
  Future<Map<String, dynamic>> getSupervisorsWithThesisId() async {
    final res = await _api.get('$_base/supervisors');
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'supervisors': [], 'thesisId': ''};
  }

  /// GET /thesisGuidance/student/supervisors
  /// Returns supervisors assigned to this student's thesis.
  Future<List<dynamic>> getSupervisors() async {
    final res = await _api.get('$_base/supervisors');
    if (res is List) {
      return res;
    }
    if (res is Map && res.containsKey('supervisors')) {
      return res['supervisors'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  // ── Milestones ──────────────────────────────────────────────

  /// GET /milestones/thesis/:thesisId
  /// Returns milestones for a specific thesis.
  Future<List<dynamic>> getMilestones(String thesisId) async {
    final res = await _api.get('/milestones/thesis/$thesisId');
    if (res is Map && res.containsKey('milestones')) {
      return res['milestones'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    if (res is List) {
      return res;
    }
    return [];
  }

  // ── Supervisor Availability ─────────────────────────────────

  /// GET /thesisGuidance/student/supervisors/:supervisorId/availability
  /// Returns busy slots for a given supervisor.
  Future<List<dynamic>> getSupervisorAvailability(
    String supervisorId, {
    String? start,
    String? end,
  }) async {
    final params = <String, String>{};
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;
    final res = await _api.get(
      '$_base/supervisors/$supervisorId/availability',
      queryParams: params.isNotEmpty ? params : null,
    );
    if (res is Map && res.containsKey('busySlots')) {
      return res['busySlots'] as List;
    }
    if (res is List) {
      return res;
    }
    return [];
  }

  // ── Request Guidance ────────────────────────────────────────

  /// POST /thesisGuidance/student/guidance/request
  /// Creates a new guidance request (multipart/form-data).
  Future<Map<String, dynamic>> requestGuidance({
    required String guidanceDate,
    required List<String> milestoneIds,
    String? studentNotes,
    String? supervisorId,
    String? documentUrl,
    int duration = 60,
    String? filePath,
    String? fileName,
  }) async {
    final fields = <String, String>{
      'guidanceDate': guidanceDate,
      'duration': duration.toString(),
    };
    if (studentNotes != null && studentNotes.trim().isNotEmpty) {
      fields['studentNotes'] = studentNotes;
    }
    if (supervisorId != null && supervisorId.isNotEmpty) {
      fields['supervisorId'] = supervisorId;
    }
    if (documentUrl != null && documentUrl.trim().isNotEmpty) {
      fields['documentUrl'] = documentUrl;
    }

    // milestoneIds[] as repeated fields
    final listFields = milestoneIds
        .map((id) => MapEntry('milestoneIds[]', id))
        .toList();

    final res = await _api.postMultipart(
      '$_base/guidance/request',
      fields: fields,
      listFields: listFields,
      filePath: filePath,
      fileName: fileName,
    );

    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'success': true};
  }

  // ── Cancel Guidance ─────────────────────────────────────────

  /// PATCH /thesisGuidance/student/guidance/:guidanceId/cancel
  /// Cancels a guidance request (before it's completed).
  Future<Map<String, dynamic>> cancelGuidance(
    String guidanceId, {
    String? reason,
  }) async {
    final body = <String, dynamic>{};
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason;
    }
    final res = await _api.patch(
      '$_base/guidance/$guidanceId/cancel',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  // ── Reschedule Guidance ─────────────────────────────────────

  /// PATCH /thesisGuidance/student/guidance/:guidanceId/reschedule
  /// Reschedules a guidance request to a new date/time.
  Future<Map<String, dynamic>> rescheduleGuidance(
    String guidanceId, {
    required DateTime guidanceDate,
    String? studentNotes,
  }) async {
    final body = <String, dynamic>{
      'guidanceDate': guidanceDate.toUtc().toIso8601String(),
    };
    if (studentNotes != null && studentNotes.trim().isNotEmpty) {
      body['studentNotes'] = studentNotes;
    }
    final res = await _api.patch(
      '$_base/guidance/$guidanceId/reschedule',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  // ── Submit Session Summary (Catatan Bimbingan) ──────────────

  /// POST /thesisGuidance/student/guidance/:guidanceId/submit-summary
  /// Submits session summary and action items after a guidance session.
  Future<Map<String, dynamic>> submitSessionSummary(
    String guidanceId, {
    required String sessionSummary,
    String? actionItems,
  }) async {
    final body = <String, dynamic>{
      'sessionSummary': sessionSummary,
    };
    if (actionItems != null && actionItems.trim().isNotEmpty) {
      body['actionItems'] = actionItems;
    }
    final res = await _api.post(
      '$_base/guidance/$guidanceId/submit-summary',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  // ── Update Milestone Progress ───────────────────────────────

  /// PATCH /milestones/:milestoneId/progress
  /// Updates milestone progress percentage (0–100).
  Future<Map<String, dynamic>> updateMilestoneProgress(
    String milestoneId, {
    required int progressPercentage,
  }) async {
    final res = await _api.patch(
      '/milestones/$milestoneId/progress',
      body: {'progressPercentage': progressPercentage},
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// PATCH /milestones/:milestoneId/status
  /// Updates milestone status (not_started, in_progress, pending_review, revision_needed).
  Future<Map<String, dynamic>> updateMilestoneStatus(
    String milestoneId, {
    required String status,
    String? notes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes;
    }
    final res = await _api.patch(
      '/milestones/$milestoneId/status',
      body: body,
    );
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }
}
