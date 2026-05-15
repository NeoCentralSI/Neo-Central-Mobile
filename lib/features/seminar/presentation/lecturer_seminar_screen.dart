import 'package:flutter/material.dart';

import '../../../core/models/auth_models.dart';
import '../../../shared/widgets/activity_placeholder_shell.dart';
import '../../../shared/widgets/shared_widgets.dart';

class LecturerSeminarScreen extends StatelessWidget {
  final UserModel? user;

  const LecturerSeminarScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ActivityPlaceholderShell(
      user: user,
      activeRoute: 'seminar_hasil',
      title: 'Seminar Hasil',
      subtitle: 'Daftar seminar hasil untuk dosen dibagi menjadi mahasiswa bimbingan dan mahasiswa yang diuji.',
      activeRoleLabel: 'Dosen',
      tabs: const [
        ActivityTabItem(label: 'Mahasiswa Bimbingan', value: 'supervised'),
        ActivityTabItem(label: 'Menguji Mahasiswa', value: 'examiner'),
      ],
      tabBuilder: (_, activeTab) {
        final title = activeTab == 'examiner' ? 'Mahasiswa yang Diuji' : 'Mahasiswa Bimbingan';
        final description = activeTab == 'examiner'
            ? 'Placeholder untuk daftar seminar hasil yang melibatkan dosen sebagai penguji.'
            : 'Placeholder untuk daftar seminar hasil dari mahasiswa bimbingan dosen.';

        return ActivityPlaceholderPanel(
          title: title,
          description: description,
          children: const [
            AppCard(
              child: Text('Tab ini nantinya akan menampilkan daftar mahasiswa dan shortcut ke detail seminar.'),
            ),
          ],
        );
      },
    );
  }
}