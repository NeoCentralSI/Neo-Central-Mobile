import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/core/utils/notification_helpers.dart';
import 'package:neocentral/features/shell/notification_router.dart';

UserModel _user(String role) => UserModel(
  id: 'u1',
  fullName: 'Pengguna',
  email: 'u@unand.ac.id',
  isVerified: true,
  roles: [UserRoleEntry(id: 'r1', name: role)],
);

void main() {
  late GlobalKey<NavigatorState> navigatorKey;
  late List<NotificationDestination> built;

  NotificationRouter routerWith({bool failing = false}) => NotificationRouter(
    navigatorKey: navigatorKey,
    openDelay: Duration.zero,
    pageBuilder: (destination, _) {
      if (failing && destination != NotificationDestination.notificationList) {
        throw StateError('screen removed');
      }
      built.add(destination);
      return Scaffold(body: Text('page:${destination.name}'));
    },
  );

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('home')),
    ),
  );

  setUp(() {
    navigatorKey = GlobalKey<NavigatorState>();
    built = [];
  });

  testWidgets('a tap for a removed module opens the notification list', (
    tester,
  ) async {
    await pumpApp(tester);
    final router = routerWith();
    // attach() would touch Firebase; open() is what a tap calls.
    router.debugSetUser(_user('Mahasiswa'));

    for (final type in [
      'seminar_examiner_assigned',
      'defence_scheduled',
      'yudisium_participant_appointed',
      'supervisor_request_submitted',
    ]) {
      await router.open({'type': type, 'seminarId': 'x'});
      await tester.pumpAndSettle();
      expect(find.text('page:notificationList'), findsOneWidget);
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed payloads never throw', (tester) async {
    await pumpApp(tester);
    final router = routerWith();
    router.debugSetUser(_user('Pembimbing 1'));

    await router.open(null);
    await router.open({'type': 123, 'data': 'oops'});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(built, everyElement(NotificationDestination.notificationList));
  });

  testWidgets('a screen that fails to build falls back to the list', (
    tester,
  ) async {
    await pumpApp(tester);
    final router = routerWith(failing: true);
    router.debugSetUser(_user('Pembimbing 1'));

    await router.open({'type': 'thesis-guidance:requested'});
    await tester.pumpAndSettle();

    expect(find.text('page:notificationList'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lecturer guidance tap opens the request list', (tester) async {
    await pumpApp(tester);
    final router = routerWith();
    router.debugSetUser(_user('Ketua Departemen'));

    await router.open({'type': 'thesis-guidance:requested'});
    await tester.pumpAndSettle();

    expect(
      find.text(
        'page:${NotificationDestination.lecturerGuidanceRequests.name}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('admin taps go to the list, except Pengumuman', (tester) async {
    await pumpApp(tester);
    final router = routerWith();
    router.debugSetUser(_user('Admin'));

    await router.open({'type': 'thesis-guidance:requested'});
    await router.open({'type': 'seminar_scheduled'});
    await tester.pumpAndSettle();

    expect(built, [
      NotificationDestination.notificationList,
      NotificationDestination.announcements,
    ]);
  });

  testWidgets('no signed-in user: taps are ignored', (tester) async {
    await pumpApp(tester);
    await routerWith().open({'type': 'thesis-guidance:approved'});
    await tester.pumpAndSettle();

    expect(built, isEmpty);
    expect(find.text('home'), findsOneWidget);
  });
}
