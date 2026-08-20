import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/seminar_models.dart';

class SeminarAudiencePanel extends StatefulWidget {
  final String seminarId;
  final SeminarDetail detail;
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
  final _searchController = TextEditingController();
  List<SeminarAudience> _audiences = const [];
  bool _isLoading = true;
  String? _error;
  String? _busyStudentId;

  @override
  bool get wantKeepAlive => true;

  bool get _isSupervisor {
    final lecturerId = widget.user?.lecturer?.id;
    return lecturerId != null &&
        widget.detail.supervisors.any((item) => item.lecturerId == lecturerId);
  }

  List<SeminarAudience> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _audiences;
    return _audiences
        .where(
          (item) =>
              item.studentName.toLowerCase().contains(query) ||
              item.nim.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getAudiences(widget.seminarId);
      if (!mounted) return;
      setState(() => _audiences = result);
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePresence(SeminarAudience audience) async {
    final studentId = audience.studentId;
    if (studentId == null) {
      _showMessage(
        'ID mahasiswa peserta tidak tersedia.',
        AppColors.destructive,
      );
      return;
    }
    setState(() => _busyStudentId = studentId);
    try {
      await _api.updateAudience(
        widget.seminarId,
        studentId,
        action: audience.isPresent
            ? AudienceAction.unapprove
            : AudienceAction.approve,
      );
      if (!mounted) return;
      _showMessage(
        audience.isPresent
            ? 'Status hadir peserta dibatalkan.'
            : 'Kehadiran peserta berhasil diverifikasi.',
        audience.isPresent ? AppColors.textPrimary : AppColors.successDark,
      );
      await _load();
    } catch (exception) {
      if (mounted) {
        _showMessage(
          'Gagal memperbarui kehadiran: $exception',
          AppColors.destructive,
        );
      }
    } finally {
      if (mounted) setState(() => _busyStudentId = null);
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.base,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari peserta…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                label:
                    '${_audiences.where((item) => item.isPresent).length} / ${_audiences.length} hadir',
                variant: BadgeVariant.outline,
              ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final data = _filtered;
    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            const Icon(
              Icons.groups_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              _audiences.isEmpty
                  ? 'Belum ada peserta yang mendaftar.'
                  : 'Tidak ada hasil yang cocok.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          4,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        itemCount: data.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final audience = data[index];
          return _AudienceCard(
            index: index + 1,
            audience: audience,
            canVerify: _isSupervisor && audience.studentId != null,
            isBusy: _busyStudentId == audience.studentId,
            onToggle: () => _togglePresence(audience),
          );
        },
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final int index;
  final SeminarAudience audience;
  final bool canVerify;
  final bool isBusy;
  final VoidCallback onToggle;

  const _AudienceCard({
    required this.index,
    required this.audience,
    required this.canVerify,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Text('$index', style: AppTextStyles.caption),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(audience.studentName, style: AppTextStyles.label),
                Text(audience.nim, style: AppTextStyles.caption),
                if (audience.approvedByName != null)
                  Text(
                    'Diverifikasi oleh ${audience.approvedByName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.successDark,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canVerify)
            OutlinedButton.icon(
              onPressed: isBusy ? null : onToggle,
              icon: isBusy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      audience.isPresent
                          ? Icons.close_rounded
                          : Icons.check_rounded,
                      size: 14,
                    ),
              label: Text(audience.isPresent ? 'Batalkan' : 'Hadir'),
            )
          else
            AppBadge(
              label: audience.isPresent ? 'Hadir' : 'Belum',
              variant: audience.isPresent
                  ? BadgeVariant.success
                  : BadgeVariant.secondary,
            ),
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
