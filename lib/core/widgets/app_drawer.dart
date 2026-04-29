import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/enums/user_role.dart';
import '../../features/internship/presentation/internship_shell.dart';
import '../../features/placeholder/presentation/placeholder_screens.dart';
import '../../features/shell/main_shell.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final String activeRoute;

  const AppDrawer({
    super.key,
    required this.user,
    required this.activeRoute,
  });

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
                  if (isStudent)
                    _buildMenuItem(
                      context,
                      title: 'Metopel',
                      icon: Icons.menu_book_outlined,
                      isActive: activeRoute == 'metopel',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute == 'metopel') return;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MetopelScreen(user: user),
                          ),
                        );
                      },
                    ),
                  _buildMenuItem(
                    context,
                    title: 'Tugas Akhir',
                    icon: Icons.school_outlined,
                    isActive: activeRoute == 'tugas_akhir',
                    onTap: () {
                      Navigator.pop(context);
                      if (activeRoute == 'tugas_akhir') return;
                      
                      // For student, TA is the home shell
                      if (isStudent) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => MainShell(
                              userRole: UserRole.student,
                              user: user,
                            ),
                          ),
                          (route) => false,
                        );
                      } else {
                        // For lecturer, TA dashboard is also home
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => MainShell(
                              userRole: user?.appRole ?? UserRole.lecturer,
                              user: user,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  if (isStudent) ...[
                    _buildMenuItem(
                      context,
                      title: 'Seminar & Sidang',
                      icon: Icons.groups_outlined,
                      isActive: activeRoute == 'seminar_sidang',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute == 'seminar_sidang') return;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeminarSidangScreen(user: user),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      title: 'Yudisium',
                      icon: Icons.emoji_events_outlined,
                      isActive: activeRoute == 'yudisium',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeRoute == 'yudisium') return;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => YudisiumScreen(user: user),
                          ),
                        );
                      },
                    ),
                  ],
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
    final effectiveColor = color ?? (isActive ? AppColors.primary : AppColors.textSecondary);
    final textColor = color ?? (isActive ? AppColors.primaryDark : AppColors.textPrimary);

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
          color: effectiveColor,
        ),
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
