import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:neocentral/core/services/attachment_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_test_client.dart';

void main() {
  const api = 'https://example.test';

  group('attachmentTargetFor', () {
    test('backend file paths become encoded API paths', () {
      final target = attachmentTargetFor(
        'uploads/thesis/t1/Bab 1 (revisi).pdf',
        apiBaseUrl: api,
      );
      expect(target, isA<ApiFile>());
      target as ApiFile;
      expect(target.path, '/uploads/thesis/t1/Bab%201%20(revisi).pdf');
      expect(target.fileName, 'Bab 1 (revisi).pdf');
    });

    test('a bare path is relative to /uploads, a url keeps its path', () {
      expect(
        (attachmentTargetFor('thesis/t1/a.pdf', apiBaseUrl: api) as ApiFile)
            .path,
        '/uploads/thesis/t1/a.pdf',
      );
      expect(
        (attachmentTargetFor(
                  '$api/uploads/thesis/t1/a%20b.pdf',
                  apiBaseUrl: api,
                )
                as ApiFile)
            .path,
        '/uploads/thesis/t1/a%20b.pdf',
      );
    });

    test('links outside the API open in the browser', () {
      final target = attachmentTargetFor(
        'https://drive.google.com/file/d/x',
        apiBaseUrl: api,
      );
      expect(target, isA<ExternalLink>());
    });

    test('empty values give no target', () {
      expect(attachmentTargetFor(null), isNull);
      expect(attachmentTargetFor('  '), isNull);
    });
  });

  group('AttachmentService', () {
    late Directory temp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      temp = await Directory.systemTemp.createTemp('attachments_test');
    });

    tearDown(() async => temp.delete(recursive: true));

    test(
      'downloads with the Authorization header, saves, then opens',
      () async {
        final backend = FakeBackend(
          (_) => http.Response.bytes(
            utf8.encode('%PDF-1.4'),
            200,
            headers: {
              'content-type': 'application/pdf',
              'content-disposition': 'attachment; filename="Bab 1.pdf"',
            },
          ),
          accessToken: 'jwt-abc',
        );
        // Signed in: the client sends this token as a bearer header.
        final client = backend.client;
        String? opened;
        final service = AttachmentService(
          client: client,
          tempDir: () async => temp,
          openFile: (path) async {
            opened = path;
            return OpenResult();
          },
        );

        final result = await service.open(
          '/uploads/thesis/t1/Bab 1.pdf',
          fileName: 'Bab 1.pdf',
        );

        expect(result.opened, isTrue);
        final request = backend.requests.single;
        expect(request.url.path, '/uploads/thesis/t1/Bab%201.pdf');
        expect(request.url.queryParameters.containsKey('token'), isFalse);
        expect(request.headers['Authorization'], 'Bearer jwt-abc');
        expect(File(opened!).readAsStringSync(), '%PDF-1.4');
        expect(opened, endsWith('/attachments/Bab 1.pdf'));
      },
    );

    test('a refused download shows the backend message', () async {
      final backend = FakeBackend(
        (_) => http.Response(
          jsonEncode({'message': 'Anda tidak memiliki akses ke berkas ini'}),
          403,
        ),
      );
      final service = AttachmentService(
        client: backend.client,
        tempDir: () async => temp,
        openFile: (_) async => OpenResult(),
      );

      final result = await service.open('uploads/thesis/t1/a.pdf');

      expect(result.opened, isFalse);
      expect(result.message, 'Anda tidak memiliki akses ke berkas ini');
    });

    test('no app to open the file gives a clear message', () async {
      final backend = FakeBackend((_) => http.Response.bytes([1, 2], 200));
      final service = AttachmentService(
        client: backend.client,
        tempDir: () async => temp,
        openFile: (_) async =>
            OpenResult(type: ResultType.noAppToOpen, message: 'none'),
      );

      final result = await service.open('uploads/thesis/t1/a.xyz');

      expect(result.message, 'Tidak ada aplikasi untuk membuka dokumen ini.');
    });

    test('external links go to the browser, not the API', () async {
      final backend = FakeBackend((_) => fail('API must not be called'));
      Uri? launched;
      final service = AttachmentService(
        client: backend.client,
        tempDir: () async => temp,
        openLink: (uri) async {
          launched = uri;
          return true;
        },
      );

      final result = await service.open('https://drive.google.com/file/d/x');

      expect(result.opened, isTrue);
      expect(launched?.host, 'drive.google.com');
    });
  });
}
