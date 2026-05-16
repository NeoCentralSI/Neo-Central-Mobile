import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Riwayat Kehadiran panel — student's audience attendance history.
///
/// Header: summary badge (attended/required + met badge).
/// Body: search box + list of attendance records with status badge per row.
class StudentSeminarAttendancePanel extends StatefulWidget {
  final UserModel? user;
  final void Function(String seminarId) onSeminarTap;

  const StudentSeminarAttendancePanel({
    super.key,
    required this.onSeminarTap,
    this.user,
  });

  @override
  State<StudentSeminarAttendancePanel> createState() =>
      _StudentSeminarAttendancePanelState();
}

class _StudentSeminarAttendancePanelState
    extends State<StudentSeminarAttendancePanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = const {};
  List<Map<String, dynamic>> _records = const [];

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

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.getStudentAttendanceHistory();
      if (!mounted) return;
      setState(() {
        _summary = res['summary'] is Map
            ? Map<String, dynamic>.from(res['summary'] as Map)
            : const {};
        _records = ((res['records'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
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

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records.where((r) {
      final name = (r['presenterName'] ?? '').toString().toLowerCase();
      final title = (r['thesisTitle'] ?? '').toString().toLowerCase();
      final nim = (r['presenterNim'] ?? '').toString().toLowerCase();
      return name.contains(q) || title.contains(q) || nim.contains(q);
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
    final attended = (_summary['attended'] as num?)?.toInt() ?? 0;
    final required = (_summary['required'] as num?)?.toInt() ?? 0;
    final met = _summary['met'] == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
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
                          Text(
                            '$attended',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' / $required hadir',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: met ? 'Terpenuhi' : 'Belum',
                  variant:
                      met ? BadgeVariant.success : BadgeVariant.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari presenter / judul / NIM…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
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
              Icons.event_busy_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                child: Text(
                  _records.isEmpty
                      ? 'Belum ada riwayat kehadiran seminar.'
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
        itemBuilder: (_, i) => _AttendanceCard(
          row: data[i],
          onTap: () {
            final id = data[i]['seminarId']?.toString();
            if (id != null) widget.onSeminarTap(id);
          },
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  const _AttendanceCard({required this.row, required this.onTap});

  (String, BadgeVariant) _statusOf() {
    if (row['isPresent'] == true) {
      return ('Hadir', BadgeVariant.success);
    }
    final dateStr = row['date']?.toString();
    final endStr = row['seminarEndTime']?.toString();
    DateTime? deadline;
    try {
      if (dateStr != null && dateStr.isNotEmpty) {
        final d = DateTime.parse(dateStr);
        if (endStr != null && endStr.isNotEmpty) {
          final t = DateTime.parse(endStr).toUtc();
          deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        } else {
          deadline = DateTime(d.year, d.month, d.day, 23, 59);
        }
      }
    } catch (_) {}
    final status = (row['seminarStatus'] ?? '').toString();
    final finalized = const ['passed', 'passed_with_revision', 'failed']
            .contains(status) ||
        (row['seminarResultFinalizedAt'] ?? '').toString().isNotEmpty;
    final now = DateTime.now();

    if (deadline == null || now.isBefore(deadline)) {
      return ('Menunggu Verifikasi', BadgeVariant.warning);
    }
    if (finalized && !now.isBefore(deadline)) {
      return ('Tidak Hadir', BadgeVariant.destructive);
    }
    return ('Menunggu Verifikasi', BadgeVariant.warning);
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusVariant) = _statusOf();
    final approvedBy = (row['approvedBy'] ?? '').toString();
    final presenter = (row['presenterName'] ?? '-').toString();
    final nim = (row['presenterNim'] ?? '-').toString();
    final title = (row['thesisTitle'] ?? '-').toString();

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
                      presenter,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nim,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(label: statusLabel, variant: statusVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                _formatDate(row['date']?.toString()) ?? '-',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              if (approvedBy.isNotEmpty) ...[
                const Icon(Icons.verified_user_outlined,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Diverifikasi: $approvedBy',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
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
