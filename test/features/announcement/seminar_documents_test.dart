import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/core/services/attachment_service.dart';
import 'package:neocentral/features/announcement/data/announcement_api_service.dart';
import 'package:neocentral/features/announcement/data/announcement_models.dart';
import 'package:neocentral/features/announcement/presentation/seminar_detail_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_test_client.dart';

const _filePath = 'uploads/thesis/t1/seminar/sem1/requirement-r1-1.pdf';

Map<String, dynamic> _studentDetail({required bool canView}) => {
  'id': 'sem1',
  'status': 'scheduled',
  'thesis': {'id': 't1', 'title': 'Judul', 'supervisors': []},
  'student': {'name': 'Budi', 'nim': '2211'},
  'canViewDocuments': canView,
  'documents': canView
      ? [
          {
            'requirementId': 'r1',
            'requirementName': 'Draf Laporan TA',
            'fileName': 'Draf Laporan.pdf',
            'filePath': _filePath,
            'status': 'approved',
          },
        ]
      : [],
};

UserModel _student() => const UserModel(
  id: 'u1',
  fullName: 'Ani',
  email: 'a@unand.ac.id',
  isVerified: true,
  roles: [UserRoleEntry(id: 'r', name: 'Mahasiswa')],
);

void main() {
  late Directory temp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('seminar_docs_test');
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<FakeBackend> pump(
    WidgetTester tester,
    Map<String, dynamic> detail, {
    AttachmentService? attachments,
    FakeBackend? backend,
  }) async {
    final fake =
        backend ??
        FakeBackend((request) {
          if (request.url.path.endsWith('/audiences')) {
            return {'success': true, 'data': []};
          }
          return {'success': true, 'data': detail};
        });
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SeminarDetailScreen(
          seminarId: 'sem1',
          user: _student(),
          api: AnnouncementApiService(client: fake.client),
          attachments: attachments,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('canViewDocuments true shows the documents card', (tester) async {
    await pump(tester, _studentDetail(canView: true));

    expect(
      find.byKey(const ValueKey('seminar-documents-card')),
      findsOneWidget,
    );
    expect(find.text('Dokumen Seminar'), findsOneWidget);
    expect(find.text('Draf Laporan TA'), findsOneWidget);
    expect(find.text('Draf Laporan.pdf'), findsOneWidget);
    expect(find.text('Lihat'), findsOneWidget);
    expect(
      find.text('Dokumen seminar hanya dapat diakses peserta seminar'),
      findsNothing,
    );
    expect(
      find.text('Dokumen seminar tersedia di NeoCentral versi web'),
      findsNothing,
    );
  });

  testWidgets('canViewDocuments false shows only the small note', (
    tester,
  ) async {
    await pump(tester, _studentDetail(canView: false));

    expect(find.byKey(const ValueKey('seminar-documents-card')), findsNothing);
    expect(find.text('Dokumen Seminar'), findsNothing);
    expect(find.text('Belum Ada Dokumen'), findsNothing);
    expect(
      find.text('Dokumen seminar hanya dapat diakses peserta seminar'),
      findsOneWidget,
    );
  });

  testWidgets('an allowed but empty list shows the empty state in the card', (
    tester,
  ) async {
    await pump(tester, {..._studentDetail(canView: true), 'documents': []});

    expect(
      find.byKey(const ValueKey('seminar-documents-card')),
      findsOneWidget,
    );
    expect(find.text('Belum Ada Dokumen'), findsOneWidget);
  });

  testWidgets('Lihat downloads the file path with the session and opens it', (
    tester,
  ) async {
    final fileServer = FakeBackend(
      (_) => http.Response.bytes([37, 80, 68, 70], 200),
      accessToken: 'jwt-1',
    );
    String? openedPath;
    final attachments = AttachmentService(
      client: fileServer.client,
      tempDir: () async => temp,
      openFile: (path) async {
        openedPath = path;
        return OpenResult();
      },
    );
    await pump(tester, _studentDetail(canView: true), attachments: attachments);

    await tester.runAsync(() async {
      await tester.tap(find.text('Lihat'));
      for (var i = 0; i < 20 && openedPath == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    final request = fileServer.requests.single;
    expect(request.url.path, '/$_filePath');
    expect(request.headers['Authorization'], 'Bearer jwt-1');
    expect(openedPath, endsWith('/attachments/Draf Laporan.pdf'));
  });

  test('lecturer/Admin shape: names come from documentTypes', () {
    final detail = SeminarDetail.fromJson({
      'id': 'sem1',
      'canViewDocuments': true,
      'documentTypes': [
        {'id': 'r1', 'name': 'Draf Laporan TA'},
        {'id': 'r2', 'name': 'Bukti Bimbingan'},
      ],
      'documents': [
        {'requirementId': 'r1', 'fileName': 'a.pdf', 'filePath': _filePath},
      ],
    });

    expect(detail.documents.map((d) => d.name), [
      'Draf Laporan TA',
      'Bukti Bimbingan',
    ]);
    expect(detail.documents.first.filePath, _filePath);
    expect(detail.documents.last.isUploaded, isFalse);
  });

  test('missing canViewDocuments is read as no access', () {
    final detail = SeminarDetail.fromJson({
      'id': 'sem1',
      'documents': [
        {'requirementId': 'r1', 'filePath': _filePath},
      ],
    });

    expect(detail.canViewDocuments, isFalse);
    expect(detail.documents, isEmpty);
  });
}
