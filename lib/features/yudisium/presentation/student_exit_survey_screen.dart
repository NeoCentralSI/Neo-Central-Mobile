import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/yudisium_api_service.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/models/yudisium_models.dart';
import 'utils/yudisium_survey_validation.dart';

class StudentExitSurveyScreen extends StatefulWidget {
  final Future<void> Function()? onSubmitted;

  const StudentExitSurveyScreen({super.key, this.onSubmitted});

  @override
  State<StudentExitSurveyScreen> createState() =>
      _StudentExitSurveyScreenState();
}

class _StudentExitSurveyScreenState extends State<StudentExitSurveyScreen> {
  final _api = YudisiumApiService();
  final Map<String, String> _texts = {};
  final Map<String, String> _singleSelections = {};
  final Map<String, Set<String>> _multipleSelections = {};

  StudentYudisiumExitSurvey? _survey;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int _sessionIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final survey = await _api.getStudentExitSurvey();
      _seedAnswers(survey);
      if (!mounted) return;
      setState(() {
        _survey = survey;
        if (_sessionIndex >= survey.form.sessions.length) _sessionIndex = 0;
      });
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seedAnswers(StudentYudisiumExitSurvey survey) {
    _texts.clear();
    _singleSelections.clear();
    _multipleSelections.clear();
    final questions = {
      for (final session in survey.form.sessions)
        for (final question in session.questions) question.id: question,
    };
    for (final answer in survey.response?.answers ?? const []) {
      final question = questions[answer.questionId];
      if (question == null) continue;
      switch (question.type) {
        case YudisiumSurveyQuestionType.singleChoice:
          if (answer.optionId != null) {
            _singleSelections[question.id] = answer.optionId!;
          }
        case YudisiumSurveyQuestionType.multipleChoice:
          final ids = <String>{...answer.optionIds};
          if (ids.isEmpty && answer.optionId != null) ids.add(answer.optionId!);
          _multipleSelections[question.id] = ids;
        case YudisiumSurveyQuestionType.number:
          _texts[question.id] =
              answer.answerText ?? answer.answerNumber?.toString() ?? '';
        case YudisiumSurveyQuestionType.date:
          _texts[question.id] =
              answer.answerDate?.split('T').first ?? answer.answerText ?? '';
        case YudisiumSurveyQuestionType.shortAnswer:
        case YudisiumSurveyQuestionType.paragraph:
          _texts[question.id] = answer.answerText ?? '';
      }
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _hasAnswer(YudisiumSurveyQuestion question) => switch (question.type) {
    YudisiumSurveyQuestionType.singleChoice =>
      _singleSelections[question.id]?.isNotEmpty == true,
    YudisiumSurveyQuestionType.multipleChoice =>
      _multipleSelections[question.id]?.isNotEmpty == true,
    _ => _texts[question.id]?.trim().isNotEmpty == true,
  };

  String? _validateQuestions(Iterable<YudisiumSurveyQuestion> questions) {
    for (final question in questions) {
      if (question.isRequired && !_hasAnswer(question)) {
        return 'Pertanyaan wajib belum dijawab: ${question.question}';
      }
      if (question.type == YudisiumSurveyQuestionType.number &&
          _hasAnswer(question) &&
          parseIndonesianSurveyNumber(_texts[question.id]!) == null) {
        return 'Jawaban untuk “${question.question}” harus berupa angka yang valid.';
      }
    }
    return null;
  }

  List<YudisiumSurveyAnswerInput> _buildAnswers(
    StudentYudisiumExitSurvey survey,
  ) {
    final answers = <YudisiumSurveyAnswerInput>[];
    for (final session in survey.form.sessions) {
      for (final question in session.questions) {
        if (!_hasAnswer(question)) continue;
        switch (question.type) {
          case YudisiumSurveyQuestionType.singleChoice:
            answers.add(
              YudisiumSurveyAnswerInput(
                questionId: question.id,
                optionId: _singleSelections[question.id],
              ),
            );
          case YudisiumSurveyQuestionType.multipleChoice:
            answers.add(
              YudisiumSurveyAnswerInput(
                questionId: question.id,
                optionIds: _multipleSelections[question.id]!.toList(),
              ),
            );
          case YudisiumSurveyQuestionType.number:
            answers.add(
              YudisiumSurveyAnswerInput(
                questionId: question.id,
                answerNumber: parseIndonesianSurveyNumber(_texts[question.id]!),
              ),
            );
          case YudisiumSurveyQuestionType.date:
            answers.add(
              YudisiumSurveyAnswerInput(
                questionId: question.id,
                answerDate: _texts[question.id]!.trim(),
              ),
            );
          case YudisiumSurveyQuestionType.shortAnswer:
          case YudisiumSurveyQuestionType.paragraph:
            answers.add(
              YudisiumSurveyAnswerInput(
                questionId: question.id,
                answerText: _texts[question.id]!.trim(),
              ),
            );
        }
      }
    }
    return answers;
  }

  Future<void> _submit() async {
    final survey = _survey;
    if (survey == null || survey.isSubmitted || _isSubmitting) return;
    final allQuestions = survey.form.sessions.expand(
      (session) => session.questions,
    );
    final validation = _validateQuestions(allQuestions);
    if (validation != null) {
      _message(validation, error: true);
      return;
    }
    final answers = _buildAnswers(survey);
    if (answers.isEmpty) {
      _message('Jawaban exit survey tidak boleh kosong.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim Exit Survey?'),
        content: const Text(
          'Jawaban yang sudah dikirim tidak dapat diubah kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _api.submitStudentExitSurvey(answers);
      await _load();
      await widget.onSubmitted?.call();
      _message('Exit survey berhasil dikirim.');
    } catch (exception) {
      _message('Gagal mengirim exit survey: $exception', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _next(YudisiumSurveySession session) {
    final validation = _validateQuestions(session.questions);
    if (validation != null) {
      _message(validation, error: true);
      return;
    }
    setState(() => _sessionIndex++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Exit Survey'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_isLoading && _survey == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _survey == null) {
      return _SurveyError(message: _error!, onRetry: _load);
    }
    final survey = _survey;
    if (survey == null) {
      return const Center(child: Text('Exit survey tidak tersedia.'));
    }
    final sessions = survey.form.sessions;
    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: Text('Form exit survey belum memiliki bagian pertanyaan.'),
        ),
      );
    }
    final session = sessions[_sessionIndex];
    final last = _sessionIndex == sessions.length - 1;
    final progress = (_sessionIndex + 1) / sessions.length;

    return Column(
      children: [
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                radius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            survey.form.name,
                            style: AppTextStyles.h3,
                          ),
                        ),
                        if (survey.isSubmitted)
                          const AppBadge(
                            label: 'Selesai',
                            variant: BadgeVariant.success,
                          ),
                      ],
                    ),
                    if (survey.form.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        survey.form.description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Bagian ${_sessionIndex + 1} dari ${sessions.length}: ${session.name}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    if (survey.response != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Dikirim ${_formatDateTime(survey.response!.submittedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (session.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  session.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (
                var index = 0;
                index < session.questions.length;
                index++
              ) ...[
                _QuestionCard(
                  index: _globalQuestionIndex(survey, _sessionIndex, index),
                  question: session.questions[index],
                  textValue: _texts[session.questions[index].id] ?? '',
                  singleValue: _singleSelections[session.questions[index].id],
                  multipleValues:
                      _multipleSelections[session.questions[index].id] ??
                      const {},
                  disabled: survey.isSubmitted,
                  onTextChanged: (value) =>
                      _texts[session.questions[index].id] = value,
                  onSingleChanged: (value) => setState(
                    () =>
                        _singleSelections[session.questions[index].id] = value,
                  ),
                  onMultipleChanged: (values) => setState(
                    () => _multipleSelections[session.questions[index].id] =
                        values,
                  ),
                  onPickDate: () => _pickDate(session.questions[index]),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (_sessionIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _sessionIndex--),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Sebelumnya'),
                    ),
                  const Spacer(),
                  if (!last)
                    FilledButton.icon(
                      onPressed: () => _next(session),
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Berikutnya'),
                    )
                  else if (!survey.isSubmitted)
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Kirim Survey'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  int _globalQuestionIndex(
    StudentYudisiumExitSurvey survey,
    int sessionIndex,
    int questionIndex,
  ) =>
      survey.form.sessions
          .take(sessionIndex)
          .fold<int>(0, (sum, session) => sum + session.questions.length) +
      questionIndex +
      1;

  Future<void> _pickDate(YudisiumSurveyQuestion question) async {
    final current = DateTime.tryParse(_texts[question.id] ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _texts[question.id] = _formatDateValue(picked));
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final YudisiumSurveyQuestion question;
  final String textValue;
  final String? singleValue;
  final Set<String> multipleValues;
  final bool disabled;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onSingleChanged;
  final ValueChanged<Set<String>> onMultipleChanged;
  final VoidCallback onPickDate;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.textValue,
    required this.singleValue,
    required this.multipleValues,
    required this.disabled,
    required this.onTextChanged,
    required this.onSingleChanged,
    required this.onMultipleChanged,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: '$index. ${question.question}',
              children: [
                if (question.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.destructive),
                  ),
              ],
            ),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (question.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              question.description!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _input(),
        ],
      ),
    );
  }

  Widget _input() => switch (question.type) {
    YudisiumSurveyQuestionType.shortAnswer => TextFormField(
      key: ValueKey('${question.id}-$textValue'),
      initialValue: textValue,
      enabled: !disabled,
      onChanged: onTextChanged,
      decoration: const InputDecoration(
        labelText: 'Jawaban Anda',
        border: OutlineInputBorder(),
      ),
    ),
    YudisiumSurveyQuestionType.paragraph => TextFormField(
      key: ValueKey('${question.id}-$textValue'),
      initialValue: textValue,
      enabled: !disabled,
      onChanged: onTextChanged,
      minLines: 3,
      maxLines: 6,
      decoration: const InputDecoration(
        labelText: 'Jawaban Anda',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
    ),
    YudisiumSurveyQuestionType.number => TextFormField(
      key: ValueKey('${question.id}-$textValue'),
      initialValue: textValue,
      enabled: !disabled,
      onChanged: onTextChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Jawaban angka',
        hintText: 'Contoh: 5000000 atau 5.000.000',
        border: OutlineInputBorder(),
      ),
    ),
    YudisiumSurveyQuestionType.date => OutlinedButton.icon(
      onPressed: disabled ? null : onPickDate,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(textValue.isEmpty ? 'Pilih tanggal' : textValue),
      ),
    ),
    YudisiumSurveyQuestionType.singleChoice => Column(
      children: [
        for (final option in question.options)
          InkWell(
            onTap: disabled ? null : () => onSingleChanged(option.id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(
                    singleValue == option.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: singleValue == option.id
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(option.text)),
                ],
              ),
            ),
          ),
      ],
    ),
    YudisiumSurveyQuestionType.multipleChoice => Column(
      children: [
        for (final option in question.options)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: multipleValues.contains(option.id),
            onChanged: disabled
                ? null
                : (checked) {
                    final next = <String>{...multipleValues};
                    if (checked == true) {
                      next.add(option.id);
                    } else {
                      next.remove(option.id);
                    }
                    onMultipleChanged(next);
                  },
            title: Text(option.text),
          ),
      ],
    ),
  };
}

class _SurveyError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SurveyError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text('Gagal memuat exit survey', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateValue(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
