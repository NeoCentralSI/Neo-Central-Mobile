import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/thesis_shared/domain/thesis_access_policy.dart';

void main() {
  group('canViewThesisAssessment', () {
    test('hides assessment before the workflow allows it', () {
      expect(
        canViewThesisAssessment(
          workflowAllowsAssessment: false,
          finalized: false,
          isPresenter: false,
          isSupervisor: false,
          isExaminer: true,
          isLeadership: false,
        ),
        isFalse,
      );
    });

    test('hides an unfinished assessment from its presenter', () {
      expect(
        canViewThesisAssessment(
          workflowAllowsAssessment: true,
          finalized: false,
          isPresenter: true,
          isSupervisor: false,
          isExaminer: false,
          isLeadership: false,
        ),
        isFalse,
      );
    });

    test('allows assessors and leadership during assessment', () {
      for (final access in const [
        (supervisor: true, examiner: false, leadership: false),
        (supervisor: false, examiner: true, leadership: false),
        (supervisor: false, examiner: false, leadership: true),
      ]) {
        expect(
          canViewThesisAssessment(
            workflowAllowsAssessment: true,
            finalized: false,
            isPresenter: false,
            isSupervisor: access.supervisor,
            isExaminer: access.examiner,
            isLeadership: access.leadership,
          ),
          isTrue,
        );
      }
    });

    test('allows the presenter after the result is finalized', () {
      expect(
        canViewThesisAssessment(
          workflowAllowsAssessment: true,
          finalized: true,
          isPresenter: true,
          isSupervisor: false,
          isExaminer: false,
          isLeadership: false,
        ),
        isTrue,
      );
    });
  });

  group('canViewThesisRevision', () {
    test('allows only active presenter and supervisor revision owners', () {
      expect(
        canViewThesisRevision(
          passedWithRevision: true,
          isArchive: false,
          isPresenter: true,
          isSupervisor: false,
        ),
        isTrue,
      );
      expect(
        canViewThesisRevision(
          passedWithRevision: true,
          isArchive: false,
          isPresenter: false,
          isSupervisor: true,
        ),
        isTrue,
      );
    });

    test('hides revision from archive and unrelated roles', () {
      expect(
        canViewThesisRevision(
          passedWithRevision: true,
          isArchive: true,
          isPresenter: true,
          isSupervisor: false,
        ),
        isFalse,
      );
      expect(
        canViewThesisRevision(
          passedWithRevision: true,
          isArchive: false,
          isPresenter: false,
          isSupervisor: false,
        ),
        isFalse,
      );
    });

    test('requires the passed-with-revision workflow state', () {
      expect(
        canViewThesisRevision(
          passedWithRevision: false,
          isArchive: false,
          isPresenter: true,
          isSupervisor: false,
        ),
        isFalse,
      );
    });
  });
}
