import '../../features/thesis_shared/data/models/examiner_assignment_models.dart';
import '../../features/thesis_shared/data/models/thesis_people_models.dart';
import '../utils/api_contract_parser.dart';
import 'api_client.dart';

class ExaminerAssignmentApiService {
  static final ExaminerAssignmentApiService _instance =
      ExaminerAssignmentApiService._internal();

  factory ExaminerAssignmentApiService() => _instance;

  ExaminerAssignmentApiService._internal() : _api = ApiClient();

  ExaminerAssignmentApiService.withApiClient(ApiClient apiClient)
    : _api = apiClient;

  final ApiClient _api;

  Future<List<ExaminerAssignmentResource>> getAssignmentSeminars() =>
      _getAssignmentResources('/thesis-seminars');

  Future<List<EligibleExaminer>> getEligibleSeminarExaminers(
    String seminarId,
  ) => _getEligibleExaminers('/thesis-seminars/$seminarId/eligible-examiners');

  Future<List<ExaminerAssignment>> assignSeminarExaminers(
    String seminarId,
    List<String> examinerIds,
  ) => _assignExaminers('/thesis-seminars/$seminarId/examiners', examinerIds);

  Future<List<ExaminerAssignmentResource>> getAssignmentDefences() =>
      _getAssignmentResources('/thesis-defences');

  Future<List<EligibleExaminer>> getEligibleDefenceExaminers(
    String defenceId,
  ) => _getEligibleExaminers('/thesis-defences/$defenceId/eligible-examiners');

  Future<List<ExaminerAssignment>> assignDefenceExaminers(
    String defenceId,
    List<String> examinerIds,
  ) => _assignExaminers(
    '/thesis-defences/$defenceId/examiners',
    examinerIds,
    exactCount: 2,
  );

  Future<List<ExaminerAssignmentResource>> _getAssignmentResources(
    String endpoint,
  ) => _api.getData(
    endpoint,
    queryParams: const {'view': 'assignment'},
    decoder: (value) => requireJsonList(
      value,
      context: 'examinerAssignmentResources',
    ).map(ExaminerAssignmentResource.fromJson).toList(growable: false),
  );

  Future<List<EligibleExaminer>> _getEligibleExaminers(String endpoint) =>
      _api.getData(
        endpoint,
        decoder: (value) => requireJsonList(
          value,
          context: 'eligibleExaminers',
        ).map(EligibleExaminer.fromJson).toList(growable: false),
      );

  Future<List<ExaminerAssignment>> _assignExaminers(
    String endpoint,
    List<String> examinerIds, {
    int? exactCount,
  }) {
    final uniqueIds = examinerIds.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) {
      throw ArgumentError.value(
        examinerIds,
        'examinerIds',
        'Minimal satu penguji wajib dipilih.',
      );
    }
    if (uniqueIds.length != examinerIds.length) {
      throw ArgumentError.value(
        examinerIds,
        'examinerIds',
        'Penguji tidak boleh duplikat.',
      );
    }
    if (exactCount != null && uniqueIds.length != exactCount) {
      throw ArgumentError.value(
        examinerIds,
        'examinerIds',
        'Sidang Tugas Akhir harus memiliki tepat $exactCount penguji aktif.',
      );
    }
    return _api.postData(
      endpoint,
      body: {'examinerIds': examinerIds},
      decoder: (value) => requireJsonList(
        value,
        context: 'assignedExaminers',
      ).map(ExaminerAssignment.fromJson).toList(growable: false),
    );
  }
}
