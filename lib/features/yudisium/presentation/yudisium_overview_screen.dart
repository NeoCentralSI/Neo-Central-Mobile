import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import 'controllers/student_yudisium_controller.dart';
import 'student_exit_survey_screen.dart';
import 'student_panels/student_yudisium_overview_panel.dart';

class YudisiumOverviewScreen extends StatefulWidget {
  final UserModel? user;

  const YudisiumOverviewScreen({super.key, this.user});

  @override
  State<YudisiumOverviewScreen> createState() => _YudisiumOverviewScreenState();
}

class _YudisiumOverviewScreenState extends State<YudisiumOverviewScreen> {
  late final StudentYudisiumController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudentYudisiumController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openExitSurvey() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentExitSurveyScreen(onSubmitted: _controller.load),
      ),
    );
    if (!mounted) return;
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'yudisium'),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final overview = _controller.overview;
                  if (_controller.isLoading && overview == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_controller.error != null && overview == null) {
                    return _YudisiumError(
                      message: _controller.error!,
                      onRetry: _controller.load,
                    );
                  }
                  if (overview == null) {
                    return _YudisiumError(
                      message: 'Data yudisium tidak tersedia.',
                      onRetry: _controller.load,
                    );
                  }
                  return StudentYudisiumOverviewPanel(
                    controller: _controller,
                    overview: overview,
                    requirements: _controller.requirements,
                    onOpenExitSurvey: _openExitSurvey,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Yudisium',
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _YudisiumError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _YudisiumError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text('Gagal memuat yudisium', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
