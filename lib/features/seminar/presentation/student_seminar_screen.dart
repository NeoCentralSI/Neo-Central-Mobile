import 'package:flutter/material.dart';

import '../../../core/models/auth_models.dart';
import '../../../shared/widgets/activity_placeholder_shell.dart';
import '../../../shared/widgets/shared_widgets.dart';

class StudentSeminarScreen extends StatelessWidget {
  final UserModel? user;

  const StudentSeminarScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'seminar_hasil',
      title: 'Seminar Hasil',
      subtitle: 'Placeholder ringkasan seminar hasil mahasiswa. Detail jadwal, status, dan revisi akan ditambahkan nanti.',
      activeRoleLabel: 'Mahasiswa',
      tabs: const [ActivityTabItem(label: 'Ringkasan', value: 'overview')],
      tabBuilder: (_, __) => const ActivityPlaceholderPanel(
        title: 'Status Seminar Mahasiswa',
        description: 'Placeholder untuk melihat status seminar hasil, jadwal, dan catatan seminar.',
        children: [
          AppCard(
            child: Text('Nantinya kartu status, jadwal seminar, dan tautan detail akan muncul di sini.'),
          ),
        ],
      ),
    );
  }
}