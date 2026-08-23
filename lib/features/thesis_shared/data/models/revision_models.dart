import '../../../../core/utils/api_contract_parser.dart';

class RevisionItem {
  final String id;
  final int? examinerOrder;
  final String? examinerLecturerId;
  final String? examinerName;
  final String description;
  final String? revisionAction;
  final bool isFinished;
  final DateTime? studentSubmittedAt;
  final DateTime? supervisorApprovedAt;
  final String? approvedBySupervisorId;
  final String? approvedBySupervisorName;

  const RevisionItem({
    required this.id,
    required this.examinerOrder,
    required this.examinerLecturerId,
    required this.examinerName,
    required this.description,
    required this.revisionAction,
    required this.isFinished,
    required this.studentSubmittedAt,
    required this.supervisorApprovedAt,
    required this.approvedBySupervisorId,
    required this.approvedBySupervisorName,
  });

  factory RevisionItem.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'revision');
    return RevisionItem(
      id: json.requireString('id', context: 'revision'),
      examinerOrder: json.optionalInt('examinerOrder'),
      examinerLecturerId: json.optionalString('examinerLecturerId'),
      examinerName: json.optionalString('examinerName'),
      description: json.requireString('description', context: 'revision'),
      revisionAction: json.optionalString('revisionAction'),
      isFinished: json.requireBool('isFinished', context: 'revision'),
      studentSubmittedAt: json.optionalDateTime('studentSubmittedAt'),
      supervisorApprovedAt: json.optionalDateTime('supervisorApprovedAt'),
      approvedBySupervisorId: json.optionalString('approvedBySupervisorId'),
      approvedBySupervisorName: json.optionalString('approvedBySupervisorName'),
    );
  }
}

class RevisionBoard {
  final String? resourceId;
  final int total;
  final int finished;
  final int pendingApproval;
  final List<RevisionItem> revisions;

  const RevisionBoard({
    required this.resourceId,
    required this.total,
    required this.finished,
    required this.pendingApproval,
    required this.revisions,
  });

  factory RevisionBoard.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'revisionBoard');
    final revisions = json
        .requireList('revisions', context: 'revisionBoard')
        .map(RevisionItem.fromJson)
        .toList(growable: false);
    final summary = json.optionalMap('summary');

    return RevisionBoard(
      resourceId:
          json.optionalString('resourceId') ??
          json.optionalString('seminarId') ??
          json.optionalString('defenceId'),
      total: summary?.optionalInt('total') ?? revisions.length,
      finished:
          summary?.optionalInt('finished') ??
          revisions.where((item) => item.isFinished).length,
      pendingApproval:
          summary?.optionalInt('pendingApproval') ??
          revisions
              .where(
                (item) =>
                    item.studentSubmittedAt != null &&
                    item.supervisorApprovedAt == null,
              )
              .length,
      revisions: revisions,
    );
  }
}
