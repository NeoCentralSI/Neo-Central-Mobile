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
}
