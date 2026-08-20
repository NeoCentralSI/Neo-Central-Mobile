import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/seminar_models.dart';
import '../controllers/student_seminar_controller.dart';

class StudentSeminarAttendancePanel extends StatefulWidget {
  final UserModel? user;
  final void Function(String seminarId) onSeminarTap;
  final int refreshSignal;

  const StudentSeminarAttendancePanel({
    super.key,
    required this.onSeminarTap,
    this.user,
    this.refreshSignal = 0,
  });

  @override
  State<StudentSeminarAttendancePanel> createState() =>
      _StudentSeminarAttendancePanelState();
}

class _StudentSeminarAttendancePanelState
    extends State<StudentSeminarAttendancePanel>
    with AutomaticKeepAliveClientMixin {
  late final SeminarAttendanceController _controller;
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = SeminarAttendanceController()..addListener(_onChanged);
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant StudentSeminarAttendancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<AttendanceRecord> get _filteredRecords {
    final records = _controller.data?.records ?? const <AttendanceRecord>[];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return records;
    return records
        .where((record) {
          return record.presenterName.toLowerCase().contains(query) ||
              (record.presenterNim ?? '').toLowerCase().contains(query) ||
              record.thesisTitle.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _controller.data;
    if (_controller.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && data == null) {
      return _ErrorView(message: _controller.error!, onRetry: _controller.load);
    }
    if (data == null) return const SizedBox.shrink();

    final records = _filteredRecords;
    return RefreshIndicator(
      onRefresh: _controller.load,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(data.summary)),
          if (records.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                message: data.records.isEmpty
                    ? 'Belum ada riwayat kehadiran seminar.'
                    : 'Tidak ada hasil yang cocok.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final record = records[index];
                  return _AttendanceCard(
                    record: record,
                    onTap: () => widget.onSeminarTap(record.seminarId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(AttendanceSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        0,
      ),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            radius: 14,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Kehadiran Seminar',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${summary.attended}', style: AppTextStyles.h2),
                          Text(
                            ' / ${summary.required} hadir',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        '${summary.total} seminar tercatat',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: summary.met ? 'Terpenuhi' : 'Belum',
                  variant: summary.met
                      ? BadgeVariant.success
                      : BadgeVariant.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari presenter, judul, atau NIM…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _AttendanceCard({required this.record, required this.onTap});

  (String, BadgeVariant) get _attendanceStatus {
    if (record.isPresent) return ('Hadir', BadgeVariant.success);
    if (record.seminarStatus?.isFinal == true && _verificationEnded) {
      return ('Tidak Hadir', BadgeVariant.destructive);
    }
    return ('Menunggu Verifikasi', BadgeVariant.warning);
  }

  bool get _verificationEnded {
    final date = record.date == null ? null : DateTime.tryParse(record.date!);
    if (date == null) return record.resultFinalizedAt != null;
    final time = _parseTime(record.seminarEndTime);
    final localDate = date.toLocal();
    final deadline = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      time?.$1 ?? 23,
      time?.$2 ?? 59,
    );
    return !DateTime.now().isBefore(deadline);
  }

  (int, int)? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final plain = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (plain != null) {
      return (int.parse(plain.group(1)!), int.parse(plain.group(2)!));
    }
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : (parsed.hour, parsed.minute);
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusVariant) = _attendanceStatus;
    final date = record.date == null ? null : DateTime.tryParse(record.date!);
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 14,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.presenterName,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      record.presenterNim ?? '-',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              AppBadge(label: statusLabel, variant: statusVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.thesisTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Meta(
                icon: Icons.calendar_today_outlined,
                text: date == null ? '-' : formatDateIndonesian(date.toLocal()),
              ),
              if (record.approvedBy != null)
                _Meta(
                  icon: Icons.verified_user_outlined,
                  text: 'Diverifikasi: ${record.approvedBy}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Flexible(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: AppTextStyles.h4),
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
