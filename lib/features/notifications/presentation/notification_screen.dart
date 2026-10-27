import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_api_service.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart' as fmt;
import '../../../core/utils/notification_helpers.dart' as nh;
import '../../../shared/widgets/shared_widgets.dart';
import '../../shell/notification_router.dart';

/// Notifikasi: the signed-in user's in-app notifications, for every role.
///
/// Tapping an item marks it read and, when its module exists on mobile, opens
/// that screen (same rules as a push tap). Other items just stay here.
class NotificationScreen extends StatefulWidget {
  /// Shown as a bottom tab (Admin), so there is no back button.
  final bool isTab;

  const NotificationScreen({super.key, this.isTab = false});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = NotificationApiService();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  static List<Map<String, dynamic>> _items(Object? list) => [
    if (list is List)
      for (final item in list)
        if (item is Map) Map<String, dynamic>.from(item),
  ];

  Future<void> _loadInitial({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await _api.getNotifications(limit: _pageSize, offset: 0);
      final list = _items(result['notifications']);
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _unreadCount = result['unreadCount'] as int? ?? 0;
        _hasMore = list.length >= _pageSize;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = errorMessageOf(e, fallback: 'Notifikasi tidak dapat dimuat.');
      });
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
      final list = _items(result['notifications']);
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
      _showError(errorMessageOf(e, fallback: 'Gagal menandai notifikasi.'));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua'),
        content: const Text(
          'Yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat '
          'dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteAllNotifications();
      await _loadInitial(silent: true);
    } catch (e) {
      _showError(errorMessageOf(e, fallback: 'Gagal menghapus notifikasi.'));
    }
  }

  Future<void> _deleteSingle(String id) async {
    try {
      await _api.deleteNotification(id);
      if (!mounted) return;
      setState(() {
        final removed = _notifications.where((n) => '${n['id']}' == id);
        if (removed.any((n) => n['isRead'] != true) && _unreadCount > 0) {
          _unreadCount--;
        }
        _notifications.removeWhere((n) => '${n['id']}' == id);
      });
    } catch (e) {
      _showError(errorMessageOf(e, fallback: 'Gagal menghapus notifikasi.'));
    }
  }

  Future<void> _markOneAsRead(String id) async {
    try {
      await _api.markAsRead(id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => '${n['id']}' == id);
        if (idx != -1) {
          _notifications[idx] = {..._notifications[idx], 'isRead': true};
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  void _onTap(Map<String, dynamic> item) {
    final id = '${item['id']}';
    if (item['isRead'] != true) _markOneAsRead(id);

    final router = NotificationRouter.instance;
    final destination = router.destinationFor(item);
    if (destination == nh.NotificationDestination.notificationList) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => router.pageFor(destination, router.user),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
          GradientHeader(
            title: 'Notifikasi',
            subtitle: _isLoading
                ? null
                : (_unreadCount > 0
                      ? '$_unreadCount belum dibaca'
                      : 'Semua notifikasi sudah dibaca'),
            leading: widget.isTab ? null : HeaderIconButton.back(context),
            trailing: _notifications.isEmpty ? null : _buildMenu(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitial,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.white),
      tooltip: 'Opsi',
      onSelected: (value) {
        if (value == 'read_all') _markAllAsRead();
        if (value == 'delete_all') _deleteAll();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
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
              Icon(Icons.delete_sweep, size: 18, color: AppColors.destructive),
              SizedBox(width: 8),
              Text(
                'Hapus Semua',
                style: TextStyle(color: AppColors.destructive),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ScrollableCenter(
        child: ErrorStateView(message: _error!, onRetry: _loadInitial),
      );
    }
    if (_notifications.isEmpty) {
      return const ScrollableCenter(
        child: EmptyStateView(
          icon: Icons.notifications_off_outlined,
          title: 'Belum Ada Notifikasi',
          message: 'Notifikasi terbaru akan muncul di sini',
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.base),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final item = _notifications[index];
        final id = '${item['id']}';
        return Dismissible(
          key: ValueKey(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.destructive,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.white,
              size: 24,
            ),
          ),
          confirmDismiss: (_) async {
            await _deleteSingle(id);
            return false; // the list is updated by _deleteSingle
          },
          child: _NotificationItem(
            notification: item,
            onTap: () => _onTap(item),
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['isRead'] != true;
    final title = notification['title']?.toString().trim();
    final message = notification['message']?.toString() ?? '';
    final type = nh.notificationTypeOf(notification);
    final createdAt = notification['createdAt']?.toString();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              nh.notificationIconData(type),
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title == null || title.isEmpty ? 'Notifikasi' : title,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        fmt.relativeTime(createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
