import '../../../../core/models/api_exception.dart';
import '../../../../core/utils/api_contract_parser.dart';
import 'thesis_people_models.dart';

enum ExaminerAssignmentStatus {
  unassigned('unassigned'),
  rejected('rejected'),
  partiallyRejected('partially_rejected'),
  pending('pending'),
  confirmed('confirmed'),
  finished('finished');

  final String value;

  const ExaminerAssignmentStatus(this.value);

  static ExaminerAssignmentStatus fromJson(dynamic value) {
    return ExaminerAssignmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ApiContractException(
        'Status penetapan penguji tidak dikenali: ${value ?? 'null'}.',
      ),
    );
  }

  bool get isEditable => this != finished;
}

class ExaminerAssignmentResource {
  final String id;
  final String? thesisId;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final List<AssignmentSupervisor> supervisors;
  final String status;
  final DateTime? registeredAt;
  final ExaminerAssignmentStatus assignmentStatus;
  final List<ExaminerAssignment> examiners;
  final List<ExaminerAssignment> rejectedExaminers;

  const ExaminerAssignmentResource({
    required this.id,
    required this.thesisId,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    required this.supervisors,
    required this.status,
    required this.registeredAt,
    required this.assignmentStatus,
    required this.examiners,
    required this.rejectedExaminers,
  });

  factory ExaminerAssignmentResource.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'examinerAssignmentResource');
    return ExaminerAssignmentResource(
      id: json.requireString('id', context: 'examinerAssignmentResource'),
      thesisId: json.optionalString('thesisId'),
      studentName: json.requireString(
        'studentName',
        context: 'examinerAssignmentResource',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'examinerAssignmentResource',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'examinerAssignmentResource',
      ),
      supervisors: json
          .requireList('supervisors', context: 'examinerAssignmentResource')
          .map(AssignmentSupervisor.fromJson)
          .toList(growable: false),
      status: json.requireString(
        'status',
        context: 'examinerAssignmentResource',
      ),
      registeredAt: json.optionalDateTime('registeredAt'),
      assignmentStatus: ExaminerAssignmentStatus.fromJson(
        json['assignmentStatus'],
      ),
      examiners: json
          .requireList('examiners', context: 'examinerAssignmentResource')
          .map(ExaminerAssignment.fromJson)
          .toList(growable: false),
      rejectedExaminers: json
          .requireList(
            'rejectedExaminers',
            context: 'examinerAssignmentResource',
          )
          .map(ExaminerAssignment.fromJson)
          .toList(growable: false),
    );
  }
}

class AssignmentSupervisor {
  final String name;
  final String role;

  const AssignmentSupervisor({required this.name, required this.role});

  factory AssignmentSupervisor.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assignmentSupervisor');
    return AssignmentSupervisor(
      name: json.requireString('name', context: 'assignmentSupervisor'),
      role: json.requireString('role', context: 'assignmentSupervisor'),
    );
  }
}

class LecturerAvailabilityRange {
  final String day;
  final String dayLabel;
  final String startTime;
  final String endTime;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String label;

  const LecturerAvailabilityRange({
    required this.day,
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    required this.validFrom,
    required this.validUntil,
    required this.label,
  });

  factory LecturerAvailabilityRange.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'lecturerAvailabilityRange');
    return LecturerAvailabilityRange(
      day: json.requireString('day', context: 'lecturerAvailabilityRange'),
      dayLabel: json.requireString(
        'dayLabel',
        context: 'lecturerAvailabilityRange',
      ),
      startTime: json.requireString(
        'startTime',
        context: 'lecturerAvailabilityRange',
      ),
      endTime: json.requireString(
        'endTime',
        context: 'lecturerAvailabilityRange',
      ),
      validFrom: json.optionalDateTime('validFrom'),
      validUntil: json.optionalDateTime('validUntil'),
      label: json.requireString('label', context: 'lecturerAvailabilityRange'),
    );
  }
}

class LecturerUpcomingEvent {
  final String type;
  final String title;
  final String studentName;
  final DateTime date;
  final String startTime;
  final String endTime;

  const LecturerUpcomingEvent({
    required this.type,
    required this.title,
    required this.studentName,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory LecturerUpcomingEvent.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'lecturerUpcomingEvent');
    return LecturerUpcomingEvent(
      type: json.requireString('type', context: 'lecturerUpcomingEvent'),
      title: json.requireString('title', context: 'lecturerUpcomingEvent'),
      studentName: json.requireString(
        'studentName',
        context: 'lecturerUpcomingEvent',
      ),
      date: json.requireDateTime('date', context: 'lecturerUpcomingEvent'),
      startTime: json.requireString(
        'startTime',
        context: 'lecturerUpcomingEvent',
      ),
      endTime: json.requireString('endTime', context: 'lecturerUpcomingEvent'),
    );
  }
}

class EligibleExaminer {
  final String id;
  final String fullName;
  final String identityNumber;
  final String scienceGroup;
  final int upcomingCount;
  final List<LecturerAvailabilityRange> availabilityRanges;
  final List<LecturerUpcomingEvent> events;
  final bool isPreviousExaminer;
  final bool isSelectable;

  const EligibleExaminer({
    required this.id,
    required this.fullName,
    required this.identityNumber,
    required this.scienceGroup,
    required this.upcomingCount,
    required this.availabilityRanges,
    required this.events,
    required this.isPreviousExaminer,
    required this.isSelectable,
  });

  factory EligibleExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'eligibleExaminer');
    return EligibleExaminer(
      id: json.requireString('id', context: 'eligibleExaminer'),
      fullName: json.requireString('fullName', context: 'eligibleExaminer'),
      identityNumber: json.requireString(
        'identityNumber',
        context: 'eligibleExaminer',
      ),
      scienceGroup: json.requireString(
        'scienceGroup',
        context: 'eligibleExaminer',
      ),
      upcomingCount: json.requireInt(
        'upcomingCount',
        context: 'eligibleExaminer',
      ),
      availabilityRanges: json
          .requireList('availabilityRanges', context: 'eligibleExaminer')
          .map(LecturerAvailabilityRange.fromJson)
          .toList(growable: false),
      events: json
          .requireList('events', context: 'eligibleExaminer')
          .map(LecturerUpcomingEvent.fromJson)
          .toList(growable: false),
      isPreviousExaminer: json.requireBool(
        'isPreviousExaminer',
        context: 'eligibleExaminer',
      ),
      isSelectable: json.requireBool(
        'isSelectable',
        context: 'eligibleExaminer',
      ),
    );
  }
}
