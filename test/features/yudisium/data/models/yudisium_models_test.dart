import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/api_exception.dart';
import 'package:neocentral/features/thesis_shared/data/models/academic_requirement.dart';
import 'package:neocentral/features/yudisium/data/models/yudisium_models.dart';

void main() {
  group('StudentYudisiumOverview', () {
    test('keeps the active participant separate from rejected history', () {
      final overview = StudentYudisiumOverview.fromJson({
        'yudisium': _eventJson(status: 'open'),
        'participantStatus': 'registered',
        'studentName': 'Mahasiswa Uji',
        'studentNim': '221001',
        'thesis': {'id': 'thesis-1', 'title': 'Judul Tugas Akhir'},
        'checklist': _checklistJson(exitSurveyMet: true),
        'allChecklistMet': true,
        'allCplVerified': false,
        'cplScores': [
          {
            'code': 'CPL-01',
            'description': 'Mampu memecahkan masalah komputasi',
            'score': 82.5,
            'minimalScore': 70,
            'status': 'validated',
            'passed': true,
            'validatedBy': 'Dr. Validator',
            'validatedByNip': '19800101',
            'validatedAt': '2026-08-18T08:00:00.000Z',
          },
        ],
        'requirements': [
          {
            'id': 'requirement-uuid',
            'name': 'Bebas Pustaka',
            'description': 'Surat bebas pustaka',
            'isUploaded': true,
            'status': 'terunggah',
            'submittedAt': '2026-08-18T07:00:00.000Z',
          },
        ],
        'history': [
          {
            'id': 'participant-old',
            'yudisiumId': 'yudisium-old',
            'yudisiumName': 'Yudisium Juli 2026',
            'status': 'rejected',
            'createdAt': '2026-07-10T07:00:00.000Z',
            'registrationOpenDate': '2026-07-01T00:00:00.000Z',
            'registrationCloseDate': '2026-07-10T00:00:00.000Z',
            'eventDate': '2026-07-20T00:00:00.000Z',
          },
        ],
      });

      expect(overview.participantStatus, YudisiumParticipantStatus.registered);
      expect(overview.activeStepIndex, 1);
      expect(
        overview.history.single.status,
        YudisiumParticipantStatus.rejected,
      );
      expect(overview.cplScores.single.status, YudisiumCplStatus.validated);
      expect(overview.requirements.single.id, 'requirement-uuid');
    });

    test('accepts an overview with no active yudisium period', () {
      final overview = StudentYudisiumOverview.fromJson({
        'yudisium': null,
        'participantStatus': null,
        'studentName': 'Mahasiswa Uji',
        'studentNim': '221001',
        'thesis': null,
        'checklist': _checklistJson(exitSurveyMet: false),
        'allChecklistMet': false,
        'allCplVerified': false,
        'cplScores': [],
        'requirements': [],
        'history': [],
      });

      expect(overview.yudisium, isNull);
      expect(overview.participantStatus, isNull);
      expect(overview.activeStepIndex, -1);
    });

    test('maps every server participant status to the exact progress step', () {
      const expected = {
        YudisiumParticipantStatus.registered: 1,
        YudisiumParticipantStatus.eligible: 2,
        YudisiumParticipantStatus.appointed: 3,
        YudisiumParticipantStatus.finalized: 4,
        YudisiumParticipantStatus.rejected: -1,
      };
      for (final entry in expected.entries) {
        final overview = StudentYudisiumOverview.fromJson({
          'yudisium': _eventJson(status: 'closed'),
          'participantStatus': entry.key.value,
          'studentName': 'Mahasiswa Uji',
          'studentNim': '221001',
          'thesis': null,
          'checklist': _checklistJson(exitSurveyMet: true),
          'allChecklistMet': true,
          'allCplVerified': false,
          'cplScores': [],
          'requirements': [],
          'history': [],
        });
        expect(overview.activeStepIndex, entry.value);
      }
    });

    test('rejects unknown participant and event statuses', () {
      expect(
        () => YudisiumParticipantStatus.fromJson('verified'),
        throwsA(isA<ApiContractException>()),
      );
      expect(
        () => YudisiumDisplayStatus.fromJson('registration_open'),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  test('detailed requirement retains item ID used by protected download', () {
    final requirements = StudentYudisiumRequirements.fromJson({
      'yudisiumId': 'yudisium-1',
      'participantId': 'participant-1',
      'participantStatus': 'registered',
      'requirements': [
        {
          'id': 'requirement-uuid',
          'name': 'Bebas Laboratorium',
          'description': null,
          'status': 'declined',
          'submittedAt': '2026-08-18T07:00:00.000Z',
          'verifiedAt': '2026-08-18T08:00:00.000Z',
          'validationNotes': 'Dokumen tidak terbaca',
          'document': {
            'id': 'requirement-item-uuid',
            'fileName': 'bebas-lab.pdf',
            'filePath': '/uploads/yudisium/bebas-lab.pdf',
          },
        },
      ],
    });

    final item = requirements.requirements.single;
    expect(item.id, 'requirement-uuid');
    expect(item.status, DocumentStatus.declined);
    expect(item.document?.itemId, 'requirement-item-uuid');
  });

  group('StudentYudisiumExitSurvey', () {
    test('parses, orders, and restores all six question types', () {
      final survey = StudentYudisiumExitSurvey.fromJson({
        'yudisium': {'id': 'yudisium-1', 'name': 'Yudisium Agustus'},
        'form': {
          'id': 'form-1',
          'name': 'Exit Survey Alumni',
          'description': 'Isi dengan jujur',
          'sessions': [
            {
              'id': 'session-2',
              'name': 'Lanjutan',
              'description': null,
              'order': 2,
              'questions': [_question('q-date', 'date', 1)],
            },
            {
              'id': 'session-1',
              'name': 'Utama',
              'description': null,
              'order': 1,
              'questions': [
                _question('q-short', 'short_answer', 1),
                _question('q-paragraph', 'paragraph', 2),
                _question('q-single', 'single_choice', 3, choice: true),
                _question('q-multiple', 'multiple_choice', 4, choice: true),
                _question('q-number', 'number', 5),
              ],
            },
          ],
        },
        'response': {
          'id': 'participant-1',
          'submittedAt': '2026-08-18T09:00:00.000Z',
          'answers': [
            {
              'questionId': 'q-single',
              'optionId': 'option-1',
              'optionIds': [],
              'answerText': null,
              'answerNumber': null,
              'answerDate': null,
            },
            {
              'questionId': 'q-multiple',
              'optionId': null,
              'optionIds': ['option-1', 'option-2'],
              'answerText': null,
              'answerNumber': null,
              'answerDate': null,
            },
            {
              'questionId': 'q-number',
              'optionId': null,
              'optionIds': [],
              'answerText': null,
              'answerNumber': 4.25,
              'answerDate': null,
            },
          ],
        },
        'isSubmitted': true,
      });

      expect(survey.form.sessions.first.id, 'session-1');
      expect(
        survey.form.sessions
            .expand((session) => session.questions)
            .map((question) => question.type)
            .toSet(),
        YudisiumSurveyQuestionType.values.toSet(),
      );
      expect(survey.response?.answers[1].optionIds, ['option-1', 'option-2']);
      expect(survey.response?.answers[2].answerNumber, 4.25);
      expect(survey.isSubmitted, true);
    });

    test('rejects a question type outside the backend enum', () {
      expect(
        () => YudisiumSurveyQuestionType.fromJson('rating'),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  test('parses typed yudisium announcements', () {
    final announcement = YudisiumAnnouncement.fromJson({
      ..._eventJson(status: 'completed'),
      'notes': 'Hadir 30 menit lebih awal',
      'participants': [
        {
          'id': 'participant-1',
          'studentName': 'Mahasiswa Uji',
          'studentNim': '221001',
          'thesisTitle': 'Judul Tugas Akhir',
          'status': 'finalized',
          'registeredAt': '2026-08-01T08:00:00.000Z',
        },
      ],
    });

    expect(announcement.status, YudisiumDisplayStatus.completed);
    expect(
      announcement.participants.single.status,
      YudisiumParticipantStatus.finalized,
    );
  });
}

Map<String, dynamic> _eventJson({required String status}) => {
  'id': 'yudisium-1',
  'name': 'Yudisium Agustus 2026',
  'status': status,
  'registrationOpenDate': '2026-08-01T00:00:00.000Z',
  'registrationCloseDate': '2026-08-15T00:00:00.000Z',
  'eventDate': '2026-08-25T00:00:00.000Z',
  'room': {'id': 'room-1', 'name': 'Aula Utama'},
  'decreeDocument': null,
  'exitSurveyForm': {'id': 'form-1', 'title': 'Exit Survey'},
};

Map<String, dynamic> _checklistJson({required bool exitSurveyMet}) => {
  'sks': {
    'label': 'Menyelesaikan 146 SKS',
    'met': true,
    'current': 148,
    'required': 146,
  },
  'lulusSidang': {'label': 'Lulus Sidang TA', 'met': true},
  'revisiSidang': {
    'label': 'Menyelesaikan revisi sidang TA',
    'met': true,
    'revisionFinalizedAt': '2026-08-01T08:00:00.000Z',
  },
  'mataKuliahWajib': {'label': 'Lulus semua mata kuliah wajib', 'met': true},
  'mataKuliahMkwu': {'label': 'Lulus semua mata kuliah MKWU', 'met': true},
  'mataKuliahKerjaPraktik': {
    'label': 'Lulus mata kuliah kerja praktik',
    'met': true,
  },
  'mataKuliahKkn': {'label': 'Lulus mata kuliah KKN', 'met': true},
  'exitSurvey': {
    'label': 'Mengisi Exit Survey',
    'met': exitSurveyMet,
    'submittedAt': exitSurveyMet ? '2026-08-02T08:00:00.000Z' : null,
    'responseId': exitSurveyMet ? 'participant-1' : null,
    'isAvailable': !exitSurveyMet,
  },
};

Map<String, dynamic> _question(
  String id,
  String type,
  int order, {
  bool choice = false,
}) => {
  'id': id,
  'exitSurveySessionId': 'session-1',
  'question': 'Pertanyaan $id',
  'description': null,
  'questionType': type,
  'isRequired': true,
  'orderNumber': order,
  'options': choice
      ? [
          {'id': 'option-1', 'optionText': 'Pilihan 1', 'orderNumber': 1},
          {'id': 'option-2', 'optionText': 'Pilihan 2', 'orderNumber': 2},
        ]
      : [],
};
