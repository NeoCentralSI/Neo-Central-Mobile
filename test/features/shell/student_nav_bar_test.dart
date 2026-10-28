import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/shell/student_nav_bar.dart';

const _items = [
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

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('fits a $width px wide phone and routes taps', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <int>[];
      var centre = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: StudentNavBar(
              items: _items,
              selectedIndex: 0,
              onSelected: selected.add,
              onCenterPressed: () => centre++,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final label in [
        'Beranda',
        'Bimbingan',
        'Ajukan',
        'Milestone',
        'Profil',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('Bimbingan'));
      await tester.tap(find.text('Milestone'));
      await tester.tap(find.text('Profil'));
      await tester.tap(find.byKey(const ValueKey('student-nav-center')));
      await tester.pump();

      // Tab indices skip the centre button.
      expect(selected, [1, 2, 3]);
      expect(centre, 1);
    });
  }
}
