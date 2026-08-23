part of 'yudisium_models.dart';

enum YudisiumSurveyQuestionType {
  shortAnswer('short_answer'),
  paragraph('paragraph'),
  singleChoice('single_choice'),
  multipleChoice('multiple_choice'),
  number('number'),
  date('date');

  final String value;
  const YudisiumSurveyQuestionType(this.value);

  static YudisiumSurveyQuestionType fromJson(dynamic value) =>
      YudisiumSurveyQuestionType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => throw ApiContractException(
          'Tipe pertanyaan exit survey tidak dikenali: ${value ?? 'null'}.',
        ),
      );
}

class YudisiumSurveyOption {
  final String id;
  final String text;
  final int orderNumber;

  const YudisiumSurveyOption({
    required this.id,
    required this.text,
    required this.orderNumber,
  });

  factory YudisiumSurveyOption.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.option');
    return YudisiumSurveyOption(
      id: json.requireString('id', context: 'exitSurvey.option'),
      text: json.requireString('optionText', context: 'exitSurvey.option'),
      orderNumber: json.optionalInt('orderNumber') ?? 0,
    );
  }
}

class YudisiumSurveyQuestion {
  final String id;
  final String? sessionId;
  final String question;
  final String? description;
  final YudisiumSurveyQuestionType type;
  final bool isRequired;
  final int orderNumber;
  final List<YudisiumSurveyOption> options;

  const YudisiumSurveyQuestion({
    required this.id,
    required this.sessionId,
    required this.question,
    required this.description,
    required this.type,
    required this.isRequired,
    required this.orderNumber,
    required this.options,
  });

  factory YudisiumSurveyQuestion.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.question');
    return YudisiumSurveyQuestion(
      id: json.requireString('id', context: 'exitSurvey.question'),
      sessionId: json.optionalString('exitSurveySessionId'),
      question: json.requireString('question', context: 'exitSurvey.question'),
      description: json.optionalString('description'),
      type: YudisiumSurveyQuestionType.fromJson(json['questionType']),
      isRequired: json.requireBool(
        'isRequired',
        context: 'exitSurvey.question',
      ),
      orderNumber: json.requireInt(
        'orderNumber',
        context: 'exitSurvey.question',
      ),
      options: json
          .optionalList('options')
          .map(YudisiumSurveyOption.fromJson)
          .toList(growable: false),
    );
  }
}

class YudisiumSurveySession {
  final String id;
  final String name;
  final String? description;
  final int order;
  final List<YudisiumSurveyQuestion> questions;

  const YudisiumSurveySession({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.questions,
  });

  factory YudisiumSurveySession.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.session');
    return YudisiumSurveySession(
      id: json.requireString('id', context: 'exitSurvey.session'),
      name: json.requireString('name', context: 'exitSurvey.session'),
      description: json.optionalString('description'),
      order: json.requireInt('order', context: 'exitSurvey.session'),
      questions: json
          .requireList('questions', context: 'exitSurvey.session')
          .map(YudisiumSurveyQuestion.fromJson)
          .toList(growable: false),
    );
  }
}

class YudisiumSurveyForm {
  final String id;
  final String name;
  final String? description;
  final List<YudisiumSurveySession> sessions;

  const YudisiumSurveyForm({
    required this.id,
    required this.name,
    required this.description,
    required this.sessions,
  });

  factory YudisiumSurveyForm.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.form');
    final sessions =
        json
            .requireList('sessions', context: 'exitSurvey.form')
            .map(YudisiumSurveySession.fromJson)
            .toList(growable: false)
          ..sort((a, b) => a.order.compareTo(b.order));
    return YudisiumSurveyForm(
      id: json.requireString('id', context: 'exitSurvey.form'),
      name: json.requireString('name', context: 'exitSurvey.form'),
      description: json.optionalString('description'),
      sessions: sessions,
    );
  }
}

class YudisiumSurveyResponseAnswer {
  final String questionId;
  final String? optionId;
  final List<String> optionIds;
  final String? answerText;
  final num? answerNumber;
  final String? answerDate;

  const YudisiumSurveyResponseAnswer({
    required this.questionId,
    required this.optionId,
    required this.optionIds,
    required this.answerText,
    required this.answerNumber,
    required this.answerDate,
  });

  factory YudisiumSurveyResponseAnswer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.response.answer');
    final optionIds = json.optionalList('optionIds');
    if (optionIds.any((item) => item is! String)) {
      throw const ApiContractException(
        'exitSurvey.response.answer.optionIds harus berupa daftar string.',
      );
    }
    return YudisiumSurveyResponseAnswer(
      questionId: json.requireString(
        'questionId',
        context: 'exitSurvey.response.answer',
      ),
      optionId: json.optionalString('optionId'),
      optionIds: optionIds.cast<String>(),
      answerText: json.optionalString('answerText'),
      answerNumber: json.optionalNum('answerNumber'),
      answerDate: json.optionalString('answerDate'),
    );
  }
}

class YudisiumSurveyResponse {
  final String id;
  final DateTime submittedAt;
  final List<YudisiumSurveyResponseAnswer> answers;

  const YudisiumSurveyResponse({
    required this.id,
    required this.submittedAt,
    required this.answers,
  });

  factory YudisiumSurveyResponse.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.response');
    return YudisiumSurveyResponse(
      id: json.requireString('id', context: 'exitSurvey.response'),
      submittedAt: json.requireDateTime(
        'submittedAt',
        context: 'exitSurvey.response',
      ),
      answers: json
          .requireList('answers', context: 'exitSurvey.response')
          .map(YudisiumSurveyResponseAnswer.fromJson)
          .toList(growable: false),
    );
  }
}

class StudentYudisiumExitSurvey {
  final String yudisiumId;
  final String yudisiumName;
  final YudisiumSurveyForm form;
  final YudisiumSurveyResponse? response;
  final bool isSubmitted;

  const StudentYudisiumExitSurvey({
    required this.yudisiumId,
    required this.yudisiumName,
    required this.form,
    required this.response,
    required this.isSubmitted,
  });

  factory StudentYudisiumExitSurvey.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'studentExitSurvey');
    final yudisium = json.requireMap('yudisium', context: 'studentExitSurvey');
    return StudentYudisiumExitSurvey(
      yudisiumId: yudisium.requireString(
        'id',
        context: 'studentExitSurvey.yudisium',
      ),
      yudisiumName: yudisium.requireString(
        'name',
        context: 'studentExitSurvey.yudisium',
      ),
      form: YudisiumSurveyForm.fromJson(json['form']),
      response: json['response'] == null
          ? null
          : YudisiumSurveyResponse.fromJson(json['response']),
      isSubmitted: json.requireBool(
        'isSubmitted',
        context: 'studentExitSurvey',
      ),
    );
  }
}

class YudisiumSurveyAnswerInput {
  final String questionId;
  final String? optionId;
  final List<String>? optionIds;
  final String? answerText;
  final num? answerNumber;
  final String? answerDate;

  const YudisiumSurveyAnswerInput({
    required this.questionId,
    this.optionId,
    this.optionIds,
    this.answerText,
    this.answerNumber,
    this.answerDate,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    if (optionId != null) 'optionId': optionId,
    if (optionIds != null) 'optionIds': optionIds,
    if (answerText != null) 'answerText': answerText,
    if (answerNumber != null) 'answerNumber': answerNumber,
    if (answerDate != null) 'answerDate': answerDate,
  };
}

class YudisiumExitSurveySubmissionResult {
  final YudisiumSurveyResponse response;

  const YudisiumExitSurveySubmissionResult({required this.response});

  factory YudisiumExitSurveySubmissionResult.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'exitSurvey.submission');
    return YudisiumExitSurveySubmissionResult(
      response: YudisiumSurveyResponse.fromJson(json['response']),
    );
  }
}
