import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/enums/user_role.dart';
import '../../profile/presentation/profile_screen.dart';
import 'lecturer/lecturer_dashboard.dart';
import 'student/dashboard_screen.dart';
import 'student/logbook_screen.dart';
import 'student/guidance_screen.dart';
import 'student/seminar_screen.dart';

class InternshipShell extends StatefulWidget {
  final UserModel? user;
  const InternshipShell({super.key, this.user});

  @override
  State<InternshipShell> createState() => _InternshipShellState();
}

class _InternshipShellState extends State<InternshipShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user?.appRole == UserRole.student;

    final List<Widget> pages = isStudent
        ? [
            InternshipDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
            InternshipLogbookScreen(user: widget.user),
            InternshipGuidanceScreen(user: widget.user),
            InternshipSeminarScreen(user: widget.user),
            ProfileScreen(user: widget.user),
          ]
        : [
            InternshipLecturerDashboard(user: widget.user),
            ProfileScreen(user: widget.user),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
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
            indicatorColor: isStudent ? Colors.amber.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: isStudent
                ? const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: Colors.amber),
                      label: 'Beranda',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment, color: Colors.amber),
                      label: 'Logbook',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum, color: Colors.amber),
                      label: 'Bimbingan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups, color: Colors.amber),
                      label: 'Seminar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: Colors.amber),
                      label: 'Profil',
                    ),
                  ]
                : const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: AppColors.primary),
                      label: 'Beranda',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: AppColors.primary),
                      label: 'Profil',
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
