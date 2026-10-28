import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/announcement_api_service.dart';
import 'seminar_announcement_tab.dart';
import 'yudisium_announcement_tab.dart';

/// Pengumuman: announced Seminar Hasil and Yudisium results, as on web
/// (`ThesisSeminarAnnouncement.tsx` and `YudisiumAnnouncement.tsx`).
///
/// Every role reads both boards. Only students can register for, or cancel
/// their registration to, a seminar as audience.
class AnnouncementScreen extends StatefulWidget {
  final UserModel? user;

  /// Drawer to show; defaults to the role drawer. Pass a page with no drawer
  /// by setting [showDrawer] to false.
  final Widget? customDrawer;
  final bool showDrawer;
  final AnnouncementApiService? api;

  const AnnouncementScreen({
    super.key,
    this.user,
    this.customDrawer,
    this.showDrawer = true,
    this.api,
  });

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AnnouncementApiService _api;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AnnouncementApiService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final drawer = widget.showDrawer
        ? (widget.customDrawer ??
              AppDrawer(user: widget.user, activeRoute: 'pengumuman'))
        : null;
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: drawer,
      body: Column(
        children: [
          GradientHeader(
            title: 'Pengumuman',
            leading: drawer != null
                ? HeaderIconButton.menu()
                : (canPop ? HeaderIconButton.back(context) : null),
            bottom: HeaderTabBar(
              controller: _tabController,
              labels: const ['Seminar Hasil', 'Yudisium'],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SeminarAnnouncementTab(api: _api, user: widget.user),
                YudisiumAnnouncementTab(api: _api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
