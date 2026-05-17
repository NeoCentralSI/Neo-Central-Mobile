import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/defence_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Revisi panel — used by both supervisor and presenter (student).
///
/// • Supervisor: approve / unapprove submitted revisions, finalize the board.
/// • Presenter: create, edit, submit, cancel-submit, delete own items. Also
///   sees the auto-generated examiner-notes section at the top.
///
/// Mirrors `website/src/components/thesis-defence/ThesisDefenceDetailRevisionPanel.tsx`.
class DefenceRevisionPanel extends StatefulWidget {
  final String defenceId;
  final Map<String, dynamic> detail;
  final UserModel? user;
  final Future<void> Function() onRefresh;

  const DefenceRevisionPanel({
    super.key,
    required this.defenceId,
    required this.detail,
    required this.onRefresh,
    this.user,
  });

  @override
  State<DefenceRevisionPanel> createState() => _DefenceRevisionPanelState();
}

class _DefenceRevisionPanelState extends State<DefenceRevisionPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = DefenceApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _board = const {};
  String? _busyId;
  bool _busyFinalize = false;
  bool _busyCreate = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  bool get _isSupervisor {
    final lecturerId = widget.user?.lecturer?.id;
    if (lecturerId == null) return false;
    final supervisors = (widget.detail['supervisors'] as List?) ?? const [];
    return supervisors
        .whereType<Map>()
        .any((s) => s['lecturerId'] == lecturerId);
  }

  bool get _isPresenter {
    final myNim = widget.user?.identityNumber;
    final detailStudent = widget.detail['student'];
    if (myNim != null && detailStudent is Map && detailStudent['nim'] == myNim) {
      return true;
    }
    final studentId = widget.user?.student?.id;
    if (studentId != null &&
        detailStudent is Map &&
        detailStudent['id'] == studentId) {
      return true;
    }
    return false;
  }

  bool get _isFinalized {
    final revisionFinalizedAt =
        (widget.detail['revisionFinalizedAt'] ?? '').toString();
    if (revisionFinalizedAt.isNotEmpty) return true;
    return _board['isFinalized'] == true;
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final board = await _api.getDefenceRevisions(widget.defenceId);
      if (!mounted) return;
      setState(() {
        _board = board;
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

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runRowAction(
    String revisionId,
    Future<void> Function() block, {
    String? successMsg,
  }) async {
    setState(() => _busyId = revisionId);
    try {
      await block();
      if (successMsg != null) _toast(successMsg);
      await _fetch();
      await widget.onRefresh();
    } catch (e) {
      _toast('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // ─── Supervisor actions ────────────────────────────────────────

  Future<void> _toggleApproval(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final isFinished = row['isFinished'] == true;
    if (isFinished) {
      final confirmed = await _confirm(
        title: 'Batalkan Persetujuan?',
        body: 'Status item revisi ini akan kembali menjadi "Diajukan".',
      );
      if (confirmed != true) return;
    }
    await _runRowAction(
      id,
      () => _api.updateDefenceRevision(
        widget.defenceId,
        id,
        action: isFinished ? 'unapprove' : 'approve',
      ),
      successMsg: isFinished
          ? 'Persetujuan revisi dibatalkan.'
          : 'Revisi disetujui.',
    );
  }

  // ─── Student actions ───────────────────────────────────────────

  Future<void> _submitRevision(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Ajukan Perbaikan?',
      body: 'Perbaikan akan menunggu persetujuan pembimbing.',
    );
    if (confirmed != true) return;
    await _runRowAction(
      id,
      () => _api.updateDefenceRevision(widget.defenceId, id, action: 'submit'),
      successMsg: 'Perbaikan berhasil diajukan.',
    );
  }

  Future<void> _cancelSubmit(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Batalkan Pengajuan?',
      body: 'Status akan kembali menjadi "Diproses" dan Anda dapat '
          'mengeditnya kembali.',
    );
    if (confirmed != true) return;
    await _runRowAction(
      id,
      () => _api.updateDefenceRevision(
        widget.defenceId,
        id,
        action: 'cancel_submit',
      ),
      successMsg: 'Pengajuan dibatalkan.',
    );
  }

  Future<void> _deleteRevision(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Hapus Item Revisi?',
      body: 'Data akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (confirmed != true) return;
    await _runRowAction(
      id,
      () => _api.deleteDefenceRevision(widget.defenceId, id),
      successMsg: 'Item revisi dihapus.',
    );
  }

  Future<void> _editRevision(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final result = await _showRevisionForm(
      title: 'Edit Revisi',
      initialDescription: (row['description'] ?? '').toString(),
      initialAction: (row['revisionAction'] ?? '').toString(),
    );
    if (result == null) return;
    await _runRowAction(
      id,
      () => _api.updateDefenceRevision(
        widget.defenceId,
        id,
        action: 'save_action',
        description: result.description,
        revisionAction: result.revisionAction,
      ),
      successMsg: 'Perubahan disimpan.',
    );
  }

  Future<void> _createRevision() async {
    final examiners = ((widget.detail['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    if (examiners.isEmpty) {
      _toast('Belum ada penguji untuk sidang ini.', isError: true);
      return;
    }
    final result = await _showCreateRevisionDialog(examiners);
    if (result == null) return;
    setState(() => _busyCreate = true);
    try {
      await _api.createDefenceRevision(
        widget.defenceId,
        defenceExaminerId: result.examinerId,
        description: result.description,
        revisionAction: result.revisionAction,
      );
      _toast('Item revisi berhasil dibuat.');
      await _fetch();
      await widget.onRefresh();
    } catch (e) {
      _toast('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyCreate = false);
    }
  }

  // ─── Supervisor finalize ───────────────────────────────────────

  Future<void> _finalize({required bool finalize}) async {
    final confirmed = await _confirm(
      title: finalize ? 'Finalisasi Revisi?' : 'Batal Finalisasi Revisi?',
      body: finalize
          ? 'Menandai seluruh revisi selesai dan siap untuk yudisium.'
          : 'Anda akan dapat mengubah status persetujuan item revisi kembali.',
      confirmLabel: finalize ? 'Ya, Finalisasi' : 'Ya, Batalkan',
    );
    if (confirmed != true) return;

    setState(() => _busyFinalize = true);
    try {
      if (finalize) {
        await _api.finalizeDefenceRevisions(widget.defenceId);
      } else {
        await _api.unfinalizeDefenceRevisions(widget.defenceId);
      }
      _toast(finalize
          ? 'Revisi berhasil difinalisasi.'
          : 'Finalisasi revisi dibatalkan.');
      await _fetch();
      await widget.onRefresh();
    } catch (e) {
      _toast('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyFinalize = false);
    }
  }

  // ─── Confirm + form dialogs ────────────────────────────────────

  Future<bool?> _confirm({
    required String title,
    required String body,
    String confirmLabel = 'Ya, Lanjutkan',
    bool destructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: destructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<_RevisionFormResult?> _showRevisionForm({
    required String title,
    required String initialDescription,
    required String initialAction,
  }) async {
    final descCtrl = TextEditingController(text: initialDescription);
    final actCtrl = TextEditingController(text: initialAction);
    final result = await showDialog<_RevisionFormResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catatan Revisi',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: descCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: _inputDeco('Tuliskan catatan revisi…'),
              ),
              const SizedBox(height: 12),
              Text(
                'Perbaikan Yang Dilakukan',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: actCtrl,
                minLines: 2,
                maxLines: 5,
                decoration:
                    _inputDeco('Isi perbaikan yang dilakukan (opsional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final d = descCtrl.text.trim();
              if (d.isEmpty) return;
              Navigator.of(context).pop(_RevisionFormResult(
                description: d,
                revisionAction: actCtrl.text.trim(),
              ));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    descCtrl.dispose();
    actCtrl.dispose();
    return result;
  }

  Future<_CreateFormResult?> _showCreateRevisionDialog(
    List<Map<String, dynamic>> examiners,
  ) async {
    String? selectedId = examiners.first['id']?.toString();
    final descCtrl = TextEditingController();
    final actCtrl = TextEditingController();
    final result = await showDialog<_CreateFormResult>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tambah Item Revisi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dosen Penguji',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  isExpanded: true,
                  decoration: _inputDeco(null),
                  items: [
                    for (final e in examiners)
                      DropdownMenuItem(
                        value: e['id']?.toString(),
                        child: Text(
                          'Penguji ${e['order']} - ${(e['lecturerName'] ?? '-').toString()}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setSt(() => selectedId = v),
                ),
                const SizedBox(height: 12),
                Text(
                  'Catatan Revisi',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _inputDeco('Tuliskan catatan revisi…'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Perbaikan Yang Dilakukan',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: actCtrl,
                  minLines: 2,
                  maxLines: 5,
                  decoration:
                      _inputDeco('Isi perbaikan yang dilakukan (opsional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final id = selectedId;
                final d = descCtrl.text.trim();
                if (id == null || d.isEmpty) return;
                Navigator.of(ctx).pop(_CreateFormResult(
                  examinerId: id,
                  description: d,
                  revisionAction: actCtrl.text.trim(),
                ));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    descCtrl.dispose();
    actCtrl.dispose();
    return result;
  }

  InputDecoration _inputDeco(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      );

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }

    final allRevisions = ((_board['revisions'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final visible = (_isPresenter
            ? allRevisions
            : allRevisions
                .where((r) =>
                    r['studentSubmittedAt'] != null || r['isFinished'] == true)
                .toList())
      ..sort((a, b) => (a['examinerOrder'] as num? ?? 0)
          .compareTo(b['examinerOrder'] as num? ?? 0));

    final summary = (_board['summary'] as Map?) ?? const {};
    final total = (summary['total'] as num?)?.toInt() ?? allRevisions.length;
    final finished = (summary['finished'] as num?)?.toInt() ??
        allRevisions.where((r) => r['isFinished'] == true).length;
    final hasSubmitted = allRevisions.any(
        (r) => r['studentSubmittedAt'] != null || r['isFinished'] == true);
    final allApproved = allRevisions.every(
        (r) => r['studentSubmittedAt'] == null || r['isFinished'] == true);
    final canFinalize = !_isFinalized &&
        allRevisions.isNotEmpty &&
        hasSubmitted &&
        allApproved;

    final examinerNotes = ((widget.detail['examinerNotes'] as List?) ??
            const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (_isPresenter && examinerNotes.isNotEmpty) ...[
            _ExaminerNotesSection(notes: examinerNotes),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_isPresenter && !_isFinalized && allRevisions.isNotEmpty) ...[
            _PresenterInfoCard(),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildHeaderBar(total, finished, canFinalize),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: AppColors.textTertiary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isPresenter
                        ? 'Belum ada item revisi.'
                        : 'Belum ada revisi yang diajukan mahasiswa.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final row in visible) ...[
              _RevisionCard(
                row: row,
                isPresenter: _isPresenter,
                isSupervisor: _isSupervisor,
                isFinalized: _isFinalized,
                busy: _busyId == row['id']?.toString(),
                onSupervisorToggle: () => _toggleApproval(row),
                onEdit: () => _editRevision(row),
                onSubmit: () => _submitRevision(row),
                onCancelSubmit: () => _cancelSubmit(row),
                onDelete: () => _deleteRevision(row),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildHeaderBar(int total, int finished, bool canFinalize) {
    return Row(
      children: [
        AppBadge(
          label: '$finished / $total disetujui',
          variant: BadgeVariant.outline,
        ),
        const Spacer(),
        if (_isPresenter && !_isFinalized)
          OutlinedButton.icon(
            onPressed: _busyCreate ? null : _createRevision,
            icon: _busyCreate
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 16),
            label: const Text('Tambah'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        if (_isPresenter && _isSupervisor) const SizedBox(width: 8),
        if (_isSupervisor) ...[
          if (_isFinalized)
            OutlinedButton.icon(
              onPressed:
                  _busyFinalize ? null : () => _finalize(finalize: false),
              icon: _busyFinalize
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: const Text('Batalkan Finalisasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warningDark,
                side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: !canFinalize || _busyFinalize
                  ? null
                  : () => _finalize(finalize: true),
              icon: _busyFinalize
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Selesaikan Revisi'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canFinalize ? AppColors.primary : AppColors.surface,
                foregroundColor:
                    canFinalize ? Colors.white : AppColors.textTertiary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Helpers / model ─────────────────────────────────────────────

class _RevisionFormResult {
  final String description;
  final String revisionAction;
  _RevisionFormResult({
    required this.description,
    required this.revisionAction,
  });
}

class _CreateFormResult {
  final String examinerId;
  final String description;
  final String revisionAction;
  _CreateFormResult({
    required this.examinerId,
    required this.description,
    required this.revisionAction,
  });
}

class _PresenterInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Perbaikan',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daftar perbaikan di bawah dibuat otomatis dari catatan penguji. '
                  'Lengkapi kolom "Perbaikan" untuk setiap item, lalu ajukan agar '
                  'dapat diperiksa oleh pembimbing.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExaminerNotesSection extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  const _ExaminerNotesSection({required this.notes});

  @override
  State<_ExaminerNotesSection> createState() => _ExaminerNotesSectionState();
}

class _ExaminerNotesSectionState extends State<_ExaminerNotesSection> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.notes.length; i++) ...[
          _NoteCard(
            order: widget.notes[i]['examinerOrder'],
            name: (widget.notes[i]['lecturerName'] ?? '-').toString(),
            notes: (widget.notes[i]['revisionNotes'] ?? '').toString(),
            isExpanded: _expanded.contains(i),
            onToggle: () => setState(() {
              if (_expanded.contains(i)) {
                _expanded.remove(i);
              } else {
                _expanded.add(i);
              }
            }),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final dynamic order;
  final String name;
  final String notes;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _NoteCard({
    required this.order,
    required this.name,
    required this.notes,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 12,
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan — Penguji $order ($name)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Text(
                notes.trim().isEmpty ? 'Tidak ada catatan.' : notes,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isPresenter;
  final bool isSupervisor;
  final bool isFinalized;
  final bool busy;
  final VoidCallback onSupervisorToggle;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onCancelSubmit;
  final VoidCallback onDelete;

  const _RevisionCard({
    required this.row,
    required this.isPresenter,
    required this.isSupervisor,
    required this.isFinalized,
    required this.busy,
    required this.onSupervisorToggle,
    required this.onEdit,
    required this.onSubmit,
    required this.onCancelSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final order = row['examinerOrder'];
    final name = (row['examinerName'] ?? '-').toString();
    final description = (row['description'] ?? '-').toString();
    final action = (row['revisionAction'] ?? '').toString();
    final isFinished = row['isFinished'] == true;
    final isSubmitted = row['studentSubmittedAt'] != null;

    final (label, variant) = _statusOf(isFinished, isSubmitted);

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 14,
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
              AppBadge(label: label, variant: variant),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Catatan',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'Perbaikan',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.isEmpty ? '-' : action,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle:
                  action.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          if (_buildActionRow(action) != null) ...[
            const SizedBox(height: 10),
            _buildActionRow(action)!,
          ],
        ],
      ),
    );
  }

  Widget? _buildActionRow(String action) {
    final children = <Widget>[];

    if (isPresenter && !isFinalized) {
      final isFinished = row['isFinished'] == true;
      final isSubmitted = row['studentSubmittedAt'] != null;
      if (!isFinished) {
        if (!isSubmitted) {
          children.add(_iconAction(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onTap: onEdit,
            color: AppColors.primaryDark,
          ));
          if (action.isNotEmpty) {
            children.add(_iconAction(
              icon: Icons.send_rounded,
              tooltip: 'Ajukan',
              onTap: onSubmit,
              color: AppColors.primaryDark,
            ));
          }
          children.add(_iconAction(
            icon: Icons.delete_outline,
            tooltip: 'Hapus',
            onTap: onDelete,
            color: AppColors.destructiveDark,
          ));
        } else {
          children.add(_iconAction(
            icon: Icons.undo,
            tooltip: 'Batalkan Pengajuan',
            onTap: onCancelSubmit,
            color: AppColors.warningDark,
          ));
        }
      }
    }

    if (isSupervisor && !isFinalized) {
      final isFinished = row['isFinished'] == true;
      final isSubmitted = row['studentSubmittedAt'] != null;
      if (isSubmitted && !isFinished) {
        children.add(_supervisorToggle(isApproved: false));
      } else if (isFinished) {
        children.add(_supervisorToggle(isApproved: true));
      }
    }

    if (children.isEmpty) return null;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: busy ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 16),
        ),
      ),
    );
  }

  Widget _supervisorToggle({required bool isApproved}) {
    final color =
        isApproved ? AppColors.warningDark : AppColors.successDark;
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onSupervisorToggle,
        icon: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                isApproved ? Icons.refresh : Icons.check_rounded,
                size: 14,
                color: color,
              ),
        label: Text(
          isApproved ? 'Batalkan Persetujuan' : 'Setujui',
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static (String, BadgeVariant) _statusOf(bool isFinished, bool isSubmitted) {
    if (isFinished) return ('Disetujui', BadgeVariant.success);
    if (isSubmitted) return ('Diajukan', BadgeVariant.primary);
    return ('Diproses', BadgeVariant.warning);
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
