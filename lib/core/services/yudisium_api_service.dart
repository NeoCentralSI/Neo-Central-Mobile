import '../../features/yudisium/data/models/yudisium_models.dart';
import '../utils/api_contract_parser.dart';
import 'api_client.dart';

/// Typed API surface for the student and announcement Yudisium flows.
class YudisiumApiService {
  static final YudisiumApiService _instance = YudisiumApiService._internal();

  factory YudisiumApiService() => _instance;

  YudisiumApiService._internal() : _api = ApiClient();

  YudisiumApiService.withApiClient(ApiClient apiClient) : _api = apiClient;

  final ApiClient _api;

  Future<List<YudisiumAnnouncement>> getYudisiumAnnouncements() => _api.getData(
    '/yudisiums/announcements',
    decoder: (value) => requireJsonList(
      value,
      context: 'yudisiumAnnouncements',
    ).map(YudisiumAnnouncement.fromJson).toList(growable: false),
  );

  Future<StudentYudisiumOverview> getStudentYudisiumOverview() => _api.getData(
    '/yudisiums/me/overview',
    decoder: StudentYudisiumOverview.fromJson,
  );

  Future<StudentYudisiumRequirements> getStudentYudisiumRequirements() =>
      _api.getData(
        '/yudisiums/me/requirements',
        decoder: StudentYudisiumRequirements.fromJson,
      );

  Future<StudentYudisiumExitSurvey> getStudentExitSurvey() => _api.getData(
    '/yudisiums/me/exit-survey',
    decoder: StudentYudisiumExitSurvey.fromJson,
  );

  Future<YudisiumExitSurveySubmissionResult> submitStudentExitSurvey(
    List<YudisiumSurveyAnswerInput> answers,
  ) => _api.postData(
    '/yudisiums/me/exit-survey',
    body: {'answers': answers.map((answer) => answer.toJson()).toList()},
    decoder: YudisiumExitSurveySubmissionResult.fromJson,
  );

  Future<YudisiumDocumentUploadResult> uploadStudentYudisiumDocument({
    required String filePath,
    required String fileName,
    required String requirementId,
  }) async {
    final response = await _api.postMultipart(
      '/yudisiums/me/requirements/upload',
      fields: {'requirementId': requirementId},
      filePath: filePath,
      fileName: fileName,
      fileField: 'file',
    );
    return _decodeMultipartData(
      response,
      YudisiumDocumentUploadResult.fromJson,
    );
  }

  Future<ApiBinaryResponse> downloadStudentRequirement({
    required String yudisiumId,
    required String participantId,
    required String itemId,
  }) => _api.getBinary(
    '/yudisiums/$yudisiumId/participants/$participantId/requirements/$itemId/file',
  );

  Future<ApiBinaryResponse> downloadStudentCplReport() =>
      _api.getBinary('/yudisiums/me/cpl-report');

  Future<ApiBinaryResponse> downloadStudentCertificate() =>
      _api.getBinary('/yudisiums/me/certificate');

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
