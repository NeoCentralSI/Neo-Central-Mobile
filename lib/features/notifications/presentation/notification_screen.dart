import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../../core/utils/formatters.dart' as fmt;
import '../../../../core/utils/notification_helpers.dart' as nh;
import '../../../../shared/widgets/shared_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = NotificationApiService();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<dynamic> _notifications = [];
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

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
    });
    try {
      final result = await _api.getNotifications(limit: _pageSize, offset: 0);
      final list = result['notifications'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _unreadCount = result['unreadCount'] as int;
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
      await _loadInitial();
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
      await _loadInitial();
    } catch (e) {
      _showError('Gagal menghapus notifikasi: $e');
    }
  }

  Future<void> _deleteSingle(String id) async {
    try {
      await _api.deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => n['id'].toString() == id);
        // Refresh unread count to stay accurate
        _api.getUnreadCount().then((c) {
          if (mounted) setState(() => _unreadCount = c);
        });
      });
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
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        title: Row(
          children: [
            Text('Notifikasi', style: AppTextStyles.h4),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
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
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'read_all') _markAllAsRead();
                if (value == 'delete_all') _deleteAll();
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
                      Icon(Icons.delete_sweep, size: 18, color: AppColors.destructive),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.base),
                itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final item = _notifications[index];
                  final id = item['id'].toString();
                  return Dismissible(
                    key: Key(id),
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
                      return false; // we handle list update manually
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
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

// ─── Notification item tile ───────────────────────────────────────────────────

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
          // Icon bubble
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _iconColor(type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData(type), color: _iconColor(type), size: 20),
          ),
          const SizedBox(width: 12),
          // Content
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
                        _relativeTime(createdAt),
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
          // Unread dot
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

  String _relativeTime(String iso) => fmt.relativeTime(iso);
}
