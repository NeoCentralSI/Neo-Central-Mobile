import 'api_client.dart';

/// API service for student-facing internship activities.
/// 
/// Base path: /insternship
class InternshipApiService {
  static final InternshipApiService _instance = InternshipApiService._internal();
  factory InternshipApiService() => _instance;
  InternshipApiService._internal();

  final ApiClient _api = ApiClient();
  static const _base = '/insternship';

  // ── Dashboard / Overview ────────────────────────────────────

  /// GET /insternship/activity/logbook
  /// Returns logbooks and internship detail for the current student.
  Future<Map<String, dynamic>> getLogbookOverview() async {
    final res = await _api.get('$_base/activity/logbook');
    return res as Map<String, dynamic>;
  }

  // ── Logbook ─────────────────────────────────────────────────

  /// PUT /insternship/activity/logbook/:id
  /// Updates activity description for a specific logbook entry.
  Future<Map<String, dynamic>> updateLogbook(String id, String activityDescription) async {
    final res = await _api.put('$_base/activity/logbook/$id', body: {
      'activityDescription': activityDescription,
    });
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/logbook/finish
  /// Locks the logbook (no more edits allowed).
  Future<Map<String, dynamic>> lockLogbook() async {
    final res = await _api.post('$_base/activity/logbook/finish');
    return res as Map<String, dynamic>;
  }

  // ── Guidance / Bimbingan ────────────────────────────────────

  /// GET /insternship/activity/guidance
  /// Returns guidance timeline for the current student.
  Future<Map<String, dynamic>> getGuidanceTimeline() async {
    final res = await _api.get('$_base/activity/guidance');
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/guidance/submit
  /// Submits student guidance answers for a specific week.
  Future<Map<String, dynamic>> submitStudentGuidance(int weekNumber, Map<String, String> answers) async {
    final res = await _api.post('$_base/activity/guidance/submit', body: {
      'weekNumber': weekNumber,
      'answers': answers,
    });
    return res as Map<String, dynamic>;
  }

  // ── Documents ───────────────────────────────────────────────

  /// POST /insternship/activity/report
  /// Uploads internal internship report.
  Future<Map<String, dynamic>> uploadReport(String filePath) async {
    return await _api.postMultipart(
      '$_base/activity/report',
      filePath: filePath,
    );
  }

  /// POST /insternship/activity/certificate
  /// Uploads completion certificate from company.
  Future<Map<String, dynamic>> uploadCertificate(String filePath) async {
    return await _api.postMultipart(
      '$_base/activity/certificate',
      filePath: filePath,
    );
  }

  /// POST /insternship/activity/receipt
  /// Uploads company receipt (KP-004).
  Future<Map<String, dynamic>> uploadReceipt(String filePath) async {
    return await _api.postMultipart(
      '$_base/activity/receipt',
      filePath: filePath,
    );
  }

  // ── Seminar ────────────────────────────────────────────────
  
  /// GET /insternship/activity/seminars
  /// Returns a list of upcoming seminars for all students.
  Future<List<dynamic>> getUpcomingSeminars() async {
    final res = await _api.get('$_base/activity/seminars');
    if (res is Map && res.containsKey('data')) {
      return res['data'] as List;
    }
    return [];
  }

  /// GET /insternship/activity/seminars/:id
  /// Returns detail for a specific seminar.
  Future<Map<String, dynamic>> getSeminarDetail(String id) async {
    final res = await _api.get('$_base/activity/seminars/$id');
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/seminars/:id/audience
  /// Registers the current student as audience (attendance).
  Future<Map<String, dynamic>> registerAttendance(String seminarId) async {
    final res = await _api.post('$_base/activity/seminars/$seminarId/audience');
    return res as Map<String, dynamic>;
  }

  /// DELETE /insternship/activity/seminars/:id/audience
  /// Unregisters the current student as audience.
  Future<Map<String, dynamic>> unregisterAttendance(String seminarId) async {
    final res = await _api.delete('$_base/activity/seminars/$seminarId/audience');
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/register-seminar
  /// Registers the current student for an internship seminar.
  Future<Map<String, dynamic>> registerSeminar(Map<String, dynamic> data) async {
    final res = await _api.post('$_base/activity/register-seminar', body: data);
    return res as Map<String, dynamic>;
  }

  // ── Lecturer Facing ─────────────────────────────────────────

  /// GET /insternship/activity/guidance/lecturer/students
  /// Returns a list of internship students supervised by the current lecturer.
  Future<List<dynamic>> getSupervisedStudents() async {
    final res = await _api.get('$_base/activity/guidance/lecturer/students');
    if (res is List) return res;
    if (res is Map && res['success'] == true) return res['data'] as List;
    return [];
  }

  /// GET /insternship/activity/guidance/lecturer/students/:internshipId
  /// Returns the guidance timeline for a specific supervised student.
  Future<Map<String, dynamic>> getSupervisedStudentTimeline(String internshipId) async {
    final res = await _api.get('$_base/activity/guidance/lecturer/students/$internshipId');
    return res as Map<String, dynamic>;
  }

  /// GET /insternship/activity/guidance/lecturer/students/:internshipId/week/:weekNumber
  Future<Map<String, dynamic>> getSupervisedStudentWeekDetail(String internshipId, int weekNumber) async {
    final res = await _api.get('$_base/activity/guidance/lecturer/students/$internshipId/week/$weekNumber');
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/guidance/lecturer/students/:internshipId/week/:weekNumber/evaluate
  Future<Map<String, dynamic>> submitLecturerEvaluation(String internshipId, int weekNumber, Map<String, dynamic> evaluations) async {
    final res = await _api.post('$_base/activity/guidance/lecturer/students/$internshipId/week/$weekNumber/evaluate', body: {
      'evaluations': evaluations,
    });
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/guidance/lecturer/seminar/:id/approve
  Future<Map<String, dynamic>> approveSeminar(String seminarId) async {
    final res = await _api.post('$_base/activity/guidance/lecturer/seminar/$seminarId/approve');
    return res as Map<String, dynamic>;
  }

  /// POST /insternship/activity/guidance/lecturer/seminar/:id/reject
  Future<Map<String, dynamic>> rejectSeminar(String seminarId, String notes) async {
    final res = await _api.post('$_base/activity/guidance/lecturer/seminar/$seminarId/reject', body: {'notes': notes});
    return res as Map<String, dynamic>;
  }
}
