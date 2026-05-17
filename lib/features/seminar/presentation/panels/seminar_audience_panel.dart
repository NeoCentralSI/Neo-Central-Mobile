import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Peserta panel — audience list with supervisor approve/unapprove actions.
///
/// Mobile scope:
///   • Supervisor: can approve / unapprove audience presence.
///   • Examiner / HoD: read-only list.
class SeminarAudiencePanel extends StatefulWidget {
  final String seminarId;
  final Map<String, dynamic> detail;
  final UserModel? user;

  const SeminarAudiencePanel({
    super.key,
    required this.seminarId,
    required this.detail,
    this.user,
  });

  @override
  State<SeminarAudiencePanel> createState() => _SeminarAudiencePanelState();
}

class _SeminarAudiencePanelState extends State<SeminarAudiencePanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String? _busyStudentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isSupervisor {
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
      final raw = await _api.getAudiences(widget.seminarId);
      if (!mounted) return;
      setState(() {
        _items = raw
            .map((m) => {
                  'studentId': m['studentId'] ?? m['student']?['id'],
                  'studentName':
                      m['fullName'] ?? m['studentName'] ?? '-',
                  'nim': m['nim'] ?? '-',
                  'registeredAt': m['registeredAt'],
                  'approvedAt': m['approvedAt'],
                  'approvedByName': m['approvedByName'],
                })
            .toList();
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
    final studentId = row['studentId']?.toString();
    if (studentId == null) return;
    final isApproved = row['approvedAt'] != null;
    setState(() => _busyStudentId = studentId);
    try {
      await _api.updateAudience(
        widget.seminarId,
        studentId,
        action: isApproved ? 'unapprove' : 'approve',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved
                ? 'Persetujuan kehadiran dibatalkan.'
                : 'Kehadiran peserta disetujui.',
          ),
          backgroundColor:
              isApproved ? AppColors.textPrimary : AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui kehadiran: $e'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyStudentId = null);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((row) {
      final name = (row['studentName'] ?? '').toString().toLowerCase();
      final nim = (row['nim'] ?? '').toString().toLowerCase();
      return name.contains(q) || nim.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final total = _items.length;
    final approved = _items.where((r) => r['approvedAt'] != null).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari peserta…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: '$approved / $total hadir',
                variant: BadgeVariant.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }
    final data = _filtered;
    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.groups_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                child: Text(
                  _items.isEmpty
                      ? 'Belum ada peserta yang mendaftar.'
                      : 'Tidak ada hasil yang cocok.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          4,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _AudienceCard(
          index: i + 1,
          row: data[i],
          showApproveAction: _isSupervisor,
          isBusy: _busyStudentId == data[i]['studentId'],
          onToggle: () => _toggleApproval(data[i]),
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> row;
  final bool showApproveAction;
  final bool isBusy;
  final VoidCallback onToggle;

  const _AudienceCard({
    required this.index,
    required this.row,
    required this.showApproveAction,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = (row['studentName'] ?? '-').toString();
    final nim = (row['nim'] ?? '-').toString();
    final isApproved = row['approvedAt'] != null;
    final approvedByName = row['approvedByName']?.toString();

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$index',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  nim,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (isApproved && approvedByName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Disetujui oleh $approvedByName',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.successDark),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (showApproveAction)
            _ToggleButton(
              isApproved: isApproved,
              isBusy: isBusy,
              onPressed: onToggle,
            )
          else
            AppBadge(
              label: isApproved ? 'Hadir' : 'Belum',
              variant:
                  isApproved ? BadgeVariant.success : BadgeVariant.secondary,
            ),
        ],
      ),
    );
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
        isApproved ? AppColors.destructive : AppColors.successDark;
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        icon: isBusy
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                isApproved ? Icons.close_rounded : Icons.check_rounded,
                size: 14,
                color: color,
              ),
        label: Text(
          isApproved ? 'Batal' : 'Setujui',
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
