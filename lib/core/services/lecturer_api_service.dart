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

  /// GET /thesisGuidance/lecturer/my-students/:thesisId
  /// Returns detailed info for a specific student's thesis.
  Future<Map<String, dynamic>> getStudentDetail(String thesisId) async {
    final res = await _api.get('$_base/my-students/$thesisId');
    return res as Map<String, dynamic>;
  }

  // ── Guidance Requests ───────────────────────────────────────

  /// GET /thesisGuidance/lecturer/requests
  /// Returns pending guidance requests from students.
  Future<List<dynamic>> getRequests() async {
    final res = await _api.get('$_base/requests');
    if (res is List) {
      return res;
    }
    if (res is Map && res.containsKey('requests')) {
      return res['requests'] as List;
    }
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  /// GET /thesisGuidance/lecturer/scheduled
  /// Returns scheduled (approved) guidance sessions.
  Future<List<dynamic>> getScheduledGuidances() async {
    final res = await _api.get('$_base/scheduled');
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

  // ── Session Summary Approval ────────────────────────────────

  /// GET /thesisGuidance/lecturer/pending-approval
  /// Returns guidance sessions with summaries pending lecturer approval.
  Future<List<dynamic>> getPendingApproval() async {
    final res = await _api.get('$_base/pending-approval');
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
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return res as List? ?? [];
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
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return res as List? ?? [];
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
}
