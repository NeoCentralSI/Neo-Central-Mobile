part of 'seminar_models.dart';

class SupervisorReadiness {
  final String name;
  final String role;
  final bool ready;

  const SupervisorReadiness({
    required this.name,
    required this.role,
    required this.ready,
  });

  factory SupervisorReadiness.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'checklist.supervisor');
    return SupervisorReadiness(
      name: json.requireString('name', context: 'checklist.supervisor'),
      role: json.requireString('role', context: 'checklist.supervisor'),
      ready: json.requireBool('ready', context: 'checklist.supervisor'),
    );
  }
}

class SeminarChecklistItem {
  final bool met;
  final String label;
  final int? current;
  final int? required;
  final List<SupervisorReadiness> supervisors;

  const SeminarChecklistItem({
    required this.met,
    required this.label,
    this.current,
    this.required,
    this.supervisors = const [],
  });

  factory SeminarChecklistItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'checklist.item');
    return SeminarChecklistItem(
      met: json.requireBool('met', context: 'checklist.item'),
      label: json.requireString('label', context: 'checklist.item'),
      current: json.optionalInt('current'),
      required: json.optionalInt('required'),
      supervisors: json
          .optionalList('supervisors')
          .map(SupervisorReadiness.fromJson)
          .toList(growable: false),
    );
  }
}

class SeminarChecklist {
  final SeminarChecklistItem guidance;
  final SeminarChecklistItem attendance;
  final SeminarChecklistItem researchMethod;
  final SeminarChecklistItem supervisors;

  const SeminarChecklist({
    required this.guidance,
    required this.attendance,
    required this.researchMethod,
    required this.supervisors,
  });

  factory SeminarChecklist.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'checklist');
    return SeminarChecklist(
      guidance: SeminarChecklistItem.fromJson(json['bimbingan']),
      attendance: SeminarChecklistItem.fromJson(json['kehadiran']),
      researchMethod: SeminarChecklistItem.fromJson(json['metopen']),
      supervisors: SeminarChecklistItem.fromJson(json['pembimbing']),
    );
  }

  List<SeminarChecklistItem> get items => [
    guidance,
    attendance,
    researchMethod,
    supervisors,
  ];
}

class SeminarMilestone {
  final String id;
  final String label;
  final bool checked;

  const SeminarMilestone({
    required this.id,
    required this.label,
    required this.checked,
  });

  factory SeminarMilestone.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'milestone');
    return SeminarMilestone(
      id: json.requireString('id', context: 'milestone'),
      label: json.requireString('label', context: 'milestone'),
      checked: json.requireBool('checked', context: 'milestone'),
    );
  }
}

class RequirementConfiguration {
  final bool isConfigured;
  final String? message;

  const RequirementConfiguration({
    required this.isConfigured,
    required this.message,
  });

  factory RequirementConfiguration.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'requirementConfiguration');
    return RequirementConfiguration(
      isConfigured: json.requireBool(
        'isConfigured',
        context: 'requirementConfiguration',
      ),
      message: json.optionalString('message'),
    );
  }
}

class SeminarUploadConfig {
  final List<String> acceptedExtensions;
  final int maxFileSizeBytes;
  final num maxFileSizeMb;

  const SeminarUploadConfig({
    required this.acceptedExtensions,
    required this.maxFileSizeBytes,
    required this.maxFileSizeMb,
  });

  factory SeminarUploadConfig.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'uploadConfig');
    return SeminarUploadConfig(
      acceptedExtensions: json
          .requireList('accept', context: 'uploadConfig')
          .map((item) {
            if (item is! String) {
              throw const ApiContractException(
                'uploadConfig.accept harus berisi string.',
              );
            }
            return item;
          })
          .toList(growable: false),
      maxFileSizeBytes: json.requireInt(
        'maxFileSizeBytes',
        context: 'uploadConfig',
      ),
      maxFileSizeMb: json.requireNum('maxFileSizeMb', context: 'uploadConfig'),
    );
  }
}

class SeminarInfo {
  final String id;
  final SeminarStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? meetingLink;
  final num? finalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;
  final DateTime? revisionFinalizedAt;
  final String? cancelledReason;
  final DateTime? scheduledAt;
  final String? invitationLetterNo;
  final RoomSummary? room;
  final List<ExaminerAssignment> examiners;

  const SeminarInfo({
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
    required this.revisionFinalizedAt,
    required this.cancelledReason,
    required this.scheduledAt,
    required this.invitationLetterNo,
    required this.room,
    required this.examiners,
  });

  factory SeminarInfo.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar');
    return SeminarInfo(
      id: json.requireString('id', context: 'seminar'),
      status: SeminarStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      meetingLink: json.optionalString('meetingLink'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      revisionFinalizedAt: json.optionalDateTime('revisionFinalizedAt'),
      cancelledReason: json.optionalString('cancelledReason'),
      scheduledAt: json.optionalDateTime('scheduledAt'),
      invitationLetterNo: json.optionalString('invitationLetterNo'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      examiners: json
          .optionalList('examiners')
          .map(ExaminerAssignment.fromJson)
          .toList(growable: false),
    );
  }
}

class StudentSeminarOverview {
  final String? thesisId;
  final String? thesisTitle;
  final SeminarChecklist checklist;
  final bool allChecklistMet;
  final List<SeminarMilestone> milestones;
  final bool canUpload;
  final List<AcademicRequirement> requirements;
  final RequirementConfiguration requirementConfiguration;
  final SeminarUploadConfig uploadConfig;
  final SeminarInfo? seminar;

  const StudentSeminarOverview({
    required this.thesisId,
    required this.thesisTitle,
    required this.checklist,
    required this.allChecklistMet,
    required this.milestones,
    required this.canUpload,
    required this.requirements,
    required this.requirementConfiguration,
    required this.uploadConfig,
    required this.seminar,
  });

  factory StudentSeminarOverview.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentSeminarOverview');
    return StudentSeminarOverview(
      thesisId: json.optionalString('thesisId'),
      thesisTitle: json.optionalString('thesisTitle'),
      checklist: SeminarChecklist.fromJson(json['checklist']),
      allChecklistMet: json.requireBool(
        'allChecklistMet',
        context: 'studentSeminarOverview',
      ),
      milestones: json
          .requireList('milestones', context: 'studentSeminarOverview')
          .map(SeminarMilestone.fromJson)
          .toList(growable: false),
      canUpload: json.requireBool(
        'canUpload',
        context: 'studentSeminarOverview',
      ),
      requirements: json
          .requireList('requirements', context: 'studentSeminarOverview')
          .map(AcademicRequirement.fromJson)
          .toList(growable: false),
      requirementConfiguration: RequirementConfiguration.fromJson(
        json['requirementConfiguration'],
      ),
      uploadConfig: SeminarUploadConfig.fromJson(json['uploadConfig']),
      seminar: json['seminar'] == null
          ? null
          : SeminarInfo.fromJson(json['seminar']),
    );
  }
}

class AttendanceSummary {
  final int attended;
  final int total;
  final int required;
  final bool met;

  const AttendanceSummary({
    required this.attended,
    required this.total,
    required this.required,
    required this.met,
  });

  factory AttendanceSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'attendance.summary');
    return AttendanceSummary(
      attended: json.requireInt('attended', context: 'attendance.summary'),
      total: json.requireInt('total', context: 'attendance.summary'),
      required: json.requireInt('required', context: 'attendance.summary'),
      met: json.requireBool('met', context: 'attendance.summary'),
    );
  }
}

class AttendanceRecord {
  final String seminarId;
  final SeminarStatus? seminarStatus;
  final String? seminarEndTime;
  final DateTime? resultFinalizedAt;
  final String presenterName;
  final String? presenterNim;
  final String thesisTitle;
  final String? date;
  final bool isPresent;
  final DateTime? approvedAt;
  final String? approvedBy;

  const AttendanceRecord({
    required this.seminarId,
    required this.seminarStatus,
    required this.seminarEndTime,
    required this.resultFinalizedAt,
    required this.presenterName,
    required this.presenterNim,
    required this.thesisTitle,
    required this.date,
    required this.isPresent,
    required this.approvedAt,
    required this.approvedBy,
  });

  factory AttendanceRecord.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'attendance.record');
    return AttendanceRecord(
      seminarId: json.requireString('seminarId', context: 'attendance.record'),
      seminarStatus: json['seminarStatus'] == null
          ? null
          : SeminarStatus.fromJson(json['seminarStatus']),
      seminarEndTime: json.optionalString('seminarEndTime'),
      resultFinalizedAt: json.optionalDateTime('seminarResultFinalizedAt'),
      presenterName: json.requireString(
        'presenterName',
        context: 'attendance.record',
      ),
      presenterNim: json.optionalString('presenterNim'),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'attendance.record',
      ),
      date: json.optionalString('date'),
      isPresent: json.requireBool('isPresent', context: 'attendance.record'),
      approvedAt: json.optionalDateTime('approvedAt'),
      approvedBy: json.optionalString('approvedBy'),
    );
  }
}

class AttendanceHistory {
  final AttendanceSummary summary;
  final List<AttendanceRecord> records;

  const AttendanceHistory({required this.summary, required this.records});

  factory AttendanceHistory.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'attendanceHistory');
    return AttendanceHistory(
      summary: AttendanceSummary.fromJson(json['summary']),
      records: json
          .requireList('records', context: 'attendanceHistory')
          .map(AttendanceRecord.fromJson)
          .toList(growable: false),
    );
  }
}

class SeminarHistoryExaminer {
  final int order;
  final String lecturerName;
  final num? assessmentScore;

  const SeminarHistoryExaminer({
    required this.order,
    required this.lecturerName,
    required this.assessmentScore,
  });

  factory SeminarHistoryExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'history.examiner');
    return SeminarHistoryExaminer(
      order: json.requireInt('order', context: 'history.examiner'),
      lecturerName: json.requireString(
        'lecturerName',
        context: 'history.examiner',
      ),
      assessmentScore: json.optionalNum('assessmentScore'),
    );
  }
}

class SeminarHistoryItem {
  final String id;
  final SeminarStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? meetingLink;
  final num? finalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;
  final String? cancelledReason;
  final RoomSummary? room;
  final List<SeminarHistoryExaminer> examiners;

  const SeminarHistoryItem({
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
    required this.room,
    required this.examiners,
  });

  factory SeminarHistoryItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminarHistory');
    return SeminarHistoryItem(
      id: json.requireString('id', context: 'seminarHistory'),
      status: SeminarStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      meetingLink: json.optionalString('meetingLink'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      cancelledReason: json.optionalString('cancelledReason'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      examiners: json
          .requireList('examiners', context: 'seminarHistory')
          .map(SeminarHistoryExaminer.fromJson)
          .toList(growable: false),
    );
  }
}
