import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/defence_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Penilaian panel — examiner/supervisor assessment form + finalization rekap.
///
/// Mobile scope:
///   • Examiner (ongoing): form to fill scores + revisionNotes + Submit/Save Draf.
///   • Supervisor (ongoing): same form but scores + supervisorNotes, plus
///     finalization section with "Tetapkan Hasil Sidang" when unlocked.
///   • Finalised (any role): rekap matrix with examiner avg + supervisor score
///     + final score + grade.
class DefenceAssessmentPanel extends StatefulWidget {
  final String defenceId;
  final Map<String, dynamic> detail;
  final UserModel? user;
  final Future<void> Function() onRefresh;

  const DefenceAssessmentPanel({
    super.key,
    required this.defenceId,
    required this.detail,
    required this.onRefresh,
    this.user,
  });

  @override
  State<DefenceAssessmentPanel> createState() => _DefenceAssessmentPanelState();
}

class _DefenceAssessmentPanelState extends State<DefenceAssessmentPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = DefenceApiService();

  bool _isLoading = true;
  String? _error;

  // Form data (examiner or supervisor)
  Map<String, dynamic>? _form;
  final Map<String, int> _scores = {};
  final TextEditingController _notesCtrl = TextEditingController();
  String? _submittingMode; // 'draft' | 'submit'

  // Finalization data
  Map<String, dynamic>? _finalData;
  bool _recommendRevision = false;
  bool _finalizing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isFinalized {
    const finalStatuses = ['passed', 'passed_with_revision', 'failed'];
    return finalStatuses.contains((widget.detail['status'] ?? '').toString());
  }

  bool get _isUserExaminer {
    final lecturerId = widget.user?.lecturer?.id;
    if (lecturerId == null) return false;
    final examiners = (widget.detail['examiners'] as List?) ?? const [];
    return examiners
        .whereType<Map>()
        .any((e) => e['lecturerId'] == lecturerId);
  }

  bool get _isUserSupervisor {
    final lecturerId = widget.user?.lecturer?.id;
    if (lecturerId == null) return false;
    final supervisors = (widget.detail['supervisors'] as List?) ?? const [];
    return supervisors
        .whereType<Map>()
        .any((s) => s['lecturerId'] == lecturerId);
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final finalData = await _api.getDefenceFinalizationData(widget.defenceId);

      Map<String, dynamic>? form;
      if ((_isUserExaminer || _isUserSupervisor) && !_isFinalized) {
        try {
          form = await _api.getDefenceAssessment(widget.defenceId);
        } catch (_) {
          form = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _finalData = finalData;
        _form = form;
        _hydrateScoresFromForm();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _hydrateScoresFromForm() {
    _scores.clear();
    final form = _form;
    if (form == null) return;
    final groups = (form['criteriaGroups'] as List?) ?? const [];
    for (final g in groups.whereType<Map>()) {
      for (final c in ((g['criteria'] as List?) ?? const []).whereType<Map>()) {
        final id = c['id']?.toString();
        if (id == null) continue;
        final score = c['score'];
        if (score is num) _scores[id] = score.toInt();
      }
    }
    final assessorRole = (form['assessorRole'] ?? 'examiner').toString();
    if (assessorRole == 'examiner') {
      _notesCtrl.text =
          form['examiner']?['revisionNotes']?.toString() ?? '';
    } else {
      _notesCtrl.text =
          form['supervisor']?['supervisorNotes']?.toString() ?? '';
    }
  }

  String get _assessorRole =>
      (_form?['assessorRole'] ?? 'examiner').toString();

  bool get _isAssessmentSubmitted {
    final form = _form;
    if (form == null) return false;
    if (_assessorRole == 'examiner') {
      return (form['examiner']?['assessmentSubmittedAt'] ?? '').toString().isNotEmpty;
    }
    return (form['supervisor']?['assessmentSubmittedAt'] ?? '').toString().isNotEmpty;
  }

  Future<void> _submitAssessment({required bool isDraft}) async {
    final form = _form;
    if (form == null) return;
    final groups = (form['criteriaGroups'] as List?) ?? const [];
    final allCriteria = <Map<String, dynamic>>[];
    for (final g in groups.whereType<Map>()) {
      for (final c in ((g['criteria'] as List?) ?? const []).whereType<Map>()) {
        allCriteria.add(Map<String, dynamic>.from(c));
      }
    }

    if (!isDraft) {
      for (final c in allCriteria) {
        final id = c['id']?.toString();
        if (id == null) continue;
        final v = _scores[id];
        final maxScore = (c['maxScore'] as num?)?.toInt() ?? 0;
        if (v == null || v < 0 || v > maxScore) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nilai "${c['name']}" harus 0–$maxScore.'),
              backgroundColor: AppColors.destructive,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    setState(() => _submittingMode = isDraft ? 'draft' : 'submit');
    try {
      final scoresPayload = _scores.entries
          .map((e) => {'assessmentCriteriaId': e.key, 'score': e.value})
          .toList();
      await _api.submitDefenceAssessment(
        widget.defenceId,
        scores: scoresPayload,
        revisionNotes:
            _assessorRole == 'examiner' ? _notesCtrl.text.trim() : null,
        supervisorNotes:
            _assessorRole == 'supervisor' ? _notesCtrl.text.trim() : null,
        isDraft: isDraft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft
              ? 'Draf penilaian berhasil disimpan.'
              : 'Penilaian berhasil dikirim.'),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetch();
      await widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingMode = null);
    }
  }

  Future<void> _finalize() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tetapkan Hasil Sidang?'),
        content: const Text(
          'Tindakan ini akan menetapkan hasil akhir sidang secara '
          'permanen dan tidak dapat diubah lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Tetapkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _finalizing = true);
    try {
      await _api.finalizeDefence(
        widget.defenceId,
        recommendRevision: _recommendRevision,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil sidang berhasil ditetapkan.'),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetch();
      await widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menetapkan hasil: $e'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _finalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((_isUserExaminer || _isUserSupervisor) &&
                !_isFinalized &&
                _form != null)
              _buildAssessmentForm(),
            if ((_isUserExaminer || _isUserSupervisor) &&
                !_isFinalized &&
                _form != null)
              const SizedBox(height: AppSpacing.base),
            _buildRekap(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─── Assessment form (examiner or supervisor) ────────────────

  Widget _buildAssessmentForm() {
    final form = _form!;
    final isSubmitted = _isAssessmentSubmitted;
    final groups = ((form['criteriaGroups'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final seen = <String>{};
    final uniqueGroups = <Map<String, dynamic>>[];
    for (final g in groups) {
      final code = (g['code'] ?? '').toString();
      if (!seen.contains(code)) {
        seen.add(code);
        uniqueGroups.add(g);
      }
    }

    final totalMax = uniqueGroups.fold<int>(0, (sum, g) {
      final cs = ((g['criteria'] as List?) ?? const []).whereType<Map>();
      return sum +
          cs.fold<int>(0, (s, c) => s + ((c['maxScore'] as num?)?.toInt() ?? 0));
    });
    final totalScore = _scores.values.fold<int>(0, (s, v) => s + v);
    final roleLabel =
        _assessorRole == 'supervisor' ? 'Pembimbing' : 'Penguji';
    final notesLabel = _assessorRole == 'supervisor'
        ? 'Catatan Pembimbing'
        : 'Catatan Penguji';

    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Form Penilaian ($roleLabel)',
                    style: AppTextStyles.label,
                  ),
                ),
                AppBadge(
                  label: isSubmitted ? 'Sudah Submit' : 'Draf / Belum',
                  variant: isSubmitted
                      ? BadgeVariant.success
                      : BadgeVariant.warning,
                ),
              ],
            ),
          ),
          for (final group in uniqueGroups)
            _buildGroupSection(group, isSubmitted),
          // Notes field
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notesLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (isSubmitted)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _notesCtrl.text.trim().isEmpty
                          ? 'Tidak ada catatan.'
                          : _notesCtrl.text,
                      style: AppTextStyles.bodySmall,
                    ),
                  )
                else
                  TextField(
                    controller: _notesCtrl,
                    enabled: _submittingMode == null,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan catatan evaluasi…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Total + action buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total Skor',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      Text(
                        '$totalScore',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ' / $totalMax',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSubmitted) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submittingMode != null
                              ? null
                              : () => _submitAssessment(isDraft: true),
                          icon: _submittingMode == 'draft'
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Simpan Draf'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submittingMode != null
                              ? null
                              : () => _confirmAndSubmit(),
                          icon: _submittingMode == 'submit'
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Penilaian?'),
        content: const Text(
          'Tindakan ini akan mengunci seluruh penilaian Anda. '
          'Nilai yang telah disubmit tidak dapat diubah lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _submitAssessment(isDraft: false);
    }
  }

  Widget _buildGroupSection(Map<String, dynamic> group, bool isSubmitted) {
    final criteria = ((group['criteria'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final groupMax = criteria.fold<int>(
        0, (s, c) => s + ((c['maxScore'] as num?)?.toInt() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.surfaceSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (group['code'] ?? '').toString(),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'maks. $groupMax',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              if ((group['description'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    (group['description']).toString(),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        for (final c in criteria) _buildCriterionRow(c, isSubmitted),
      ],
    );
  }

  Widget _buildCriterionRow(Map<String, dynamic> c, bool isSubmitted) {
    final id = c['id']?.toString();
    if (id == null) return const SizedBox.shrink();
    final maxScore = (c['maxScore'] as num?)?.toInt() ?? 0;
    final name = (c['name'] ?? '-').toString();
    final score = _scores[id] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(name, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
              enabled: !isSubmitted && _submittingMode == null,
              controller: TextEditingController(text: score.toString())
                ..selection = TextSelection.collapsed(
                    offset: score.toString().length),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: (v) {
                final n = int.tryParse(v) ?? 0;
                setState(() => _scores[id] = n.clamp(0, maxScore));
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                suffix: Text('/ $maxScore',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Rekap section ───────────────────────────────────────────

  Widget _buildRekap() {
    final data = _finalData;
    if (data == null) return const SizedBox.shrink();

    final examiners = ((data['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final supervisorAssessment = data['supervisorAssessment'] is Map
        ? Map<String, dynamic>.from(data['supervisorAssessment'] as Map)
        : <String, dynamic>{};
    final defence = data['defence'] is Map
        ? Map<String, dynamic>.from(data['defence'] as Map)
        : <String, dynamic>{};
    final isResultFinalized =
        (defence['resultFinalizedAt'] ?? '').toString().isNotEmpty;
    final examinerAvg = (data['examinerAverageScore'] as num?)?.toDouble();
    final supervisorScore =
        (supervisorAssessment['assessmentScore'] as num?)?.toDouble();
    final finalScore = (defence['finalScore'] as num?)?.toDouble();
    final grade = (defence['grade'] ?? '').toString();
    final canFinalize =
        data['recommendationUnlocked'] == true && _isUserSupervisor && !isResultFinalized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assessment_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Rekap Penilaian',
                          style: AppTextStyles.label),
                    ),
                  ],
                ),
              ),
              if (examiners.isEmpty && supervisorAssessment.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Belum ada data penilaian.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else ...[
                for (final ex in examiners)
                  _ExaminerSummaryCard(examiner: ex),
                _SupervisorSummaryCard(
                  supervisorAssessment: supervisorAssessment,
                  supervisorName:
                      (data['supervisor']?['name'] ?? '-').toString(),
                ),
              ],
              if (examinerAvg != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rata-rata Penguji (70%)',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary)),
                            Text(
                              examinerAvg.toStringAsFixed(2),
                              style: AppTextStyles.label.copyWith(
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (supervisorScore != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Skor Pembimbing (30%)',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary)),
                              Text(
                                supervisorScore.toStringAsFixed(2),
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (finalScore != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Nilai Akhir',
                            style: AppTextStyles.label),
                      ),
                      if (grade.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grade,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        finalScore.toStringAsFixed(2),
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: finalScore >= 55
                              ? AppColors.successDark
                              : AppColors.destructive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppBadge(
                        label: finalScore >= 55 ? 'LULUS' : 'TIDAK LULUS',
                        variant: finalScore >= 55
                            ? BadgeVariant.success
                            : BadgeVariant.destructive,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canFinalize) ...[
          const SizedBox(height: AppSpacing.base),
          _buildFinalizationCard(finalScore),
        ],
        if (isResultFinalized) ...[
          const SizedBox(height: AppSpacing.base),
          _buildFinalizedCard(defence),
        ],
        if (!isResultFinalized &&
            data['recommendationUnlocked'] != true &&
            (_isUserSupervisor || _isUserExaminer)) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Penetapan hasil akan terbuka setelah seluruh penguji dan '
              'pembimbing menyelesaikan penilaian.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.warningDark),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinalizationCard(double? avgScore) {
    final isPass = (avgScore ?? 0) >= 55;
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Status Kelulusan Otomatis',
                    style: AppTextStyles.label),
              ),
              AppBadge(
                label: isPass ? 'LULUS' : 'TIDAK LULUS',
                variant: isPass
                    ? BadgeVariant.success
                    : BadgeVariant.destructive,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Berdasarkan akumulasi nilai penguji (70%) dan pembimbing (30%).',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          if (isPass) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _recommendRevision,
                  onChanged: _finalizing
                      ? null
                      : (v) =>
                          setState(() => _recommendRevision = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Lulus dengan Revisi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 4),
              child: Text(
                'Mahasiswa wajib melakukan revisi sebelum yudisium.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nilai akhir di bawah 55. Mahasiswa dinyatakan Tidak Lulus.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.destructiveDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finalizing ? null : _finalize,
              icon: _finalizing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.gavel_rounded, size: 18),
              label: const Text('Tetapkan Hasil Sidang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizedCard(Map defence) {
    final status = (defence['status'] ?? '').toString();
    final by = defence['resultFinalizedBy']?.toString();
    final at = defence['resultFinalizedAt']?.toString();
    final grade = (defence['grade'] ?? '').toString();
    String label;
    BadgeVariant variant;
    switch (status) {
      case 'passed':
        label = 'Lulus';
        variant = BadgeVariant.success;
        break;
      case 'passed_with_revision':
        label = 'Lulus + Revisi';
        variant = BadgeVariant.success;
        break;
      case 'failed':
        label = 'Tidak Lulus';
        variant = BadgeVariant.destructive;
        break;
      default:
        label = status;
        variant = BadgeVariant.secondary;
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Hasil Sidang', style: AppTextStyles.label)),
              if (grade.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Grade $grade',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              AppBadge(label: label, variant: variant),
            ],
          ),
          if (at != null && at.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Difinalisasi pada ${_formatDateTime(at)}'
              '${by != null && by.isNotEmpty ? ' oleh $by' : ''}.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}.'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _ExaminerSummaryCard extends StatelessWidget {
  final Map<String, dynamic> examiner;
  const _ExaminerSummaryCard({required this.examiner});

  @override
  Widget build(BuildContext context) {
    final order = examiner['order'];
    final name = (examiner['lecturerName'] ?? '-').toString();
    final submittedAt =
        (examiner['assessmentSubmittedAt'] ?? '').toString();
    final score = examiner['assessmentScore'];
    final notes = (examiner['revisionNotes'] ?? '').toString();
    final isSubmitted = submittedAt.isNotEmpty;
    final isDraft = !isSubmitted && score != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penguji $order', style: AppTextStyles.label),
                    Text(
                      name,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: isSubmitted
                    ? 'Sudah Submit'
                    : isDraft
                        ? 'Draf'
                        : 'Belum Isi',
                variant: isSubmitted
                    ? BadgeVariant.success
                    : isDraft
                        ? BadgeVariant.warning
                        : BadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.score_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Nilai: ',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              Text(
                score == null ? '-' : score.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Catatan: $notes',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupervisorSummaryCard extends StatelessWidget {
  final Map<String, dynamic> supervisorAssessment;
  final String supervisorName;
  const _SupervisorSummaryCard({
    required this.supervisorAssessment,
    required this.supervisorName,
  });

  @override
  Widget build(BuildContext context) {
    final submittedAt =
        (supervisorAssessment['assessmentSubmittedAt'] ?? '').toString();
    final score = supervisorAssessment['assessmentScore'];
    final notes =
        (supervisorAssessment['supervisorNotes'] ?? '').toString();
    final isSubmitted = submittedAt.isNotEmpty;
    final isDraft = !isSubmitted && score != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pembimbing', style: AppTextStyles.label),
                    Text(
                      supervisorName,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: isSubmitted
                    ? 'Sudah Submit'
                    : isDraft
                        ? 'Draf'
                        : 'Belum Isi',
                variant: isSubmitted
                    ? BadgeVariant.success
                    : isDraft
                        ? BadgeVariant.warning
                        : BadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.score_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Nilai (30%): ',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              Text(
                score == null ? '-' : score.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Catatan: $notes',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.destructive),
            const SizedBox(height: 12),
            Text('Gagal memuat data',
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
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
