import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../seminar/presentation/seminar_detail_screen.dart';
import 'panels/seminar_announcement_panel.dart';
import 'panels/yudisium_announcement_panel.dart';

/// Pengumuman — list of announced seminars and yudisium events.
///
/// Two tabs (mirroring the web `ThesisSeminarAnnouncement.tsx` /
/// `YudisiumAnnouncement.tsx`):
///   • Seminar Hasil — student can register / cancel registration; lecturer
///                     sees a friendly notice (endpoint is MAHASISWA-only).
///   • Yudisium      — public list of yudisium events with their participants.
class AnnouncementScreen extends StatefulWidget {
  final UserModel? user;
  final Widget? customDrawer;

  const AnnouncementScreen({super.key, this.user, this.customDrawer});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
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

  bool get _isStudent => widget.user?.appRole == UserRole.student;

  void _openSeminarDetail(String seminarId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          SeminarDetailScreen(seminarId: seminarId, user: widget.user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: widget.customDrawer ??
          AppDrawer(user: widget.user, activeRoute: 'pengumuman'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SeminarAnnouncementPanel(
                    user: widget.user,
                    isStudent: _isStudent,
                    onOpenSeminar: _openSeminarDetail,
                  ),
                  YudisiumAnnouncementPanel(user: widget.user),
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
                  'Pengumuman',
                  style: AppTextStyles.h1
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(text: 'Seminar Hasil'),
              Tab(text: 'Yudisium'),
            ],
          ),
        ],
      ),
    );
  }
}
