import 'api_client.dart';

/// API service for lecturer-facing thesis guidance endpoints.
///
/// Base path: /thesisGuidance/lecturer
class LecturerApiService {
  static final LecturerApiService _instance = LecturerApiService._internal();
  factory LecturerApiService() => _instance;
  LecturerApiService._internal();

  final ApiClient _api = ApiClient();
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

  /// GET /thesisGuidance/lecturer/requests
  /// Returns pending guidance requests from students.
  Future<List<dynamic>> getRequests() async {
    final res = await _api.get('$_base/requests');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('requests') && res['requests'] is List) {
        return res['requests'] as List;
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
    final res = await _api.patch('$_base/requests/$guidanceId/approve', body: body);
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
    final res = await _api.patch('$_base/requests/$guidanceId/reject', body: body);
    if (res is Map<String, dynamic>) return res;
    return {'success': true};
  }

  /// GET /thesisGuidance/lecturer/scheduled
  /// Returns scheduled (approved) guidance sessions.
  Future<List<dynamic>> getScheduledGuidances() async {
    final res = await _api.get('$_base/scheduled');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('guidances') && res['guidances'] is List) {
        return res['guidances'] as List;
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

  // ── Session Summary Approval ────────────────────────────────

  /// GET /thesisGuidance/lecturer/pending-approval
  /// Returns guidance sessions with summaries pending lecturer approval.
  Future<List<dynamic>> getPendingApproval() async {
    final res = await _api.get('$_base/pending-approval');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('guidances') && res['guidances'] is List) {
        return res['guidances'] as List;
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

  // ── Guidance History for a Student ──────────────────────────

  /// GET /thesisGuidance/lecturer/guidance-history/:studentId
  /// Returns guidance sessions for a specific student.
  Future<List<dynamic>> getGuidanceHistory(String studentId) async {
    final res = await _api.get('$_base/guidance-history/$studentId');
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

  // ── Progress ────────────────────────────────────────────────

  /// GET /thesisGuidance/lecturer/progress
  /// Returns milestone progress for all students.
  Future<List<dynamic>> getProgress() async {
    final res = await _api.get('$_base/progress');
    if (res is List) {
      return res;
    }
    if (res is Map && res.containsKey('students')) {
      return res['students'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  /// GET /thesisGuidance/lecturer/progress/:studentId
  /// Returns detailed milestone progress for a specific student.
  Future<Map<String, dynamic>> getStudentProgressDetail(String studentId) async {
    final res = await _api.get('$_base/progress/$studentId');
    return res as Map<String, dynamic>;
  }

  /// PATCH /thesisGuidance/lecturer/progress/:studentId/final-approval
  /// Approves the student's 100% completion for seminar readiness.
  Future<void> finalApproval(String studentId) async {
    await _api.patch('$_base/progress/$studentId/final-approval', body: {});
  }

  // ── Transfers ───────────────────────────────────────────────

  /// GET /thesisGuidance/lecturer/transfer/incoming
  /// Returns list of incoming student transfer requests.
  Future<List<dynamic>> getIncomingTransfers() async {
    final res = await _api.get('$_base/transfer/incoming');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('data') && res['data'] is List) {
        return res['data'] as List;
      }
      if (res.containsKey('items') && res['items'] is List) {
        return res['items'] as List;
      }
      if (res.containsKey('requests') && res['requests'] is List) {
        return res['requests'] as List;
      }
    }
    return [];
  }

  /// PATCH /thesisGuidance/lecturer/transfer/:notificationId/approve
  Future<void> approveTransfer(String notificationId) async {
    await _api.patch('$_base/transfer/$notificationId/approve', body: {});
  }

  /// PATCH /thesisGuidance/lecturer/transfer/:notificationId/reject
  Future<void> rejectTransfer(String notificationId, String reason) async {
    await _api.patch(
      '$_base/transfer/$notificationId/reject',
      body: {'reviewNotes': reason},
    );
  }

  // ── Topic Changes ───────────────────────────────────────────

  /// GET /thesis-change-requests/lecturer/pending
  /// Returns all topic change requests pending for this lecturer.
  Future<List<dynamic>> getPendingTopicChanges() async {
    final res = await _api.get('/thesis-change-requests/lecturer/pending');
    if (res is List) return res;
    if (res is Map) {
      if (res.containsKey('data') && res['data'] is List) {
        return res['data'] as List;
      }
      if (res.containsKey('items') && res['items'] is List) {
        return res['items'] as List;
      }
      if (res.containsKey('requests') && res['requests'] is List) {
        return res['requests'] as List;
      }
    }
    return [];
  }

  /// POST /thesis-change-requests/:requestId/review
  Future<void> approveTopicChange(String requestId, String notes) async {
    await _api.post(
      '/thesis-change-requests/$requestId/review',
      body: {'status': 'approved', 'notes': notes},
    );
  }

  /// POST /thesis-change-requests/:requestId/review
  Future<void> rejectTopicChange(String requestId, String notes) async {
    await _api.post(
      '/thesis-change-requests/$requestId/review',
      body: {'status': 'rejected', 'notes': notes},
    );
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
    final res = await _api.post('/milestones/$milestoneId/validate', body: body);
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
}
