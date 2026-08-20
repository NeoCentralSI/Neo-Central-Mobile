import '../../../../core/models/api_exception.dart';
import '../../../../core/utils/api_contract_parser.dart';

enum DocumentStatus {
  submitted,
  approved,
  declined;

  static DocumentStatus fromJson(dynamic value) {
    return switch (value) {
      'submitted' => DocumentStatus.submitted,
      'approved' => DocumentStatus.approved,
      'declined' => DocumentStatus.declined,
      _ => throw ApiContractException(
        'Status dokumen tidak dikenali: ${value ?? 'null'}.',
      ),
    };
  }
}

class AcademicRequirement {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final RequirementDocument? document;

  const AcademicRequirement({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.document,
  });

  factory AcademicRequirement.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'requirement');
    return AcademicRequirement(
      id: json.requireString('id', context: 'requirement'),
      name: json.requireString('name', context: 'requirement'),
      description: json.optionalString('description'),
      displayOrder: json.optionalInt('displayOrder') ?? 0,
      document: json['document'] == null
          ? null
          : RequirementDocument.fromJson(json['document']),
    );
  }
}

class RequirementDocument {
  final String resourceId;
  final String requirementId;
  final DocumentStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? notes;
  final String? verifiedBy;
  final String? fileName;
  final String? filePath;
  final String? mimeType;
  final int? fileSize;

  const RequirementDocument({
    required this.resourceId,
    required this.requirementId,
    required this.status,
    required this.submittedAt,
    required this.verifiedAt,
    required this.notes,
    required this.verifiedBy,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
  });

  factory RequirementDocument.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'requirement.document');
    final resourceId =
        json['resourceId'] ??
        json['thesisSeminarId'] ??
        json['thesisDefenceId'] ??
        json['yudisiumParticipantId'];
    if (resourceId is! String || resourceId.isEmpty) {
      throw const ApiContractException(
        'requirement.document tidak memiliki resource ID yang valid.',
      );
    }

    return RequirementDocument(
      resourceId: resourceId,
      requirementId: json.requireString(
        'requirementId',
        context: 'requirement.document',
      ),
      status: DocumentStatus.fromJson(json['status']),
      submittedAt: json.requireDateTime(
        'submittedAt',
        context: 'requirement.document',
      ),
      verifiedAt: json.optionalDateTime('verifiedAt'),
      notes: json.optionalString('notes'),
      verifiedBy: json.optionalString('verifiedBy'),
      fileName: json.optionalString('fileName'),
      filePath: json.optionalString('filePath'),
      mimeType: json.optionalString('mimeType'),
      fileSize: json.optionalInt('fileSize'),
    );
  }
}
