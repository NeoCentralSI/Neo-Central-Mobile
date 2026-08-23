import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/api_exception.dart';
import 'package:neocentral/features/defence/data/models/defence_models.dart';
import 'package:neocentral/features/thesis_shared/data/models/academic_requirement.dart';

void main() {
  group('StudentDefenceOverview', () {
    test('parses checklist, requirement UUID, and current attempt', () {
      final overview = StudentDefenceOverview.fromJson({
        'thesisId': 'thesis-1',
        'thesisTitle': 'Sistem Informasi Akademik',
        'checklist': {
          'lulusSeminar': {
            'met': true,
            'label': 'Lulus Seminar Hasil',
            'seminarStatus': 'passed_with_revision',
          },
          'sks': {
            'met': true,
            'label': 'Minimal 142 SKS',
            'current': 144,
            'required': 142,
          },
          'revisiSeminar': {
            'met': true,
            'label': 'Revisi Seminar',
            'seminarStatus': 'passed_with_revision',
            'total': 2,
            'finished': 2,
            'isVisible': true,
          },
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
          {'id': 'documents', 'label': 'Dokumen Lengkap', 'checked': false},
        ],
        'canUpload': true,
        'requirements': [
          {
            'id': 'requirement-uuid',
            'name': 'Naskah Sidang',
            'description': 'PDF',
            'displayOrder': 1,
            'document': {
              'thesisDefenceId': 'defence-1',
              'requirementId': 'requirement-uuid',
              'status': 'declined',
              'submittedAt': '2026-08-18T08:00:00.000Z',
              'notes': 'Perbaiki lembar pengesahan',
              'fileName': 'naskah.pdf',
            },
          },
        ],
        'requirementConfiguration': {'isConfigured': true, 'message': null},
        'uploadConfig': {
          'accept': ['.pdf'],
          'maxFileSizeBytes': 10485760,
          'maxFileSizeMb': 10,
        },
        'defence': {
          'id': 'defence-1',
          'status': 'registered',
          'registeredAt': '2026-08-18T07:00:00.000Z',
          'date': null,
          'startTime': null,
          'endTime': null,
          'meetingLink': null,
          'finalScore': null,
          'grade': null,
          'resultFinalizedAt': null,
          'cancelledReason': null,
          'scheduledAt': null,
          'invitationLetterNo': null,
          'room': null,
          'documents': [],
          'examiners': [],
        },
      });

      expect(overview.checklist.sks.current, 144);
      expect(overview.checklist.seminarRevision.finished, 2);
      expect(overview.requirements.single.id, 'requirement-uuid');
      expect(
        overview.requirements.single.document?.status,
        DocumentStatus.declined,
      );
      expect(overview.defence?.status, DefenceStatus.registered);
    });

    test('accepts no-thesis response without fabricating a defence', () {
      final overview = StudentDefenceOverview.fromJson({
        'thesisId': null,
        'thesisTitle': null,
        'checklist': {
          'lulusSeminar': {
            'met': false,
            'label': 'Lulus Seminar Hasil',
            'seminarStatus': null,
          },
          'sks': {
            'met': false,
            'label': 'Minimal 142 SKS',
            'current': 0,
            'required': 142,
          },
          'revisiSeminar': {
            'met': false,
            'label': 'Revisi Seminar',
            'seminarStatus': null,
            'total': 0,
            'finished': 0,
            'isVisible': false,
          },
          'pembimbing': {
            'met': false,
            'label': 'Persetujuan Pembimbing',
            'supervisors': [],
          },
        },
        'allChecklistMet': false,
        'milestones': [],
        'canUpload': false,
        'requirements': [],
        'requirementConfiguration': {
          'isConfigured': false,
          'message': 'Tugas akhir belum terdaftar.',
        },
        'uploadConfig': {
          'accept': ['.pdf'],
          'maxFileSizeBytes': 10485760,
          'maxFileSizeMb': 10,
        },
        'defence': null,
      });

      expect(overview.thesisId, isNull);
      expect(overview.defence, isNull);
      expect(overview.canUpload, false);
    });
  });

  group('Defence assessment contracts', () {
    test('parses supervisor rubric and server-owned passing threshold', () {
      final form = DefenceAssessmentForm.fromJson({
        'defence': {
          'id': 'defence-1',
          'status': 'ongoing',
          'studentName': 'Mahasiswa',
          'studentNim': '221001',
          'thesisTitle': 'Judul',
          'date': '2026-08-20',
          'startTime': '08:00',
          'endTime': '10:00',
          'room': {'id': 'room-1', 'name': 'Ruang Sidang'},
        },
        'assessorRole': 'supervisor',
        'examiner': null,
        'supervisor': {
          'roleName': 'Pembimbing 1',
          'assessmentScore': 18,
          'supervisorNotes': 'Pertahankan kualitas naskah',
          'assessmentSubmittedAt': null,
        },
        'criteriaGroups': [
          {
            'id': 'cpmk-supervisor',
            'code': 'CPMK-S',
            'description': 'Proses bimbingan',
            'criteria': [
              {
                'id': 'criterion-supervisor',
                'name': 'Kemandirian',
                'maxScore': 20,
                'score': 18,
                'rubrics': [
                  {
                    'id': 'rubric-1',
                    'minScore': 16,
                    'maxScore': 20,
                    'description': 'Sangat baik',
                  },
                ],
              },
            ],
          },
        ],
        'minimumPassingScore': 70,
      });

      expect(form.assessorRole, DefenceAssessorRole.supervisor);
      expect(form.criteriaGroups.single.code, 'CPMK-S');
      expect(form.minimumPassingScore, 70);
      expect(form.isSubmitted, false);
    });

    test(
      'parses finalization without deriving pass/fail from a mobile constant',
      () {
        final data = DefenceFinalizationData.fromJson({
          'defence': {
            'id': 'defence-1',
            'status': 'ongoing',
            'examinerAverageScore': 52,
            'supervisorScore': 20,
            'finalScore': null,
            'computedFinalScore': 72,
            'grade': null,
            'resultFinalizedAt': null,
            'resultFinalizedBy': null,
            'revisionFinalizedAt': null,
            'revisionFinalizedBy': null,
            'studentName': 'Mahasiswa',
            'studentNim': '221001',
            'thesisTitle': 'Judul',
          },
          'supervisor': {
            'roleName': 'Pembimbing 1',
            'name': 'Dr. Pembimbing',
            'canFinalize': true,
          },
          'examiners': [
            {
              'id': 'examiner-1',
              'lecturerId': 'lecturer-1',
              'lecturerName': 'Dr. Penguji 1',
              'order': 1,
              'assessmentScore': 52,
              'revisionNotes': null,
              'assessmentSubmittedAt': '2026-08-20T09:00:00.000Z',
              'isDraft': false,
              'assessmentDetails': [],
            },
            {
              'id': 'examiner-2',
              'lecturerId': 'lecturer-2',
              'lecturerName': 'Dr. Penguji 2',
              'order': 2,
              'assessmentScore': 52,
              'revisionNotes': null,
              'assessmentSubmittedAt': '2026-08-20T09:10:00.000Z',
              'isDraft': false,
              'assessmentDetails': [],
            },
          ],
          'supervisorAssessment': {
            'assessmentScore': 20,
            'supervisorNotes': null,
            'assessmentSubmittedAt': '2026-08-20T09:20:00.000Z',
            'assessmentDetails': [],
          },
          'allExaminerSubmitted': true,
          'supervisorAssessmentSubmitted': true,
          'recommendationUnlocked': true,
          'minimumPassingScore': 70,
        });

        expect(data.examiners, hasLength(2));
        expect(data.defence.computedFinalScore, 72);
        expect(data.minimumPassingScore, 70);
        expect(data.recommendationUnlocked, true);
      },
    );

    test('parses the read-only student transcript', () {
      final transcript = StudentDefenceAssessment.fromJson({
        'defence': {
          'id': 'defence-1',
          'status': 'passed',
          'examinerAverageScore': 55,
          'supervisorScore': 20,
          'finalScore': 75,
          'grade': 'B+',
          'resultFinalizedAt': '2026-08-20T10:00:00.000Z',
          'room': {'id': 'room-1', 'name': 'Ruang Sidang'},
          'date': '2026-08-20',
          'startTime': '08:00',
          'endTime': '10:00',
          'meetingLink': null,
        },
        'examiners': [
          {
            'id': 'examiner-1',
            'lecturerId': 'lecturer-1',
            'lecturerName': 'Dr. Penguji',
            'order': 1,
            'assessmentScore': 55,
            'assessmentSubmittedAt': '2026-08-20T09:00:00.000Z',
            'revisionNotes': 'Rapikan diagram',
            'assessmentDetails': [],
          },
        ],
        'supervisorAssessment': {
          'name': 'Dr. Pembimbing',
          'assessmentScore': 20,
          'supervisorNotes': 'Baik',
          'assessmentSubmittedAt': '2026-08-20T09:30:00.000Z',
          'assessmentDetails': [],
        },
      });

      expect(transcript.defence.status, DefenceStatus.passed);
      expect(transcript.defence.finalScore, 75);
      expect(transcript.examiners.single.revisionNotes, 'Rapikan diagram');
    });
  });

  test('detail normalizes backend viewerRole none for non-assessors', () {
    final detail = DefenceDetail.fromJson({
      'id': 'defence-1',
      'status': 'scheduled',
      'isArchive': false,
      'thesis': {'id': 'thesis-1', 'title': 'Typed Mobile Contract'},
      'student': {'name': 'Mahasiswa', 'nim': '123'},
      'supervisors': <dynamic>[],
      'documents': <dynamic>[],
      'documentTypes': <dynamic>[],
      'examiners': <dynamic>[],
      'rejectedExaminers': <dynamic>[],
      'viewerRole': 'none',
      'canOpenExaminerAssessment': false,
      'canOpenSupervisorAssessment': false,
      'canOpenSupervisorFinalization': false,
      'allExaminerSubmitted': false,
      'supervisorAssessmentSubmitted': false,
    });

    expect(detail.viewerRole, DefenceAssessorRole.viewer);
  });

  test('revision board exposes the backend finalization state', () {
    final board = DefenceRevisionBoard.fromJson({
      'defenceId': 'defence-1',
      'summary': {'total': 1, 'finished': 1, 'pendingApproval': 0},
      'isFinalized': true,
      'revisions': [
        {
          'id': 'revision-1',
          'examinerOrder': 1,
          'examinerLecturerId': 'lecturer-1',
          'examinerName': 'Dr. Penguji',
          'description': 'Rapikan diagram',
          'revisionAction': 'Sudah dirapikan',
          'isFinished': true,
          'studentSubmittedAt': '2026-08-21T08:00:00.000Z',
          'supervisorApprovedAt': '2026-08-21T09:00:00.000Z',
          'approvedBySupervisorName': 'Dr. Pembimbing',
        },
      ],
    });

    expect(board.isFinalized, true);
    expect(board.finished, 1);
  });

  test('rejects an unknown defence workflow status', () {
    expect(
      () => DefenceStatus.fromJson('completed'),
      throwsA(isA<ApiContractException>()),
    );
  });
}
