import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';

class SeminarDetailScreen extends StatelessWidget {
  final UserModel? user;

  const SeminarDetailScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: user, activeRoute: 'seminar_hasil'),
      appBar: AppBar(
        title: const Text('Detail Seminar'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppCard(
          child: Text(
            'Placeholder detail seminar.\n\nHalaman ini akan menjadi shared detail view dengan panel identitas, assessment, attendance, dan revision sesuai role dan status.',
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}