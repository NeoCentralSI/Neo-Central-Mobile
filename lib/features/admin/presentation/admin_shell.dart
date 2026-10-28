import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/auth_models.dart';
import '../../announcement/presentation/announcement_screen.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Shell for the Admin role on mobile: Pengumuman, Notifikasi and Profil.
///
/// Every other admin feature lives on the web app. Notification taps are
/// routed app-wide by `NotificationRouter`.
class AdminShell extends StatefulWidget {
  final UserModel? user;
  const AdminShell({super.key, this.user});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AnnouncementScreen(user: widget.user, showDrawer: false),
      const NotificationScreen(isTab: true),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'Pengumuman',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: 'Notifikasi',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
