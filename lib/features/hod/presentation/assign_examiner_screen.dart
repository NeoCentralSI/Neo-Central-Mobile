import 'package:flutter/material.dart';

import '../../../../core/models/auth_models.dart';
import '../../../../shared/widgets/activity_placeholder_shell.dart';

class AssignExaminerScreen extends StatelessWidget {
  final UserModel? user;

  const AssignExaminerScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'assign_examiner',
      title: 'Tetapkan Penguji',
      subtitle: 'Kelola penetapan penguji untuk Seminar Hasil dan Sidang TA',
      activeRoleLabel: 'Dosen',
      tabs: const [
        ActivityTabItem(label: 'Seminar Hasil', value: 'seminar_hasil'),
        ActivityTabItem(label: 'Sidang TA', value: 'sidang_ta'),
      ],
      tabBuilder: (context, activeTab) {
        if (activeTab == 'sidang_ta') {
          return const ActivityPlaceholderPanel(
            title: 'Tetapkan Penguji Sidang TA',
            description: 'Placeholder untuk penetapan penguji sidang TA oleh Ketua Departemen.',
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Daftar sidang TA dan penguji akan ditampilkan di sini.'),
                ),
              ),
            ],
          );
        }

        return const ActivityPlaceholderPanel(
          title: 'Tetapkan Penguji Seminar Hasil',
          description: 'Placeholder untuk penetapan penguji seminar hasil oleh Ketua Departemen.',
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Daftar seminar hasil dan penguji akan ditampilkan di sini.'),
              ),
            ),
          ],
        );
      },
    );
  }
}
