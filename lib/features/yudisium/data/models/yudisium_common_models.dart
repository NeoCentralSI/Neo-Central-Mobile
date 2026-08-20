part of 'yudisium_models.dart';

enum YudisiumDisplayStatus {
  draft('draft'),
  open('open'),
  closed('closed'),
  ongoing('ongoing'),
  completed('completed');

  final String value;
  const YudisiumDisplayStatus(this.value);

  static YudisiumDisplayStatus fromJson(dynamic value) =>
      YudisiumDisplayStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw ApiContractException(
          'Status periode yudisium tidak dikenali: ${value ?? 'null'}.',
        ),
      );
}

enum YudisiumParticipantStatus {
  registered('registered'),
  eligible('eligible'),
  appointed('appointed'),
  rejected('rejected'),
  finalized('finalized');

  final String value;
  const YudisiumParticipantStatus(this.value);

  static YudisiumParticipantStatus fromJson(dynamic value) =>
      YudisiumParticipantStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw ApiContractException(
          'Status peserta yudisium tidak dikenali: ${value ?? 'null'}.',
        ),
      );

  bool get locksDocuments =>
      this == eligible || this == appointed || this == finalized;

  bool get canDownloadCplReport =>
      this == eligible || this == appointed || this == finalized;

  bool get canDownloadCertificate => this == appointed || this == finalized;
}

enum YudisiumCplStatus {
  calculated('calculated'),
  validated('validated'),
  finalized('finalized');

  final String value;
  const YudisiumCplStatus(this.value);

  static YudisiumCplStatus fromJson(dynamic value) =>
      YudisiumCplStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw ApiContractException(
          'Status nilai CPL tidak dikenali: ${value ?? 'null'}.',
        ),
      );

  bool get isValidated => this == validated || this == finalized;
}

class YudisiumFileReference {
  final String id;
  final String? fileName;
  final String? filePath;

  const YudisiumFileReference({
    required this.id,
    required this.fileName,
    required this.filePath,
  });

  factory YudisiumFileReference.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.file');
    return YudisiumFileReference(
      id: json.requireString('id', context: 'yudisium.file'),
      fileName: json.optionalString('fileName'),
      filePath: json.optionalString('filePath'),
    );
  }
}

class YudisiumExitSurveyFormSummary {
  final String id;
  final String name;

  const YudisiumExitSurveyFormSummary({required this.id, required this.name});

  factory YudisiumExitSurveyFormSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.exitSurveyForm');
    final name = json.optionalString('title') ?? json.optionalString('name');
    if (name == null || name.isEmpty) {
      throw const ApiContractException(
        'yudisium.exitSurveyForm tidak memiliki nama yang valid.',
      );
    }
    return YudisiumExitSurveyFormSummary(
      id: json.requireString('id', context: 'yudisium.exitSurveyForm'),
      name: name,
    );
  }
}

class YudisiumEventSummary {
  final String id;
  final String name;
  final YudisiumDisplayStatus status;
  final DateTime? registrationOpenDate;
  final DateTime? registrationCloseDate;
  final DateTime? eventDate;
  final RoomSummary? room;
  final String? notes;
  final YudisiumFileReference? decreeDocument;
  final YudisiumExitSurveyFormSummary? exitSurveyForm;

  const YudisiumEventSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.registrationOpenDate,
    required this.registrationCloseDate,
    required this.eventDate,
    required this.room,
    required this.notes,
    required this.decreeDocument,
    required this.exitSurveyForm,
  });

  factory YudisiumEventSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.event');
    return YudisiumEventSummary(
      id: json.requireString('id', context: 'yudisium.event'),
      name: json.requireString('name', context: 'yudisium.event'),
      status: YudisiumDisplayStatus.fromJson(json['status']),
      registrationOpenDate: json.optionalDateTime('registrationOpenDate'),
      registrationCloseDate: json.optionalDateTime('registrationCloseDate'),
      eventDate: json.optionalDateTime('eventDate'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      notes: json.optionalString('notes'),
      decreeDocument: json['decreeDocument'] == null
          ? null
          : YudisiumFileReference.fromJson(json['decreeDocument']),
      exitSurveyForm: json['exitSurveyForm'] == null
          ? null
          : YudisiumExitSurveyFormSummary.fromJson(json['exitSurveyForm']),
    );
  }
}

class YudisiumChecklistItem {
  final String label;
  final bool met;
  final int? current;
  final int? required;
  final DateTime? submittedAt;
  final DateTime? revisionFinalizedAt;
  final String? responseId;
  final bool isAvailable;

  const YudisiumChecklistItem({
    required this.label,
    required this.met,
    required this.current,
    required this.required,
    required this.submittedAt,
    required this.revisionFinalizedAt,
    required this.responseId,
    required this.isAvailable,
  });

  factory YudisiumChecklistItem.fromJson(dynamic value, String context) {
    final json = requireJsonMap(value, context: context);
    return YudisiumChecklistItem(
      label: json.requireString('label', context: context),
      met: json.requireBool('met', context: context),
      current: json.optionalInt('current'),
      required: json.optionalInt('required'),
      submittedAt: json.optionalDateTime('submittedAt'),
      revisionFinalizedAt: json.optionalDateTime('revisionFinalizedAt'),
      responseId: json.optionalString('responseId'),
      isAvailable: json.optionalBool('isAvailable'),
    );
  }
}

class YudisiumChecklist {
  final YudisiumChecklistItem sks;
  final YudisiumChecklistItem passedDefence;
  final YudisiumChecklistItem? defenceRevision;
  final YudisiumChecklistItem mandatoryCourses;
  final YudisiumChecklistItem mkwu;
  final YudisiumChecklistItem internship;
  final YudisiumChecklistItem kkn;
  final YudisiumChecklistItem exitSurvey;

  const YudisiumChecklist({
    required this.sks,
    required this.passedDefence,
    required this.defenceRevision,
    required this.mandatoryCourses,
    required this.mkwu,
    required this.internship,
    required this.kkn,
    required this.exitSurvey,
  });

  factory YudisiumChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.checklist');
    return YudisiumChecklist(
      sks: YudisiumChecklistItem.fromJson(json['sks'], 'checklist.sks'),
      passedDefence: YudisiumChecklistItem.fromJson(
        json['lulusSidang'],
        'checklist.lulusSidang',
      ),
      defenceRevision: json['revisiSidang'] == null
          ? null
          : YudisiumChecklistItem.fromJson(
              json['revisiSidang'],
              'checklist.revisiSidang',
            ),
      mandatoryCourses: YudisiumChecklistItem.fromJson(
        json['mataKuliahWajib'],
        'checklist.mataKuliahWajib',
      ),
      mkwu: YudisiumChecklistItem.fromJson(
        json['mataKuliahMkwu'],
        'checklist.mataKuliahMkwu',
      ),
      internship: YudisiumChecklistItem.fromJson(
        json['mataKuliahKerjaPraktik'],
        'checklist.mataKuliahKerjaPraktik',
      ),
      kkn: YudisiumChecklistItem.fromJson(
        json['mataKuliahKkn'],
        'checklist.mataKuliahKkn',
      ),
      exitSurvey: YudisiumChecklistItem.fromJson(
        json['exitSurvey'],
        'checklist.exitSurvey',
      ),
    );
  }

  List<({String key, YudisiumChecklistItem item})> get orderedItems => [
    (key: 'sks', item: sks),
    (key: 'lulusSidang', item: passedDefence),
    if (defenceRevision != null) (key: 'revisiSidang', item: defenceRevision!),
    (key: 'mataKuliahWajib', item: mandatoryCourses),
    (key: 'mataKuliahMkwu', item: mkwu),
    (key: 'mataKuliahKerjaPraktik', item: internship),
    (key: 'mataKuliahKkn', item: kkn),
    (key: 'exitSurvey', item: exitSurvey),
  ];
}
