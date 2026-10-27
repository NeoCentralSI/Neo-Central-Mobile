import 'package:flutter/material.dart';

import '../../core/models/auth_models.dart';
import '../../core/navigation/navigator_key.dart' as nav;
import '../../core/services/fcm_service.dart';
import '../../core/utils/notification_helpers.dart';
import '../announcement/presentation/announcement_screen.dart';
import '../guidance/presentation/lecturer/guidance_requests_screen.dart';
import '../guidance/presentation/student/guidance_history_screen.dart';
import '../guidance/presentation/student/milestone_progress_screen.dart';
import '../internship/presentation/internship_shell.dart';
import '../notifications/presentation/notification_screen.dart';

typedef NotificationPageBuilder =
    Widget Function(NotificationDestination destination, UserModel? user);

/// Opens the right screen when a notification is tapped, for every role.
///
/// One router serves the whole app, so a tap works whichever shell is showing
/// (Tugas Akhir, Kerja Praktik or Admin). Types whose module is not on mobile
/// open the notification list; see [resolveNotificationDestination].
class NotificationRouter {
  NotificationRouter({
    GlobalKey<NavigatorState>? navigatorKey,
    NotificationPageBuilder? pageBuilder,
    this.openDelay = const Duration(milliseconds: 400),
  }) : _navigatorKey = navigatorKey ?? nav.navigatorKey,
       _pageBuilder = pageBuilder ?? buildNotificationPage;

  /// The router used by the app.
  static final NotificationRouter instance = NotificationRouter();

  final GlobalKey<NavigatorState> _navigatorKey;
  final NotificationPageBuilder _pageBuilder;

  /// Wait before pushing, so a tap on cold start does not race the first
  /// route transition (Flutter can drop a push issued mid-transition).
  final Duration openDelay;

  UserModel? _user;
  bool _listening = false;

  /// Signed-in user, or null after logout.
  UserModel? get user => _user;

  /// Starts routing taps for [user]. Call after every successful login.
  void attach(UserModel user) {
    _user = user;
    if (_listening) return;
    FcmService().addOpenListener(_onOpen);
    _listening = true;
  }

  /// Stops routing taps. Call on logout.
  void detach() {
    _user = null;
    if (!_listening) return;
    FcmService().removeOpenListener(_onOpen);
    _listening = false;
  }

  void _onOpen(Map<String, dynamic> data) => open(data);

  /// Destination for a notification payload with the current user's role.
  NotificationDestination destinationFor(
    Map<String, dynamic>? data, {
    UserModel? user,
  }) {
    final target = user ?? _user;
    if (target == null) return NotificationDestination.notificationList;
    return resolveNotificationDestination(
      type: notificationTypeOf(data),
      role: target.appRole,
    );
  }

  /// Opens the screen for a tapped notification. Never throws: any failure
  /// ends on the notification list.
  Future<void> open(Map<String, dynamic>? data) async {
    final user = _user;
    if (user == null) return;
    NotificationDestination destination;
    try {
      destination = destinationFor(data, user: user);
    } catch (_) {
      destination = NotificationDestination.notificationList;
    }
    if (openDelay > Duration.zero) await Future<void>.delayed(openDelay);
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => pageFor(destination, user)),
    );
  }

  /// Screen for [destination]; falls back to the notification list.
  Widget pageFor(NotificationDestination destination, UserModel? user) {
    try {
      return _pageBuilder(destination, user);
    } catch (_) {
      return _pageBuilder(NotificationDestination.notificationList, user);
    }
  }
}

/// Default screens for each destination.
Widget buildNotificationPage(
  NotificationDestination destination,
  UserModel? user,
) {
  switch (destination) {
    case NotificationDestination.notificationList:
      return const NotificationScreen();
    case NotificationDestination.announcements:
      return AnnouncementScreen(user: user, showDrawer: false);
    case NotificationDestination.studentGuidance:
      return GuidanceHistoryScreen(user: user);
    case NotificationDestination.studentMilestones:
      return const MilestoneProgressScreen();
    case NotificationDestination.lecturerGuidanceRequests:
      return const GuidanceRequestsScreen(initialTab: 0);
    case NotificationDestination.lecturerGuidanceSummaries:
      return const GuidanceRequestsScreen(initialTab: 1);
    case NotificationDestination.lecturerMilestones:
      return const GuidanceRequestsScreen(initialTab: 2);
    case NotificationDestination.internship:
      return InternshipShell(user: user);
  }
}
