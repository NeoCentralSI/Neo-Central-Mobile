import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/api_exception.dart';
import 'package:neocentral/features/seminar/data/models/seminar_models.dart';
import 'package:neocentral/features/thesis_shared/data/models/academic_requirement.dart';
import 'package:neocentral/features/thesis_shared/data/models/examiner_assignment_models.dart';

void main() {
  group('StudentSeminarOverview', () {
    test('parses requirement UUIDs, upload config, and current attempt', () {
      final overview = StudentSeminarOverview.fromJson({
        'thesisId': 'thesis-1',
        'thesisTitle': 'Sistem Informasi Akademik',
        'checklist': {
          'bimbingan': {
            'met': true,
            'current': 8,
            'required': 8,
            'label': '8 Bimbingan',
          },
          'kehadiran': {
            'met': true,
            'current': 5,
            'required': 5,
            'label': '5 Kehadiran Seminar',
          },
          'metopen': {'met': true, 'label': 'Lulus Metopen'},
          'pembimbing': {
            'met': true,
            'label': 'Persetujuan Pembimbing',
            'supervisors': [
              {'name': 'Dr. Pembimbing', 'role': 'Pembimbing 1', 'ready': true},
            ],
          },
        },
        'allChecklistMet': true,
        'milestones': [
          {'id': 'requirements', 'label': 'Persyaratan', 'checked': true},
        ],
        'canUpload': true,
        'requirements': [
          {
            'id': 'requirement-uuid',
            'name': 'Naskah Seminar',
            'description': 'PDF',
            'displayOrder': 1,
            'document': {
              'thesisSeminarId': 'seminar-1',
              'requirementId': 'requirement-uuid',
              'status': 'declined',
              'submittedAt': '2026-08-18T08:00:00.000Z',
              'verifiedAt': '2026-08-18T09:00:00.000Z',
              'verifiedBy': 'Admin',
              'notes': 'Perbaiki halaman pengesahan',
              'fileName': 'naskah.pdf',
              'filePath': '/uploads/naskah.pdf',
              'mimeType': 'application/pdf',
              'fileSize': 1024,
            },
          },
        ],
        'requirementConfiguration': {'isConfigured': true, 'message': null},
        'uploadConfig': {
          'accept': ['.pdf'],
          'maxFileSizeBytes': 5242880,
          'maxFileSizeMb': 5,
        },
        'seminar': {
          'id': 'seminar-1',
          'status': 'registered',
          'registeredAt': '2026-08-18T07:00:00.000Z',
          'date': null,
          'startTime': null,
          'endTime': null,
          'meetingLink': null,
          'finalScore': null,
          'resultFinalizedAt': null,
          'cancelledReason': null,
          'scheduledAt': null,
          'room': null,
          'examiners': [],
        },
      });

      expect(overview.canUpload, true);
      expect(overview.requirements.single.id, 'requirement-uuid');
      expect(
        overview.requirements.single.document?.status,
        DocumentStatus.declined,
      );
      expect(overview.uploadConfig.maxFileSizeBytes, 5242880);
      expect(overview.seminar?.status, SeminarStatus.registered);
    });

    test('parses the no-thesis response without fabricating a seminar', () {
      final overview = StudentSeminarOverview.fromJson({
        'thesisId': null,
        'thesisTitle': null,
        'checklist': {
          'bimbingan': {
            'met': false,
            'current': 0,
            'required': 8,
            'label': '8 Bimbingan',
          },
          'kehadiran': {
            'met': false,
            'current': 0,
            'required': 5,
            'label': '5 Kehadiran Seminar',
          },
          'metopen': {'met': false, 'label': 'Lulus Metopen'},
          'pembimbing': {
            'met': false,
            'label': 'Persetujuan Pembimbing',
            'supervisors': [],
          },
        },
        'allChecklistMet': false,
        'milestones': [],
        'canUpload': false,
        'seminar': null,
        'requirements': [],
        'requirementConfiguration': {
          'isConfigured': false,
          'message': 'Tugas akhir belum tersedia.',
        },
        'uploadConfig': {
          'accept': ['.pdf'],
          'maxFileSizeBytes': 1048576,
          'maxFileSizeMb': 1,
        },
      });

      expect(overview.thesisId, isNull);
      expect(overview.seminar, isNull);
      expect(overview.requirementConfiguration.isConfigured, false);
    });
  });

  group('SeminarDetail', () {
    test('normalizes the student detail variant with nested supervisors', () {
      final detail = SeminarDetail.fromJson({
        'id': 'seminar-1',
        'status': 'passed_with_revision',
        'registeredAt': '2026-08-18T07:00:00.000Z',
        'date': '2026-08-20',
        'startTime': '08:00',
        'endTime': '10:00',
        'meetingLink': null,
        'finalScore': 76.5,
        'grade': 'B+',
        'resultFinalizedAt': '2026-08-20T10:00:00.000Z',
        'revisionFinalizedAt': null,
        'cancelledReason': null,
        'scheduledAt': '2026-08-19T08:00:00.000Z',
        'room': {'id': 'room-1', 'name': 'Ruang Seminar'},
        'student': {
          'id': 'student-1',
          'name': 'Mahasiswa Satu',
          'nim': '221001',
        },
        'thesis': {
          'id': 'thesis-1',
          'title': 'Judul Tugas Akhir',
          'supervisors': [
            {'role': 'Pembimbing 1', 'lecturerName': 'Dr. Pembimbing'},
          ],
        },
        'examiners': [
          {
            'id': 'examiner-1',
            'order': 1,
            'lecturerName': 'Dr. Penguji',
            'assessmentScore': 76.5,
            'assessmentSubmittedAt': '2026-08-20T09:30:00.000Z',
          },
        ],
        'documents': [
          {
            'requirementId': 'requirement-1',
            'requirementName': 'Naskah',
            'status': 'approved',
            'submittedAt': '2026-08-18T08:00:00.000Z',
          },
        ],
        'revisions': [],
        'audiences': [
          {
            'studentName': 'Peserta Satu',
            'nim': '221002',
            'registeredAt': '2026-08-19T10:00:00.000Z',
            'approvedAt': null,
            'approvedByName': null,
          },
        ],
      });

      expect(detail.supervisors.single.name, 'Dr. Pembimbing');
      expect(detail.examiners.single.lecturerId, isNull);
      expect(detail.examiners.single.assessmentScore, 76.5);
      expect(detail.documents.single.requirementId, 'requirement-1');
    });

    test('rejects unknown workflow status', () {
      expect(
        () => SeminarStatus.fromJson('completed'),
        throwsA(isA<ApiContractException>()),
      );
    });

    test('allows invitation download only after a valid schedule exists', () {
      expect(SeminarStatus.registered.canDownloadInvitation, isFalse);
      expect(SeminarStatus.verified.canDownloadInvitation, isFalse);
      expect(SeminarStatus.examinerAssigned.canDownloadInvitation, isFalse);
      expect(SeminarStatus.scheduled.canDownloadInvitation, isTrue);
      expect(SeminarStatus.ongoing.canDownloadInvitation, isTrue);
      expect(SeminarStatus.passed.canDownloadInvitation, isTrue);
      expect(SeminarStatus.passedWithRevision.canDownloadInvitation, isTrue);
      expect(SeminarStatus.failed.canDownloadInvitation, isTrue);
      expect(SeminarStatus.cancelled.canDownloadInvitation, isFalse);
    });
  });

  group('Assessment and finalization', () {
    test('parses dynamic criteria and server-owned passing threshold', () {
      final form = SeminarAssessmentForm.fromJson({
        'seminar': {
          'id': 'seminar-1',
          'status': 'ongoing',
          'studentName': 'Mahasiswa',
          'studentNim': '221001',
          'thesisTitle': 'Judul',
          'date': '2026-08-20',
          'startTime': '08:00',
          'endTime': '10:00',
          'room': {'id': 'room-1', 'name': 'Ruang Seminar'},
        },
        'examiner': {
          'id': 'examiner-1',
          'order': 1,
          'assessmentScore': 22,
          'revisionNotes': 'Perbaiki diagram',
          'assessmentSubmittedAt': null,
        },
        'criteriaGroups': [
          {
            'id': 'cpmk-1',
            'code': 'CPMK01',
            'description': 'Presentasi',
            'criteria': [
              {
                'id': 'criterion-1',
                'name': 'Penyampaian',
                'maxScore': 25,
                'score': 22,
                'rubrics': [],
              },
            ],
          },
        ],
        'minimumPassingScore': 67.5,
      });

      expect(form.minimumPassingScore, 67.5);
      expect(form.criteriaGroups.single.criteria.single.score, 22);
      expect(form.isLocked, false);
    });
  });

  group('Announcements and attendance', () {
    test('derives audience registration actions from the typed state', () {
      final announcement = SeminarAnnouncement.fromJson({
        'id': 'seminar-1',
        'date': '2026-08-20',
        'startTime': '08:00',
        'endTime': '10:00',
        'status': 'scheduled',
        'resultFinalizedAt': null,
        'meetingLink': null,
        'room': {'id': 'room-1', 'name': 'Ruang Seminar'},
        'thesisTitle': 'Judul',
        'presenterName': 'Mahasiswa',
        'presenterStudentId': 'student-1',
        'supervisors': [
          {'role': 'Pembimbing 1', 'name': 'Dr. Pembimbing'},
        ],
        'examiners': [
          {'order': 1, 'name': 'Dr. Penguji'},
        ],
        'isOwn': false,
        'isPast': false,
        'isRegistered': false,
        'isPresent': false,
        'registeredAt': null,
      });

      expect(announcement.canRegister, true);
      expect(announcement.canUnregister, false);
    });
  });

  group('Examiner assignment models', () {
    test('parses assignment and eligible-examiner contracts', () {
      final assignment = ExaminerAssignmentResource.fromJson({
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
        'assignmentStatus': 'partially_rejected',
        'examiners': [
          {
            'id': 'examiner-1',
            'lecturerId': 'lecturer-1',
            'lecturerName': 'Dr. Penguji',
            'order': 1,
            'availabilityStatus': 'available',
            'respondedAt': '2026-08-18T09:00:00.000Z',
          },
        ],
        'rejectedExaminers': [],
      });

      expect(
        assignment.assignmentStatus,
        ExaminerAssignmentStatus.partiallyRejected,
      );
      expect(assignment.examiners.single.lecturerId, 'lecturer-1');
    });
  });
}
