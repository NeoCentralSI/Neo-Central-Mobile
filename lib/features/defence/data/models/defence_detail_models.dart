part of 'defence_models.dart';

class LecturerDefenceListItem {
  final String id;
  final String? thesisId;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final List<DefenceSupervisor> supervisors;
  final DefenceStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final RoomSummary? room;
  final String? myRole;
  final ExaminerAvailabilityStatus? myExaminerStatus;
  final String? myExaminerId;
  final int? myExaminerOrder;
  final List<DefenceExaminer> examiners;

  const LecturerDefenceListItem({
    required this.id,
    required this.thesisId,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    required this.supervisors,
    required this.status,
    required this.registeredAt,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.myRole,
    required this.myExaminerStatus,
    required this.myExaminerId,
    required this.myExaminerOrder,
    required this.examiners,
  });

  factory LecturerDefenceListItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'lecturerDefence');
    return LecturerDefenceListItem(
      id: json.requireString('id', context: 'lecturerDefence'),
      thesisId: json.optionalString('thesisId'),
      studentName: json.requireString(
        'studentName',
        context: 'lecturerDefence',
      ),
      studentNim: json.requireString('studentNim', context: 'lecturerDefence'),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'lecturerDefence',
      ),
      supervisors: json
          .requireList('supervisors', context: 'lecturerDefence')
          .map(DefenceSupervisor.fromJson)
          .toList(growable: false),
      status: DefenceStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      myRole: json.optionalString('myRole'),
      myExaminerStatus: json['myExaminerStatus'] == null
          ? null
          : ExaminerAvailabilityStatus.fromJson(json['myExaminerStatus']),
      myExaminerId: json.optionalString('myExaminerId'),
      myExaminerOrder: json.optionalInt('myExaminerOrder'),
      examiners: json
          .optionalList('examiners')
          .map(DefenceExaminer.fromJson)
          .toList(growable: false),
    );
  }
}

class DefenceThesis {
  final String id;
  final String title;

  const DefenceThesis({required this.id, required this.title});

  factory DefenceThesis.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.thesis');
    return DefenceThesis(
      id: json.requireString('id', context: 'defence.thesis'),
      title: json.requireString('title', context: 'defence.thesis'),
    );
  }
}

class DefenceDetail {
  final String id;
  final DefenceStatus status;
  final DateTime? registeredAt;
  final bool isArchive;
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
  final DefenceThesis thesis;
  final StudentSummary student;
  final List<DefenceSupervisor> supervisors;
  final List<DefenceDocument> documents;
  final List<AcademicRequirement> documentTypes;
  final List<DefenceExaminer> examiners;
  final List<DefenceExaminer> rejectedExaminers;
  final DefenceAssessorRole viewerRole;
  final String? mySupervisorRole;
  final String? myExaminerId;
  final int? myExaminerOrder;
  final ExaminerAvailabilityStatus? myExaminerAvailabilityStatus;
  final DateTime? myAssessmentSubmittedAt;
  final bool canOpenExaminerAssessment;
  final bool canOpenSupervisorAssessment;
  final bool canOpenSupervisorFinalization;
  final bool allExaminerSubmitted;
  final bool supervisorAssessmentSubmitted;

  const DefenceDetail({
    required this.id,
    required this.status,
    required this.registeredAt,
    required this.isArchive,
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
    required this.thesis,
    required this.student,
    required this.supervisors,
    required this.documents,
    required this.documentTypes,
    required this.examiners,
    required this.rejectedExaminers,
    required this.viewerRole,
    required this.mySupervisorRole,
    required this.myExaminerId,
    required this.myExaminerOrder,
    required this.myExaminerAvailabilityStatus,
    required this.myAssessmentSubmittedAt,
    required this.canOpenExaminerAssessment,
    required this.canOpenSupervisorAssessment,
    required this.canOpenSupervisorFinalization,
    required this.allExaminerSubmitted,
    required this.supervisorAssessmentSubmitted,
  });

  factory DefenceDetail.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defenceDetail');
    return DefenceDetail(
      id: json.requireString('id', context: 'defenceDetail'),
      status: DefenceStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
      isArchive: json.optionalBool('isArchive'),
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
      thesis: DefenceThesis.fromJson(json['thesis']),
      student: StudentSummary.fromJson(json['student']),
      supervisors: json
          .optionalList('supervisors')
          .map(DefenceSupervisor.fromJson)
          .toList(growable: false),
      documents: json
          .optionalList('documents')
          .map(DefenceDocument.fromJson)
          .toList(growable: false),
      documentTypes: json
          .optionalList('documentTypes')
          .map((item) {
            final requirement = requireJsonMap(
              item,
              context: 'defence.documentType',
            );
            return AcademicRequirement(
              id: requirement.requireString(
                'id',
                context: 'defence.documentType',
              ),
              name: requirement.requireString(
                'name',
                context: 'defence.documentType',
              ),
              description: requirement.optionalString('description'),
              displayOrder: requirement.optionalInt('displayOrder') ?? 0,
              document: null,
            );
          })
          .toList(growable: false),
      examiners: json
          .optionalList('examiners')
          .map(DefenceExaminer.fromJson)
          .toList(growable: false),
      rejectedExaminers: json
          .optionalList('rejectedExaminers')
          .map(DefenceExaminer.fromJson)
          .toList(growable: false),
      viewerRole: switch (json.optionalString('viewerRole')) {
        null || 'none' => DefenceAssessorRole.viewer,
        final role => DefenceAssessorRole.fromJson(role),
      },
      mySupervisorRole: json.optionalString('mySupervisorRole'),
      myExaminerId: json.optionalString('myExaminerId'),
      myExaminerOrder: json.optionalInt('myExaminerOrder'),
      myExaminerAvailabilityStatus: json['myExaminerAvailabilityStatus'] == null
          ? null
          : ExaminerAvailabilityStatus.fromJson(
              json['myExaminerAvailabilityStatus'],
            ),
      myAssessmentSubmittedAt: json.optionalDateTime('myAssessmentSubmittedAt'),
      canOpenExaminerAssessment: json.optionalBool('canOpenExaminerAssessment'),
      canOpenSupervisorAssessment: json.optionalBool(
        'canOpenSupervisorAssessment',
      ),
      canOpenSupervisorFinalization: json.optionalBool(
        'canOpenSupervisorFinalization',
      ),
      allExaminerSubmitted: json.optionalBool('allExaminerSubmitted'),
      supervisorAssessmentSubmitted: json.optionalBool(
        'supervisorAssessmentSubmitted',
      ),
    );
  }
}

class DefenceAssignmentResponseResult {
  final String examinerId;
  final ExaminerAvailabilityStatus availabilityStatus;
  final bool defenceTransitioned;

  const DefenceAssignmentResponseResult({
    required this.examinerId,
    required this.availabilityStatus,
    required this.defenceTransitioned,
  });

  factory DefenceAssignmentResponseResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.assignmentResponse');
    return DefenceAssignmentResponseResult(
      examinerId: json.requireString(
        'examinerId',
        context: 'defence.assignmentResponse',
      ),
      availabilityStatus: ExaminerAvailabilityStatus.fromJson(
        json['availabilityStatus'],
      ),
      defenceTransitioned: json.requireBool(
        'defenceTransitioned',
        context: 'defence.assignmentResponse',
      ),
    );
  }
}

class DefenceRevisionBoard {
  final String? defenceId;
  final int total;
  final int finished;
  final int pendingApproval;
  final bool isFinalized;
  final List<RevisionItem> revisions;

  const DefenceRevisionBoard({
    required this.defenceId,
    required this.total,
    required this.finished,
    required this.pendingApproval,
    required this.isFinalized,
    required this.revisions,
  });

  factory DefenceRevisionBoard.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.revisionBoard');
    final common = RevisionBoard.fromJson(json);
    return DefenceRevisionBoard(
      defenceId: json.optionalString('defenceId'),
      total: common.total,
      finished: common.finished,
      pendingApproval: common.pendingApproval,
      isFinalized: json.optionalBool('isFinalized'),
      revisions: common.revisions,
    );
  }
}
