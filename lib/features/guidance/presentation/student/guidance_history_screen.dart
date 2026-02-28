import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import 'guidance_schedule_screen.dart';

/// Student guidance history screen – fetches sessions from backend
class GuidanceHistoryScreen extends StatefulWidget {
  final bool isTab;
  const GuidanceHistoryScreen({super.key, this.isTab = false});

  @override
  State<GuidanceHistoryScreen> createState() => _GuidanceHistoryScreenState();
}

class _GuidanceHistoryScreenState extends State<GuidanceHistoryScreen> {
  final _api = StudentApiService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _sessions = await _api.getGuidanceHistory();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  int _countByStatus(String status) =>
      _sessions.where((s) => s['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Riwayat Bimbingan', style: AppTextStyles.h4),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuidanceScheduleScreen()),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Baru'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Coba Lagi',
                    icon: Icons.refresh,
                    onPressed: _loadData,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Summary bar
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        _StatChip(
                          label: '${_countByStatus("completed")} Selesai',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          label: '${_countByStatus("accepted")} Dijadwalkan',
                          icon: Icons.event,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          label: '${_countByStatus("requested")} Menunggu',
                          icon: Icons.hourglass_empty,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _sessions.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada riwayat bimbingan',
                              style: AppTextStyles.body,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                              AppSpacing.pagePadding,
                            ),
                            itemCount: _sessions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) =>
                                _GuidanceSessionItem(session: _sessions[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceSessionItem extends StatelessWidget {
  final dynamic session;
  const _GuidanceSessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final status = (session['status'] ?? '').toString();
    final BadgeVariant variant;
    final String badgeLabel;

    switch (status) {
      case 'completed':
        variant = BadgeVariant.success;
        badgeLabel = 'Selesai';
        break;
      case 'accepted':
        variant = BadgeVariant.primary;
        badgeLabel = 'Dijadwalkan';
        break;
      case 'requested':
        variant = BadgeVariant.warning;
        badgeLabel = 'Menunggu';
        break;
      case 'rejected':
        variant = BadgeVariant.destructive;
        badgeLabel = 'Ditolak';
        break;
      case 'cancelled':
        variant = BadgeVariant.outline;
        badgeLabel = 'Dibatalkan';
        break;
      default:
        variant = BadgeVariant.outline;
        badgeLabel = status;
    }

    // Use formatted date from backend, or raw requestedDate
    final dateStr =
        session['requestedDateFormatted'] ??
        session['approvedDateFormatted'] ??
        _formatDate(session['requestedDate']) ??
        '-';
    final supervisorName = (session['supervisorName'] ?? '-').toString();
    // Use studentNotes as topic if available
    final topic = (session['studentNotes'] ?? session['topic'] ?? 'Bimbingan')
        .toString();

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic,
                        style: AppTextStyles.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(label: badgeLabel, variant: variant),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  supervisorName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(dateStr.toString(), style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
