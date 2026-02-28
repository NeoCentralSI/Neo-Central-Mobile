import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/user_role.dart';
import '../../core/models/auth_models.dart';
import '../profile/presentation/profile_screen.dart';

// Import screens - lecturer
import '../guidance/presentation/lecturer/guidance_requests_screen.dart';
import '../guidance/presentation/lecturer/student_list_screen.dart';
import '../guidance/presentation/lecturer/lecturer_dashboard_screen.dart';

// Import screens – student
import '../guidance/presentation/student/student_dashboard_screen.dart';
import '../guidance/presentation/student/guidance_schedule_screen.dart';
import '../guidance/presentation/student/guidance_history_screen.dart';

/// Main app shell providing bottom navigation for each role.
class MainShell extends StatefulWidget {
  final UserRole userRole;
  final UserModel? user;
  const MainShell({super.key, required this.userRole, this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _initialSubTab = 0;

  void _switchTab(int index, {int initialTab = 0}) {
    setState(() {
      _currentIndex = index;
      _initialSubTab = initialTab;
    });
  }

  List<Widget> get _lecturerPages => [
    LecturerDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
    GuidanceRequestsScreen(
      isTab: true,
      initialTab: _initialSubTab,
      key: ValueKey('approval_$_initialSubTab'),
    ),
    const StudentListScreen(isTab: true),
    ProfileScreen(user: widget.user),
  ];

  List<Widget> get _studentPages => [
    StudentDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
    const GuidanceScheduleScreen(isTab: true),
    const GuidanceHistoryScreen(isTab: true),
    ProfileScreen(user: widget.user),
  ];

  List<Widget> get _pages =>
      widget.userRole == UserRole.lecturer ? _lecturerPages : _studentPages;

  List<NavigationDestination> get _lecturerDestinations => const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Approval',
    ),
    NavigationDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group),
      label: 'Mahasiswa',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  List<NavigationDestination> get _studentDestinations => const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Jadwalkan',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Riwayat',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = widget.userRole == UserRole.lecturer
        ? _lecturerDestinations
        : _studentDestinations;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
