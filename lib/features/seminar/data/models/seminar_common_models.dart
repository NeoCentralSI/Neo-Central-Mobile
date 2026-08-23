part of 'seminar_models.dart';

enum SeminarStatus {
  registered('registered'),
  verified('verified'),
  examinerAssigned('examiner_assigned'),
  scheduled('scheduled'),
  ongoing('ongoing'),
  passed('passed'),
  passedWithRevision('passed_with_revision'),
  failed('failed'),
  cancelled('cancelled');

  final String value;
  const SeminarStatus(this.value);

  static SeminarStatus fromJson(dynamic value) {
    return SeminarStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ApiContractException(
        'Status seminar tidak dikenali: ${value ?? 'null'}.',
      ),
    );
  }

  bool get isFinal =>
      this == SeminarStatus.passed ||
      this == SeminarStatus.passedWithRevision ||
      this == SeminarStatus.failed ||
      this == SeminarStatus.cancelled;

  bool get canShowAssessment =>
      this == SeminarStatus.ongoing ||
      this == SeminarStatus.passed ||
      this == SeminarStatus.passedWithRevision ||
      this == SeminarStatus.failed;

  bool get canDownloadInvitation =>
      this == SeminarStatus.scheduled ||
      this == SeminarStatus.ongoing ||
      this == SeminarStatus.passed ||
      this == SeminarStatus.passedWithRevision ||
      this == SeminarStatus.failed;
}

enum ExaminerResponse {
  available('available'),
  unavailable('unavailable');

  final String value;
  const ExaminerResponse(this.value);
}

enum SeminarRevisionAction {
  saveAction('save_action'),
  submit('submit'),
  cancelSubmit('cancel_submit'),
  approve('approve'),
  unapprove('unapprove');

  final String value;
  const SeminarRevisionAction(this.value);
}

enum AudienceAction {
  approve('approve'),
  unapprove('unapprove'),
  togglePresence('toggle_presence');

  final String value;
  const AudienceAction(this.value);
}

class SeminarSupervisor {
  final String? lecturerId;
  final String name;
  final String role;

  const SeminarSupervisor({
    required this.lecturerId,
    required this.name,
    required this.role,
  });

  factory SeminarSupervisor.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'seminar.supervisor');
    final name = json['name'] ?? json['lecturerName'];
    if (name is! String || name.isEmpty) {
      throw const ApiContractException(
        'seminar.supervisor tidak memiliki nama dosen.',
      );
    }
    return SeminarSupervisor(
      lecturerId: json.optionalString('lecturerId'),
      name: name,
      role: json.requireString('role', context: 'seminar.supervisor'),
    );
  }
}
