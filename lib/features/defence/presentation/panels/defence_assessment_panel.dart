import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/defence_api_service.dart';
import '../../../../core/utils/binary_download.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/assessment_models.dart';
import '../../data/models/defence_models.dart';

class DefenceAssessmentPanel extends StatefulWidget {
  final String defenceId;
  final DefenceDetail detail;
  final UserModel? user;
  final Future<void> Function() onRefresh;

  const DefenceAssessmentPanel({
    super.key,
    required this.defenceId,
    required this.detail,
    required this.user,
    required this.onRefresh,
  });

  @override
  State<DefenceAssessmentPanel> createState() => _DefenceAssessmentPanelState();
}

class _DefenceAssessmentPanelState extends State<DefenceAssessmentPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = DefenceApiService();
  final _notesController = TextEditingController();
  final Map<String, num> _scores = {};

  DefenceAssessmentForm? _form;
  DefenceFinalizationData? _finalization;
  StudentDefenceAssessment? _studentAssessment;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDownloading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  bool get _isStudent => widget.user?.appRole == UserRole.student;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      DefenceAssessmentForm? form;
      DefenceFinalizationData? finalization;
      StudentDefenceAssessment? studentAssessment;

      if (_isStudent && widget.detail.status.isFinal) {
        studentAssessment = await _api.getStudentAssessment(widget.defenceId);
      } else {
        if (widget.detail.status == DefenceStatus.ongoing &&
            (widget.detail.canOpenExaminerAssessment ||
                widget.detail.canOpenSupervisorAssessment)) {
          form = await _api.getAssessment(widget.defenceId);
        }
        finalization = await _api.getFinalizationData(widget.defenceId);
      }

      if (!mounted) return;
      _scores.clear();
      if (form != null) {
        for (final group in form.criteriaGroups) {
          for (final criterion in group.criteria) {
            _scores[criterion.id] = criterion.score ?? 0;
          }
        }
        _notesController.text = switch (form.assessorRole) {
          DefenceAssessorRole.examiner => form.examiner?.revisionNotes ?? '',
          DefenceAssessorRole.supervisor =>
            form.supervisor?.supervisorNotes ?? '',
          DefenceAssessorRole.viewer => '',
        };
      }
      setState(() {
        _form = form;
        _finalization = finalization;
        _studentAssessment = studentAssessment;
      });
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AssessmentCriterion> _criteria(DefenceAssessmentForm form) => form
      .criteriaGroups
      .expand((group) => group.criteria)
      .toList(growable: false);

  Future<void> _submitAssessment({required bool isDraft}) async {
    final form = _form;
    if (form == null || form.isSubmitted || _isSubmitting) return;
    final criteria = _criteria(form);
    if (criteria.isEmpty) {
      _message('Rubrik penilaian belum tersedia.', error: true);
      return;
    }
    for (final criterion in criteria) {
      final score = _scores[criterion.id];
      if (score == null || score < 0 || score > criterion.maxScore) {
        _message(
          'Nilai ${criterion.name} harus berada pada rentang 0–${criterion.maxScore}.',
          error: true,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.submitAssessment(
        widget.defenceId,
        scores: criteria
            .map(
              (criterion) => DefenceAssessmentScoreInput(
                assessmentCriteriaId: criterion.id,
                score: _scores[criterion.id]!,
              ),
            )
            .toList(growable: false),
        revisionNotes: form.assessorRole == DefenceAssessorRole.examiner
            ? _notesController.text
            : null,
        supervisorNotes: form.assessorRole == DefenceAssessorRole.supervisor
            ? _notesController.text
            : null,
        isDraft: isDraft,
      );
      if (!mounted) return;
      _message(
        isDraft
            ? 'Draf penilaian berhasil disimpan.'
            : 'Penilaian berhasil disubmit.',
      );
      await _load();
      await widget.onRefresh();
    } catch (exception) {
      _message('Gagal menyimpan penilaian: $exception', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _finalize() async {
    final data = _finalization;
    if (data == null || !data.supervisor.canFinalize) return;
    var recommendRevision = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tetapkan Hasil Sidang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nilai akhir terhitung: ${_score(data.defence.computedFinalScore)}',
              ),
              Text(
                'Batas lulus: ${_score(data.minimumPassingScore)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: recommendRevision,
                onChanged: (value) =>
                    setDialogState(() => recommendRevision = value ?? false),
                title: const Text('Rekomendasikan lulus dengan revisi'),
                subtitle: const Text(
                  'Jika nilai di bawah batas, backend tetap menetapkan tidak lulus.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tetapkan'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _api.finalizeDefence(
        widget.defenceId,
        recommendRevision: recommendRevision,
      );
      if (!mounted) return;
      _message('Hasil sidang berhasil ditetapkan.');
      await widget.onRefresh();
      await _load();
    } catch (exception) {
      _message('Gagal menetapkan hasil sidang: $exception', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _downloadResult() async {
    setState(() => _isDownloading = true);
    try {
      final response = await _api.downloadAssessmentResult(widget.defenceId);
      final saved = await saveBinaryResponse(
        response,
        fallbackFileName: 'Hasil-Penilaian-Sidang-TA.pdf',
      );
      if (saved) _message('Hasil penilaian berhasil disimpan.');
    } catch (exception) {
      _message('Gagal mengunduh hasil penilaian: $exception', error: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _message(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? AppColors.destructive : AppColors.successDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final student = _studentAssessment;
    if (student != null) {
      return _StudentTranscript(
        data: student,
        isDownloading: _isDownloading,
        onDownload: _downloadResult,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (_form case final form?) ...[
            _AssessmentFormCard(
              form: form,
              scores: _scores,
              notesController: _notesController,
              isSubmitting: _isSubmitting,
              onScoreChanged: (criterionId, score) {
                setState(() => _scores[criterionId] = score);
              },
              onSaveDraft: () => _submitAssessment(isDraft: true),
              onSubmit: () => _submitAssessment(isDraft: false),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          if (_finalization case final data?)
            _FinalizationCard(
              data: data,
              isBusy: _isSubmitting,
              isDownloading: _isDownloading,
              onFinalize: _finalize,
              onDownload: _downloadResult,
            ),
        ],
      ),
    );
  }
}

class _AssessmentFormCard extends StatelessWidget {
  final DefenceAssessmentForm form;
  final Map<String, num> scores;
  final TextEditingController notesController;
  final bool isSubmitting;
  final void Function(String criterionId, num score) onScoreChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  const _AssessmentFormCard({
    required this.form,
    required this.scores,
    required this.notesController,
    required this.isSubmitting,
    required this.onScoreChanged,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final locked =
        form.defence.status != DefenceStatus.ongoing || form.isSubmitted;
    final roleLabel = form.assessorRole == DefenceAssessorRole.examiner
        ? 'Penguji'
        : 'Pembimbing';
    final total = scores.values.fold<num>(0, (sum, value) => sum + value);
    final maximum = form.criteriaGroups
        .expand((group) => group.criteria)
        .fold<num>(0, (sum, item) => sum + item.maxScore);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(title: 'Form Penilaian $roleLabel'),
                  ),
                  AppBadge(
                    label: form.isSubmitted ? 'Sudah disubmit' : 'Draf',
                    variant: form.isSubmitted
                        ? BadgeVariant.success
                        : BadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${form.defence.studentName} • ${form.defence.studentNim}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Total sementara ${_score(total)} dari ${_score(maximum)}',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final group in form.criteriaGroups) ...[
          _EditableAssessmentGroup(
            group: group,
            scores: scores,
            enabled: !locked && !isSubmitting,
            onScoreChanged: onScoreChanged,
          ),
          const SizedBox(height: AppSpacing.base),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                form.assessorRole == DefenceAssessorRole.examiner
                    ? 'Catatan Revisi'
                    : 'Catatan Pembimbing',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                enabled: !locked && !isSubmitting,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan catatan penilaian bila diperlukan',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!locked) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onSaveDraft,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Simpan Draf'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isSubmitting ? null : onSubmit,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableAssessmentGroup extends StatelessWidget {
  final AssessmentGroup group;
  final Map<String, num> scores;
  final bool enabled;
  final void Function(String criterionId, num score) onScoreChanged;

  const _EditableAssessmentGroup({
    required this.group,
    required this.scores,
    required this.enabled,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${group.code} — ${group.description}', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          for (var index = 0; index < group.criteria.length; index++) ...[
            _CriterionInput(
              criterion: group.criteria[index],
              value: scores[group.criteria[index].id] ?? 0,
              enabled: enabled,
              onChanged: (score) =>
                  onScoreChanged(group.criteria[index].id, score),
            ),
            if (index != group.criteria.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _CriterionInput extends StatelessWidget {
  final AssessmentCriterion criterion;
  final num value;
  final bool enabled;
  final ValueChanged<num> onChanged;

  const _CriterionInput({
    required this.criterion,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(criterion.name, style: AppTextStyles.label)),
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: TextFormField(
                key: ValueKey('${criterion.id}:$value:$enabled'),
                initialValue: value.toString(),
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: '/${_score(criterion.maxScore)}',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (raw) {
                  final parsed = num.tryParse(raw.replaceAll(',', '.'));
                  if (parsed != null) onChanged(parsed);
                },
              ),
            ),
          ],
        ),
        if (criterion.rubrics.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Rubrik penilaian', style: AppTextStyles.caption),
            children: criterion.rubrics
                .map(
                  (rubric) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_score(rubric.minScore)}–${_score(rubric.maxScore)}: ${rubric.description}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _FinalizationCard extends StatelessWidget {
  final DefenceFinalizationData data;
  final bool isBusy;
  final bool isDownloading;
  final VoidCallback onFinalize;
  final VoidCallback onDownload;

  const _FinalizationCard({
    required this.data,
    required this.isBusy,
    required this.isDownloading,
    required this.onFinalize,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final finalized =
        data.defence.resultFinalizedAt != null || data.defence.status.isFinal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Rekap Penilaian')),
              AppBadge(
                label: _statusLabel(data.defence.status),
                variant: _statusVariant(data.defence.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final examiner in data.examiners)
            _ScoreRow(
              label: 'Penguji ${examiner.order} — ${examiner.lecturerName}',
              score: examiner.assessmentScore,
              submitted: examiner.submittedAt != null,
            ),
          _ScoreRow(
            label: '${data.supervisor.roleName} — ${data.supervisor.name}',
            score: data.supervisorAssessment.assessmentScore,
            submitted: data.supervisorAssessmentSubmitted,
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Rata-rata Penguji',
            value: _score(data.defence.examinerAverageScore),
          ),
          _SummaryRow(
            label: 'Nilai Pembimbing',
            value: _score(data.defence.supervisorScore),
          ),
          _SummaryRow(
            label: finalized ? 'Nilai Akhir' : 'Nilai Akhir Terhitung',
            value: _score(
              finalized
                  ? data.defence.finalScore
                  : data.defence.computedFinalScore,
            ),
          ),
          _SummaryRow(
            label: 'Batas Kelulusan',
            value: _score(data.minimumPassingScore),
          ),
          if (data.defence.grade != null)
            _SummaryRow(label: 'Nilai Huruf', value: data.defence.grade!),
          if (!data.recommendationUnlocked && !finalized) ...[
            const SizedBox(height: 10),
            const _Notice(
              text:
                  'Finalisasi terkunci sampai dua penguji dan pembimbing submit penilaian.',
            ),
          ],
          if (data.supervisor.canFinalize && data.recommendationUnlocked) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onFinalize,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Tetapkan Hasil Sidang'),
              ),
            ),
          ],
          if (finalized) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Unduh Hasil Penilaian'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentTranscript extends StatelessWidget {
  final StudentDefenceAssessment data;
  final bool isDownloading;
  final VoidCallback onDownload;

  const _StudentTranscript({
    required this.data,
    required this.isDownloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: SectionHeader(title: 'Berita Acara Sidang'),
                  ),
                  AppBadge(
                    label: _statusLabel(data.defence.status),
                    variant: _statusVariant(data.defence.status),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                label: 'Rata-rata Penguji',
                value: _score(data.defence.examinerAverageScore),
              ),
              _SummaryRow(
                label: 'Nilai Pembimbing',
                value: _score(data.defence.supervisorScore),
              ),
              _SummaryRow(
                label: 'Nilai Akhir',
                value: _score(data.defence.finalScore),
              ),
              _SummaryRow(
                label: 'Nilai Huruf',
                value: data.defence.grade ?? '-',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Unduh Hasil Penilaian'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final examiner in data.examiners) ...[
          _ReadOnlyAssessmentCard(
            title: 'Penguji ${examiner.order} — ${examiner.lecturerName}',
            score: examiner.assessmentScore,
            notes: examiner.revisionNotes,
            groups: examiner.assessmentDetails,
          ),
          const SizedBox(height: AppSpacing.base),
        ],
        _ReadOnlyAssessmentCard(
          title: 'Pembimbing — ${data.supervisorAssessment.name ?? '-'}',
          score: data.supervisorAssessment.assessmentScore,
          notes: data.supervisorAssessment.supervisorNotes,
          groups: data.supervisorAssessment.assessmentDetails,
        ),
      ],
    );
  }
}

class _ReadOnlyAssessmentCard extends StatelessWidget {
  final String title;
  final num? score;
  final String? notes;
  final List<AssessmentGroup> groups;

  const _ReadOnlyAssessmentCard({
    required this.title,
    required this.score,
    required this.notes,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.h4)),
              Text(_score(score), style: AppTextStyles.h3),
            ],
          ),
          for (final group in groups) ...[
            const Divider(height: 24),
            Text(
              '${group.code} — ${group.description}',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 6),
            for (final criterion in group.criteria)
              _SummaryRow(
                label: criterion.name,
                value:
                    '${_score(criterion.score)} / ${_score(criterion.maxScore)}',
              ),
          ],
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const Divider(height: 24),
            Text('Catatan', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(notes!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final num? score;
  final bool submitted;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            submitted ? Icons.check_circle : Icons.schedule_outlined,
            size: 18,
            color: submitted ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Text(_score(score), style: AppTextStyles.label),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 12),
          Text(value, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
              color: AppColors.destructive,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text('Gagal memuat penilaian', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
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

String _score(num? value) {
  if (value == null) return '-';
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
}

String _statusLabel(DefenceStatus status) => switch (status) {
  DefenceStatus.registered => 'Terdaftar',
  DefenceStatus.verified => 'Terverifikasi',
  DefenceStatus.examinerAssigned => 'Penguji Ditetapkan',
  DefenceStatus.scheduled => 'Dijadwalkan',
  DefenceStatus.ongoing => 'Berlangsung',
  DefenceStatus.passed => 'Lulus',
  DefenceStatus.passedWithRevision => 'Lulus + Revisi',
  DefenceStatus.failed => 'Tidak Lulus',
  DefenceStatus.cancelled => 'Dibatalkan',
};

BadgeVariant _statusVariant(DefenceStatus status) => switch (status) {
  DefenceStatus.passed ||
  DefenceStatus.passedWithRevision => BadgeVariant.success,
  DefenceStatus.failed || DefenceStatus.cancelled => BadgeVariant.destructive,
  DefenceStatus.ongoing => BadgeVariant.primary,
  DefenceStatus.scheduled ||
  DefenceStatus.examinerAssigned => BadgeVariant.warning,
  _ => BadgeVariant.secondary,
};
