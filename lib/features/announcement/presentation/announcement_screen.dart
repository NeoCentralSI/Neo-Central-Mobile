import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/activity_placeholder_shell.dart';
import '../../../core/enums/user_role.dart';

class AnnouncementScreen extends StatelessWidget {
  final UserModel? user;
  final Widget? customDrawer;

  const AnnouncementScreen({super.key, this.user, this.customDrawer});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'pengumuman',
      customDrawer: customDrawer,
      title: 'Pengumuman',
      subtitle: 'Daftar pengumuman untuk Seminar dan Yudisium',
      activeRoleLabel: user == null ? 'Umum' : (user!.appRole == UserRole.lecturer ? 'Dosen' : 'Mahasiswa'),
      tabs: const [
        ActivityTabItem(label: 'Seminar Hasil', value: 'seminar'),
        ActivityTabItem(label: 'Yudisium', value: 'yudisium'),
      ],
      tabBuilder: (ctx, tab) {
        if (tab == 'yudisium') {
          return const _AnnouncementTab(
            title: 'Pengumuman Yudisium',
            description: 'Placeholder untuk daftar pengumuman yudisium.',
          );
        }
        return const _AnnouncementTab(
          title: 'Pengumuman Seminar Hasil',
          description: 'Placeholder untuk daftar pengumuman seminar hasil.',
        );
      },
    );
  }
}

class _AnnouncementTab extends StatelessWidget {
  final String title;
  final String description;

  const _AnnouncementTab({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            backgroundColor: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: AppSpacing.sm),
                Text(description, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          const AppCard(
            child: Text('Nantinya daftar pengumuman, pencarian, dan detail peserta akan ditambahkan di sini.'),
          ),
        ],
      ),
    );
  }
}