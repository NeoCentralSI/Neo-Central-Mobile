import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/auth_models.dart';
import '../../core/widgets/app_drawer.dart';
import '../../features/notifications/presentation/notification_screen.dart' show NotificationScreen;
import 'shared_widgets.dart';

class ActivityTabItem {
  final String label;
  final String value;

  const ActivityTabItem({required this.label, required this.value});
}

class ActivityPlaceholderShell extends StatelessWidget {
  final UserModel? user;
  final String activeRoute;
  final String title;
  final String subtitle;
  final String activeRoleLabel;
  final List<ActivityTabItem> tabs;
  final Widget Function(BuildContext context, String activeTab) tabBuilder;
  final String initialTab;
  final Widget? customDrawer;

  const ActivityPlaceholderShell({
    super.key,
    required this.user,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.activeRoleLabel,
    required this.tabs,
    required this.tabBuilder,
    this.initialTab = 'overview',
    this.customDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final initialIndex = tabs.indexWhere((tab) => tab.value == initialTab);

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSecondary,
        drawer: customDrawer ?? AppDrawer(user: user, activeRoute: activeRoute),
        body: SafeArea(
          child: Column(
            children: [
              // TA-style header with gradient and optional TabBar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  20,
                  AppSpacing.pagePadding,
                  12,
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
                          builder: (inner) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                              onPressed: () => Scaffold.of(inner).openDrawer(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 20),
                          ),
                        ),
                        // placeholder for actions
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const NotificationScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (tabs.length > 1) ...[
                      const SizedBox(height: 12),
                      TabBar(
                        isScrollable: true,
                        indicatorColor: AppColors.white,
                        indicatorWeight: 3,
                        labelColor: AppColors.white,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                        unselectedLabelColor: AppColors.white.withValues(alpha: 0.8),
                        tabs: tabs.map((t) => Tab(text: t.label)).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        backgroundColor: AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBadge(label: activeRoleLabel, variant: BadgeVariant.primary),
                            const SizedBox(height: AppSpacing.base),
                            Text(title, style: AppTextStyles.h3),
                            const SizedBox(height: AppSpacing.sm),
                            Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: tabs.length > 1
                            ? TabBarView(
                                children: tabs.map((tab) => tabBuilder(context, tab.value)).toList(),
                              )
                            : tabBuilder(context, tabs.first.value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityPlaceholderPanel extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const ActivityPlaceholderPanel({
    super.key,
    required this.title,
    required this.description,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            backgroundColor: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: AppSpacing.sm),
                Text(description, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          ...children,
        ],
      ),
    );
  }
}