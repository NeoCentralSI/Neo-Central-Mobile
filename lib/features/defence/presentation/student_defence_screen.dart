import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import 'defence_detail_screen.dart';
import 'student_panels/student_defence_overview_panel.dart';

class StudentDefenceScreen extends StatefulWidget {
  final UserModel? user;

  const StudentDefenceScreen({super.key, this.user});

  @override
  State<StudentDefenceScreen> createState() => _StudentDefenceScreenState();
}

class _StudentDefenceScreenState extends State<StudentDefenceScreen> {
  int _refreshSignal = 0;

  Future<void> _openDetail(String defenceId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DefenceDetailScreen(defenceId: defenceId, user: widget.user),
      ),
    );
    if (mounted) setState(() => _refreshSignal++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'sidang_ta'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StudentDefenceOverviewPanel(
                user: widget.user,
                onDefenceTap: _openDetail,
                refreshSignal: _refreshSignal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        18,
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
            builder: (drawerContext) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sidang Tugas Akhir',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Status, persyaratan, dan riwayat sidang',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
