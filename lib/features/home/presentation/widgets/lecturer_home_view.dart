import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../approval/presentation/approval_list_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../../notifications/presentation/notification_screen.dart';
import '../../../settings/presentation/settings_screen.dart';

class LecturerHomeView extends StatelessWidget {
  const LecturerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(context),
          const SizedBox(height: 32),

          // Stats Section
          _buildStatsSection(),
          const SizedBox(height: 32),

          // Events Section
          _buildEventsSection(),
          const SizedBox(height: 32),

          // Action Button
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 28),
            // TODO: Replace with network image when API is ready
            // backgroundImage: NetworkImage('...'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat pagi,',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dr. Ricky Akbar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '14',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Menunggu Approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    final events = [
      _EventItem(
        time: '09:00',
        title: 'Review Skripsi',
        subtitle: 'Sarah Jenkins',
        isLast: false,
      ),
      _EventItem(
        time: '11:30',
        title: 'Sesi Bimbingan',
        subtitle: 'Mark Doe',
        isLast: false,
      ),
      _EventItem(
        time: '14:00',
        title: 'Rapat Jurusan',
        subtitle: 'Ruang 304',
        isLast: false,
      ),
      _EventItem(
        time: '16:30',
        title: 'Tidak ada agenda lagi',
        subtitle: '',
        isLast: true,
        isGray: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Event yang Akan Datang',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
          ],
        ),
        const Divider(height: 32),
        ...events,
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApprovalListScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Lihat Approval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}

class _EventItem extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool isGray;

  const _EventItem({
    required this.time,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.isGray = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isGray ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 40,
            color: isGray
                ? Colors.transparent
                : AppColors.primaryLight.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isGray
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontStyle: isGray ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
}
