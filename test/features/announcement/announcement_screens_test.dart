import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/features/announcement/data/announcement_api_service.dart';
import 'package:neocentral/features/announcement/presentation/announcement_screen.dart';
import 'package:neocentral/features/announcement/presentation/seminar_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/api_test_client.dart';

UserModel _student() => const UserModel(
  id: 'u1',
  fullName: 'Mahasiswa',
  email: 'm@unand.ac.id',
  isVerified: true,
  roles: [UserRoleEntry(id: 'r', name: 'Mahasiswa')],
  student: StudentData(id: 'st1'),
);

UserModel _lecturer(String lecturerId) => UserModel(
  id: 'u2',
  fullName: 'Dosen',
  email: 'd@unand.ac.id',
  isVerified: true,
  roles: const [UserRoleEntry(id: 'r', name: 'Pembimbing 1')],
  lecturer: LecturerData(id: lecturerId),
);

Map<String, dynamic> _announcement() => {
  'id': 'sem1',
  'date': '2099-01-05T00:00:00.000Z',
  'startTime': '1970-01-01T09:00:00.000Z',
  'endTime': '1970-01-01T10:00:00.000Z',
  'status': 'scheduled',
  'room': {'id': 'r1', 'name': 'Ruang Seminar'},
  'thesisTitle': 'Sistem Informasi Akademik',
  'presenterName': 'BUDI SANTOSO',
  'supervisors': [
    {'role': 'Pembimbing 1', 'name': 'Dr. Ani'},
  ],
  'examiners': [
    {'order': 1, 'name': 'Dr. Joko'},
  ],
  'isOwn': false,
  'isPast': false,
  'isRegistered': false,
  'isPresent': false,
};

Map<String, dynamic> _detail(String status) => {
  'id': 'sem1',
  'status': status,
  'date': '2026-01-05T00:00:00.000Z',
  'startTime': '1970-01-01T09:00:00.000Z',
  'endTime': '1970-01-01T10:00:00.000Z',
  'room': {'id': 'r1', 'name': 'Ruang Seminar'},
  'thesis': {'id': 't1', 'title': 'Sistem Informasi Akademik'},
  'student': {'id': 'st9', 'name': 'Budi Santoso', 'nim': '2211'},
  'supervisors': [
    {'lecturerId': 'L1', 'name': 'Dr. Ani', 'role': 'Pembimbing 1'},
  ],
  'examiners': [
    {'order': 1, 'lecturerName': 'Dr. Joko'},
  ],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('student sees the seminar board and can register', (
    tester,
  ) async {
    final backend = FakeBackend((request) {
      final path = request.url.path;
      if (path == '/thesis-seminars/announcements') {
        return {
          'success': true,
          'data': [_announcement()],
        };
      }
      if (path == '/thesis-seminars/sem1/audience-register') {
        return {
          'success': true,
          'data': {'message': 'Berhasil mendaftar sebagai peserta seminar.'},
        };
      }
      return {'success': true, 'data': []};
    });

    await pump(
      tester,
      AnnouncementScreen(
        user: _student(),
        showDrawer: false,
        api: AnnouncementApiService(client: backend.client),
      ),
    );

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Dijadwalkan'), findsOneWidget);
    expect(find.text('Belum Daftar'), findsOneWidget);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Daftar'));
    await tester.pumpAndSettle();

    expect(
      backend.requests.any(
        (r) =>
            r.method == 'POST' &&
            r.url.path == '/thesis-seminars/sem1/audience-register',
      ),
      isTrue,
    );
    expect(
      find.text('Berhasil mendaftar sebagai peserta seminar.'),
      findsOneWidget,
    );
  });

  testWidgets('a rejection shows the backend message', (tester) async {
    final backend = FakeBackend((request) {
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Seminar ini tidak lagi membuka pendaftaran kehadiran.',
          }),
          400,
        );
      }
      return {
        'success': true,
        'data': [_announcement()],
      };
    });

    await pump(
      tester,
      AnnouncementScreen(
        user: _student(),
        showDrawer: false,
        api: AnnouncementApiService(client: backend.client),
      ),
    );
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Daftar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Seminar ini tidak lagi membuka pendaftaran kehadiran.'),
      findsOneWidget,
    );
  });

  testWidgets('empty boards show the web empty state', (tester) async {
    final backend = FakeBackend((_) => {'success': true, 'data': []});

    await pump(
      tester,
      AnnouncementScreen(
        user: _lecturer('L1'),
        showDrawer: false,
        api: AnnouncementApiService(client: backend.client),
      ),
    );

    expect(find.text('Belum Ada Pengumuman'), findsOneWidget);
    expect(find.text('Daftar'), findsNothing);
  });

  testWidgets('detail has two centred tabs; no documents without access', (
    tester,
  ) async {
    final backend = FakeBackend((request) {
      if (request.url.path.endsWith('/audiences')) {
        return {'success': true, 'data': []};
      }
      return {'success': true, 'data': _detail('scheduled')};
    });

    await pump(
      tester,
      SeminarDetailScreen(
        seminarId: 'sem1',
        user: _student(),
        api: AnnouncementApiService(client: backend.client),
      ),
    );

    expect(find.text('Informasi Seminar'), findsOneWidget);
    expect(find.text('Informasi Tugas Akhir'), findsOneWidget);
    expect(
      find.text('Dokumen seminar hanya dapat diakses peserta seminar'),
      findsOneWidget,
    );
    expect(find.textContaining('Unduh'), findsNothing);

    final identitas = tester.getCenter(find.text('Identitas'));
    final peserta = tester.getCenter(find.text('Peserta'));
    // Equal-width tabs: both labels sit at the same distance from centre.
    expect(
      (420 / 2 - identitas.dx - (peserta.dx - 420 / 2)).abs(),
      lessThan(1),
    );
  });

  testWidgets('the seminar supervisor confirms attendance', (tester) async {
    final backend = FakeBackend((request) {
      if (request.method == 'PATCH') return {'success': true, 'data': {}};
      if (request.url.path.endsWith('/audiences')) {
        return {
          'success': true,
          'data': [
            {
              'studentId': 'st5',
              'fullName': 'Citra',
              'nim': '2212',
              'approvedAt': null,
            },
          ],
        };
      }
      return {'success': true, 'data': _detail('passed')};
    });

    await pump(
      tester,
      SeminarDetailScreen(
        seminarId: 'sem1',
        user: _lecturer('L1'),
        api: AnnouncementApiService(client: backend.client),
      ),
    );
    await tester.tap(find.text('Peserta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final patch = backend.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.path, '/thesis-seminars/sem1/audiences/st5');
    expect(jsonDecode(patch.body), {'action': 'approve'});
  });

  testWidgets('other lecturers only read the attendance list', (tester) async {
    final backend = FakeBackend((request) {
      if (request.url.path.endsWith('/audiences')) {
        return {
          'success': true,
          'data': [
            {'studentId': 'st5', 'fullName': 'Citra', 'nim': '2212'},
          ],
        };
      }
      return {'success': true, 'data': _detail('passed')};
    });

    await pump(
      tester,
      SeminarDetailScreen(
        seminarId: 'sem1',
        user: _lecturer('OTHER'),
        api: AnnouncementApiService(client: backend.client),
      ),
    );
    await tester.tap(find.text('Peserta'));
    await tester.pumpAndSettle();

    expect(find.text('Citra'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });
}
