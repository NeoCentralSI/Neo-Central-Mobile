import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/auth_service.dart';
import '../../announcement/presentation/announcement_screen.dart';
import '../../auth/presentation/login_screen.dart';

/// Minimal side drawer for the Admin role.
///
/// Only surfaces the two screens an admin uses on mobile:
/// Dashboard (notification inbox) and Pengumuman (announcements).
/// All other app sections are intentionally omitted — admin work
/// happens on the web app.
class AdminDrawer extends StatelessWidget {
  final UserModel? user;
  final String activeRoute;

  const AdminDrawer({super.key, this.user, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
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
                      (user?.fullName ?? 'A')[0].toUpperCase(),
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Admin',
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
                _buildItem(
                  context,
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  isActive: activeRoute == 'dashboard',
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    if (activeRoute != 'dashboard') {
                      Navigator.pop(context); // pop Pengumuman screen
                    }
                  },
                ),
                _buildItem(
                  context,
                  title: 'Pengumuman',
                  icon: Icons.campaign_outlined,
                  isActive: activeRoute == 'pengumuman',
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    if (activeRoute == 'pengumuman') return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementScreen(
                          user: user,
                          customDrawer: AdminDrawer(
                            user: user,
                            activeRoute: 'pengumuman',
                          ),
                        ),
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
            child: _buildItem(
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
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext);
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

  Widget _buildItem(
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
