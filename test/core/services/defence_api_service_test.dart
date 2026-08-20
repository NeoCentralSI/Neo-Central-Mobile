import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/defence_api_service.dart';
import 'package:neocentral/core/services/examiner_assignment_api_service.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:neocentral/features/defence/data/models/defence_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late SecureStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = SecureStorageService(tokenStore: _MemoryTokenStore());
  });

  ApiClient apiWith(MockClient client) => ApiClient.withDependencies(
    httpClient: client,
    storage: storage,
    baseUrl: 'https://example.test',
    timeout: const Duration(seconds: 2),
  );

  group('DefenceApiService', () {
    test(
      'sends the typed examiner response and omits a blank reason',
      () async {
        final service = DefenceApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              expect(
                request.url.path,
                '/thesis-defences/defence-1/examiners/examiner-1/respond',
              );
              expect(jsonDecode(request.body), {'status': 'unavailable'});
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'examinerId': 'examiner-1',
                    'availabilityStatus': 'unavailable',
                    'defenceTransitioned': false,
                  },
                }),
                200,
              );
            }),
          ),
        );

        final result = await service.respondToExaminerAssignment(
          'defence-1',
          'examiner-1',
          response: DefenceExaminerResponse.unavailable,
          unavailableReasons: '   ',
        );
        expect(result.defenceTransitioned, false);
      },
    );

    test('submits supervisor rubric IDs, notes, and draft state', () async {
      final service = DefenceApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(request.url.path, '/thesis-defences/defence-1/assessment');
            expect(jsonDecode(request.body), {
              'scores': [
                {'assessmentCriteriaId': 'supervisor-criterion', 'score': 18},
              ],
              'supervisorNotes': 'Proses bimbingan baik',
              'isDraft': true,
            });
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'assessorRole': 'supervisor',
                  'defenceId': 'defence-1',
                  'assessmentScore': 18,
                  'assessmentSubmittedAt': null,
                },
              }),
              200,
            );
          }),
        ),
      );

      final result = await service.submitAssessment(
        'defence-1',
        scores: const [
          DefenceAssessmentScoreInput(
            assessmentCriteriaId: 'supervisor-criterion',
            score: 18,
          ),
        ],
        supervisorNotes: 'Proses bimbingan baik',
        isDraft: true,
      );
      expect(result.assessorRole, DefenceAssessorRole.supervisor);
      expect(result.assessmentScore, 18);
    });

    test('uploads by requirementId against the active defence', () async {
      final service = DefenceApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(request.url.path, '/thesis-defences/active/documents');
            expect(request.body, contains('name="requirementId"'));
            expect(request.body, contains('requirement-uuid'));
            expect(request.body, isNot(contains('documentTypeName')));
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'thesisDefenceId': 'defence-created',
                  'requirementId': 'requirement-uuid',
                  'status': 'submitted',
                  'submittedAt': '2026-08-18T08:00:00.000Z',
                  'verifiedAt': null,
                  'verifiedBy': null,
                  'notes': null,
                  'fileName': 'naskah.pdf',
                  'filePath': '/uploads/naskah.pdf',
                  'mimeType': 'application/pdf',
                  'fileSize': 52,
                },
              }),
              200,
            );
          }),
        ),
      );

      final document = await service.uploadStudentDocument(
        null,
        filePath: 'test/fixtures/seminar-upload.pdf',
        fileName: 'naskah.pdf',
        requirementId: 'requirement-uuid',
      );
      expect(document.resourceId, 'defence-created');
      expect(document.requirementId, 'requirement-uuid');
    });

    test('loads the dedicated read-only student assessment endpoint', () async {
      final service = DefenceApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(
              request.url.path,
              '/thesis-defences/defence-1/assessment-view',
            );
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'defence': {
                    'id': 'defence-1',
                    'status': 'passed',
                    'examinerAverageScore': 55,
                    'supervisorScore': 20,
                    'finalScore': 75,
                    'grade': 'B+',
                    'resultFinalizedAt': '2026-08-20T10:00:00.000Z',
                    'room': null,
                    'date': '2026-08-20',
                    'startTime': '08:00',
                    'endTime': '10:00',
                    'meetingLink': null,
                  },
                  'examiners': [],
                  'supervisorAssessment': {
                    'name': 'Dr. Pembimbing',
                    'assessmentScore': 20,
                    'supervisorNotes': null,
                    'assessmentSubmittedAt': '2026-08-20T09:30:00.000Z',
                    'assessmentDetails': [],
                  },
                },
              }),
              200,
            );
          }),
        ),
      );

      final result = await service.getStudentAssessment('defence-1');
      expect(result.defence.status, DefenceStatus.passed);
      expect(result.defence.finalScore, 75);
    });
  });

  group('Defence examiner assignment', () {
    test('requires exactly two unique active examiners', () {
      final service = ExaminerAssignmentApiService.withApiClient(
        apiWith(
          MockClient(
            (_) async => throw StateError('Request should not be sent'),
          ),
        ),
      );

      expect(
        () => service.assignDefenceExaminers('defence-1', const ['lecturer-1']),
        throwsArgumentError,
      );
      expect(
        () => service.assignDefenceExaminers('defence-1', const [
          'lecturer-1',
          'lecturer-1',
        ]),
        throwsArgumentError,
      );
    });
  });
}
