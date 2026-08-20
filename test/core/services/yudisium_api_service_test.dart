import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:neocentral/core/services/yudisium_api_service.dart';
import 'package:neocentral/features/thesis_shared/data/models/academic_requirement.dart';
import 'package:neocentral/features/yudisium/data/models/yudisium_models.dart';
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

  group('YudisiumApiService', () {
    test('submits all six native exit-survey answer shapes', () async {
      final service = YudisiumApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(request.url.path, '/yudisiums/me/exit-survey');
            expect(jsonDecode(request.body), {
              'answers': [
                {'questionId': 'q-short', 'answerText': 'Jawaban singkat'},
                {'questionId': 'q-paragraph', 'answerText': 'Jawaban panjang'},
                {'questionId': 'q-single', 'optionId': 'option-1'},
                {
                  'questionId': 'q-multiple',
                  'optionIds': ['option-1', 'option-2'],
                },
                {'questionId': 'q-number', 'answerNumber': 4.25},
                {'questionId': 'q-date', 'answerDate': '2026-08-18'},
              ],
            });
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'response': {
                    'id': 'participant-1',
                    'submittedAt': '2026-08-18T09:00:00.000Z',
                    'answers': [],
                  },
                },
              }),
              200,
            );
          }),
        ),
      );

      final result = await service.submitStudentExitSurvey(const [
        YudisiumSurveyAnswerInput(
          questionId: 'q-short',
          answerText: 'Jawaban singkat',
        ),
        YudisiumSurveyAnswerInput(
          questionId: 'q-paragraph',
          answerText: 'Jawaban panjang',
        ),
        YudisiumSurveyAnswerInput(questionId: 'q-single', optionId: 'option-1'),
        YudisiumSurveyAnswerInput(
          questionId: 'q-multiple',
          optionIds: ['option-1', 'option-2'],
        ),
        YudisiumSurveyAnswerInput(questionId: 'q-number', answerNumber: 4.25),
        YudisiumSurveyAnswerInput(
          questionId: 'q-date',
          answerDate: '2026-08-18',
        ),
      ]);

      expect(result.response.id, 'participant-1');
    });

    test('uploads a PDF using the requirement UUID field', () async {
      final service = YudisiumApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(request.url.path, '/yudisiums/me/requirements/upload');
            expect(request.body, contains('name="requirementId"'));
            expect(request.body, contains('requirement-uuid'));
            expect(request.body, isNot(contains('requirement-item-uuid')));
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'requirementId': 'requirement-uuid',
                  'fileName': 'persyaratan.pdf',
                  'filePath': '/uploads/yudisium/persyaratan.pdf',
                  'status': 'submitted',
                },
              }),
              200,
            );
          }),
        ),
      );

      final result = await service.uploadStudentYudisiumDocument(
        filePath: 'test/fixtures/seminar-upload.pdf',
        fileName: 'persyaratan.pdf',
        requirementId: 'requirement-uuid',
      );

      expect(result.requirementId, 'requirement-uuid');
      expect(result.status, DocumentStatus.submitted);
    });

    test('downloads a requirement through the protected item route', () async {
      await storage.saveTokens(
        accessToken: 'student-token',
        refreshToken: 'refresh-token',
      );
      final service = YudisiumApiService.withApiClient(
        apiWith(
          MockClient((request) async {
            expect(
              request.url.path,
              '/yudisiums/yudisium-1/participants/participant-1/'
              'requirements/item-1/file',
            );
            expect(request.headers['Authorization'], 'Bearer student-token');
            return http.Response.bytes(
              [37, 80, 68, 70],
              200,
              headers: {
                'content-type': 'application/pdf',
                'content-disposition': 'attachment; filename="dokumen.pdf"',
              },
            );
          }),
        ),
      );

      final result = await service.downloadStudentRequirement(
        yudisiumId: 'yudisium-1',
        participantId: 'participant-1',
        itemId: 'item-1',
      );

      expect(result.fileName, 'dokumen.pdf');
      expect(result.bytes, [37, 80, 68, 70]);
    });

    test(
      'uses authenticated endpoints for CPL report and certificate',
      () async {
        await storage.saveTokens(
          accessToken: 'student-token',
          refreshToken: 'refresh-token',
        );
        final visited = <String>[];
        final service = YudisiumApiService.withApiClient(
          apiWith(
            MockClient((request) async {
              visited.add(request.url.path);
              expect(request.headers['Authorization'], 'Bearer student-token');
              return http.Response.bytes(
                [37, 80, 68, 70],
                200,
                headers: {'content-type': 'application/pdf'},
              );
            }),
          ),
        );

        await service.downloadStudentCplReport();
        await service.downloadStudentCertificate();

        expect(visited, [
          '/yudisiums/me/cpl-report',
          '/yudisiums/me/certificate',
        ]);
      },
    );
  });
}
