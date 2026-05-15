import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/defence_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Revisi panel — supervisor view of revision items for Sidang TA.
///
/// Mobile scope: supervisor can approve / unapprove submitted revisions
/// and finalize / unfinalize the board.
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

  Future<void> _toggleApproval(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null) return;
    final isFinished = row['isFinished'] == true;
    setState(() => _busyId = id);
    try {
      await _api.updateDefenceRevision(
        widget.defenceId,
        id,
        action: isFinished ? 'unapprove' : 'approve',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFinished
              ? 'Persetujuan revisi dibatalkan.'
              : 'Revisi disetujui.'),
          backgroundColor:
              isFinished ? AppColors.textPrimary : AppColors.successDark,
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
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _finalize({required bool finalize}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(finalize
            ? 'Finalisasi Revisi?'
            : 'Batal Finalisasi Revisi?'),
        content: Text(finalize
            ? 'Menandai seluruh revisi selesai dan siap untuk yudisium.'
            : 'Anda akan dapat mengubah status persetujuan item revisi kembali.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(finalize ? 'Ya, Finalisasi' : 'Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyFinalize = true);
    try {
      if (finalize) {
        await _api.finalizeDefenceRevisions(widget.defenceId);
      } else {
        await _api.unfinalizeDefenceRevisions(widget.defenceId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finalize
              ? 'Revisi berhasil difinalisasi.'
              : 'Finalisasi revisi dibatalkan.'),
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
      if (mounted) setState(() => _busyFinalize = false);
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

    final allRevisions = ((_board['revisions'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final visible = allRevisions
        .where((r) =>
            r['studentSubmittedAt'] != null || r['isFinished'] == true)
        .toList()
      ..sort((a, b) =>
          (a['examinerOrder'] as num? ?? 0)
              .compareTo(b['examinerOrder'] as num? ?? 0));

    final summary = (_board['summary'] as Map?) ?? const {};
    final total = (summary['total'] as num?)?.toInt() ?? allRevisions.length;
    final finished = (summary['finished'] as num?)?.toInt() ??
        allRevisions.where((r) => r['isFinished'] == true).length;
    final hasSubmitted = allRevisions
        .any((r) => r['studentSubmittedAt'] != null || r['isFinished'] == true);
    final allApproved = allRevisions.every(
        (r) => r['studentSubmittedAt'] == null || r['isFinished'] == true);
    final canFinalize =
        !_isFinalized && allRevisions.isNotEmpty && hasSubmitted && allApproved;

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
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
                    'Belum ada revisi yang diajukan mahasiswa.',
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
                showSupervisorAction: _isSupervisor && !_isFinalized,
                isBusy: _busyId == row['id']?.toString(),
                onToggle: () => _toggleApproval(row),
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

class _RevisionCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool showSupervisorAction;
  final bool isBusy;
  final VoidCallback onToggle;

  const _RevisionCard({
    required this.row,
    required this.showSupervisorAction,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final order = row['examinerOrder'];
    final name = (row['examinerName'] ?? '-').toString();
    final description = (row['description'] ?? '-').toString();
    final action = (row['revisionAction'] ?? '').toString();
    final isFinished = row['isFinished'] == true;
    final submittedAt = row['studentSubmittedAt'];

    final (label, variant) = _statusOf(isFinished, submittedAt != null);

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
              fontStyle: action.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          if (showSupervisorAction) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _ToggleButton(
                isApproved: isFinished,
                isBusy: isBusy,
                onPressed: onToggle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static (String, BadgeVariant) _statusOf(
      bool isFinished, bool isSubmitted) {
    if (isFinished) return ('Disetujui', BadgeVariant.success);
    if (isSubmitted) return ('Diajukan', BadgeVariant.primary);
    return ('Diproses', BadgeVariant.warning);
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isApproved;
  final bool isBusy;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.isApproved,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isApproved ? AppColors.warningDark : AppColors.successDark;
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        icon: isBusy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
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
              borderRadius: BorderRadius.circular(10)),
        ),
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
