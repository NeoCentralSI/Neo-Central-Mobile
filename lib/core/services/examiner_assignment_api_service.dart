import 'api_client.dart';

/// API surface for Head-of-Department examiner assignment flows.
///
/// Mirrors the web `useAssignmentSeminars` / `useEligibleExaminers` /
/// `useAssignExaminers` hooks and the parallel defence hooks.
///
/// Endpoints (all guarded by `Ketua Departemen` role on the backend):
///   GET  /thesis-seminars?view=assignment        → AssignmentSeminarItem[]
///   GET  /thesis-seminars/:id/eligible-examiners → EligibleExaminer[]
///   POST /thesis-seminars/:id/examiners          ({ examinerIds })
///   GET  /thesis-defences?view=assignment        → AssignmentDefenceItem[]
///   GET  /thesis-defences/:id/eligible-examiners → EligibleExaminer[]
///   POST /thesis-defences/:id/examiners          ({ examinerIds })
class ExaminerAssignmentApiService {
  static final ExaminerAssignmentApiService _instance =
      ExaminerAssignmentApiService._internal();
  factory ExaminerAssignmentApiService() => _instance;
  ExaminerAssignmentApiService._internal();

  final ApiClient _api = ApiClient();

  // ── Seminar Hasil ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAssignmentSeminars() async {
    final res = await _api.get(
      '/thesis-seminars',
      queryParams: const {'view': 'assignment'},
    );
    return _unwrapList(res);
  }

  Future<List<Map<String, dynamic>>> getEligibleSeminarExaminers(
    String seminarId,
  ) async {
    final res = await _api.get('/thesis-seminars/$seminarId/eligible-examiners');
    return _unwrapList(res);
  }

  Future<List<Map<String, dynamic>>> assignSeminarExaminers(
    String seminarId,
    List<String> examinerIds,
  ) async {
    final res = await _api.post(
      '/thesis-seminars/$seminarId/examiners',
      body: {'examinerIds': examinerIds},
    );
    return _unwrapList(res);
  }

  // ── Sidang TA (Defence) ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAssignmentDefences() async {
    final res = await _api.get(
      '/thesis-defences',
      queryParams: const {'view': 'assignment'},
    );
    return _unwrapList(res);
  }

  Future<List<Map<String, dynamic>>> getEligibleDefenceExaminers(
    String defenceId,
  ) async {
    final res = await _api.get('/thesis-defences/$defenceId/eligible-examiners');
    return _unwrapList(res);
  }

  Future<List<Map<String, dynamic>>> assignDefenceExaminers(
    String defenceId,
    List<String> examinerIds,
  ) async {
    final res = await _api.post(
      '/thesis-defences/$defenceId/examiners',
      body: {'examinerIds': examinerIds},
    );
    return _unwrapList(res);
  }

  // Backend may return either a bare list or `{ data: [...] }` / `{ items: [...] }`.
  List<Map<String, dynamic>> _unwrapList(dynamic res) {
    final raw = res is List
        ? res
        : res is Map<String, dynamic>
            ? (res['data'] ?? res['items'] ?? res['examiners'] ?? const [])
            : const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
