import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../thesis_shared/data/models/revision_models.dart';
import '../../data/models/seminar_models.dart';

class SeminarRevisionPanel extends StatefulWidget {
  final String seminarId;
  final SeminarDetail detail;
  final UserModel? user;
  final Future<void> Function() onRefresh;

  const SeminarRevisionPanel({
    super.key,
    required this.seminarId,
    required this.detail,
    required this.user,
    required this.onRefresh,
  });

  @override
  State<SeminarRevisionPanel> createState() => _SeminarRevisionPanelState();
}

class _SeminarRevisionPanelState extends State<SeminarRevisionPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  RevisionBoard? _board;
  bool _isLoading = true;
  String? _error;
  String? _busyRevisionId;
  bool _busyFinalization = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isPresenter {
    final studentId = widget.user?.student?.id;
    return (studentId != null && widget.detail.student.id == studentId) ||
        widget.user?.identityNumber == widget.detail.student.nim;
  }

  bool get _isSupervisor {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        widget.detail.supervisors.any((item) => item.lecturerId == lecturerId);
  }

  bool get _isFinalized => widget.detail.revisionFinalizedAt != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final board = await _api.getRevisions(widget.seminarId);
      if (!mounted) return;
      setState(() => _board = board);
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runRevisionAction(
    RevisionItem revision,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyRevisionId = revision.id);
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage, AppColors.successDark);
      await _load();
    } catch (exception) {
      if (mounted) {
        _showMessage('Tindakan gagal: $exception', AppColors.destructive);
      }
    } finally {
      if (mounted) setState(() => _busyRevisionId = null);
    }
  }

  Future<void> _editAction(RevisionItem revision) async {
    final controller = TextEditingController(text: revision.revisionAction);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Isi Perbaikan'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 7,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Jelaskan perbaikan yang telah dilakukan…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _runRevisionAction(
      revision,
      () => _api.updateRevision(
        widget.seminarId,
        revision.id,
        action: SeminarRevisionAction.saveAction,
        revisionAction: value,
      ),
      'Perbaikan berhasil disimpan.',
    );
  }

  Future<void> _submit(RevisionItem revision) async {
    await _runRevisionAction(
      revision,
      () => _api.updateRevision(
        widget.seminarId,
        revision.id,
        action: SeminarRevisionAction.submit,
      ),
      'Perbaikan berhasil diajukan kepada pembimbing.',
    );
  }

  Future<void> _cancelSubmit(RevisionItem revision) async {
    await _runRevisionAction(
      revision,
      () => _api.updateRevision(
        widget.seminarId,
        revision.id,
        action: SeminarRevisionAction.cancelSubmit,
      ),
      'Pengajuan perbaikan berhasil dibatalkan.',
    );
  }

  Future<void> _toggleApproval(RevisionItem revision) async {
    await _runRevisionAction(
      revision,
      () => _api.updateRevision(
        widget.seminarId,
        revision.id,
        action: revision.isFinished
            ? SeminarRevisionAction.unapprove
            : SeminarRevisionAction.approve,
      ),
      revision.isFinished
          ? 'Persetujuan revisi dibatalkan.'
          : 'Revisi berhasil disetujui.',
    );
  }

  Future<void> _delete(RevisionItem revision) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Item Revisi?'),
        content: const Text('Item yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runRevisionAction(
      revision,
      () => _api.deleteRevision(widget.seminarId, revision.id),
      'Item revisi berhasil dihapus.',
    );
  }

  Future<void> _create() async {
    if (widget.detail.examiners.isEmpty) {
      _showMessage('Data penguji tidak tersedia.', AppColors.destructive);
      return;
    }
    final draft = await showDialog<_RevisionDraft>(
      context: context,
      builder: (_) => _CreateRevisionDialog(examiners: widget.detail.examiners),
    );
    if (draft == null) return;
    setState(() => _busyRevisionId = 'new');
    try {
      await _api.createRevision(
        widget.seminarId,
        seminarExaminerId: draft.examinerId,
        description: draft.description,
        revisionAction: draft.action,
      );
      if (!mounted) return;
      _showMessage('Item revisi berhasil ditambahkan.', AppColors.successDark);
      await _load();
    } catch (exception) {
      if (mounted) {
        _showMessage(
          'Gagal menambah revisi: $exception',
          AppColors.destructive,
        );
      }
    } finally {
      if (mounted) setState(() => _busyRevisionId = null);
    }
  }

  Future<void> _toggleFinalization() async {
    final finalize = !_isFinalized;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          finalize ? 'Finalisasi Revisi?' : 'Buka Finalisasi Revisi?',
        ),
        content: Text(
          finalize
              ? 'Seluruh revisi akan dinyatakan selesai.'
              : 'Finalisasi dibuka kembali agar persetujuan dapat diubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(finalize ? 'Finalisasi' : 'Buka Kembali'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyFinalization = true);
    try {
      if (finalize) {
        await _api.finalizeRevisions(widget.seminarId);
      } else {
        await _api.unfinalizeRevisions(widget.seminarId);
      }
      if (!mounted) return;
      _showMessage(
        finalize
            ? 'Seluruh revisi berhasil difinalisasi.'
            : 'Finalisasi revisi berhasil dibuka kembali.',
        AppColors.successDark,
      );
      await widget.onRefresh();
    } catch (exception) {
      if (mounted) {
        _showMessage('Tindakan gagal: $exception', AppColors.destructive);
      }
    } finally {
      if (mounted) setState(() => _busyFinalization = false);
    }
  }

  void _showMessage(String message, Color color) {
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
    final board = _board;
    if (board == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _SummaryCard(board: board, finalized: _isFinalized),
          const SizedBox(height: AppSpacing.base),
          if (board.revisions.isEmpty)
            const _EmptyRevisions()
          else
            for (final revision in board.revisions) ...[
              _RevisionCard(
                revision: revision,
                isPresenter: _isPresenter,
                isSupervisor: _isSupervisor,
                finalized: _isFinalized,
                busy: _busyRevisionId == revision.id,
                onEdit: () => _editAction(revision),
                onSubmit: () => _submit(revision),
                onCancelSubmit: () => _cancelSubmit(revision),
                onToggleApproval: () => _toggleApproval(revision),
                onDelete: () => _delete(revision),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (_isPresenter && !_isFinalized) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _busyRevisionId == null ? _create : null,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Item Revisi'),
            ),
          ],
          if (_isSupervisor &&
              (_isFinalized ||
                  (board.total > 0 && board.finished == board.total))) ...[
            const SizedBox(height: AppSpacing.base),
            FilledButton.icon(
              onPressed: _busyFinalization ? null : _toggleFinalization,
              icon: Icon(
                _isFinalized ? Icons.lock_open_outlined : Icons.verified,
              ),
              label: Text(
                _isFinalized ? 'Buka Kembali Finalisasi' : 'Finalisasi Revisi',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final RevisionBoard board;
  final bool finalized;

  const _SummaryCard({required this.board, required this.finalized});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Progres Revisi', style: AppTextStyles.h4)),
              AppBadge(
                label: finalized
                    ? 'Difinalisasi'
                    : '${board.finished}/${board.total}',
                variant: finalized
                    ? BadgeVariant.success
                    : BadgeVariant.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: board.total == 0 ? 0 : board.finished / board.total,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            '${board.pendingApproval} item menunggu persetujuan pembimbing',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  final RevisionItem revision;
  final bool isPresenter;
  final bool isSupervisor;
  final bool finalized;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onCancelSubmit;
  final VoidCallback onToggleApproval;
  final VoidCallback onDelete;

  const _RevisionCard({
    required this.revision,
    required this.isPresenter,
    required this.isSupervisor,
    required this.finalized,
    required this.busy,
    required this.onEdit,
    required this.onSubmit,
    required this.onCancelSubmit,
    required this.onToggleApproval,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = revision.studentSubmittedAt != null;
    final canEdit =
        isPresenter && !submitted && !revision.isFinished && !finalized;
    final canApprove = isSupervisor && submitted && !finalized;
    return AppCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Penguji ${revision.examinerOrder ?? '-'} • ${revision.examinerName ?? '-'}',
                  style: AppTextStyles.label,
                ),
              ),
              AppBadge(
                label: revision.isFinished
                    ? 'Disetujui'
                    : submitted
                    ? 'Diajukan'
                    : revision.revisionAction?.isNotEmpty == true
                    ? 'Draft'
                    : 'Belum Dikerjakan',
                variant: revision.isFinished
                    ? BadgeVariant.success
                    : submitted
                    ? BadgeVariant.warning
                    : BadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Catatan Penguji', style: AppTextStyles.caption),
          Text(revision.description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 10),
          Text('Perbaikan Mahasiswa', style: AppTextStyles.caption),
          Text(
            revision.revisionAction?.isNotEmpty == true
                ? revision.revisionAction!
                : 'Belum diisi.',
            style: AppTextStyles.bodySmall.copyWith(
              color: revision.revisionAction?.isNotEmpty == true
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
          ),
          if (revision.approvedBySupervisorName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Disetujui oleh ${revision.approvedBySupervisorName}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.successDark,
              ),
            ),
          ],
          if (canEdit ||
              (isPresenter && submitted && !finalized) ||
              canApprove) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Isi/Edit'),
                  ),
                if (canEdit && revision.revisionAction?.isNotEmpty == true)
                  FilledButton.icon(
                    onPressed: busy ? null : onSubmit,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Ajukan'),
                  ),
                if (canEdit)
                  IconButton(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.destructive,
                    tooltip: 'Hapus item',
                  ),
                if (isPresenter &&
                    submitted &&
                    !revision.isFinished &&
                    !finalized)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onCancelSubmit,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Batalkan Pengajuan'),
                  ),
                if (canApprove)
                  FilledButton.icon(
                    onPressed: busy ? null : onToggleApproval,
                    icon: Icon(
                      revision.isFinished
                          ? Icons.undo
                          : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      revision.isFinished ? 'Batalkan Persetujuan' : 'Setujui',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RevisionDraft {
  final String examinerId;
  final String description;
  final String action;

  const _RevisionDraft({
    required this.examinerId,
    required this.description,
    required this.action,
  });
}

class _CreateRevisionDialog extends StatefulWidget {
  final List<SeminarExaminer> examiners;

  const _CreateRevisionDialog({required this.examiners});

  @override
  State<_CreateRevisionDialog> createState() => _CreateRevisionDialogState();
}

class _CreateRevisionDialogState extends State<_CreateRevisionDialog> {
  late String _examinerId;
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _examinerId = widget.examiners.first.id;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Item Revisi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _examinerId,
              items: widget.examiners
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text('Penguji ${item.order}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _examinerId = value ?? _examinerId,
              decoration: const InputDecoration(labelText: 'Penguji'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Catatan revisi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actionController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Perbaikan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final description = _descriptionController.text.trim();
            if (description.isEmpty) return;
            Navigator.pop(
              context,
              _RevisionDraft(
                examinerId: _examinerId,
                description: description,
                action: _actionController.text.trim(),
              ),
            );
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

class _EmptyRevisions extends StatelessWidget {
  const _EmptyRevisions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.task_alt, size: 52, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text('Belum ada item revisi.', style: AppTextStyles.bodySmall),
        ],
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
