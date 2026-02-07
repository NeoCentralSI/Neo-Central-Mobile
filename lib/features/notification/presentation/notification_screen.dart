import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: const [
          Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '4 belum dibaca',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 32),

          _NotificationItem(
            title: 'Pengingat Jadwal',
            description:
                'Bimbingan dengan Sarah Jenkins akan dimulai dalam 30 menit.',
            timeAgo: '30 menit yang lalu',
            isUnread: true,
          ),
          _NotificationItem(
            title: 'Request Baru',
            description: 'Michael Chen mengajukan judul tugas akhir baru.',
            timeAgo: '2 jam yang lalu',
            isUnread: true,
          ),
          _NotificationItem(
            title: 'Jadwal Rapat',
            description: 'Rapat Jurusan dijadwalkan ulang ke pukul 14:00.',
            timeAgo: '1 hari yang lalu',
            isUnread: false,
          ),
          _NotificationItem(
            title: 'Sistem Maintenance',
            description:
                'Sistem akan mengalami maintenance pada hari Sabtu pukul 22:00.',
            timeAgo: '2 hari yang lalu',
            isUnread: false,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String description;
  final String timeAgo;
  final bool isUnread;

  const _NotificationItem({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.background, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isUnread ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
