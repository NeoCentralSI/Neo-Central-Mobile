import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/api_exception.dart';
import 'package:neocentral/features/thesis_shared/data/models/thesis_shared_models.dart';

void main() {
  group('AcademicRequirement', () {
    test('parses a seminar/defence requirement document contract', () {
      final requirement = AcademicRequirement.fromJson({
        'id': 'requirement-1',
        'name': 'Naskah Tugas Akhir',
        'description': 'PDF final',
        'displayOrder': 2,
        'document': {
          'thesisDefenceId': 'defence-1',
          'requirementId': 'requirement-1',
          'status': 'approved',
          'submittedAt': '2026-08-18T08:00:00.000Z',
          'verifiedAt': '2026-08-18T09:00:00.000Z',
          'notes': null,
          'verifiedBy': 'admin-1',
          'fileName': 'tugas-akhir.pdf',
          'filePath': '/documents/tugas-akhir.pdf',
          'mimeType': 'application/pdf',
          'fileSize': 2048,
        },
      });

      expect(requirement.id, 'requirement-1');
      expect(requirement.document?.resourceId, 'defence-1');
      expect(requirement.document?.status, DocumentStatus.approved);
      expect(requirement.document?.fileSize, 2048);
    });

    test('rejects an unknown document status', () {
      expect(
        () => DocumentStatus.fromJson('verified'),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  group('Assessment models', () {
    test('parses dynamic groups, criteria, scores, and rubrics', () {
      final group = AssessmentGroup.fromJson({
        'id': 'cpmk-1',
        'code': 'CPMK01',
        'description': 'Kemampuan analisis',
        'criteria': [
          {
            'id': 'criterion-1',
            'name': 'Presentasi',
            'maxScore': 25,
            'score': 21.5,
            'displayOrder': 1,
            'rubrics': [
              {
                'id': 'rubric-1',
                'minScore': 20,
                'maxScore': 25,
                'description': 'Sangat baik',
              },
            ],
          },
        ],
      });

      expect(group.code, 'CPMK01');
      expect(group.criteria.single.score, 21.5);
      expect(group.criteria.single.rubrics.single.maxScore, 25);
    });

    test('rejects a malformed numeric score contract', () {
      expect(
        () => AssessmentCriterion.fromJson({
          'id': 'criterion-1',
          'name': 'Presentasi',
          'maxScore': '25',
          'score': null,
          'rubrics': const [],
        }),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  group('Revision models', () {
    test('parses board summary and revision state', () {
      final board = RevisionBoard.fromJson({
        'seminarId': 'seminar-1',
        'summary': {'total': 1, 'finished': 0, 'pendingApproval': 1},
        'revisions': [
          {
            'id': 'revision-1',
            'examinerOrder': 1,
            'examinerLecturerId': 'lecturer-1',
            'examinerName': 'Dr. Penguji',
            'description': 'Perjelas pembahasan',
            'revisionAction': 'Bab IV diperbarui',
            'isFinished': false,
            'studentSubmittedAt': '2026-08-18T10:00:00.000Z',
            'supervisorApprovedAt': null,
            'approvedBySupervisorId': null,
            'approvedBySupervisorName': null,
          },
        ],
      });

      expect(board.resourceId, 'seminar-1');
      expect(board.pendingApproval, 1);
      expect(board.revisions.single.examinerOrder, 1);
    });

    test('derives summary if the backend omits it', () {
      final board = RevisionBoard.fromJson({
        'defenceId': 'defence-1',
        'revisions': [
          {
            'id': 'revision-1',
            'examinerOrder': null,
            'examinerLecturerId': null,
            'examinerName': null,
            'description': 'Rapikan simpulan',
            'revisionAction': 'Selesai',
            'isFinished': true,
            'studentSubmittedAt': '2026-08-18T10:00:00.000Z',
            'supervisorApprovedAt': '2026-08-18T11:00:00.000Z',
            'approvedBySupervisorId': 'supervisor-1',
            'approvedBySupervisorName': 'Dr. Pembimbing',
          },
        ],
      });

      expect(board.total, 1);
      expect(board.finished, 1);
      expect(board.pendingApproval, 0);
    });
  });

  group('People and schedule models', () {
    test('parses an examiner assignment with typed availability', () {
      final examiner = ExaminerAssignment.fromJson({
        'id': 'examiner-1',
        'lecturerId': 'lecturer-1',
        'lecturerName': 'Dr. Penguji',
        'order': 1,
        'availabilityStatus': 'available',
        'unavailableReasons': null,
        'respondedAt': '2026-08-18T07:00:00.000Z',
        'assessmentScore': 82.5,
        'assessmentSubmittedAt': '2026-08-18T09:00:00.000Z',
        'revisionNotes': 'Perbaiki diagram',
      });

      expect(examiner.availabilityStatus, ExaminerAvailabilityStatus.available);
      expect(examiner.hasSubmittedAssessment, true);
    });

    test('parses a hybrid schedule and room metadata', () {
      final schedule = ThesisSchedule.fromJson({
        'date': '2026-08-20',
        'startTime': '08:00',
        'endTime': '10:00',
        'meetingLink': 'https://meet.example.test/room',
        'scheduledAt': '2026-08-18T06:00:00.000Z',
        'invitationLetterNo': '001/UN16/SI/2026',
        'room': {
          'id': 'room-1',
          'name': 'Ruang Seminar',
          'location': 'Gedung A',
          'capacity': 40,
        },
      });

      expect(schedule.room?.capacity, 40);
      expect(schedule.isOnline, true);
      expect(schedule.isComplete, true);
    });
  });
}
