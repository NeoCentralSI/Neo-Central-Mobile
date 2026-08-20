part of 'seminar_models.dart';

class LecturerSeminarListItem {
  final String id;
  final String? thesisId;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final List<SeminarSupervisor> supervisors;
  final SeminarStatus status;
  final DateTime? registeredAt;
  final String? date;
  final String? startTime;
  final String? endTime;
  final RoomSummary? room;
  final String? myRole;
  final ExaminerAvailabilityStatus? myExaminerStatus;
  final String? myExaminerId;
  final int? myExaminerOrder;
  final List<ExaminerAssignment> examiners;

  const LecturerSeminarListItem({
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

  static LecturerSeminarListItem parse(dynamic value) {
    final json = requireJsonMap(value, context: 'lecturerSeminar');
    return LecturerSeminarListItem(
      id: json.requireString('id', context: 'lecturerSeminar'),
      thesisId: json.optionalString('thesisId'),
      studentName: json.requireString(
        'studentName',
        context: 'lecturerSeminar',
      ),
      studentNim: json.requireString('studentNim', context: 'lecturerSeminar'),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'lecturerSeminar',
      ),
      supervisors: json
          .requireList('supervisors', context: 'lecturerSeminar')
          .map(SeminarSupervisor.fromJson)
          .toList(growable: false),
      status: SeminarStatus.fromJson(json['status']),
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
          .map(ExaminerAssignment.fromJson)
          .toList(growable: false),
    );
  }
}

class SeminarDocument {
  final String requirementId;
  final String? requirementName;
  final DocumentStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? notes;
  final String? verifiedBy;
  final String? fileName;
  final String? filePath;

  const SeminarDocument({
    required this.requirementId,
    required this.requirementName,
    required this.status,
    required this.submittedAt,
    required this.verifiedAt,
    required this.notes,
    required this.verifiedBy,
    required this.fileName,
    required this.filePath,
  });

  factory SeminarDocument.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar.document');
    return SeminarDocument(
      requirementId:
          json.optionalString('requirementId') ??
          json.requireString('documentTypeId', context: 'seminar.document'),
      requirementName:
          json.optionalString('requirementName') ??
          json.optionalString('documentTypeName'),
      status: DocumentStatus.fromJson(json['status']),
      submittedAt: json.optionalDateTime('submittedAt'),
      verifiedAt: json.optionalDateTime('verifiedAt'),
      notes: json.optionalString('notes'),
      verifiedBy: json.optionalString('verifiedBy'),
      fileName: json.optionalString('fileName'),
      filePath: json.optionalString('filePath'),
    );
  }
}

class SeminarAudience {
  final String? studentId;
  final String studentName;
  final String nim;
  final DateTime? registeredAt;
  final DateTime? approvedAt;
  final String? approvedByName;

  const SeminarAudience({
    required this.studentId,
    required this.studentName,
    required this.nim,
    required this.registeredAt,
    required this.approvedAt,
    required this.approvedByName,
  });

  bool get isPresent => approvedAt != null;

  factory SeminarAudience.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar.audience');
    final name = json['studentName'] ?? json['fullName'];
    if (name is! String) {
      throw const ApiContractException(
        'seminar.audience tidak memiliki nama mahasiswa.',
      );
    }
    return SeminarAudience(
      studentId: json.optionalString('studentId'),
      studentName: name,
      nim: json.requireString('nim', context: 'seminar.audience'),
      registeredAt: json.optionalDateTime('registeredAt'),
      approvedAt: json.optionalDateTime('approvedAt'),
      approvedByName: json.optionalString('approvedByName'),
    );
  }
}

class SeminarThesis {
  final String id;
  final String title;

  const SeminarThesis({required this.id, required this.title});

  factory SeminarThesis.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar.thesis');
    return SeminarThesis(
      id: json.requireString('id', context: 'seminar.thesis'),
      title: json.requireString('title', context: 'seminar.thesis'),
    );
  }
}

class SeminarExaminer {
  final String id;
  final String? lecturerId;
  final String lecturerName;
  final int order;
  final ExaminerAvailabilityStatus? availabilityStatus;
  final num? assessmentScore;
  final DateTime? assessmentSubmittedAt;
  final String? revisionNotes;

  const SeminarExaminer({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.order,
    required this.availabilityStatus,
    required this.assessmentScore,
    required this.assessmentSubmittedAt,
    required this.revisionNotes,
  });

  bool get hasSubmittedAssessment => assessmentSubmittedAt != null;

  factory SeminarExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar.examiner');
    return SeminarExaminer(
      id: json.requireString('id', context: 'seminar.examiner'),
      lecturerId: json.optionalString('lecturerId'),
      lecturerName:
          json.optionalString('lecturerName') ??
          'Dosen penguji tidak diketahui',
      order: json.requireInt('order', context: 'seminar.examiner'),
      availabilityStatus: json['availabilityStatus'] == null
          ? null
          : ExaminerAvailabilityStatus.fromJson(json['availabilityStatus']),
      assessmentScore: json.optionalNum('assessmentScore'),
      assessmentSubmittedAt: json.optionalDateTime('assessmentSubmittedAt'),
      revisionNotes: json.optionalString('revisionNotes'),
    );
  }
}

class SeminarDetail {
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
  final SeminarThesis thesis;
  final StudentSummary student;
  final List<SeminarSupervisor> supervisors;
  final List<SeminarDocument> documents;
  final List<AcademicRequirement> documentTypes;
  final List<SeminarExaminer> examiners;
  final List<SeminarAudience> audiences;
  final List<RevisionItem> revisions;

  const SeminarDetail({
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
    required this.thesis,
    required this.student,
    required this.supervisors,
    required this.documents,
    required this.documentTypes,
    required this.examiners,
    required this.audiences,
    required this.revisions,
  });

  factory SeminarDetail.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminarDetail');
    final thesisJson = requireJsonMap(
      json['thesis'],
      context: 'seminar.thesis',
    );
    final supervisorValues = json.optionalList('supervisors').isNotEmpty
        ? json.optionalList('supervisors')
        : thesisJson.optionalList('supervisors');
    return SeminarDetail(
      id: json.requireString('id', context: 'seminarDetail'),
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
      thesis: SeminarThesis.fromJson(thesisJson),
      student: StudentSummary.fromJson(json['student']),
      supervisors: supervisorValues
          .map(SeminarSupervisor.fromJson)
          .toList(growable: false),
      documents: json
          .optionalList('documents')
          .map(SeminarDocument.fromJson)
          .toList(growable: false),
      documentTypes: json
          .optionalList('documentTypes')
          .map((item) {
            final requirement = requireJsonMap(
              item,
              context: 'seminar.documentType',
            );
            return AcademicRequirement(
              id: requirement.requireString(
                'id',
                context: 'seminar.documentType',
              ),
              name: requirement.requireString(
                'name',
                context: 'seminar.documentType',
              ),
              description: null,
              displayOrder: 0,
              document: null,
            );
          })
          .toList(growable: false),
      examiners: json
          .optionalList('examiners')
          .map(SeminarExaminer.fromJson)
          .toList(growable: false),
      audiences: json
          .optionalList('audiences')
          .map(SeminarAudience.fromJson)
          .toList(growable: false),
      revisions: json
          .optionalList('revisions')
          .map(RevisionItem.fromJson)
          .toList(growable: false),
    );
  }
}
