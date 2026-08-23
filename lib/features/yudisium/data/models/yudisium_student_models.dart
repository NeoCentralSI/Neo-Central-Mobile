part of 'yudisium_models.dart';

class YudisiumThesisSummary {
  final String id;
  final String title;

  const YudisiumThesisSummary({required this.id, required this.title});

  factory YudisiumThesisSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.thesis');
    return YudisiumThesisSummary(
      id: json.requireString('id', context: 'yudisium.thesis'),
      title: json.requireString('title', context: 'yudisium.thesis'),
    );
  }
}

class YudisiumCplScore {
  final String code;
  final String description;
  final num? score;
  final num minimalScore;
  final YudisiumCplStatus status;
  final bool passed;
  final String? validatedBy;
  final String? validatedByNip;
  final DateTime? validatedAt;

  const YudisiumCplScore({
    required this.code,
    required this.description,
    required this.score,
    required this.minimalScore,
    required this.status,
    required this.passed,
    required this.validatedBy,
    required this.validatedByNip,
    required this.validatedAt,
  });

  factory YudisiumCplScore.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.cplScore');
    return YudisiumCplScore(
      code: json.requireString('code', context: 'yudisium.cplScore'),
      description: json.requireString(
        'description',
        context: 'yudisium.cplScore',
      ),
      score: json.optionalNum('score'),
      minimalScore: json.requireNum(
        'minimalScore',
        context: 'yudisium.cplScore',
      ),
      status: YudisiumCplStatus.fromJson(json['status']),
      passed: json.requireBool('passed', context: 'yudisium.cplScore'),
      validatedBy:
          json.optionalString('validatedBy') ??
          json.optionalString('verifiedBy'),
      validatedByNip:
          json.optionalString('validatedByNip') ??
          json.optionalString('verifiedByNip'),
      validatedAt:
          json.optionalDateTime('validatedAt') ??
          json.optionalDateTime('verifiedAt'),
    );
  }
}

class YudisiumOverviewRequirement {
  final String id;
  final String name;
  final String? description;
  final bool isUploaded;
  final String status;
  final DateTime? submittedAt;

  const YudisiumOverviewRequirement({
    required this.id,
    required this.name,
    required this.description,
    required this.isUploaded,
    required this.status,
    required this.submittedAt,
  });

  factory YudisiumOverviewRequirement.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.requirement');
    final status = json.requireString(
      'status',
      context: 'yudisium.requirement',
    );
    if (status != 'terunggah' && status != 'menunggu') {
      throw ApiContractException(
        'Status ringkasan dokumen yudisium tidak dikenali: $status.',
      );
    }
    return YudisiumOverviewRequirement(
      id: json.requireString('id', context: 'yudisium.requirement'),
      name: json.requireString('name', context: 'yudisium.requirement'),
      description: json.optionalString('description'),
      isUploaded: json.requireBool(
        'isUploaded',
        context: 'yudisium.requirement',
      ),
      status: status,
      submittedAt: json.optionalDateTime('submittedAt'),
    );
  }
}

class YudisiumHistoryItem {
  final String id;
  final String yudisiumId;
  final String yudisiumName;
  final YudisiumParticipantStatus status;
  final DateTime? createdAt;
  final DateTime? registrationOpenDate;
  final DateTime? registrationCloseDate;
  final DateTime? eventDate;

  const YudisiumHistoryItem({
    required this.id,
    required this.yudisiumId,
    required this.yudisiumName,
    required this.status,
    required this.createdAt,
    required this.registrationOpenDate,
    required this.registrationCloseDate,
    required this.eventDate,
  });

  factory YudisiumHistoryItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.history');
    return YudisiumHistoryItem(
      id: json.requireString('id', context: 'yudisium.history'),
      yudisiumId: json.requireString('yudisiumId', context: 'yudisium.history'),
      yudisiumName: json.requireString(
        'yudisiumName',
        context: 'yudisium.history',
      ),
      status: YudisiumParticipantStatus.fromJson(json['status']),
      createdAt: json.optionalDateTime('createdAt'),
      registrationOpenDate: json.optionalDateTime('registrationOpenDate'),
      registrationCloseDate: json.optionalDateTime('registrationCloseDate'),
      eventDate: json.optionalDateTime('eventDate'),
    );
  }
}

class StudentYudisiumOverview {
  final YudisiumEventSummary? yudisium;
  final YudisiumParticipantStatus? participantStatus;
  final String studentName;
  final String studentNim;
  final YudisiumThesisSummary? thesis;
  final YudisiumChecklist checklist;
  final bool allChecklistMet;
  final bool allCplVerified;
  final List<YudisiumCplScore> cplScores;
  final List<YudisiumOverviewRequirement> requirements;
  final List<YudisiumHistoryItem> history;

  const StudentYudisiumOverview({
    required this.yudisium,
    required this.participantStatus,
    required this.studentName,
    required this.studentNim,
    required this.thesis,
    required this.checklist,
    required this.allChecklistMet,
    required this.allCplVerified,
    required this.cplScores,
    required this.requirements,
    required this.history,
  });

  factory StudentYudisiumOverview.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentYudisiumOverview');
    return StudentYudisiumOverview(
      yudisium: json['yudisium'] == null
          ? null
          : YudisiumEventSummary.fromJson(json['yudisium']),
      participantStatus: json['participantStatus'] == null
          ? null
          : YudisiumParticipantStatus.fromJson(json['participantStatus']),
      studentName: json.requireString(
        'studentName',
        context: 'studentYudisiumOverview',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'studentYudisiumOverview',
      ),
      thesis: json['thesis'] == null
          ? null
          : YudisiumThesisSummary.fromJson(json['thesis']),
      checklist: YudisiumChecklist.fromJson(json['checklist']),
      allChecklistMet: json.requireBool(
        'allChecklistMet',
        context: 'studentYudisiumOverview',
      ),
      allCplVerified: json.requireBool(
        'allCplVerified',
        context: 'studentYudisiumOverview',
      ),
      cplScores: json
          .requireList('cplScores', context: 'studentYudisiumOverview')
          .map(YudisiumCplScore.fromJson)
          .toList(growable: false),
      requirements: json
          .requireList('requirements', context: 'studentYudisiumOverview')
          .map(YudisiumOverviewRequirement.fromJson)
          .toList(growable: false),
      history: json
          .optionalList('history')
          .map(YudisiumHistoryItem.fromJson)
          .toList(growable: false),
    );
  }

  int get activeStepIndex => switch (participantStatus) {
    YudisiumParticipantStatus.finalized => 4,
    YudisiumParticipantStatus.appointed => 3,
    YudisiumParticipantStatus.eligible => 2,
    YudisiumParticipantStatus.registered => 1,
    YudisiumParticipantStatus.rejected => -1,
    null => allChecklistMet ? 0 : -1,
  };
}

class YudisiumRequirementDocument {
  final String itemId;
  final String? fileName;
  final String? filePath;

  const YudisiumRequirementDocument({
    required this.itemId,
    required this.fileName,
    required this.filePath,
  });

  factory YudisiumRequirementDocument.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.document');
    return YudisiumRequirementDocument(
      itemId: json.requireString('id', context: 'yudisium.document'),
      fileName: json.optionalString('fileName'),
      filePath: json.optionalString('filePath'),
    );
  }
}

class YudisiumRequirementUploadStatus {
  final String id;
  final String name;
  final String? description;
  final String? notes;
  final DocumentStatus? status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? validationNotes;
  final YudisiumRequirementDocument? document;

  const YudisiumRequirementUploadStatus({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.status,
    required this.submittedAt,
    required this.verifiedAt,
    required this.validationNotes,
    required this.document,
  });

  factory YudisiumRequirementUploadStatus.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.uploadRequirement');
    return YudisiumRequirementUploadStatus(
      id: json.requireString('id', context: 'yudisium.uploadRequirement'),
      name: json.requireString('name', context: 'yudisium.uploadRequirement'),
      description: json.optionalString('description'),
      notes: json.optionalString('notes'),
      status: json['status'] == null
          ? null
          : DocumentStatus.fromJson(json['status']),
      submittedAt: json.optionalDateTime('submittedAt'),
      verifiedAt: json.optionalDateTime('verifiedAt'),
      validationNotes: json.optionalString('validationNotes'),
      document: json['document'] == null
          ? null
          : YudisiumRequirementDocument.fromJson(json['document']),
    );
  }
}

class StudentYudisiumRequirements {
  final String? yudisiumId;
  final String? participantId;
  final YudisiumParticipantStatus? participantStatus;
  final List<YudisiumRequirementUploadStatus> requirements;

  const StudentYudisiumRequirements({
    required this.yudisiumId,
    required this.participantId,
    required this.participantStatus,
    required this.requirements,
  });

  factory StudentYudisiumRequirements.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentYudisiumRequirements');
    return StudentYudisiumRequirements(
      yudisiumId: json.optionalString('yudisiumId'),
      participantId: json.optionalString('participantId'),
      participantStatus: json['participantStatus'] == null
          ? null
          : YudisiumParticipantStatus.fromJson(json['participantStatus']),
      requirements: json
          .requireList('requirements', context: 'studentYudisiumRequirements')
          .map(YudisiumRequirementUploadStatus.fromJson)
          .toList(growable: false),
    );
  }
}

class YudisiumDocumentUploadResult {
  final String requirementId;
  final String fileName;
  final String filePath;
  final DocumentStatus status;

  const YudisiumDocumentUploadResult({
    required this.requirementId,
    required this.fileName,
    required this.filePath,
    required this.status,
  });

  factory YudisiumDocumentUploadResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.uploadResult');
    return YudisiumDocumentUploadResult(
      requirementId: json.requireString(
        'requirementId',
        context: 'yudisium.uploadResult',
      ),
      fileName: json.requireString(
        'fileName',
        context: 'yudisium.uploadResult',
      ),
      filePath: json.requireString(
        'filePath',
        context: 'yudisium.uploadResult',
      ),
      status: DocumentStatus.fromJson(json['status']),
    );
  }
}
