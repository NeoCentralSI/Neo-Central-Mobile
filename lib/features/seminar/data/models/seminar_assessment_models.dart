part of 'seminar_models.dart';

class AssessmentSeminarSummary {
  final String id;
  final SeminarStatus status;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final String? date;
  final String? startTime;
  final String? endTime;
  final RoomSummary? room;

  const AssessmentSeminarSummary({
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

  factory AssessmentSeminarSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.seminar');
    return AssessmentSeminarSummary(
      id: json.requireString('id', context: 'assessment.seminar'),
      status: SeminarStatus.fromJson(json['status']),
      studentName: json.requireString(
        'studentName',
        context: 'assessment.seminar',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'assessment.seminar',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'assessment.seminar',
      ),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
    );
  }
}

class ExaminerAssessmentIdentity {
  final String id;
  final int order;
  final num? assessmentScore;
  final String? revisionNotes;
  final DateTime? submittedAt;

  const ExaminerAssessmentIdentity({
    required this.id,
    required this.order,
    required this.assessmentScore,
    required this.revisionNotes,
    required this.submittedAt,
  });

  factory ExaminerAssessmentIdentity.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.examiner');
    return ExaminerAssessmentIdentity(
      id: json.requireString('id', context: 'assessment.examiner'),
      order: json.requireInt('order', context: 'assessment.examiner'),
      assessmentScore: json.optionalNum('assessmentScore'),
      revisionNotes: json.optionalString('revisionNotes'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
    );
  }
}

class SeminarAssessmentForm {
  final AssessmentSeminarSummary seminar;
  final ExaminerAssessmentIdentity? examiner;
  final List<AssessmentGroup> criteriaGroups;
  final num minimumPassingScore;

  const SeminarAssessmentForm({
    required this.seminar,
    required this.examiner,
    required this.criteriaGroups,
    required this.minimumPassingScore,
  });

  bool get isLocked => examiner?.submittedAt != null;

  factory SeminarAssessmentForm.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessmentForm');
    return SeminarAssessmentForm(
      seminar: AssessmentSeminarSummary.fromJson(json['seminar']),
      examiner: json['examiner'] == null
          ? null
          : ExaminerAssessmentIdentity.fromJson(json['examiner']),
      criteriaGroups: json
          .requireList('criteriaGroups', context: 'assessmentForm')
          .map(AssessmentGroup.fromJson)
          .toList(growable: false),
      minimumPassingScore: json.requireNum(
        'minimumPassingScore',
        context: 'assessmentForm',
      ),
    );
  }
}

class FinalizationExaminer {
  final String id;
  final String lecturerId;
  final String lecturerName;
  final int order;
  final num? assessmentScore;
  final String? revisionNotes;
  final DateTime? submittedAt;
  final bool isDraft;
  final List<AssessmentGroup> assessmentDetails;

  const FinalizationExaminer({
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

  factory FinalizationExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization.examiner');
    return FinalizationExaminer(
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

class FinalizationSeminar {
  final String id;
  final SeminarStatus status;
  final num? finalScore;
  final DateTime? resultFinalizedAt;
  final DateTime? revisionFinalizedAt;
  final String studentName;
  final String studentNim;
  final String thesisTitle;

  const FinalizationSeminar({
    required this.id,
    required this.status,
    required this.finalScore,
    required this.resultFinalizedAt,
    required this.revisionFinalizedAt,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
  });

  factory FinalizationSeminar.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization.seminar');
    return FinalizationSeminar(
      id: json.requireString('id', context: 'finalization.seminar'),
      status: SeminarStatus.fromJson(json['status']),
      finalScore: json.optionalNum('finalScore'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      revisionFinalizedAt: json.optionalDateTime('revisionFinalizedAt'),
      studentName: json.requireString(
        'studentName',
        context: 'finalization.seminar',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'finalization.seminar',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'finalization.seminar',
      ),
    );
  }
}

class SeminarFinalizationData {
  final FinalizationSeminar seminar;
  final String supervisorRoleName;
  final bool canFinalize;
  final List<FinalizationExaminer> examiners;
  final bool allExaminerSubmitted;
  final num? averageScore;
  final bool recommendationUnlocked;
  final List<AssessmentGroup> criteriaGroups;
  final num minimumPassingScore;

  const SeminarFinalizationData({
    required this.seminar,
    required this.supervisorRoleName,
    required this.canFinalize,
    required this.examiners,
    required this.allExaminerSubmitted,
    required this.averageScore,
    required this.recommendationUnlocked,
    required this.criteriaGroups,
    required this.minimumPassingScore,
  });

  factory SeminarFinalizationData.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalization');
    final supervisor = json.requireMap('supervisor', context: 'finalization');
    return SeminarFinalizationData(
      seminar: FinalizationSeminar.fromJson(json['seminar']),
      supervisorRoleName: supervisor.requireString(
        'roleName',
        context: 'finalization.supervisor',
      ),
      canFinalize: supervisor.requireBool(
        'canFinalize',
        context: 'finalization.supervisor',
      ),
      examiners: json
          .requireList('examiners', context: 'finalization')
          .map(FinalizationExaminer.fromJson)
          .toList(growable: false),
      allExaminerSubmitted: json.requireBool(
        'allExaminerSubmitted',
        context: 'finalization',
      ),
      averageScore: json.optionalNum('averageScore'),
      recommendationUnlocked: json.requireBool(
        'recommendationUnlocked',
        context: 'finalization',
      ),
      criteriaGroups: json
          .requireList('criteriaGroups', context: 'finalization')
          .map(AssessmentGroup.fromJson)
          .toList(growable: false),
      minimumPassingScore: json.requireNum(
        'minimumPassingScore',
        context: 'finalization',
      ),
    );
  }
}

class AssignmentResponseResult {
  final String examinerId;
  final ExaminerAvailabilityStatus availabilityStatus;
  final bool seminarTransitioned;

  const AssignmentResponseResult({
    required this.examinerId,
    required this.availabilityStatus,
    required this.seminarTransitioned,
  });

  factory AssignmentResponseResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assignmentResponse');
    return AssignmentResponseResult(
      examinerId: json.requireString(
        'examinerId',
        context: 'assignmentResponse',
      ),
      availabilityStatus: ExaminerAvailabilityStatus.fromJson(
        json['availabilityStatus'],
      ),
      seminarTransitioned: json.requireBool(
        'seminarTransitioned',
        context: 'assignmentResponse',
      ),
    );
  }
}

class AssessmentSubmissionResult {
  final String examinerId;
  final num? assessmentScore;
  final DateTime? submittedAt;

  const AssessmentSubmissionResult({
    required this.examinerId,
    required this.assessmentScore,
    required this.submittedAt,
  });

  factory AssessmentSubmissionResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessmentSubmission');
    return AssessmentSubmissionResult(
      examinerId: json.requireString(
        'examinerId',
        context: 'assessmentSubmission',
      ),
      assessmentScore: json.optionalNum('assessmentScore'),
      submittedAt: json.optionalDateTime('assessmentSubmittedAt'),
    );
  }
}

class SeminarFinalizationResult {
  final String seminarId;
  final SeminarStatus status;
  final num? finalScore;
  final DateTime? resultFinalizedAt;

  const SeminarFinalizationResult({
    required this.seminarId,
    required this.status,
    required this.finalScore,
    required this.resultFinalizedAt,
  });

  factory SeminarFinalizationResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'finalizationResult');
    return SeminarFinalizationResult(
      seminarId: json.requireString('seminarId', context: 'finalizationResult'),
      status: SeminarStatus.fromJson(json['status']),
      finalScore: json.optionalNum('finalScore'),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
    );
  }
}
