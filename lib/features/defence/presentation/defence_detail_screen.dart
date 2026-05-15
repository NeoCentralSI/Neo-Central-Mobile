import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';

class DefenceDetailScreen extends StatelessWidget {
  final UserModel? user;

  const DefenceDetailScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: user, activeRoute: 'sidang_ta'),
      appBar: AppBar(
        title: const Text('Detail Sidang'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: AppCard(
          child: Text(
            'Placeholder detail sidang.\n\nNanti halaman ini akan menjadi shared detail view dengan panel identitas, assessment, attendance, dan revision sesuai role dan status.',
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}