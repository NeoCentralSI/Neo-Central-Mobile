import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';

class _BasePlaceholderScreen extends StatelessWidget {
  final String title;
  final UserModel? user;
  final String activeRoute;

  const _BasePlaceholderScreen({
    required this.title,
    this.user,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: user, activeRoute: activeRoute),
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



class MetopelScreen extends StatelessWidget {
  final UserModel? user;
  const MetopelScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) =>
      _BasePlaceholderScreen(title: 'Metopel', user: user, activeRoute: 'metopel');
}

class SeminarSidangScreen extends StatelessWidget {
  final UserModel? user;
  const SeminarSidangScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) => _BasePlaceholderScreen(
        title: 'Seminar & Sidang',
        user: user,
        activeRoute: 'seminar_sidang',
      );
}

class YudisiumScreen extends StatelessWidget {
  final UserModel? user;
  const YudisiumScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) => _BasePlaceholderScreen(
        title: 'Yudisium',
        user: user,
        activeRoute: 'yudisium',
      );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bantuan')),
        body: const Center(child: Text('Halaman Bantuan sedang dikembangkan.')),
      );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tentang Aplikasi')),
        body: const Center(child: Text('NeoCentral v1.0.0')),
      );
}
