part of 'defence_models.dart';

class DefenceAssessmentSummary {
  final String id;
  final DefenceStatus status;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final String? date;
  final String? startTime;
  final String? endTime;
  final RoomSummary? room;

  const DefenceAssessmentSummary({
    required this.id,
    required this.status,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory DefenceAssessmentSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.defence');
    return DefenceAssessmentSummary(
      id: json.requireString('id', context: 'assessment.defence'),
      status: DefenceStatus.fromJson(json['status']),
      studentName: json.requireString(
        'studentName',
        context: 'assessment.defence',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'assessment.defence',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'assessment.defence',
      ),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
    );
  }
}

class DefenceExaminerAssessmentIdentity {
  final String id;
  final int order;
  final num? assessmentScore;
  final String? revisionNotes;
  final DateTime? submittedAt;

  const DefenceExaminerAssessmentIdentity({
    required this.id,
    required this.order,
    required this.assessmentScore,
    required this.revisionNotes,
    required this.submittedAt,
  });

  factory DefenceExaminerAssessmentIdentity.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.examiner');
    return DefenceExaminerAssessmentIdentity(
      id: json.requireString('id', context: 'assessment.examiner'),
      order: json.requireInt('order', context: 'assessment.examiner'),
      assessmentScore: json.optionalNum('assessmentScore'),
      revisionNotes: json.optionalString('revisionNotes'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
    );
  }
}

class DefenceSupervisorAssessmentIdentity {
  final String roleName;
  final num? assessmentScore;
  final String? supervisorNotes;
  final DateTime? submittedAt;

  const DefenceSupervisorAssessmentIdentity({
    required this.roleName,
    required this.assessmentScore,
    required this.supervisorNotes,
    required this.submittedAt,
  });

  factory DefenceSupervisorAssessmentIdentity.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.supervisor');
    return DefenceSupervisorAssessmentIdentity(
      roleName: json.requireString(
        'roleName',
        context: 'assessment.supervisor',
      ),
      assessmentScore: json.optionalNum('assessmentScore'),
      supervisorNotes: json.optionalString('supervisorNotes'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
    );
  }
}

class DefenceAssessmentForm {
  final DefenceAssessmentSummary defence;
  final DefenceAssessorRole assessorRole;
  final DefenceExaminerAssessmentIdentity? examiner;
  final DefenceSupervisorAssessmentIdentity? supervisor;
  final List<AssessmentGroup> criteriaGroups;
  final num minimumPassingScore;

  const DefenceAssessmentForm({
    required this.defence,
    required this.assessorRole,
    required this.examiner,
    required this.supervisor,
    required this.criteriaGroups,
    required this.minimumPassingScore,
  });

  bool get isSubmitted => switch (assessorRole) {
    DefenceAssessorRole.examiner => examiner?.submittedAt != null,
    DefenceAssessorRole.supervisor => supervisor?.submittedAt != null,
    DefenceAssessorRole.viewer => true,
  };

  factory DefenceAssessmentForm.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defenceAssessmentForm');
    return DefenceAssessmentForm(
      defence: DefenceAssessmentSummary.fromJson(json['defence']),
      assessorRole: DefenceAssessorRole.fromJson(json['assessorRole']),
      examiner: json['examiner'] == null
          ? null
          : DefenceExaminerAssessmentIdentity.fromJson(json['examiner']),
      supervisor: json['supervisor'] == null
          ? null
          : DefenceSupervisorAssessmentIdentity.fromJson(json['supervisor']),
      criteriaGroups: json
          .requireList('criteriaGroups', context: 'defenceAssessmentForm')
          .map(AssessmentGroup.fromJson)
          .toList(growable: false),
      minimumPassingScore: json.requireNum(
        'minimumPassingScore',
        context: 'defenceAssessmentForm',
      ),
    );
  }
}

class DefenceAssessmentSubmissionResult {
  final DefenceAssessorRole assessorRole;
  final String? examinerId;
  final String? defenceId;
  final num? assessmentScore;
  final DateTime? submittedAt;

  const DefenceAssessmentSubmissionResult({
    required this.assessorRole,
    required this.examinerId,
    required this.defenceId,
    required this.assessmentScore,
    required this.submittedAt,
  });

  factory DefenceAssessmentSubmissionResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defenceAssessmentSubmission');
    return DefenceAssessmentSubmissionResult(
      assessorRole: DefenceAssessorRole.fromJson(json['assessorRole']),
      examinerId: json.optionalString('examinerId'),
      defenceId: json.optionalString('defenceId'),
      assessmentScore: json.optionalNum('assessmentScore'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
    );
  }
}

class DefenceFinalizationSummary {
  final String id;
  final DefenceStatus status;
  final num? examinerAverageScore;
  final num? supervisorScore;
  final num? finalScore;
  final num? computedFinalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;
  final String? resultFinalizedBy;
  final DateTime? revisionFinalizedAt;
  final String? revisionFinalizedBy;
  final String studentName;
  final String studentNim;
  final String thesisTitle;

  const DefenceFinalizationSummary({
    required this.id,
    required this.status,
    required this.examinerAverageScore,
    required this.supervisorScore,
    required this.finalScore,
    required this.computedFinalScore,
    required this.grade,
    required this.resultFinalizedAt,
    required this.resultFinalizedBy,
    required this.revisionFinalizedAt,
    required this.revisionFinalizedBy,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
  });

  factory DefenceFinalizationSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization.defence');
    return DefenceFinalizationSummary(
      id: json.requireString('id', context: 'finalization.defence'),
      status: DefenceStatus.fromJson(json['status']),
      examinerAverageScore: json.optionalNum('examinerAverageScore'),
      supervisorScore: json.optionalNum('supervisorScore'),
      finalScore: json.optionalNum('finalScore'),
      computedFinalScore: json.optionalNum('computedFinalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      resultFinalizedBy: json.optionalString('resultFinalizedBy'),
      revisionFinalizedAt: json.optionalDateTime('revisionFinalizedAt'),
      revisionFinalizedBy: json.optionalString('revisionFinalizedBy'),
      studentName: json.requireString(
        'studentName',
        context: 'finalization.defence',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'finalization.defence',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'finalization.defence',
      ),
    );
  }
}

class DefenceFinalizationSupervisor {
  final String roleName;
  final String name;
  final bool canFinalize;

  const DefenceFinalizationSupervisor({
    required this.roleName,
    required this.name,
    required this.canFinalize,
  });

  factory DefenceFinalizationSupervisor.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization.supervisor');
    return DefenceFinalizationSupervisor(
      roleName: json.requireString(
        'roleName',
        context: 'finalization.supervisor',
      ),
      name: json.requireString('name', context: 'finalization.supervisor'),
      canFinalize: json.requireBool(
        'canFinalize',
        context: 'finalization.supervisor',
      ),
    );
  }
}

class DefenceFinalizationExaminer {
  final String id;
  final String lecturerId;
  final String lecturerName;
  final int order;
  final num? assessmentScore;
  final String? revisionNotes;
  final DateTime? submittedAt;
  final bool isDraft;
  final List<AssessmentGroup> assessmentDetails;

  const DefenceFinalizationExaminer({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.order,
    required this.assessmentScore,
    required this.revisionNotes,
    required this.submittedAt,
    required this.isDraft,
    required this.assessmentDetails,
  });

  factory DefenceFinalizationExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization.examiner');
    return DefenceFinalizationExaminer(
      id: json.requireString('id', context: 'finalization.examiner'),
      lecturerId: json.requireString(
        'lecturerId',
        context: 'finalization.examiner',
      ),
      lecturerName: json.requireString(
        'lecturerName',
        context: 'finalization.examiner',
      ),
      order: json.requireInt('order', context: 'finalization.examiner'),
      assessmentScore: json.optionalNum('assessmentScore'),
      revisionNotes: json.optionalString('revisionNotes'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
      isDraft: json.optionalBool('isDraft'),
      assessmentDetails: json
          .optionalList('assessmentDetails')
          .map(AssessmentGroup.fromJson)
          .toList(growable: false),
    );
  }
}

class DefenceSupervisorAssessment {
  final String? name;
  final num? assessmentScore;
  final String? supervisorNotes;
  final DateTime? submittedAt;
  final List<AssessmentGroup> assessmentDetails;

  const DefenceSupervisorAssessment({
    required this.name,
    required this.assessmentScore,
    required this.supervisorNotes,
    required this.submittedAt,
    required this.assessmentDetails,
  });

  factory DefenceSupervisorAssessment.fromJson(dynamic value) {
    final json = requireJsonMap(
      value,
      context: 'finalization.supervisorAssessment',
    );
    return DefenceSupervisorAssessment(
      name: json.optionalString('name'),
      assessmentScore: json.optionalNum('assessmentScore'),
      supervisorNotes: json.optionalString('supervisorNotes'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
      assessmentDetails: json
          .optionalList('assessmentDetails')
          .map(AssessmentGroup.fromJson)
          .toList(growable: false),
    );
  }
}

class DefenceFinalizationData {
  final DefenceFinalizationSummary defence;
  final DefenceFinalizationSupervisor supervisor;
  final List<DefenceFinalizationExaminer> examiners;
  final DefenceSupervisorAssessment supervisorAssessment;
  final bool allExaminerSubmitted;
  final bool supervisorAssessmentSubmitted;
  final bool recommendationUnlocked;
  final num minimumPassingScore;

  const DefenceFinalizationData({
    required this.defence,
    required this.supervisor,
    required this.examiners,
    required this.supervisorAssessment,
    required this.allExaminerSubmitted,
    required this.supervisorAssessmentSubmitted,
    required this.recommendationUnlocked,
    required this.minimumPassingScore,
  });

  factory DefenceFinalizationData.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defenceFinalization');
    return DefenceFinalizationData(
      defence: DefenceFinalizationSummary.fromJson(json['defence']),
      supervisor: DefenceFinalizationSupervisor.fromJson(json['supervisor']),
      examiners: json
          .requireList('examiners', context: 'defenceFinalization')
          .map(DefenceFinalizationExaminer.fromJson)
          .toList(growable: false),
      supervisorAssessment: DefenceSupervisorAssessment.fromJson(
        json['supervisorAssessment'],
      ),
      allExaminerSubmitted: json.requireBool(
        'allExaminerSubmitted',
        context: 'defenceFinalization',
      ),
      supervisorAssessmentSubmitted: json.requireBool(
        'supervisorAssessmentSubmitted',
        context: 'defenceFinalization',
      ),
      recommendationUnlocked: json.requireBool(
        'recommendationUnlocked',
        context: 'defenceFinalization',
      ),
      minimumPassingScore: json.requireNum(
        'minimumPassingScore',
        context: 'defenceFinalization',
      ),
    );
  }
}

class DefenceFinalizationResult {
  final String defenceId;
  final DefenceStatus status;
  final num? examinerAverageScore;
  final num? supervisorScore;
  final num? finalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;

  const DefenceFinalizationResult({
    required this.defenceId,
    required this.status,
    required this.examinerAverageScore,
    required this.supervisorScore,
    required this.finalScore,
    required this.grade,
    required this.resultFinalizedAt,
  });

  factory DefenceFinalizationResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defenceFinalizationResult');
    return DefenceFinalizationResult(
      defenceId: json.requireString(
        'defenceId',
        context: 'defenceFinalizationResult',
      ),
      status: DefenceStatus.fromJson(json['status']),
      examinerAverageScore: json.optionalNum('examinerAverageScore'),
      supervisorScore: json.optionalNum('supervisorScore'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
    );
  }
}

class StudentDefenceAssessmentSummary {
  final String id;
  final DefenceStatus status;
  final num? examinerAverageScore;
  final num? supervisorScore;
  final num? finalScore;
  final String? grade;
  final DateTime? resultFinalizedAt;
  final RoomSummary? room;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? meetingLink;

  const StudentDefenceAssessmentSummary({
    required this.id,
    required this.status,
    required this.examinerAverageScore,
    required this.supervisorScore,
    required this.finalScore,
    required this.grade,
    required this.resultFinalizedAt,
    required this.room,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.meetingLink,
  });

  factory StudentDefenceAssessmentSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentAssessment.defence');
    return StudentDefenceAssessmentSummary(
      id: json.requireString('id', context: 'studentAssessment.defence'),
      status: DefenceStatus.fromJson(json['status']),
      examinerAverageScore: json.optionalNum('examinerAverageScore'),
      supervisorScore: json.optionalNum('supervisorScore'),
      finalScore: json.optionalNum('finalScore'),
      grade: json.optionalString('grade'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      meetingLink: json.optionalString('meetingLink'),
    );
  }
}

class StudentDefenceAssessment {
  final StudentDefenceAssessmentSummary defence;
  final List<DefenceFinalizationExaminer> examiners;
  final DefenceSupervisorAssessment supervisorAssessment;

  const StudentDefenceAssessment({
    required this.defence,
    required this.examiners,
    required this.supervisorAssessment,
  });

  factory StudentDefenceAssessment.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentDefenceAssessment');
    return StudentDefenceAssessment(
      defence: StudentDefenceAssessmentSummary.fromJson(json['defence']),
      examiners: json
          .requireList('examiners', context: 'studentDefenceAssessment')
          .map(DefenceFinalizationExaminer.fromJson)
          .toList(growable: false),
      supervisorAssessment: DefenceSupervisorAssessment.fromJson(
        json['supervisorAssessment'],
      ),
    );
  }
}
