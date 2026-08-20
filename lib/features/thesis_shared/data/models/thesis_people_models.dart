import '../../../../core/models/api_exception.dart';
import '../../../../core/utils/api_contract_parser.dart';

enum ExaminerAvailabilityStatus {
  pending,
  available,
  unavailable;

  static ExaminerAvailabilityStatus fromJson(dynamic value) {
    return switch (value) {
      'pending' => ExaminerAvailabilityStatus.pending,
      'available' => ExaminerAvailabilityStatus.available,
      'unavailable' => ExaminerAvailabilityStatus.unavailable,
      _ => throw ApiContractException(
        'Status ketersediaan penguji tidak dikenali: ${value ?? 'null'}.',
      ),
    };
  }
}

class RoomSummary {
  final String id;
  final String name;
  final String? location;
  final int? capacity;

  const RoomSummary({
    required this.id,
    required this.name,
    this.location,
    this.capacity,
  });

  factory RoomSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'room');
    return RoomSummary(
      id: json.requireString('id', context: 'room'),
      name: json.requireString('name', context: 'room'),
      location: json.optionalString('location'),
      capacity: json.optionalInt('capacity'),
    );
  }
}

class StudentSummary {
  final String? id;
  final String name;
  final String nim;

  const StudentSummary({
    required this.id,
    required this.name,
    required this.nim,
  });

  factory StudentSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'student');
    return StudentSummary(
      id: json.optionalString('id') ?? json.optionalString('studentId'),
      name: json.requireString('name', context: 'student'),
      nim: json.requireString('nim', context: 'student'),
    );
  }
}

class LecturerSummary {
  final String lecturerId;
  final String name;
  final String? role;

  const LecturerSummary({
    required this.lecturerId,
    required this.name,
    required this.role,
  });

  factory LecturerSummary.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'lecturer');
    final id = json['lecturerId'] ?? json['id'];
    final name = json['lecturerName'] ?? json['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      throw const ApiContractException(
        'Ringkasan dosen tidak memiliki ID atau nama yang valid.',
      );
    }
    return LecturerSummary(
      lecturerId: id,
      name: name,
      role: json.optionalString('role') ?? json.optionalString('roleName'),
    );
  }
}

class ExaminerAssignment {
  final String id;
  final String lecturerId;
  final String? lecturerName;
  final int order;
  final ExaminerAvailabilityStatus availabilityStatus;
  final String? unavailableReasons;
  final DateTime? respondedAt;
  final num? assessmentScore;
  final DateTime? assessmentSubmittedAt;
  final String? revisionNotes;

  const ExaminerAssignment({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.order,
    required this.availabilityStatus,
    required this.unavailableReasons,
    required this.respondedAt,
    required this.assessmentScore,
    required this.assessmentSubmittedAt,
    required this.revisionNotes,
  });

  bool get hasSubmittedAssessment => assessmentSubmittedAt != null;

  factory ExaminerAssignment.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'examiner');
    return ExaminerAssignment(
      id: json.requireString('id', context: 'examiner'),
      lecturerId: json.requireString('lecturerId', context: 'examiner'),
      lecturerName: json.optionalString('lecturerName'),
      order: json.requireInt('order', context: 'examiner'),
      availabilityStatus: ExaminerAvailabilityStatus.fromJson(
        json['availabilityStatus'],
      ),
      unavailableReasons: json.optionalString('unavailableReasons'),
      respondedAt: json.optionalDateTime('respondedAt'),
      assessmentScore: json.optionalNum('assessmentScore'),
      assessmentSubmittedAt: json.optionalDateTime('assessmentSubmittedAt'),
      revisionNotes: json.optionalString('revisionNotes'),
    );
  }
}
