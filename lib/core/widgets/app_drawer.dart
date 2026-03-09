import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/enums/user_role.dart';
import '../../features/placeholder/presentation/placeholder_screens.dart';

class AppDrawer extends StatelessWidget {
  final UserModel? user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Determine user role.
    final isStudent = user?.appRole == UserRole.student;

    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: AppColors.surfaceSecondary,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.fullName ?? 'U')[0].toUpperCase(),
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'User',
                  style: AppTextStyles.h3.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    context,
                    title: 'Kerja Praktek',
                    icon: Icons.work_outline,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KerjaPraktekScreen(),
                        ),
                      );
                    },
                  ),
                  if (isStudent)
                    _buildMenuItem(
                      context,
                      title: 'Metopel',
                      icon: Icons.menu_book_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MetopelScreen(),
                          ),
                        );
                      },
                    ),
                  _buildMenuItem(
                    context,
                    title: 'Tugas Akhir',
                    icon: Icons.school_outlined,
                    isActive:
                        true, // Assuming this is launched from TA dashboard
                    onTap: () {
                      Navigator.pop(context);
                      // Already in TA
                    },
                  ),
                  if (isStudent) ...[
                    _buildMenuItem(
                      context,
                      title: 'Seminar & Sidang',
                      icon: Icons.groups_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SeminarSidangScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Yudisium',
                      icon: Icons.emoji_events_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const YudisiumScreen(),
                          ),
                        );
                      },
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
