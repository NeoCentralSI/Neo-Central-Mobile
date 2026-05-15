import 'package:flutter/material.dart';

import '../../../core/models/auth_models.dart';
import '../../../shared/widgets/activity_placeholder_shell.dart';
import '../../../shared/widgets/shared_widgets.dart';

class YudisiumOverviewScreen extends StatelessWidget {
  final UserModel? user;

  const YudisiumOverviewScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'yudisium',
      title: 'Yudisium',
      subtitle: 'Placeholder ringkasan proses yudisium mahasiswa. Ini akan menjadi halaman student-only.',
      activeRoleLabel: 'Mahasiswa',
      tabs: const [ActivityTabItem(label: 'Ringkasan', value: 'overview')],
      tabBuilder: (_, __) => const ActivityPlaceholderPanel(
        title: 'Status Yudisium Mahasiswa',
        description: 'Placeholder untuk status yudisium, checklist, dokumen, dan riwayat peserta.',
        children: [
          AppCard(
            child: Text('Nantinya halaman ini akan memuat progress yudisium, checklist, dan dokumen pendukung.'),
          ),
        ],
      ),
    );
  }
}