import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/notification_api_service.dart';
import '../../../core/utils/formatters.dart' as fmt;
import '../../../core/utils/notification_helpers.dart' as nh;
import '../../../shared/widgets/shared_widgets.dart';
import 'admin_drawer.dart';

/// Admin Dashboard — Admin role landing page on mobile.
///
/// Admin on mobile is intentionally minimal: most admin features live on the
/// web app. The mobile experience for Admin is centered on FCM-driven
/// notifications, so this screen is a notification overview + the full inbox.
class AdminDashboardScreen extends StatefulWidget {
  final UserModel? user;

  const AdminDashboardScreen({super.key, this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = NotificationApiService();
  final _fcm = FcmService();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  int _totalCount = 0;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
    _fcm.addListener(_onFcmMessage);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fcm.removeListener(_onFcmMessage);
    super.dispose();
  }

  void _onFcmMessage(Map<String, dynamic> data) {
    _loadInitial(silent: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasMore = true;
      });
    }
    try {
      final result = await _api.getNotifications(limit: _pageSize, offset: 0);
      final list = result['notifications'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _unreadCount = (result['unreadCount'] as int?) ?? 0;
        _totalCount = (result['total'] as int?) ?? list.length;
        _hasMore = list.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Gagal memuat notifikasi: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _api.getNotifications(
        limit: _pageSize,
        offset: _notifications.length,
      );
      final list = result['notifications'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications.addAll(list);
        _hasMore = list.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      await _loadInitial(silent: true);
    } catch (e) {
      _showError('Gagal menandai notifikasi: $e');
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua'),
        content: const Text(
          'Yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteAllNotifications();
      await _loadInitial(silent: true);
    } catch (e) {
      _showError('Gagal menghapus notifikasi: $e');
    }
  }

  Future<void> _deleteSingle(String id) async {
    try {
      await _api.deleteNotification(id);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((n) => n['id'].toString() == id);
      });
      final count = await _api.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (e) {
      _showError('Gagal menghapus notifikasi: $e');
    }
  }

  Future<void> _markOneAsRead(String id) async {
    try {
      await _api.markAsRead(id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'].toString() == id);
        if (idx != -1) {
          final updated = Map<String, dynamic>.from(_notifications[idx] as Map);
          updated['isRead'] = true;
          _notifications[idx] = updated;
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?.fullName ?? 'Admin';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AdminDrawer(user: widget.user, activeRoute: 'dashboard'),
      body: RefreshIndicator(
        onRefresh: () => _loadInitial(),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(firstName),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.base,
                AppSpacing.pagePadding,
                8,
              ),
              sliver: SliverToBoxAdapter(child: _buildOverviewCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.base,
                AppSpacing.pagePadding,
                8,
              ),
              sliver: SliverToBoxAdapter(child: _buildInboxHeader()),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_notifications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  0,
                  AppSpacing.pagePadding,
                  24,
                ),
                sliver: SliverList.separated(
                  itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _notifications[index];
                    final id = item['id'].toString();
                    return Dismissible(
                      key: Key('admin_notif_$id'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.destructive,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await _deleteSingle(id);
                        return false;
                      },
                      child: _NotificationItem(
                        notification: item,
                        onTap: () {
                          if (item['isRead'] != true) {
                            _markOneAsRead(id);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          60,
          AppSpacing.pagePadding,
          28,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(
              builder: (ctx) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Admin',
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
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            if (_notifications.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'read_all') _markAllAsRead();
                    if (v == 'delete_all') _deleteAll();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'read_all',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 18),
                          SizedBox(width: 8),
                          Text('Tandai Semua Dibaca'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep,
                            size: 18,
                            color: AppColors.destructive,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hapus Semua',
                            style: TextStyle(color: AppColors.destructive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _StatBlock(
                icon: Icons.mark_email_unread_outlined,
                iconColor: AppColors.primary,
                label: 'Belum Dibaca',
                value: '$_unreadCount',
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _StatBlock(
                icon: Icons.inbox_outlined,
                iconColor: AppColors.info,
                label: 'Total Notifikasi',
                value: '$_totalCount',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxHeader() {
    return Row(
      children: [
        Text('Inbox Notifikasi', style: AppTextStyles.h4),
        const SizedBox(width: 8),
        if (_unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_unreadCount',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('Belum ada notifikasi', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Notifikasi terbaru akan muncul di sini',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _loadInitial(),
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

// ─── Stat block ───────────────────────────────────────────────────────────

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Notification item ────────────────────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['isRead'] != true;
    final title = notification['title']?.toString() ?? 'Notifikasi';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';
    final createdAt = notification['createdAt']?.toString();

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      backgroundColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.05)
          : Colors.white,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _iconColor(type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData(type), color: _iconColor(type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        fmt.relativeTime(createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconData(String type) => nh.notificationIconData(type);

  Color _iconColor(String type) {
    switch (type) {
      case 'GUIDANCE_REQUEST':
        return AppColors.info;
      case 'TRANSFER_REQUEST':
        return AppColors.warning;
      case 'TOPIC_CHANGE_REQUEST':
        return AppColors.primary;
      case 'VAL_SEMINAR':
        return AppColors.success;
      case 'ADVISOR_REQUEST':
        return AppColors.primaryLight;
      case 'MILESTONE_UPDATE':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
