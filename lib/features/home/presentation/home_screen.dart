import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/user_role.dart';
import 'widgets/lecturer_home_view.dart';

/// Home screen widget
/// 
/// Main screen of the application after login.
/// Renders different views based on the user role.
class HomeScreen extends StatefulWidget {
  final UserRole userRole;

  const HomeScreen({
    super.key,
    this.userRole = UserRole.lecturer, // Default to lecturer for now
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildRoleView(),
      ),
    );
  }

  Widget _buildRoleView() {
    switch (widget.userRole) {
      case UserRole.lecturer:
        return const LecturerHomeView();
      case UserRole.student:
        // TODO: Implement StudentHomeView
        return _buildPlaceholder('Student Home');
      case UserRole.staff:
        // TODO: Implement StaffHomeView
        return _buildPlaceholder('Staff Home');
    }
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Under Construction',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
