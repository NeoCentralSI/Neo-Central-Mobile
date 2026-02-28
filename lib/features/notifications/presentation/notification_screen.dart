import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = NotificationApiService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await _api.getNotifications();
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat notifikasi: $e')));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      _fetchNotifications();
    } catch (e) {
      // Ignore errors for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.base),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return _NotificationItem(
                    notification: item,
                    onRead: () => _api.markAsRead(item['id'].toString()),
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
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onRead;

  const _NotificationItem({required this.notification, required this.onRead});

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['status'] == 'unread';
    final title = notification['title'] ?? 'Notifikasi';
    final message = notification['message'] ?? '';
    final createdAt = notification['createdAt'];

    String timeStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString());
        timeStr =
            '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return AppCard(
      onTap: () {
        if (isUnread) onRead();
        // Potential navigation based on type?
      },
      backgroundColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.05)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getIconColor(notification['type']).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notification['type']),
              color: _getIconColor(notification['type']),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(timeStr, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon(dynamic type) {
    switch (type.toString()) {
      case 'GUIDANCE_REQUEST':
        return Icons.calendar_today;
      case 'TRANSFER_REQUEST':
        return Icons.swap_horiz;
      case 'TOPIC_CHANGE_REQUEST':
        return Icons.edit_note;
      case 'VAL_SEMINAR':
        return Icons.school;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(dynamic type) {
    switch (type.toString()) {
      case 'GUIDANCE_REQUEST':
        return AppColors.info;
      case 'TRANSFER_REQUEST':
        return AppColors.warning;
      case 'TOPIC_CHANGE_REQUEST':
        return AppColors.primary;
      case 'VAL_SEMINAR':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
