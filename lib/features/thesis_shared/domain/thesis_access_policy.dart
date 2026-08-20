/// Shared visibility rule for the seminar and defence assessment tabs.
bool canViewThesisAssessment({
  required bool workflowAllowsAssessment,
  required bool finalized,
  required bool isPresenter,
  required bool isSupervisor,
  required bool isExaminer,
  required bool isLeadership,
}) {
  if (!workflowAllowsAssessment) return false;
  if (finalized) {
    return isPresenter || isSupervisor || isExaminer || isLeadership;
  }
  return isSupervisor || isExaminer || isLeadership;
}

/// Revisions are owned by the student and their supervisor.
///
/// Admins and unrelated lecturer roles are deliberately excluded because the
/// backend revision routes do not grant them access.
bool canViewThesisRevision({
  required bool passedWithRevision,
  required bool isArchive,
  required bool isPresenter,
  required bool isSupervisor,
}) => passedWithRevision && !isArchive && (isPresenter || isSupervisor);
