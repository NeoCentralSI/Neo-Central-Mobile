import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../core/utils/binary_download.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/assessment_models.dart';
import '../../data/models/seminar_models.dart';
import '../seminar_detail_screen.dart';

class SeminarAssessmentPanel extends StatefulWidget {
  final String seminarId;
  final SeminarDetail detail;
  final UserModel? user;
  final Future<void> Function() onRefresh;

  const SeminarAssessmentPanel({
    super.key,
    required this.seminarId,
    required this.detail,
    required this.user,
    required this.onRefresh,
  });

  @override
  State<SeminarAssessmentPanel> createState() => _SeminarAssessmentPanelState();
}

class _SeminarAssessmentPanelState extends State<SeminarAssessmentPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  final _revisionNotesController = TextEditingController();
  final Map<String, TextEditingController> _scoreControllers = {};
  SeminarAssessmentForm? _assessment;
  SeminarFinalizationData? _finalization;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _recommendRevision = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  bool get _isExaminer {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        widget.detail.examiners.any((item) => item.lecturerId == lecturerId);
  }

  bool get _isSupervisor {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        widget.detail.supervisors.any((item) => item.lecturerId == lecturerId);
  }

  bool get _isLeadership =>
      widget.user?.appRole == UserRole.headOfDepartment ||
      widget.user?.appRole == UserRole.admin;

  bool get _isEditableExaminer =>
      _isExaminer &&
      widget.detail.status == SeminarStatus.ongoing &&
      _assessment?.examiner != null &&
      _assessment?.isLocked == false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _revisionNotesController.dispose();
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      SeminarAssessmentForm? assessment;
      SeminarFinalizationData? finalization;
      final finalized =
          widget.detail.resultFinalizedAt != null ||
          widget.detail.status.isFinal;

      if (finalized) {
        finalization = await _api.getFinalizationData(widget.seminarId);
      } else if (_isExaminer) {
        assessment = await _api.getAssessment(widget.seminarId);
      } else if (_isSupervisor || _isLeadership) {
        finalization = await _api.getFinalizationData(widget.seminarId);
      }

      if (!mounted) return;
      _replaceScoreControllers(assessment);
      setState(() {
        _assessment = assessment;
        _finalization = finalization;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _replaceScoreControllers(SeminarAssessmentForm? form) {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();
    _revisionNotesController.text = form?.examiner?.revisionNotes ?? '';
    for (final group in form?.criteriaGroups ?? const <AssessmentGroup>[]) {
      for (final criterion in group.criteria) {
        _scoreControllers[criterion.id] = TextEditingController(
          text: criterion.score?.toString() ?? '',
        );
      }
    }
  }

  Future<void> _submitAssessment({required bool draft}) async {
    final form = _assessment;
    if (form == null) return;

    final scores = <AssessmentScoreInput>[];
    for (final group in form.criteriaGroups) {
      for (final criterion in group.criteria) {
        final raw = _scoreControllers[criterion.id]?.text.trim() ?? '';
        if (raw.isEmpty) {
          if (!draft) {
            _showError('Semua kriteria harus diisi sebelum submit final.');
            return;
          }
          continue;
        }
        final score = double.tryParse(raw.replaceAll(',', '.'));
        if (score == null || score < 0 || score > criterion.maxScore) {
          _showError(
            "Nilai '${criterion.name}' harus berada pada rentang 0–${criterion.maxScore}.",
          );
          return;
        }
        scores.add(
          AssessmentScoreInput(
            assessmentCriteriaId: criterion.id,
            score: score,
          ),
        );
      }
    }

    if (!draft) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Submit Penilaian Final?'),
          content: const Text(
            'Penilaian yang sudah disubmit final tidak dapat diubah kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit Final'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);
    try {
      await _api.submitAssessment(
        widget.seminarId,
        scores: scores,
        revisionNotes: _revisionNotesController.text,
        isDraft: draft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft
                ? 'Draft penilaian berhasil disimpan.'
                : 'Penilaian final berhasil disubmit.',
          ),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
      await widget.onRefresh();
    } catch (exception) {
      if (mounted) _showError('Gagal menyimpan penilaian: $exception');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finalize() async {
    final data = _finalization;
    if (data == null || !data.canFinalize || !data.allExaminerSubmitted) return;
    final belowThreshold =
        data.averageScore != null &&
        data.averageScore! < data.minimumPassingScore;
    final recommendRevision = belowThreshold ? false : _recommendRevision;
    final outcome = belowThreshold
        ? 'tidak lulus'
        : recommendRevision
        ? 'lulus dengan revisi'
        : 'lulus';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalisasi Hasil Seminar?'),
        content: Text(
          'Berdasarkan nilai rata-rata dan ambang kelulusan dari server, hasil akan ditetapkan sebagai $outcome.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalisasi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _api.finalizeSeminar(
        widget.seminarId,
        recommendRevision: recommendRevision,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil seminar berhasil difinalisasi.'),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await widget.onRefresh();
    } catch (exception) {
      if (mounted) _showError('Gagal memfinalisasi hasil: $exception');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _downloadAssessmentResult() async {
    setState(() => _isSaving = true);
    try {
      final response = await _api.downloadAssessmentResult(widget.seminarId);
      final saved = await saveBinaryResponse(
        response,
        fallbackFileName: 'Hasil-Penilaian-Seminar-Hasil.pdf',
      );
      if (saved && mounted) {
        _showErrorWithColor(
          'Hasil penilaian berhasil disimpan.',
          AppColors.successDark,
        );
      }
    } catch (exception) {
      if (mounted) {
        _showError('Gagal mengunduh hasil penilaian: $exception');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    _showErrorWithColor(message, AppColors.destructive);
  }

  void _showErrorWithColor(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_assessment != null) return _assessmentForm(_assessment!);
    if (_finalization != null) return _finalizationView(_finalization!);
    return const _EmptyView(
      message: 'Data penilaian belum tersedia untuk peran Anda.',
    );
  }

  Widget _assessmentForm(SeminarAssessmentForm form) {
    final editable = _isEditableExaminer;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        _AssessmentHeader(
          title: 'Form Penilaian Penguji ${form.examiner?.order ?? '-'}',
          threshold: form.minimumPassingScore,
          locked: form.isLocked,
        ),
        const SizedBox(height: AppSpacing.base),
        for (final group in form.criteriaGroups) ...[
          _CriteriaGroupCard(
            group: group,
            editable: editable,
            controllers: _scoreControllers,
          ),
          const SizedBox(height: AppSpacing.base),
        ],
        AppCard(
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catatan Revisi', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: _revisionNotesController,
                readOnly: !editable,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan catatan perbaikan untuk mahasiswa…',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        if (editable) ...[
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submitAssessment(draft: true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submitAssessment(draft: false),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit Final'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _finalizationView(SeminarFinalizationData data) {
    final average = data.averageScore;
    final belowThreshold =
        average != null && average < data.minimumPassingScore;
    final alreadyFinalized = data.seminar.resultFinalizedAt != null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Rekap Penilaian', style: AppTextStyles.h4),
                  ),
                  AppBadge(
                    label: seminarStatusLabel(data.seminar.status.value),
                    variant: seminarStatusVariant(data.seminar.status.value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Nilai rata-rata',
                value: average?.toStringAsFixed(2) ?? 'Belum lengkap',
              ),
              _SummaryRow(
                label: 'Ambang kelulusan',
                value: data.minimumPassingScore.toString(),
              ),
              _SummaryRow(
                label: 'Status penguji',
                value: data.allExaminerSubmitted
                    ? 'Semua sudah submit'
                    : 'Menunggu penilaian',
              ),
              if (alreadyFinalized) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _downloadAssessmentResult,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Unduh Hasil Penilaian'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        for (final examiner in data.examiners) ...[
          _ExaminerScoreCard(examiner: examiner),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (data.canFinalize && !alreadyFinalized) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keputusan Pembimbing', style: AppTextStyles.label),
                const SizedBox(height: 8),
                if (belowThreshold)
                  Text(
                    'Nilai berada di bawah ambang kelulusan. Hasil akan ditetapkan tidak lulus.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.destructive,
                    ),
                  )
                else
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _recommendRevision,
                    onChanged: data.recommendationUnlocked
                        ? (value) => setState(
                            () => _recommendRevision = value ?? false,
                          )
                        : null,
                    title: const Text('Rekomendasikan revisi'),
                    subtitle: const Text(
                      'Aktifkan jika mahasiswa lulus dengan kewajiban revisi.',
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: !_isSaving && data.allExaminerSubmitted
                        ? _finalize
                        : null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Finalisasi Hasil'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AssessmentHeader extends StatelessWidget {
  final String title;
  final num threshold;
  final bool locked;

  const _AssessmentHeader({
    required this.title,
    required this.threshold,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                Text(
                  'Ambang kelulusan: $threshold',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (locked)
            const AppBadge(label: 'Terkunci', variant: BadgeVariant.success),
        ],
      ),
    );
  }
}

class _CriteriaGroupCard extends StatelessWidget {
  final AssessmentGroup group;
  final bool editable;
  final Map<String, TextEditingController> controllers;

  const _CriteriaGroupCard({
    required this.group,
    required this.editable,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.code, style: AppTextStyles.label),
                Text(group.description, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final criterion in group.criteria)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          criterion.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 82,
                        child: TextField(
                          controller: controllers[criterion.id],
                          readOnly: !editable,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '0',
                            suffixText: '/${criterion.maxScore}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (criterion.rubrics.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final rubric in criterion.rubrics)
                      Text(
                        '${rubric.minScore}–${rubric.maxScore}: ${rubric.description}',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExaminerScoreCard extends StatelessWidget {
  final FinalizationExaminer examiner;

  const _ExaminerScoreCard({required this.examiner});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Text(
          'Penguji ${examiner.order} • ${examiner.lecturerName}',
          style: AppTextStyles.label,
        ),
        subtitle: Text(
          examiner.submittedAt != null
              ? 'Sudah submit final'
              : examiner.isDraft
              ? 'Draft tersimpan'
              : 'Belum menilai',
          style: AppTextStyles.caption,
        ),
        trailing: Text(
          examiner.assessmentScore?.toStringAsFixed(2) ?? '-',
          style: AppTextStyles.h4,
        ),
        children: [
          if (examiner.assessmentDetails.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Rincian nilai belum tersedia.',
                style: AppTextStyles.caption,
              ),
            )
          else
            for (final group in examiner.assessmentDetails)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.code, style: AppTextStyles.labelSmall),
                    for (final criterion in group.criteria)
                      _SummaryRow(
                        label: criterion.name,
                        value:
                            '${criterion.score?.toString() ?? '-'} / ${criterion.maxScore}',
                      ),
                  ],
                ),
              ),
          if (examiner.revisionNotes?.isNotEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Catatan: ${examiner.revisionNotes}',
                style: AppTextStyles.caption,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Text(
          message,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
            const SizedBox(height: 10),
            Text(message, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
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
