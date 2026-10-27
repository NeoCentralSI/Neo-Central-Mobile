import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/shared_widgets.dart';

/// Contact details and developers, as on the footer of the web landing page
/// (`website/src/components/landing/Footer.tsx`).
abstract class AboutContent {
  static const description =
      'NeoCentral adalah platform digital untuk Kerja Praktek dan Tugas Akhir '
      'Departemen Sistem Informasi Universitas Andalas. Aplikasi mobile ini '
      'menjadi pendamping NeoCentral versi web untuk bimbingan, milestone, '
      'kerja praktik, pengumuman, dan notifikasi.';

  static const campus = 'Fakultas Teknologi Informasi, Universitas Andalas';
  static const address = 'Limau Manis, Padang, Sumatera Barat 25163';
  static const email = 'si@it.unand.ac.id';
  static const phone = '+62 751 123 456';

  static const websiteUrl = 'https://si.fti.unand.ac.id/';
  static const instagramUrl = 'https://www.instagram.com/official.siunand/';
  static const linkedinUrl = 'https://www.linkedin.com/school/unand/home/';
  static const mapsUrl =
      'https://maps.google.com/maps?q=Fakultas%20Teknologi%20Informasi%20Universitas%20Andalas';

  static const developers = [
    ('Nabil Rizki Navisa', '2211522018'),
    ('Ilham Nofaldi', '2211522028'),
    ('Mustafa Fathur Rahman', '2211522036'),
    ('Muhammad Fariz', '2211523034'),
  ];
}

/// Tentang Aplikasi.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tautan tidak dapat dibuka.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final years = year > 2025 ? '2025–$year' : '2025';
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
          GradientHeader(
            title: 'Tentang Aplikasi',
            subtitle: 'NeoCentral versi ${AppConfig.appVersion}',
            leading: HeaderIconButton.back(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.base,
              ),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            AppAssets.logo,
                            height: 40,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          const Spacer(),
                          AppBadge(
                            label: 'Versi ${AppConfig.appVersion}',
                            variant: BadgeVariant.outline,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Tentang NeoCentral', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(AboutContent.description, style: AppTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lokasi dan Kontak', style: AppTextStyles.h4),
                      const AppDivider(verticalPadding: AppSpacing.md),
                      _LinkRow(
                        icon: Icons.place_outlined,
                        label: AboutContent.campus,
                        value: AboutContent.address,
                        onTap: () => _open(context, AboutContent.mapsUrl),
                      ),
                      _LinkRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: AboutContent.email,
                        onTap: () =>
                            _open(context, 'mailto:${AboutContent.email}'),
                      ),
                      _LinkRow(
                        icon: Icons.phone_outlined,
                        label: 'Telepon',
                        value: AboutContent.phone,
                        onTap: () => _open(context, 'tel:+62751123456'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _SocialButton(
                            icon: Icons.language,
                            label: 'Website',
                            onTap: () =>
                                _open(context, AboutContent.websiteUrl),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _SocialButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Instagram',
                            onTap: () =>
                                _open(context, AboutContent.instagramUrl),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _SocialButton(
                            icon: Icons.work_outline,
                            label: 'LinkedIn',
                            onTap: () =>
                                _open(context, AboutContent.linkedinUrl),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pengembang NeoCentral', style: AppTextStyles.h4),
                      const AppDivider(verticalPadding: AppSpacing.md),
                      for (final (name, nim) in AboutContent.developers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InfoRow(
                            icon: Icons.person_outline,
                            label: 'NIM $nim',
                            value: name,
                          ),
                        ),
                    ],
                  ),
                ),
                FootnoteText('© $years NeoCentral. All rights reserved.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: InfoRow(icon: icon, label: label, value: value),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
    );
  }
}
