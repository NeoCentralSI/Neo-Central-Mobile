import '../../features/seminar/data/models/seminar_models.dart';
import '../../features/thesis_shared/data/models/academic_requirement.dart';
import '../../features/thesis_shared/data/models/revision_models.dart';
import '../utils/api_contract_parser.dart';
import 'api_client.dart';

class AssessmentScoreInput {
  final String assessmentCriteriaId;
  final num score;

  const AssessmentScoreInput({
    required this.assessmentCriteriaId,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'assessmentCriteriaId': assessmentCriteriaId,
    'score': score,
  };
}

/// Typed API surface for all Seminar Hasil use cases on mobile.
class SeminarApiService {
  static final SeminarApiService _instance = SeminarApiService._internal();

  factory SeminarApiService() => _instance;

  SeminarApiService._internal() : _api = ApiClient();

  SeminarApiService.withApiClient(ApiClient apiClient) : _api = apiClient;

  final ApiClient _api;

  Future<List<LecturerSeminarListItem>> getExaminerRequests({String? search}) =>
      _api.getData(
        '/thesis-seminars',
        queryParams: {
          'view': 'examiner_requests',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        decoder: (value) => requireJsonList(
          value,
          context: 'examinerRequests',
        ).map(LecturerSeminarListItem.parse).toList(growable: false),
      );

  Future<List<LecturerSeminarListItem>> getSupervisedStudentSeminars({
    String? search,
  }) => _api.getData(
    '/thesis-seminars',
    queryParams: {
      'view': 'supervised_students',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    },
    decoder: (value) => requireJsonList(
      value,
      context: 'supervisedSeminars',
    ).map(LecturerSeminarListItem.parse).toList(growable: false),
  );

  Future<AssignmentResponseResult> respondToExaminerAssignment(
    String seminarId,
    String examinerId, {
    required ExaminerResponse response,
    String? unavailableReasons,
  }) {
    final reason = unavailableReasons?.trim();
    return _api.postData(
      '/thesis-seminars/$seminarId/examiners/$examinerId/respond',
      body: {
        'status': response.value,
        if (reason != null && reason.isNotEmpty) 'unavailableReasons': reason,
      },
      decoder: AssignmentResponseResult.fromJson,
    );
  }

  Future<SeminarDetail> getSeminarDetail(String seminarId) => _api.getData(
    '/thesis-seminars/$seminarId',
    decoder: SeminarDetail.fromJson,
  );

  Future<SeminarAssessmentForm> getAssessment(String seminarId) => _api.getData(
    '/thesis-seminars/$seminarId/assessment',
    decoder: SeminarAssessmentForm.fromJson,
  );

  Future<AssessmentSubmissionResult> submitAssessment(
    String seminarId, {
    required List<AssessmentScoreInput> scores,
    String? revisionNotes,
    required bool isDraft,
  }) => _api.postData(
    '/thesis-seminars/$seminarId/assessment',
    body: {
      'scores': scores.map((item) => item.toJson()).toList(growable: false),
      if (revisionNotes != null) 'revisionNotes': revisionNotes.trim(),
      'isDraft': isDraft,
    },
    decoder: AssessmentSubmissionResult.fromJson,
  );

  Future<SeminarFinalizationData> getFinalizationData(String seminarId) =>
      _api.getData(
        '/thesis-seminars/$seminarId/finalization',
        decoder: SeminarFinalizationData.fromJson,
      );

  Future<SeminarFinalizationResult> finalizeSeminar(
    String seminarId, {
    required bool recommendRevision,
  }) => _api.postData(
    '/thesis-seminars/$seminarId/finalize',
    body: {'recommendRevision': recommendRevision},
    decoder: SeminarFinalizationResult.fromJson,
  );

  Future<List<SeminarAudience>> getAudiences(String seminarId) => _api.getData(
    '/thesis-seminars/$seminarId/audiences',
    decoder: (value) => requireJsonList(
      value,
      context: 'seminarAudiences',
    ).map(SeminarAudience.fromJson).toList(growable: false),
  );

  Future<void> updateAudience(
    String seminarId,
    String studentId, {
    required AudienceAction action,
  }) => _api.patchData<void>(
    '/thesis-seminars/$seminarId/audiences/$studentId',
    body: {'action': action.value},
    decoder: (value) {
      requireJsonMap(value, context: 'audienceMutation');
    },
  );

  Future<RevisionBoard> getRevisions(String seminarId) => _api.getData(
    '/thesis-seminars/$seminarId/revisions',
    decoder: RevisionBoard.fromJson,
  );

  Future<void> updateRevision(
    String seminarId,
    String revisionId, {
    required SeminarRevisionAction action,
    String? description,
    String? revisionAction,
  }) => _api.patchData<void>(
    '/thesis-seminars/$seminarId/revisions/$revisionId',
    body: {
      'action': action.value,
      if (description != null) 'description': description.trim(),
      if (revisionAction != null) 'revisionAction': revisionAction.trim(),
    },
    decoder: (value) {
      requireJsonMap(value, context: 'revisionMutation');
    },
  );

  Future<void> createRevision(
    String seminarId, {
    required String seminarExaminerId,
    required String description,
    String? revisionAction,
  }) => _api.postData<void>(
    '/thesis-seminars/$seminarId/revisions',
    body: {
      'seminarExaminerId': seminarExaminerId,
      'description': description.trim(),
      if (revisionAction != null) 'revisionAction': revisionAction.trim(),
    },
    decoder: (value) {
      requireJsonMap(value, context: 'revisionCreate');
    },
  );

  Future<void> deleteRevision(String seminarId, String revisionId) =>
      _api.deleteData<void>(
        '/thesis-seminars/$seminarId/revisions/$revisionId',
        decoder: (value) {
          requireJsonMap(value, context: 'revisionDelete');
        },
      );

  Future<void> finalizeRevisions(String seminarId) => _api.postData<void>(
    '/thesis-seminars/$seminarId/revisions/finalize',
    decoder: (value) {
      requireJsonMap(value, context: 'revisionFinalize');
    },
  );

  Future<void> unfinalizeRevisions(String seminarId) => _api.postData<void>(
    '/thesis-seminars/$seminarId/revisions/unfinalize',
    decoder: (value) {
      requireJsonMap(value, context: 'revisionUnfinalize');
    },
  );

  Future<StudentSeminarOverview> getStudentOverview() => _api.getData(
    '/thesis-seminars/me/overview',
    decoder: StudentSeminarOverview.fromJson,
  );

  Future<AttendanceHistory> getStudentAttendanceHistory() => _api.getData(
    '/thesis-seminars/me/attendance',
    decoder: AttendanceHistory.fromJson,
  );

  Future<List<SeminarHistoryItem>> getStudentSeminarHistory() => _api.getData(
    '/thesis-seminars/me/history',
    decoder: (value) => requireJsonList(
      value,
      context: 'seminarHistory',
    ).map(SeminarHistoryItem.fromJson).toList(growable: false),
  );

  Future<List<SeminarAnnouncement>> getSeminarAnnouncements() => _api.getData(
    '/thesis-seminars/announcements',
    decoder: (value) => requireJsonList(
      value,
      context: 'seminarAnnouncements',
    ).map(SeminarAnnouncement.fromJson).toList(growable: false),
  );

  Future<RequirementDocument> uploadStudentDocument(
    String? seminarId, {
    required String filePath,
    required String fileName,
    required String requirementId,
  }) async {
    final raw = await _api.postMultipart(
      '/thesis-seminars/${seminarId ?? 'active'}/documents',
      fields: {'requirementId': requirementId},
      filePath: filePath,
      fileName: fileName,
      fileField: 'file',
    );
    return _decodeMultipartData(raw, RequirementDocument.fromJson);
  }

  Future<void> registerAsAudience(String seminarId) => _api.postData<void>(
    '/thesis-seminars/$seminarId/audience-register',
    decoder: (value) {
      requireJsonMap(value, context: 'audienceRegistration');
    },
  );

  Future<void> unregisterFromAudience(String seminarId) =>
      _api.deleteData<void>(
        '/thesis-seminars/$seminarId/audience-register',
        decoder: (value) {
          requireJsonMap(value, context: 'audienceRegistration');
        },
      );

  Future<ApiBinaryResponse> downloadInvitationLetter(
    String seminarId, {
    String? letterNumber,
  }) => _api.getBinary(
    '/thesis-seminars/$seminarId/invitation-letter',
    queryParams: {
      if (letterNumber != null && letterNumber.trim().isNotEmpty)
        'nomorSurat': letterNumber.trim(),
    },
  );

  Future<ApiBinaryResponse> downloadDocument(
    String seminarId,
    String requirementId,
  ) => _api.getBinary('/thesis-seminars/$seminarId/documents/$requirementId');

  Future<ApiBinaryResponse> downloadAssessmentResult(String seminarId) =>
      _api.getBinary('/thesis-seminars/$seminarId/assessment-result');

  T _decodeMultipartData<T>(dynamic value, T Function(dynamic) decoder) {
    final envelope = requireJsonMap(value, context: 'multipartResponse');
    if (envelope['success'] is! bool || envelope['success'] != true) {
      throw ApiContractException(
        envelope['message']?.toString() ??
            'Respons upload tidak memiliki envelope sukses.',
      );
    }
    if (!envelope.containsKey('data')) {
      throw const ApiContractException(
        'Respons upload tidak memiliki field data.',
      );
    }
    return decoder(envelope['data']);
  }
}
