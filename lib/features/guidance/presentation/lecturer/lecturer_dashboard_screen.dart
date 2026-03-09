import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../notifications/presentation/notification_screen.dart'
    show NotificationScreen;

import '../../../../core/widgets/app_drawer.dart';

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
  final _fcm = FcmService();

  bool _isLoading = true;
  String? _error;

  int _unreadCount = 0;

  List<dynamic> _students = [];
  List<dynamic> _requests = [];
  List<dynamic> _pendingApproval = [];
  List<dynamic> _pendingMilestones = [];
  List<dynamic> _topicChanges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _fcm.addListener(_onFcmMessage);
  }

  @override
  void dispose() {
    _fcm.removeListener(_onFcmMessage);
    super.dispose();
  }

  /// Silently refresh counts when an FCM push arrives (approval-related).
  void _onFcmMessage(Map<String, dynamic> data) {
    // Reload dashboard data whenever a notification arrives
    _loadData(silent: true);
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      // Fire all requests in parallel; individual failures return empty lists
      final results = await Future.wait([
        _api.getMyStudents().catchError((_) => <dynamic>[]),
        _api.getRequests().catchError((_) => <dynamic>[]),
        _api.getPendingApproval().catchError((_) => <dynamic>[]),
        _api.getPendingReviewMilestones().catchError(
          (_) => <Map<String, dynamic>>[],
        ),
        _api.getPendingTopicChanges().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0];
        _requests = results[1];
        _pendingApproval = results[2];
        _pendingMilestones = results[3];
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
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
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
                            Text(
                              _error!,
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildHeaderBackground(context, firstName),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 280,
                        left: AppSpacing.pagePadding,
                        right: AppSpacing.pagePadding,
                        bottom: 40,
                      ),
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context, String name) {
    final totalActionNeeded =
        _requests.length +
        _pendingApproval.length +
        _pendingMilestones.length +
        _topicChanges.length;

    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        60,
        AppSpacing.pagePadding,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (BuildContext innerContext) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Scaffold.of(innerContext).openDrawer();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Dosen',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi, $name',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );
                                final count = await _notifApi.getUnreadCount();
                                if (mounted) {
                                  setState(() => _unreadCount = count);
                                }
                              },
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          const SizedBox(height: 32),
          // OVERALL STATS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERLU TINDAKAN',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$totalActionNeeded',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'menunggu',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inbox_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Quick Actions',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Kelola',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _QuickActionItem(
                  icon: Icons.check_circle_outline,
                  label: 'Permintaan Bimbingan',
                  subtitle: '${_requests.length} menunggu persetujuan',
                  color: AppColors.warning,
                  badge: _requests.isNotEmpty ? '${_requests.length}' : null,
                  onTap: () => widget.onSwitchTab?.call(1, initialTab: 0),
                  isLast: false,
                ),
                _QuickActionItem(
                  icon: Icons.rate_review_outlined,
                  label: 'Catatan Bimbingan',
                  subtitle: '${_pendingApproval.length} menunggu approval',
                  color: AppColors.info,
                  badge: _pendingApproval.isNotEmpty
                      ? '${_pendingApproval.length}'
                      : null,
                  onTap: () => widget.onSwitchTab?.call(1, initialTab: 1),
                  isLast: false,
                ),
                _QuickActionItem(
                  icon: Icons.flag_outlined,
                  label: 'Milestone Mahasiswa',
                  subtitle: '${_pendingMilestones.length} menunggu validasi',
                  color: AppColors.success,
                  badge: _pendingMilestones.isNotEmpty
                      ? '${_pendingMilestones.length}'
                      : null,
                  onTap: () => widget.onSwitchTab?.call(1, initialTab: 2),
                  isLast: false,
                ),
                _QuickActionItem(
                  icon: Icons.edit_note_outlined,
                  label: 'Perubahan Topik/Judul',
                  subtitle: '${_topicChanges.length} perlu review',
                  color: AppColors.primary,
                  badge: _topicChanges.isNotEmpty
                      ? '${_topicChanges.length}'
                      : null,
                  onTap: () => widget.onSwitchTab?.call(1, initialTab: 3),
                  isLast: true,
                ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceSecondary, thickness: 8, height: 8),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Mahasiswa Aktif',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => widget.onSwitchTab?.call(2),
                      child: Text(
                        'Lihat Semua',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Belum ada mahasiswa bimbingan',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._students.take(5).map((s) {
                    final name = (s['fullName'] ?? s['studentName'] ?? '-')
                        .toString();
                    final thesis = (s['thesisTitle'] ?? '-').toString();
                    final rating = (s['thesisRating'] ?? 'ONGOING').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  thesis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingBadge(rating),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(String rating) {
    Color bgColor;
    Color textColor;
    String label;

    switch (rating) {
      case 'AT_RISK':
        bgColor = AppColors.destructiveLight;
        textColor = AppColors.destructiveDark;
        label = 'Beresiko';
        break;
      case 'SLOW':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Lambat';
        break;
      case 'ONGOING':
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        label = 'On Track';
        break;
      default:
        bgColor = AppColors.borderLight;
        textColor = AppColors.textSecondary;
        label = rating;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  final bool isLast;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
      ],
    );
  }
}
