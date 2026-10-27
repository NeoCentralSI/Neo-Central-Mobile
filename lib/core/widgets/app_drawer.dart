import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/enums/user_role.dart';
import '../../features/internship/presentation/internship_shell.dart';
import '../../features/shell/main_shell.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/announcement/presentation/announcement_screen.dart';
import '../../features/guidance/presentation/student/milestone_progress_screen.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../services/auth_service.dart';

/// Side menu for students and lecturers (Admin has its own tabs).
///
/// Students: Bimbingan, Milestone, Kerja Praktek, Pengumuman, Notifikasi.
/// Lecturers (also Kadep, Sekdep, ...): Mahasiswa Bimbingan, Milestone,
/// Kerja Praktek, Pengumuman, Notifikasi. Profil lives in the bottom tabs.
class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final String activeRoute;

  const AppDrawer({super.key, required this.user, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(color: AppColors.primary),
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
                  title: isStudent ? 'Bimbingan' : 'Mahasiswa Bimbingan',
                  icon: Icons.school_outlined,
                  isActive: activeRoute == 'tugas_akhir',
                  onTap: () => _openShell(context, 'tugas_akhir'),
                ),
                _buildMenuItem(
                  context,
                  title: 'Milestone',
                  icon: Icons.flag_outlined,
                  isActive: activeRoute == 'milestone',
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute == 'milestone') return;
                    if (isStudent) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MilestoneProgressScreen(),
                        ),
                      );
                    } else {
                      // Approval Bimbingan ▸ Milestone
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MainShell(
                            userRole: UserRole.lecturer,
                            user: user,
                            initialIndex: 1,
                            initialSubTab: 2,
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Kerja Praktek',
                  icon: Icons.work_outline,
                  isActive: activeRoute == 'internship',
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute == 'internship') return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InternshipShell(user: user),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Pengumuman',
                  icon: Icons.campaign_outlined,
                  isActive: activeRoute == 'pengumuman',
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute == 'pengumuman') return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementScreen(user: user),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Notifikasi',
                  icon: Icons.notifications_outlined,
                  isActive: activeRoute == 'notifikasi',
                  onTap: () {
                    Navigator.pop(context);
                    if (activeRoute == 'notifikasi') return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildMenuItem(
              context,
              title: 'Keluar',
              icon: Icons.logout_rounded,
              color: AppColors.destructive,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  void _openShell(BuildContext context, String route) {
    Navigator.pop(context);
    if (activeRoute == route) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            MainShell(userRole: user?.appRole ?? UserRole.student, user: user),
      ),
      (route) => false,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Capture the navigator before popping the dialog or use the outer context
              final navigator = Navigator.of(context);

              Navigator.pop(dialogContext); // Close dialog

              await AuthService().logout();

              if (context.mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.destructive),
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
    Color? color,
    required VoidCallback onTap,
  }) {
    final effectiveColor =
        color ?? (isActive ? AppColors.primary : AppColors.textSecondary);
    final textColor =
        color ?? (isActive ? AppColors.primaryDark : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: effectiveColor),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
