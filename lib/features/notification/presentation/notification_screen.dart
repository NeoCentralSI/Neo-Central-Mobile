import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Notification screen placeholder
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotifItem(
        icon: Icons.calendar_today_outlined,
        color: AppColors.info,
        title: 'Bimbingan Dijadwalkan',
        body: 'Sarah Amelia mengajukan bimbingan pada 27 Feb 2025',
        time: '2j lalu',
      ),
      _NotifItem(
        icon: Icons.description_outlined,
        color: AppColors.warning,
        title: 'Catatan Menunggu Approval',
        body: 'Michael Chen mengirim catatan bimbingan sesi 18 Feb',
        time: '4j lalu',
      ),
      _NotifItem(
        icon: Icons.school_outlined,
        color: AppColors.success,
        title: 'Kesiapan Seminar Diajukan',
        body: 'Jessica Wong mengajukan kesiapan seminar',
        time: '1h lalu',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifikasi', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Tandai Semua',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: AppTextStyles.label),
                      const SizedBox(height: 3),
                      Text(n.body, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text(n.time, style: AppTextStyles.caption),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
  });
}
