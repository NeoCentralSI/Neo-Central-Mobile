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
}
