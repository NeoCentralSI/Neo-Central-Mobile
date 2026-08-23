import '../../../../core/models/api_exception.dart';
import '../../../../core/utils/api_contract_parser.dart';

enum AssessmentSubmissionState {
  draft,
  submitted;

  static AssessmentSubmissionState fromJson(dynamic value) {
    return switch (value) {
      'draft' => AssessmentSubmissionState.draft,
      'submitted' => AssessmentSubmissionState.submitted,
      _ => throw ApiContractException(
        'Status submission penilaian tidak dikenali: ${value ?? 'null'}.',
      ),
    };
  }
}

class AssessmentRubric {
  final String id;
  final num minScore;
  final num maxScore;
  final String description;

  const AssessmentRubric({
    required this.id,
    required this.minScore,
    required this.maxScore,
    required this.description,
  });

  factory AssessmentRubric.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.rubric');
    return AssessmentRubric(
      id: json.requireString('id', context: 'assessment.rubric'),
      minScore: json.requireNum('minScore', context: 'assessment.rubric'),
      maxScore: json.requireNum('maxScore', context: 'assessment.rubric'),
      description: json.requireString(
        'description',
        context: 'assessment.rubric',
      ),
    );
  }
}

class AssessmentCriterion {
  final String id;
  final String name;
  final num maxScore;
  final num? score;
  final int? displayOrder;
  final List<AssessmentRubric> rubrics;

  const AssessmentCriterion({
    required this.id,
    required this.name,
    required this.maxScore,
    required this.score,
    required this.displayOrder,
    required this.rubrics,
  });

  factory AssessmentCriterion.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.criterion');
    return AssessmentCriterion(
      id: json.requireString('id', context: 'assessment.criterion'),
      name: json.requireString('name', context: 'assessment.criterion'),
      maxScore: json.requireNum('maxScore', context: 'assessment.criterion'),
      score: json.optionalNum('score'),
      displayOrder: json.optionalInt('displayOrder'),
      rubrics: json
          .optionalList('rubrics')
          .map(AssessmentRubric.fromJson)
          .toList(growable: false),
    );
  }
}

class AssessmentGroup {
  final String id;
  final String code;
  final String description;
  final List<AssessmentCriterion> criteria;

  const AssessmentGroup({
    required this.id,
    required this.code,
    required this.description,
    required this.criteria,
  });

  factory AssessmentGroup.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'assessment.group');
    return AssessmentGroup(
      id: json.requireString('id', context: 'assessment.group'),
      code: json.requireString('code', context: 'assessment.group'),
      description: json.requireString(
        'description',
        context: 'assessment.group',
      ),
      criteria: json
          .requireList('criteria', context: 'assessment.group')
          .map(AssessmentCriterion.fromJson)
          .toList(growable: false),
    );
  }
}
