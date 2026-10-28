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
import '../guidance/presentation/student/milestone_progress_screen.dart';
import 'student_nav_bar.dart';

/// Tugas Akhir shell (Bimbingan and Milestone) with bottom navigation.
///
/// Lecturers, including those who are also Ketua or Sekretaris Departemen,
/// get the lecturer tabs; students get the student tabs. Notification taps
/// are routed app-wide by `NotificationRouter`.
class MainShell extends StatefulWidget {
  final UserRole userRole;
  final UserModel? user;

  /// Bottom tab to open first.
  final int initialIndex;

  /// Lecturer only: tab of Approval Bimbingan to open first
  /// (0 Permintaan, 1 Catatan, 2 Milestone).
  final int initialSubTab;

  const MainShell({
    super.key,
    required this.userRole,
    this.user,
    this.initialIndex = 0,
    this.initialSubTab = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;
  late int _initialSubTab = widget.initialSubTab;
  int _approvalReloadKey = 0;

  void _switchTab(int index, {int initialTab = 0}) {
    setState(() {
      _currentIndex = index;
      _initialSubTab = initialTab;
      if (index == 1) _approvalReloadKey++;
    });
  }

  List<Widget> get _lecturerPages => [
    LecturerDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
    GuidanceRequestsScreen(
      isTab: true,
      initialTab: _initialSubTab,
      key: ValueKey('approval_${_initialSubTab}_$_approvalReloadKey'),
    ),
    const StudentListScreen(isTab: true),
    ProfileScreen(user: widget.user),
  ];

  /// Student tabs: Beranda, Bimbingan, Milestone, Profil. Ajukan Bimbingan
  /// is the round button in the middle of the bar, not a tab.
  List<Widget> get _studentPages => [
    StudentDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
    GuidanceHistoryScreen(
      key: ValueKey('history_$_historyReloadKey'),
      isTab: true,
      user: widget.user,
    ),
    MilestoneProgressScreen(isTab: true, user: widget.user),
    ProfileScreen(user: widget.user),
  ];

  int _historyReloadKey = 0;

  /// Opens Ajukan Bimbingan; after a request is sent, shows it in Bimbingan.
  Future<void> _openGuidanceRequest() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GuidanceScheduleScreen(user: widget.user),
      ),
    );
    if (sent == true && mounted) {
      setState(() {
        _historyReloadKey++;
        _currentIndex = 1;
      });
    }
  }

  bool get _isLecturerLike => widget.userRole == UserRole.lecturer;

  List<Widget> get _pages => _isLecturerLike ? _lecturerPages : _studentPages;

  List<NavigationDestination> get _lecturerDestinations => const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Persetujuan',
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

  static const _studentItems = [
    StudentNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Beranda',
    ),
    StudentNavItem(
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
      label: 'Bimbingan',
    ),
    StudentNavItem(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      label: 'Milestone',
    ),
    StudentNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isLecturerLike) {
      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: StudentNavBar(
          items: _studentItems,
          selectedIndex: _currentIndex,
          onSelected: (i) => setState(() => _currentIndex = i),
          onCenterPressed: _openGuidanceRequest,
        ),
      );
    }

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
            destinations: _lecturerDestinations,
          ),
        ),
      ),
    );
  }
}
