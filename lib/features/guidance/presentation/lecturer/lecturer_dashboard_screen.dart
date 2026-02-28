import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../notifications/presentation/notification_screen.dart';

/// Lecturer main dashboard – shows pending approval stats + quick actions
class LecturerDashboardScreen extends StatefulWidget {
  final UserModel? user;
  final void Function(int, {int initialTab})? onSwitchTab;
  const LecturerDashboardScreen({super.key, this.user, this.onSwitchTab});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  final _api = LecturerApiService();
  final _notifApi = NotificationApiService();

  bool _isLoading = true;
  String? _error;

  int _unreadCount = 0;

  List<dynamic> _students = [];
  List<dynamic> _requests = [];
  List<dynamic> _pendingApproval = [];
  List<dynamic> _transfers = [];
  List<dynamic> _topicChanges = [];

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
      final results = await Future.wait([
        _api.getMyStudents(),
        _api.getRequests(),
        _api.getPendingApproval(),
        _api.getIncomingTransfers(),
        _api.getPendingTopicChanges(),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0];
        _requests = results[1];
        _pendingApproval = results[2];
        _transfers = results[3];
        _topicChanges = results[4];
        _isLoading = false;
      });

      // Fetch unread count separately
      _notifApi.getUnreadCount().then((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?.fullName ?? 'Dosen';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(userName),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
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
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Coba Lagi',
                        icon: Icons.refresh,
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _QuickStatsRow(
                      studentCount: _students.length,
                      requestCount: _requests.length,
                      pendingCount: _pendingApproval.length,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.base),
                    _buildRecentStudents(),
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            60,
            AppSpacing.pagePadding,
            AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                          // Refresh unread count when returning
                          final count = await _notifApi.getUnreadCount();
                          if (mounted) setState(() => _unreadCount = count);
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildQuickActions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Aksi Cepat'),
          const SizedBox(height: AppSpacing.sm),
          _QuickActionItem(
            icon: Icons.check_circle_outline,
            label: 'Permintaan Bimbingan',
            subtitle: '${_requests.length} menunggu persetujuan',
            color: AppColors.warning,
            badge: _requests.isNotEmpty ? '${_requests.length}' : null,
            onTap: () => widget.onSwitchTab?.call(1, initialTab: 0),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.rate_review_outlined,
            label: 'Catatan Bimbingan',
            subtitle: '${_pendingApproval.length} menunggu approval',
            color: AppColors.info,
            badge: _pendingApproval.isNotEmpty
                ? '${_pendingApproval.length}'
                : null,
            onTap: () => widget.onSwitchTab?.call(1, initialTab: 1),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.swap_horiz_outlined,
            label: 'Perpindahan Mahasiswa',
            subtitle: '${_transfers.length} permintaan masuk',
            color: AppColors.warning,
            badge: _transfers.isNotEmpty ? '${_transfers.length}' : null,
            onTap: () => widget.onSwitchTab?.call(1, initialTab: 3),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.edit_note_outlined,
            label: 'Perubahan Topik/Judul',
            subtitle: '${_topicChanges.length} perlu review',
            color: AppColors.primary,
            badge: _topicChanges.isNotEmpty ? '${_topicChanges.length}' : null,
            onTap: () => widget.onSwitchTab?.call(1, initialTab: 4),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.group_outlined,
            label: 'Lihat Semua Mahasiswa',
            subtitle: 'Kelola mahasiswa bimbingan',
            color: AppColors.primary,
            onTap: () => widget.onSwitchTab?.call(2),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStudents() {
    if (_students.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Belum ada mahasiswa bimbingan',
              style: AppTextStyles.body,
            ),
          ),
        ),
      );
    }

    final display = _students.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Mahasiswa Bimbingan',
            actionLabel: 'Lihat Semua',
            onAction: () => widget.onSwitchTab?.call(2),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...display.map((s) {
            final name = (s['fullName'] ?? s['studentName'] ?? '-').toString();
            final thesis = (s['thesisTitle'] ?? '-').toString();
            final rating = (s['thesisRating'] ?? 'ONGOING').toString();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.label),
                        Text(
                          thesis,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: _ratingLabel(rating),
                    variant: _ratingVariant(rating),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  BadgeVariant _ratingVariant(String rating) {
    switch (rating) {
      case 'AT_RISK':
        return BadgeVariant.destructive;
      case 'SLOW':
        return BadgeVariant.warning;
      case 'ONGOING':
        return BadgeVariant.success;
      default:
        return BadgeVariant.outline;
    }
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'AT_RISK':
        return 'Beresiko';
      case 'SLOW':
        return 'Lambat';
      case 'ONGOING':
        return 'On Track';
      default:
        return rating;
    }
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final int studentCount;
  final int requestCount;
  final int pendingCount;
  const _QuickStatsRow({
    required this.studentCount,
    required this.requestCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Mahasiswa',
            value: '$studentCount',
            icon: Icons.group,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Permintaan',
            value: '$requestCount',
            icon: Icons.pending_actions,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Catatan',
            value: '$pendingCount',
            icon: Icons.rate_review,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ─── Quick Action Item ────────────────────────────────────────
class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
