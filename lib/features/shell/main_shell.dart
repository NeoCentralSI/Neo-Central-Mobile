import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/user_role.dart';
import '../../core/models/auth_models.dart';
import '../../core/services/fcm_service.dart';
import '../hod/presentation/assign_examiner_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../seminar/presentation/lecturer_seminar_screen.dart';

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
  int _approvalReloadKey = 0;
  final _fcm = FcmService();

  @override
  void initState() {
    super.initState();
    if (_isLecturerLike) {
      _fcm.addOpenListener(_onLecturerNotificationOpened);
    }
  }

  @override
  void dispose() {
    if (_isLecturerLike) {
      _fcm.removeOpenListener(_onLecturerNotificationOpened);
    }
    super.dispose();
  }

  /// Deep-link from FCM tap into the relevant lecturer/HoD screen + tab.
  ///
  /// Notification `type` values (see services/src/services/thesis-{seminar,
  /// defence}/{doc,examiner}.service.js):
  ///   • seminar_examiner_assigned    — any lecturer assigned as examiner
  ///                                    → Seminar Hasil ▸ Menguji Mahasiswa
  ///   • seminar_need_examiner        — HoD only: doc verified, first assign
  ///   • seminar_examiner_unavailable — HoD only: an examiner rejected
  ///   • defence_need_examiner        — HoD only: defence variant
  ///   • defence_examiner_unavailable — HoD only: defence variant
  void _onLecturerNotificationOpened(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == null) return;

    // Defer navigation so it never races with an in-progress route transition
    // (e.g. the pushReplacement from AuthGate is still animating on cold start,
    // and Flutter will silently drop a push issued mid-transition).
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      if (type == 'seminar_examiner_assigned') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LecturerSeminarScreen(
              user: widget.user,
              initialTab: 'menguji_mahasiswa',
            ),
          ),
        );
        return;
      }

      if (widget.userRole == UserRole.headOfDepartment) {
        final String tab;
        if (type == 'seminar_need_examiner' ||
            type == 'seminar_examiner_unavailable') {
          tab = 'seminar_hasil';
        } else if (type == 'defence_need_examiner' ||
            type == 'defence_examiner_unavailable') {
          tab = 'sidang_ta';
        } else {
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignExaminerScreen(
              user: widget.user,
              initialTab: tab,
            ),
          ),
        );
      }
    });
  }

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

  List<Widget> get _studentPages => [
    StudentDashboardScreen(user: widget.user, onSwitchTab: _switchTab),
    GuidanceScheduleScreen(isTab: true, user: widget.user),
    GuidanceHistoryScreen(isTab: true, user: widget.user),
    ProfileScreen(user: widget.user),
  ];

  /// Head of Department is "Lecturer+" on mobile (see docs/neocentral-mobile.md
  /// §2) — render the lecturer page set, not student. Without this, HoD users
  /// landing on MainShell from AuthGate/login (which passes the real
  /// appRole) would hit StudentDashboardScreen → 403 from student-only APIs.
  bool get _isLecturerLike =>
      widget.userRole == UserRole.lecturer ||
      widget.userRole == UserRole.headOfDepartment;

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
    final destinations = _isLecturerLike
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
