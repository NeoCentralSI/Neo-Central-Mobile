part of 'defence_models.dart';

class DefenceChecklistBase {
  final bool met;
  final String label;

  const DefenceChecklistBase({required this.met, required this.label});

  static DefenceChecklistBase parse(dynamic value, String context) {
    final json = requireJsonMap(value, context: context);
    return DefenceChecklistBase(
      met: json.requireBool('met', context: context),
      label: json.requireString('label', context: context),
    );
  }
}

class DefenceSeminarChecklist {
  final bool met;
  final String label;
  final DefenceStatus? seminarStatus;

  const DefenceSeminarChecklist({
    required this.met,
    required this.label,
    required this.seminarStatus,
  });

  factory DefenceSeminarChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.checklist.seminar');
    return DefenceSeminarChecklist(
      met: json.requireBool('met', context: 'defence.checklist.seminar'),
      label: json.requireString('label', context: 'defence.checklist.seminar'),
      seminarStatus: json['seminarStatus'] == null
          ? null
          : DefenceStatus.fromJson(json['seminarStatus']),
    );
  }
}

class DefenceSksChecklist {
  final bool met;
  final String label;
  final int current;
  final int required;

  const DefenceSksChecklist({
    required this.met,
    required this.label,
    required this.current,
    required this.required,
  });

  factory DefenceSksChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.checklist.sks');
    return DefenceSksChecklist(
      met: json.requireBool('met', context: 'defence.checklist.sks'),
      label: json.requireString('label', context: 'defence.checklist.sks'),
      current: json.requireInt('current', context: 'defence.checklist.sks'),
      required: json.requireInt('required', context: 'defence.checklist.sks'),
    );
  }
}

class DefenceSeminarRevisionChecklist {
  final bool met;
  final String label;
  final DefenceStatus? seminarStatus;
  final int total;
  final int finished;
  final bool isVisible;

  const DefenceSeminarRevisionChecklist({
    required this.met,
    required this.label,
    required this.seminarStatus,
    required this.total,
    required this.finished,
    required this.isVisible,
  });

  factory DefenceSeminarRevisionChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.checklist.revision');
    return DefenceSeminarRevisionChecklist(
      met: json.requireBool('met', context: 'defence.checklist.revision'),
      label: json.requireString('label', context: 'defence.checklist.revision'),
      seminarStatus: json['seminarStatus'] == null
          ? null
          : DefenceStatus.fromJson(json['seminarStatus']),
      total: json.requireInt('total', context: 'defence.checklist.revision'),
      finished: json.requireInt(
        'finished',
        context: 'defence.checklist.revision',
      ),
      isVisible: json.optionalBool('isVisible'),
    );
  }
}

class DefenceSupervisorReadiness {
  final String name;
  final String role;
  final bool ready;

  const DefenceSupervisorReadiness({
    required this.name,
    required this.role,
    required this.ready,
  });

  factory DefenceSupervisorReadiness.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.supervisorReadiness');
    return DefenceSupervisorReadiness(
      name: json.requireString('name', context: 'defence.supervisorReadiness'),
      role: json.requireString('role', context: 'defence.supervisorReadiness'),
      ready: json.requireBool('ready', context: 'defence.supervisorReadiness'),
    );
  }
}

class DefenceSupervisorChecklist {
  final bool met;
  final String label;
  final List<DefenceSupervisorReadiness> supervisors;

  const DefenceSupervisorChecklist({
    required this.met,
    required this.label,
    required this.supervisors,
  });

  factory DefenceSupervisorChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.checklist.supervisor');
    return DefenceSupervisorChecklist(
      met: json.requireBool('met', context: 'defence.checklist.supervisor'),
      label: json.requireString(
        'label',
        context: 'defence.checklist.supervisor',
      ),
      supervisors: json
          .requireList('supervisors', context: 'defence.checklist.supervisor')
          .map(DefenceSupervisorReadiness.fromJson)
          .toList(growable: false),
    );
  }
}

class DefenceChecklist {
  final DefenceSeminarChecklist seminar;
  final DefenceSksChecklist sks;
  final DefenceSeminarRevisionChecklist seminarRevision;
  final DefenceSupervisorChecklist supervisors;

  const DefenceChecklist({
    required this.seminar,
    required this.sks,
    required this.seminarRevision,
    required this.supervisors,
  });

  factory DefenceChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.checklist');
    return DefenceChecklist(
      seminar: DefenceSeminarChecklist.fromJson(json['lulusSeminar']),
      sks: DefenceSksChecklist.fromJson(json['sks']),
      seminarRevision: DefenceSeminarRevisionChecklist.fromJson(
        json['revisiSeminar'],
      ),
      supervisors: DefenceSupervisorChecklist.fromJson(json['pembimbing']),
    );
  }
}

class DefenceInfo {
  final String id;
  final DefenceStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? meetingLink;
  final num? finalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;
  final String? cancelledReason;
  final DateTime? scheduledAt;
  final String? invitationLetterNo;
  final RoomSummary? room;
  final List<DefenceDocument> documents;
  final List<DefenceExaminer> examiners;

  const DefenceInfo({
    required this.id,
    required this.status,
    required this.registeredAt,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.meetingLink,
    required this.finalScore,
    required this.grade,
    required this.resultFinalizedAt,
    required this.cancelledReason,
    required this.scheduledAt,
    required this.invitationLetterNo,
    required this.room,
    required this.documents,
    required this.examiners,
  });

  factory DefenceInfo.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.info');
    return DefenceInfo(
      id: json.requireString('id', context: 'defence.info'),
      status: DefenceStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      meetingLink: json.optionalString('meetingLink'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      cancelledReason: json.optionalString('cancelledReason'),
      scheduledAt: json.optionalDateTime('scheduledAt'),
      invitationLetterNo: json.optionalString('invitationLetterNo'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      documents: json
          .optionalList('documents')
          .map(DefenceDocument.fromJson)
          .toList(growable: false),
      examiners: json
          .optionalList('examiners')
          .map(DefenceExaminer.fromJson)
          .toList(growable: false),
    );
  }
}

class StudentDefenceOverview {
  final String? thesisId;
  final String? thesisTitle;
  final DefenceChecklist checklist;
  final bool allChecklistMet;
  final List<DefenceMilestone> milestones;
  final bool canUpload;
  final List<AcademicRequirement> requirements;
  final DefenceRequirementConfiguration requirementConfiguration;
  final DefenceUploadConfig uploadConfig;
  final DefenceInfo? defence;

  const StudentDefenceOverview({
    required this.thesisId,
    required this.thesisTitle,
    required this.checklist,
    required this.allChecklistMet,
    required this.milestones,
    required this.canUpload,
    required this.requirements,
    required this.requirementConfiguration,
    required this.uploadConfig,
    required this.defence,
  });

  factory StudentDefenceOverview.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentDefenceOverview');
    return StudentDefenceOverview(
      thesisId: json.optionalString('thesisId'),
      thesisTitle: json.optionalString('thesisTitle'),
      checklist: DefenceChecklist.fromJson(json['checklist']),
      allChecklistMet: json.requireBool(
        'allChecklistMet',
        context: 'studentDefenceOverview',
      ),
      milestones: json
          .requireList('milestones', context: 'studentDefenceOverview')
          .map(DefenceMilestone.fromJson)
          .toList(growable: false),
      canUpload: json.requireBool(
        'canUpload',
        context: 'studentDefenceOverview',
      ),
      requirements: json
          .requireList('requirements', context: 'studentDefenceOverview')
          .map(AcademicRequirement.fromJson)
          .toList(growable: false),
      requirementConfiguration: DefenceRequirementConfiguration.fromJson(
        json['requirementConfiguration'],
      ),
      uploadConfig: DefenceUploadConfig.fromJson(json['uploadConfig']),
      defence: json['defence'] == null
          ? null
          : DefenceInfo.fromJson(json['defence']),
    );
  }
}

class DefenceHistoryItem {
  final String id;
  final DefenceStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final num? finalScore;
  final String? grade;
  final String? cancelledReason;
  final RoomSummary? room;
  final List<DefenceExaminer> examiners;

  const DefenceHistoryItem({
    required this.id,
    required this.status,
    required this.registeredAt,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.finalScore,
    required this.grade,
    required this.cancelledReason,
    required this.room,
    required this.examiners,
  });

  factory DefenceHistoryItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.history');
    return DefenceHistoryItem(
      id: json.requireString('id', context: 'defence.history'),
      status: DefenceStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      cancelledReason: json.optionalString('cancelledReason'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      examiners: json
          .optionalList('examiners')
          .map(DefenceExaminer.fromJson)
          .toList(growable: false),
    );
  }
}
