import 'package:flutter/material.dart';

import '../../../core/models/auth_models.dart';
import '../../../shared/widgets/activity_placeholder_shell.dart';
import '../../../shared/widgets/shared_widgets.dart';

class StudentDefenceScreen extends StatelessWidget {
  final UserModel? user;

  const StudentDefenceScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'sidang_ta',
      title: 'Sidang TA',
      subtitle: 'Placeholder ringkasan sidang tugas akhir mahasiswa. Jadwal, penilaian, dan revisi akan diisi nanti.',
      activeRoleLabel: 'Mahasiswa',
      tabs: const [ActivityTabItem(label: 'Ringkasan', value: 'overview')],
      tabBuilder: (_, __) => const ActivityPlaceholderPanel(
        title: 'Status Sidang Mahasiswa',
        description: 'Placeholder untuk melihat status sidang, jadwal sidang, dan catatan revisi.',
        children: [
          AppCard(
            child: Text('Nantinya di sini akan ada kartu status, jadwal sidang, dan tautan ke detail sidang.'),
          ),
        ],
      ),
    );
  }
}