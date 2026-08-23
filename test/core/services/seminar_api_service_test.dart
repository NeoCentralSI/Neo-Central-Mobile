import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/examiner_assignment_api_service.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/seminar_api_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:neocentral/features/seminar/data/models/seminar_models.dart';
import 'package:neocentral/features/thesis_shared/data/models/examiner_assignment_models.dart';
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

  group('SeminarApiService', () {
    test(
      'loads typed student attendance through the standard envelope',
      () async {
        final service = SeminarApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              expect(request.method, 'GET');
              expect(request.url.path, '/thesis-seminars/me/attendance');
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'summary': {
                      'attended': 1,
                      'total': 2,
                      'required': 5,
                      'met': false,
                    },
                    'records': [
                      {
                        'seminarId': 'seminar-1',
                        'seminarStatus': 'passed',
                        'seminarEndTime': '10:00',
                        'seminarResultFinalizedAt': '2026-08-18T10:00:00.000Z',
                        'presenterName': 'Mahasiswa',
                        'presenterNim': '221001',
                        'thesisTitle': 'Judul',
                        'date': '2026-08-18',
                        'isPresent': true,
                        'approvedAt': '2026-08-18T09:30:00.000Z',
                        'approvedBy': 'Dr. Pembimbing',
                      },
                    ],
                  },
                }),
                200,
              );
            }),
          ),
        );

        final history = await service.getStudentAttendanceHistory();
        expect(history.summary.attended, 1);
        expect(history.records.single.seminarStatus, SeminarStatus.passed);
        expect(history.records.single.isPresent, true);
      },
    );

    test(
      'sends examiner response enum and omits a blank optional reason',
      () async {
        final service = SeminarApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              expect(
                request.url.path,
                '/thesis-seminars/seminar-1/examiners/examiner-1/respond',
              );
              expect(jsonDecode(request.body), {'status': 'unavailable'});
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'examinerId': 'examiner-1',
                    'availabilityStatus': 'unavailable',
                    'seminarTransitioned': false,
                  },
                }),
                200,
              );
            }),
          ),
        );

        final result = await service.respondToExaminerAssignment(
          'seminar-1',
          'examiner-1',
          response: ExaminerResponse.unavailable,
          unavailableReasons: '   ',
        );
        expect(result.seminarTransitioned, false);
      },
    );

    test(
      'submits only typed criterion identifiers and the draft flag',
      () async {
        final service = SeminarApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              expect(request.url.path, '/thesis-seminars/seminar-1/assessment');
              expect(jsonDecode(request.body), {
                'scores': [
                  {'assessmentCriteriaId': 'criterion-uuid', 'score': 22.5},
                ],
                'revisionNotes': 'Perbaiki diagram',
                'isDraft': true,
              });
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'examinerId': 'examiner-1',
                    'assessmentScore': 22.5,
                    'assessmentSubmittedAt': null,
                  },
                }),
                200,
              );
            }),
          ),
        );

        final result = await service.submitAssessment(
          'seminar-1',
          scores: const [
            AssessmentScoreInput(
              assessmentCriteriaId: 'criterion-uuid',
              score: 22.5,
            ),
          ],
          revisionNotes: 'Perbaiki diagram',
          isDraft: true,
        );
        expect(result.assessmentScore, 22.5);
        expect(result.submittedAt, isNull);
      },
    );

    test(
      'uploads against active seminar using requirementId, not a label',
      () async {
        final service = SeminarApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              expect(request.url.path, '/thesis-seminars/active/documents');
              expect(request.body, contains('name="requirementId"'));
              expect(request.body, contains('requirement-uuid'));
              expect(request.body, isNot(contains('documentTypeName')));
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'thesisSeminarId': 'seminar-created',
                    'requirementId': 'requirement-uuid',
                    'status': 'submitted',
                    'filePath': '/uploads/naskah.pdf',
                    'fileName': 'naskah.pdf',
                    'mimeType': 'application/pdf',
                    'fileSize': 52,
                    'submittedAt': '2026-08-18T08:00:00.000Z',
                    'verifiedAt': null,
                    'verifiedBy': null,
                    'notes': null,
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
        expect(document.resourceId, 'seminar-created');
        expect(document.requirementId, 'requirement-uuid');
      },
    );

    test('downloads a document through the authenticated route', () async {
      await storage.saveTokens(
        accessToken: 'seminar-token',
        refreshToken: 'refresh-token',
      );
      final service = SeminarApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(
              request.url.path,
              '/thesis-seminars/seminar-1/documents/requirement-1',
            );
            expect(request.headers['Authorization'], 'Bearer seminar-token');
            return http.Response.bytes(
              [37, 80, 68, 70],
              200,
              headers: {
                'content-type': 'application/pdf',
                'content-disposition': 'attachment; filename="naskah.pdf"',
              },
            );
          }),
        ),
      );

      final result = await service.downloadDocument(
        'seminar-1',
        'requirement-1',
      );

      expect(result.fileName, 'naskah.pdf');
      expect(result.bytes, [37, 80, 68, 70]);
    });

    test('rejects a successful response that omits the data envelope', () {
      final service = SeminarApiService.withApiClient(
        apiWith(
          MockClient(
            (_) async => http.Response(jsonEncode({'success': true}), 200),
          ),
        ),
      );

      expect(
        service.getSeminarAnnouncements(),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  group('ExaminerAssignmentApiService', () {
    test('uses assignment view and parses typed assignment status', () async {
      final service = ExaminerAssignmentApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(request.url.path, '/thesis-seminars');
            expect(request.url.queryParameters['view'], 'assignment');
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 'seminar-1',
                    'thesisId': 'thesis-1',
                    'studentName': 'Mahasiswa',
                    'studentNim': '221001',
                    'thesisTitle': 'Judul',
                    'supervisors': [
                      {'name': 'Dr. Pembimbing', 'role': 'Pembimbing 1'},
                    ],
                    'status': 'verified',
                    'registeredAt': '2026-08-18T08:00:00.000Z',
                    'assignmentStatus': 'unassigned',
                    'examiners': [],
                    'rejectedExaminers': [],
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );

      final assignments = await service.getAssignmentSeminars();
      expect(
        assignments.single.assignmentStatus,
        ExaminerAssignmentStatus.unassigned,
      );
    });

    test('rejects duplicate examiner UUIDs before sending a request', () {
      final service = ExaminerAssignmentApiService.withApiClient(
        apiWith(
          MockClient(
            (_) async => throw StateError('Request should not be sent'),
          ),
        ),
      );

      expect(
        () => service.assignSeminarExaminers('seminar-1', const [
          'lecturer-1',
          'lecturer-1',
        ]),
        throwsArgumentError,
      );
    });
  });
}
