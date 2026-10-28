import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/announcement/data/announcement_models.dart';

void main() {
  group('SeminarAnnouncement', () {
    Map<String, dynamic> item({Map<String, dynamic> extra = const {}}) => {
      'id': 's1',
      'date': '2026-10-27T00:00:00.000Z',
      'startTime': '1970-01-01T09:00:00.000Z',
      'endTime': '1970-01-01T10:30:00.000Z',
      'status': 'scheduled',
      'room': {'id': 'r1', 'name': 'Ruang Seminar'},
      'thesisTitle': 'Judul',
      'presenterName': 'BUDI',
      'supervisors': [
        {'role': 'Pembimbing 2', 'name': 'B'},
        {'role': 'Pembimbing 1', 'name': 'A'},
      ],
      'examiners': [
        {'order': 2, 'name': 'Y'},
        {'order': 1, 'name': 'X'},
      ],
      'isOwn': false,
      'isPast': false,
      'isRegistered': false,
      'isPresent': false,
      ...extra,
    };

    test('parses the backend shape', () {
      final a = SeminarAnnouncement.tryParse(item())!;
      expect(a.roomName, 'Ruang Seminar');
      expect(a.mainSupervisor?.name, 'A');
      expect(a.examiners.map((e) => e.role), ['Penguji 1', 'Penguji 2']);
      expect(clockOf(a.startTime), '09:00');
      expect(clockOf(a.endTime), '10:30');
      expect(a.canRegister, isTrue);
      expect(a.audienceState, AudienceState.notRegistered);
    });

    test('a row without id is skipped, odd fields do not throw', () {
      expect(SeminarAnnouncement.tryParse({'presenterName': 'x'}), isNull);
      final a = SeminarAnnouncement.tryParse({
        'id': 's2',
        'room': 'not a map',
        'supervisors': null,
        'examiners': 'x',
        'isOwn': 'yes',
      })!;
      expect(a.roomName, isNull);
      expect(a.supervisors, isEmpty);
      expect(a.isOwn, isFalse);
      expect(a.presenterName, '-');
    });

    test('registration rules follow the web page', () {
      final registered = SeminarAnnouncement.tryParse(
        item(extra: {'isRegistered': true}),
      )!;
      expect(registered.canRegister, isFalse);
      expect(registered.canUnregister, isTrue);
      expect(registered.audienceState, AudienceState.registered);

      final own = SeminarAnnouncement.tryParse(item(extra: {'isOwn': true}))!;
      expect(own.canRegister, isFalse);
      expect(own.audienceState, isNull);

      final absent = SeminarAnnouncement.tryParse(
        item(extra: {'isRegistered': true, 'status': 'passed', 'isPast': true}),
      )!;
      expect(absent.canUnregister, isFalse);
      expect(absent.audienceState, AudienceState.absent);
    });
  });

  group('SeminarDetail', () {
    test('reads the shape for lecturers (top-level supervisors)', () {
      final d = SeminarDetail.fromJson({
        'id': 's1',
        'status': 'passed',
        'thesis': {'id': 't1', 'title': 'Judul'},
        'student': {'name': 'Budi', 'nim': '2211'},
        'supervisors': [
          {'lecturerId': 'L1', 'name': 'A', 'role': 'Pembimbing 1'},
        ],
        'examiners': [
          {'order': 1, 'lecturerName': 'X'},
        ],
      });
      expect(d.isSupervisedBy('L1'), isTrue);
      expect(d.isSupervisedBy('L2'), isFalse);
      expect(d.isSupervisedBy(null), isFalse);
      expect(d.isAttendanceOpen(), isTrue);
      expect(d.examiners.single.name, 'X');
    });

    test('reads the shape for students (thesis.supervisors)', () {
      final d = SeminarDetail.fromJson({
        'id': 's1',
        'status': 'scheduled',
        'date': '2099-01-01T00:00:00.000Z',
        'startTime': '1970-01-01T09:00:00.000Z',
        'thesis': {
          'id': 't1',
          'title': 'Judul',
          'supervisors': [
            {'role': 'Pembimbing 1', 'lecturerName': 'A'},
          ],
        },
        'student': {'name': 'Budi', 'nim': '2211'},
      });
      expect(d.supervisors.single.name, 'A');
      expect(d.isAttendanceOpen(now: DateTime.utc(2026)), isFalse);
      expect(d.isAttendanceOpen(now: DateTime.utc(2099, 1, 1, 3)), isTrue);
    });
  });

  test('SeminarAudience reads presence from approvedAt', () {
    final a = SeminarAudience.fromJson({
      'studentId': 'st1',
      'fullName': 'Ani',
      'nim': '22',
      'approvedAt': '2026-01-01T00:00:00Z',
      'approvedByName': 'Dosen',
    });
    expect(a.isPresent, isTrue);
    expect(
      SeminarAudience.fromJson({'approvedByName': '-'}).approvedByName,
      isNull,
    );
  });

  test('YudisiumAnnouncement sorts participants by registration', () {
    final y = YudisiumAnnouncement.tryParse({
      'id': 'y1',
      'name': 'Yudisium Oktober',
      'eventDate': '2026-10-30T00:00:00.000Z',
      'participants': [
        {
          'id': 'p2',
          'studentName': 'B',
          'registeredAt': '2026-10-02T00:00:00Z',
        },
        {
          'id': 'p1',
          'studentName': 'A',
          'registeredAt': '2026-10-01T00:00:00Z',
        },
        {'id': 'p3', 'studentName': 'C'},
      ],
    })!;
    expect(y.participants.map((p) => p.id), ['p1', 'p2', 'p3']);
    expect(y.roomName, isNull);
  });
}
