import 'api_client.dart';

/// API surface for lecturer-facing Seminar Hasil flows.
///
/// Mirrors the web `useExaminerRequests` / `useSupervisedStudentSeminars` /
/// `useRespondExaminerAssignment` hooks.
///
/// Endpoints (see services/src/routes/thesis-seminars.route.js):
///   GET  /thesis-seminars?view=examiner_requests    → ExaminerRequestItem[]
///   GET  /thesis-seminars?view=supervised_students  → SupervisedStudentSeminarItem[]
///   POST /thesis-seminars/:id/examiners/:examinerId/respond
///        ({ status, unavailableReasons? })           → RespondAssignmentResponse
class SeminarApiService {
  static final SeminarApiService _instance = SeminarApiService._internal();
  factory SeminarApiService() => _instance;
  SeminarApiService._internal();

  final ApiClient _api = ApiClient();

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
