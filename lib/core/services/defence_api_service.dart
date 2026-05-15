import 'api_client.dart';

/// API surface for lecturer-facing Sidang TA flows.
///
/// Mirrors the web `useDefenceExaminerRequests` / `useSupervisedStudentDefences` /
/// `useRespondDefenceExaminerAssignment` hooks.
///
/// Endpoints (see services/src/routes/thesis-defences.route.js):
///   GET  /thesis-defences?view=examiner_requests    → ExaminerDefenceRequestItem[]
///   GET  /thesis-defences?view=supervised_students  → SupervisedStudentDefenceItem[]
///   POST /thesis-defences/:id/examiners/:examinerId/respond
///        ({ status, unavailableReasons? })           → RespondAssignmentResponse
class DefenceApiService {
  static final DefenceApiService _instance = DefenceApiService._internal();
  factory DefenceApiService() => _instance;
  DefenceApiService._internal();

  final ApiClient _api = ApiClient();

  /// "Menguji Mahasiswa" tab data — defences where the current lecturer
  /// has been assigned as examiner.
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

  /// "Mahasiswa Bimbingan" tab data — defences where the current lecturer
  /// is a supervisor (Pembimbing 1 / 2 / etc.).
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

  /// Accept / reject an examiner assignment.
  /// [status] must be `'available'` or `'unavailable'`.
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
}
