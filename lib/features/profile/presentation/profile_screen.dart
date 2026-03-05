import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../auth/presentation/login_screen.dart';

/// Profile screen - role-aware display for both lecturer and student
class ProfileScreen extends StatelessWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final role = user?.appRole ?? UserRole.lecturer;
    final isLecturer = role == UserRole.lecturer;

    final name = user?.fullName ?? (isLecturer ? 'Dosen' : 'Mahasiswa');
    final email = user?.email ?? '-';
    final identityNumber = user?.identityNumber ?? '-';

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeaderBackground(context, isLecturer, name),
            Padding(
              padding: const EdgeInsets.only(
                top: 280,
                left: AppSpacing.pagePadding,
                right: AppSpacing.pagePadding,
                bottom: 40,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(isLecturer, identityNumber, email),
                    const Divider(
                      color: AppColors.surfaceSecondary,
                      thickness: 8,
                      height: 8,
                    ),
                    _buildMenuCard(context, isLecturer),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildLogoutButton(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(
    BuildContext context,
    bool isLecturer,
    String name,
  ) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 50),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            isLecturer ? 'Dosen Pembimbing' : 'Mahasiswa',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isLecturer, String identityNumber, String email) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Akun', style: AppTextStyles.h4),
          const AppDivider(),
          InfoRow(
            icon: Icons.badge_outlined,
            label: isLecturer ? 'NIP' : 'NIM',
            value: identityNumber,
          ),
          const SizedBox(height: AppSpacing.md),
          InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
          const SizedBox(height: AppSpacing.md),
          InfoRow(
            icon: Icons.school_outlined,
            label: 'Departemen',
            value: 'Sistem Informasi – FTI Unand',
          ),
          if (!isLecturer && user?.student?.enrollmentYear != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Angkatan',
              value: user!.student!.enrollmentYear.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, bool isLecturer) {
    final items = [
      _MenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifikasi',
        onTap: () {},
      ),
      _MenuItem(icon: Icons.help_outline, label: 'Bantuan', onTap: () {}),
      _MenuItem(
        icon: Icons.info_outline,
        label: 'Tentang Aplikasi',
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: entry.value.onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          entry.value.icon,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry.value.label,
                          style: AppTextStyles.label,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return AppButton(
      label: 'Keluar',
      icon: Icons.logout_outlined,
      isOutline: true,
      color: AppColors.destructive,
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Keluar'),
            content: const Text('Anda yakin ingin keluar dari akun ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.onTap});
}
