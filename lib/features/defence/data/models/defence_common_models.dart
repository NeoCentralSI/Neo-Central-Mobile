part of 'defence_models.dart';

enum DefenceStatus {
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
  const DefenceStatus(this.value);

  static DefenceStatus fromJson(dynamic value) =>
      DefenceStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw ApiContractException(
          'Status sidang tidak dikenali: ${value ?? 'null'}.',
        ),
      );

  bool get isFinal =>
      this == passed || this == passedWithRevision || this == failed;
  bool get canShowAssessment => this == ongoing || isFinal;
  bool get canDownloadInvitation =>
      this == scheduled || this == ongoing || isFinal;
}

enum DefenceAssessorRole {
  examiner('examiner'),
  supervisor('supervisor'),
  viewer('viewer');

  final String value;
  const DefenceAssessorRole(this.value);

  static DefenceAssessorRole fromJson(dynamic value) =>
      DefenceAssessorRole.values.firstWhere(
        (role) => role.value == value,
        orElse: () => throw ApiContractException(
          'Peran penilai sidang tidak dikenali: ${value ?? 'null'}.',
        ),
      );
}

enum DefenceExaminerResponse {
  available('available'),
  unavailable('unavailable');

  final String value;
  const DefenceExaminerResponse(this.value);
}

enum DefenceRevisionAction {
  saveAction('save_action'),
  submit('submit'),
  cancelSubmit('cancel_submit'),
  approve('approve'),
  unapprove('unapprove');

  final String value;
  const DefenceRevisionAction(this.value);
}

class DefenceSupervisor {
  final String? lecturerId;
  final String name;
  final String role;

  const DefenceSupervisor({
    required this.lecturerId,
    required this.name,
    required this.role,
  });

  factory DefenceSupervisor.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.supervisor');
    final name = json['name'] ?? json['lecturerName'];
    if (name is! String || name.isEmpty) {
      throw const ApiContractException(
        'defence.supervisor tidak memiliki nama yang valid.',
      );
    }
    return DefenceSupervisor(
      lecturerId: json.optionalString('lecturerId'),
      name: name,
      role: json.optionalString('role') ?? '-',
    );
  }
}

class DefenceExaminer {
  final String id;
  final String? lecturerId;
  final String lecturerName;
  final int order;
  final ExaminerAvailabilityStatus? availabilityStatus;
  final DateTime? respondedAt;
  final num? assessmentScore;
  final DateTime? assessmentSubmittedAt;
  final String? revisionNotes;

  const DefenceExaminer({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.order,
    required this.availabilityStatus,
    required this.respondedAt,
    required this.assessmentScore,
    required this.assessmentSubmittedAt,
    required this.revisionNotes,
  });

  bool get hasSubmittedAssessment => assessmentSubmittedAt != null;

  factory DefenceExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.examiner');
    return DefenceExaminer(
      id: json.requireString('id', context: 'defence.examiner'),
      lecturerId: json.optionalString('lecturerId'),
      lecturerName:
          json.optionalString('lecturerName') ??
          'Dosen penguji tidak diketahui',
      order: json.requireInt('order', context: 'defence.examiner'),
      availabilityStatus: json['availabilityStatus'] == null
          ? null
          : ExaminerAvailabilityStatus.fromJson(json['availabilityStatus']),
      respondedAt: json.optionalDateTime('respondedAt'),
      assessmentScore: json.optionalNum('assessmentScore'),
      assessmentSubmittedAt: json.optionalDateTime('assessmentSubmittedAt'),
      revisionNotes: json.optionalString('revisionNotes'),
    );
  }
}

class DefenceDocument {
  final String requirementId;
  final String? requirementName;
  final DocumentStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? notes;
  final String? verifiedBy;
  final String? fileName;
  final String? filePath;

  const DefenceDocument({
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

  factory DefenceDocument.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.document');
    return DefenceDocument(
      requirementId:
          json.optionalString('requirementId') ??
          json.requireString('documentTypeId', context: 'defence.document'),
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

class DefenceMilestone {
  final String id;
  final String label;
  final bool checked;

  const DefenceMilestone({
    required this.id,
    required this.label,
    required this.checked,
  });

  factory DefenceMilestone.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.milestone');
    return DefenceMilestone(
      id: json.requireString('id', context: 'defence.milestone'),
      label: json.requireString('label', context: 'defence.milestone'),
      checked: json.requireBool('checked', context: 'defence.milestone'),
    );
  }
}

class DefenceRequirementConfiguration {
  final bool isConfigured;
  final String? message;

  const DefenceRequirementConfiguration({
    required this.isConfigured,
    required this.message,
  });

  factory DefenceRequirementConfiguration.fromJson(dynamic value) {
    final json = requireJsonMap(
      value,
      context: 'defence.requirementConfiguration',
    );
    return DefenceRequirementConfiguration(
      isConfigured: json.requireBool(
        'isConfigured',
        context: 'defence.requirementConfiguration',
      ),
      message: json.optionalString('message'),
    );
  }
}

class DefenceUploadConfig {
  final List<String> accept;
  final int maxFileSizeBytes;
  final num maxFileSizeMb;

  const DefenceUploadConfig({
    required this.accept,
    required this.maxFileSizeBytes,
    required this.maxFileSizeMb,
  });

  factory DefenceUploadConfig.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'defence.uploadConfig');
    final accept = json.requireList('accept', context: 'defence.uploadConfig');
    if (accept.any((item) => item is! String)) {
      throw const ApiContractException(
        'defence.uploadConfig.accept harus berupa daftar string.',
      );
    }
    return DefenceUploadConfig(
      accept: accept.cast<String>(),
      maxFileSizeBytes: json.requireInt(
        'maxFileSizeBytes',
        context: 'defence.uploadConfig',
      ),
      maxFileSizeMb:
          json.optionalNum('maxFileSizeMb') ??
          json.requireInt('maxFileSizeBytes', context: 'defence.uploadConfig') /
              (1024 * 1024),
    );
  }
}
