import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import 'seminar_detail_screen.dart';
import 'student_panels/student_seminar_attendance_panel.dart';
import 'student_panels/student_seminar_overview_panel.dart';

/// Seminar Hasil — student view.
///
/// Mirrors `website/src/pages/thesis-seminar/StudentThesisSeminar.tsx` with
/// two tabs:
///   • Ringkasan       — checklist, milestones, identity card, documents, history
///   • Riwayat Kehadiran — student's attendance records as audience
///
/// Tapping a card opens the shared [SeminarDetailScreen].
class StudentSeminarScreen extends StatefulWidget {
  final UserModel? user;

  const StudentSeminarScreen({super.key, this.user});

  @override
  State<StudentSeminarScreen> createState() => _StudentSeminarScreenState();
}

class _StudentSeminarScreenState extends State<StudentSeminarScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDetail(String seminarId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          SeminarDetailScreen(seminarId: seminarId, user: widget.user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'seminar_hasil'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StudentSeminarOverviewPanel(
                    user: widget.user,
                    onSeminarTap: _openDetail,
                  ),
                  StudentSeminarAttendancePanel(
                    user: widget.user,
                    onSeminarTap: _openDetail,
                  ),
                ],
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
        4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu,
                        color: Colors.white, size: 24),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seminar Hasil',
                  style: AppTextStyles.h1
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Riwayat Kehadiran'),
            ],
          ),
        ],
      ),
    );
  }
}
