import '../../features/defence/data/models/defence_models.dart';
import '../../features/thesis_shared/data/models/academic_requirement.dart';
import '../utils/api_contract_parser.dart';
import 'api_client.dart';

class DefenceAssessmentScoreInput {
  final String assessmentCriteriaId;
  final num score;

  const DefenceAssessmentScoreInput({
    required this.assessmentCriteriaId,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'assessmentCriteriaId': assessmentCriteriaId,
    'score': score,
  };
}

/// Typed API surface for all Sidang Tugas Akhir use cases on mobile.
class DefenceApiService {
  static final DefenceApiService _instance = DefenceApiService._internal();

  factory DefenceApiService() => _instance;

  DefenceApiService._internal() : _api = ApiClient();

  DefenceApiService.withApiClient(ApiClient apiClient) : _api = apiClient;

  final ApiClient _api;

  Future<List<LecturerDefenceListItem>> getExaminerRequests({String? search}) =>
      _api.getData(
        '/thesis-defences',
        queryParams: {
          'view': 'examiner_requests',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        decoder: (value) => requireJsonList(
          value,
          context: 'defenceExaminerRequests',
        ).map(LecturerDefenceListItem.fromJson).toList(growable: false),
      );

  Future<List<LecturerDefenceListItem>> getSupervisedStudentDefences({
    String? search,
  }) => _api.getData(
    '/thesis-defences',
    queryParams: {
      'view': 'supervised_students',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    },
    decoder: (value) => requireJsonList(
      value,
      context: 'supervisedDefences',
    ).map(LecturerDefenceListItem.fromJson).toList(growable: false),
  );

  Future<DefenceAssignmentResponseResult> respondToExaminerAssignment(
    String defenceId,
    String examinerId, {
    required DefenceExaminerResponse response,
    String? unavailableReasons,
  }) {
    final reason = unavailableReasons?.trim();
    return _api.postData(
      '/thesis-defences/$defenceId/examiners/$examinerId/respond',
      body: {
        'status': response.value,
        if (reason != null && reason.isNotEmpty) 'unavailableReasons': reason,
      },
      decoder: DefenceAssignmentResponseResult.fromJson,
    );
  }

  Future<DefenceDetail> getDefenceDetail(String defenceId) => _api.getData(
    '/thesis-defences/$defenceId',
    decoder: DefenceDetail.fromJson,
  );

  Future<DefenceAssessmentForm> getAssessment(String defenceId) => _api.getData(
    '/thesis-defences/$defenceId/assessment',
    decoder: DefenceAssessmentForm.fromJson,
  );

  Future<DefenceAssessmentSubmissionResult> submitAssessment(
    String defenceId, {
    required List<DefenceAssessmentScoreInput> scores,
    String? revisionNotes,
    String? supervisorNotes,
    required bool isDraft,
  }) => _api.postData(
    '/thesis-defences/$defenceId/assessment',
    body: {
      'scores': scores.map((item) => item.toJson()).toList(growable: false),
      if (revisionNotes != null) 'revisionNotes': revisionNotes.trim(),
      if (supervisorNotes != null) 'supervisorNotes': supervisorNotes.trim(),
      'isDraft': isDraft,
    },
    decoder: DefenceAssessmentSubmissionResult.fromJson,
  );

  Future<DefenceFinalizationData> getFinalizationData(String defenceId) =>
      _api.getData(
        '/thesis-defences/$defenceId/finalization',
        decoder: DefenceFinalizationData.fromJson,
      );

  Future<StudentDefenceAssessment> getStudentAssessment(String defenceId) =>
      _api.getData(
        '/thesis-defences/$defenceId/assessment-view',
        decoder: StudentDefenceAssessment.fromJson,
      );

  Future<DefenceFinalizationResult> finalizeDefence(
    String defenceId, {
    required bool recommendRevision,
  }) => _api.postData(
    '/thesis-defences/$defenceId/finalize',
    body: {'recommendRevision': recommendRevision},
    decoder: DefenceFinalizationResult.fromJson,
  );

  Future<DefenceRevisionBoard> getRevisions(String defenceId) => _api.getData(
    '/thesis-defences/$defenceId/revisions',
    decoder: DefenceRevisionBoard.fromJson,
  );

  Future<void> updateRevision(
    String defenceId,
    String revisionId, {
    required DefenceRevisionAction action,
    String? description,
    String? revisionAction,
  }) => _api.patchData<void>(
    '/thesis-defences/$defenceId/revisions/$revisionId',
    body: {
      'action': action.value,
      if (description != null) 'description': description.trim(),
      if (revisionAction != null) 'revisionAction': revisionAction.trim(),
    },
    decoder: (value) {
      requireJsonMap(value, context: 'defenceRevisionMutation');
    },
  );

  Future<void> createRevision(
    String defenceId, {
    required String defenceExaminerId,
    required String description,
    String? revisionAction,
  }) => _api.postData<void>(
    '/thesis-defences/$defenceId/revisions',
    body: {
      'defenceExaminerId': defenceExaminerId,
      'description': description.trim(),
      if (revisionAction != null) 'revisionAction': revisionAction.trim(),
    },
    decoder: (value) {
      requireJsonMap(value, context: 'defenceRevisionCreate');
    },
  );

  Future<void> deleteRevision(String defenceId, String revisionId) =>
      _api.deleteData<void>(
        '/thesis-defences/$defenceId/revisions/$revisionId',
        decoder: (value) {
          requireJsonMap(value, context: 'defenceRevisionDelete');
        },
      );

  Future<void> finalizeRevisions(String defenceId) => _api.postData<void>(
    '/thesis-defences/$defenceId/revisions/finalize',
    decoder: (value) {
      requireJsonMap(value, context: 'defenceRevisionFinalize');
    },
  );

  Future<void> unfinalizeRevisions(String defenceId) => _api.postData<void>(
    '/thesis-defences/$defenceId/revisions/unfinalize',
    decoder: (value) {
      requireJsonMap(value, context: 'defenceRevisionUnfinalize');
    },
  );

  Future<StudentDefenceOverview> getStudentOverview() => _api.getData(
    '/thesis-defences/me/overview',
    decoder: StudentDefenceOverview.fromJson,
  );

  Future<List<DefenceHistoryItem>> getStudentHistory() => _api.getData(
    '/thesis-defences/me/history',
    decoder: (value) => requireJsonList(
      value,
      context: 'defenceHistory',
    ).map(DefenceHistoryItem.fromJson).toList(growable: false),
  );

  Future<RequirementDocument> uploadStudentDocument(
    String? defenceId, {
    required String filePath,
    required String fileName,
    required String requirementId,
  }) async {
    final raw = await _api.postMultipart(
      '/thesis-defences/${defenceId ?? 'active'}/documents',
      fields: {'requirementId': requirementId},
      filePath: filePath,
      fileName: fileName,
      fileField: 'file',
    );
    return _decodeMultipartData(raw, RequirementDocument.fromJson);
  }

  Future<ApiBinaryResponse> downloadDocument(
    String defenceId,
    String requirementId,
  ) => _api.getBinary(
    '/thesis-defences/$defenceId/documents/$requirementId/file',
  );

  Future<ApiBinaryResponse> downloadInvitationLetter(
    String defenceId, {
    String? letterNumber,
  }) => _api.getBinary(
    '/thesis-defences/$defenceId/invitation-letter',
    queryParams: {
      if (letterNumber != null && letterNumber.trim().isNotEmpty)
        'nomorSurat': letterNumber.trim(),
    },
  );

  Future<ApiBinaryResponse> downloadAssessmentResult(String defenceId) =>
      _api.getBinary('/thesis-defences/$defenceId/assessment-result');

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
