import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../auth/presentation/login_screen.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../placeholder/presentation/placeholder_screens.dart';
import '../../../core/widgets/app_drawer.dart';

import '../../../core/services/preferences_service.dart';

/// Profile screen - role-aware display for both lecturer and student
class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _defaultHome = 'tugas_akhir';
  bool _showHomeSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = PreferencesService();
    final home = await prefs.getDefaultHome();
    setState(() => _defaultHome = home);
  }

  Future<void> _updateDefaultHome(String? value) async {
    if (value == null) return;
    final prefs = PreferencesService();
    await prefs.setDefaultHome(value);
    setState(() => _defaultHome = value);
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user?.appRole ?? UserRole.lecturer;
    final isLecturer = role == UserRole.lecturer;

    final name = widget.user?.fullName ?? (isLecturer ? 'Dosen' : 'Mahasiswa');
    final email = widget.user?.email ?? '-';
    final identityNumber = widget.user?.identityNumber ?? '-';

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'profile'),
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
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 20,
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(height: 60),
              ],
            ),
          ),
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
          if (!isLecturer && widget.user?.student?.enrollmentYear != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Angkatan',
              value: widget.user!.student!.enrollmentYear.toString(),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildMenuCard(BuildContext context, bool isLecturer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengaturan & Informasi', style: AppTextStyles.h4),
          const AppDivider(),
          
          // Default Home Setting (Expandable)
          _buildExpandableMenuItem(
            icon: Icons.home_outlined,
            label: 'Halaman Utama Default',
            value: _defaultHome == 'internship' ? 'Kerja Praktik' : 'Tugas Akhir',
            isExpanded: _showHomeSettings,
            onTap: () => setState(() => _showHomeSettings = !_showHomeSettings),
            children: [
              _buildSubMenuItem(
                label: 'Tugas Akhir',
                isSelected: _defaultHome == 'tugas_akhir',
                onTap: () => _updateDefaultHome('tugas_akhir'),
              ),
              _buildSubMenuItem(
                label: 'Kerja Praktik',
                isSelected: _defaultHome == 'internship',
                onTap: () => _updateDefaultHome('internship'),
              ),
            ],
          ),
          Divider(height: 1, color: AppColors.divider),

          _buildPlainMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          
          _buildPlainMenuItem(
            icon: Icons.help_outline,
            label: 'Bantuan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),

          _buildPlainMenuItem(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _buildMenuIcon(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.label),
                      Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(left: 46, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildMenuIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.label),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.primary,
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
