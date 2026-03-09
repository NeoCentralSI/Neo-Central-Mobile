import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _BasePlaceholderScreen extends StatelessWidget {
  final String title;
  const _BasePlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.h4.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('Halaman $title', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Halaman ini sedang dalam pengembangan.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KerjaPraktekScreen extends StatelessWidget {
  const KerjaPraktekScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _BasePlaceholderScreen(title: 'Kerja Praktek');
}

class MetopelScreen extends StatelessWidget {
  const MetopelScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _BasePlaceholderScreen(title: 'Metopel');
}

class SeminarSidangScreen extends StatelessWidget {
  const SeminarSidangScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _BasePlaceholderScreen(title: 'Seminar & Sidang');
}

class YudisiumScreen extends StatelessWidget {
  const YudisiumScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _BasePlaceholderScreen(title: 'Yudisium');
}
