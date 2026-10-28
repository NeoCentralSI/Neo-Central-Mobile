import 'package:flutter/material.dart';

import '../../core/enums/user_role.dart';
import '../../core/models/auth_models.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/preferences_service.dart';
import '../admin/presentation/admin_shell.dart';
import '../internship/presentation/internship_shell.dart';
import 'main_shell.dart';
import 'notification_router.dart';

/// Work to do once a user is signed in (fresh login or restored session):
/// route notification taps and register the push token. Push failures never
/// block the login.
Future<void> startSession(UserModel user) async {
  NotificationRouter.instance.attach(user);
  try {
    final fcm = FcmService();
    await fcm.init();
    await fcm.registerAfterLogin();
  } catch (e) {
    debugPrint('[Session] FCM init error (non-fatal): $e');
  }
}

/// First screen after sign-in for [user].
///
/// Admin gets the Admin shell. Students and lecturers get Tugas Akhir, or
/// Kerja Praktik when they chose it as their default home in Profil.
Future<Widget> homeFor(UserModel user) async {
  final role = user.appRole;
  if (role == UserRole.admin) return AdminShell(user: user);
  final defaultHome = await PreferencesService().getDefaultHome();
  if (defaultHome == 'internship') return InternshipShell(user: user);
  return MainShell(userRole: role, user: user);
}
