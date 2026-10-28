/// One phase of a thesis's milestones, from `GET /milestones/thesis/:id`.
class MilestoneList {
  final List<dynamic> milestones;

  /// Listed phase (`proposal` or `research`).
  final String? phase;

  /// Phase the thesis is in now.
  final String? currentPhase;

  /// Set by the backend when the listed phase is read-only.
  final String? readOnlyReason;

  const MilestoneList({
    required this.milestones,
    this.phase,
    this.currentPhase,
    this.readOnlyReason,
  });

  factory MilestoneList.fromResponse(Object? res) {
    if (res is List) return MilestoneList(milestones: res);
    if (res is! Map) return const MilestoneList(milestones: []);
    String? text(Object? v) => v is String && v.isNotEmpty ? v : null;
    final data = res['data'];
    return MilestoneList(
      milestones: data is List ? data : const [],
      phase: text(res['phase']),
      currentPhase: text(res['currentPhase']),
      readOnlyReason: text(res['readOnlyReason']),
    );
  }
}
