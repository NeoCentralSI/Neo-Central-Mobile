import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/enums/user_role.dart';
import 'package:neocentral/core/utils/notification_helpers.dart';

/// Types the backend still sends for modules that are web-only now.
const _removedModuleTypes = [
  'seminar_examiner_assigned',
  'seminar_examiner_assigned_student',
  'seminar_need_examiner',
  'seminar_doc_verified',
  'thesis_seminar_h_minus_one_reminder',
  'defence_scheduled',
  'defence_examiner_assigned',
  'defence_need_examiner',
  'thesis_defence_event_day_reminder',
  'yudisium_registration_open',
  'yudisium_participant_appointed',
  'supervisor_request_submitted',
  'proposal_revision_submitted',
  'thesis_change_request',
  'thesis_guidance_evaluation',
  'research_method_promoted',
  'TRANSFER_REQUEST',
  'TOPIC_CHANGE_REQUEST',
  'something_new_from_the_future',
];

void main() {
  group('resolveNotificationDestination', () {
    test('missing or empty type opens the notification list', () {
      for (final role in UserRole.values) {
        expect(
          resolveNotificationDestination(type: null, role: role),
          NotificationDestination.notificationList,
        );
        expect(
          resolveNotificationDestination(type: '  ', role: role),
          NotificationDestination.notificationList,
        );
      }
    });

    test('removed modules open the notification list for every role', () {
      for (final role in UserRole.values) {
        for (final type in _removedModuleTypes) {
          expect(
            resolveNotificationDestination(type: type, role: role),
            NotificationDestination.notificationList,
            reason: '$type for $role',
          );
        }
      }
    });

    test('scheduled seminar opens Pengumuman for every role', () {
      for (final role in UserRole.values) {
        expect(
          resolveNotificationDestination(type: 'seminar_scheduled', role: role),
          NotificationDestination.announcements,
        );
      }
    });

    test('admin only reaches Pengumuman or the list', () {
      for (final type in [
        'thesis-guidance:requested',
        'milestone:pending_review',
        'internship_invitation',
      ]) {
        expect(
          resolveNotificationDestination(type: type, role: UserRole.admin),
          NotificationDestination.notificationList,
        );
      }
    });

    test('student guidance notifications open the guidance history', () {
      for (final type in [
        'thesis-guidance:approved',
        'thesis-guidance:rejected',
        'thesis-guidance:summary-approved',
        'guidance_reminder',
        'daily_thesis_reminder',
        'thesis_warning',
      ]) {
        expect(
          resolveNotificationDestination(type: type, role: UserRole.student),
          NotificationDestination.studentGuidance,
          reason: type,
        );
      }
    });

    test('lecturer guidance notifications open the matching approval tab', () {
      expect(
        resolveNotificationDestination(
          type: 'thesis-guidance:requested',
          role: UserRole.lecturer,
        ),
        NotificationDestination.lecturerGuidanceRequests,
      );
      expect(
        resolveNotificationDestination(
          type: 'thesis-guidance:summary-submitted',
          role: UserRole.lecturer,
        ),
        NotificationDestination.lecturerGuidanceSummaries,
      );
      expect(
        resolveNotificationDestination(
          type: 'milestone:pending_review',
          role: UserRole.lecturer,
        ),
        NotificationDestination.lecturerMilestones,
      );
    });

    test('internship notifications open Kerja Praktik', () {
      for (final role in [UserRole.student, UserRole.lecturer]) {
        expect(
          resolveNotificationDestination(
            type: 'internship_guidance:submitted',
            role: role,
          ),
          NotificationDestination.internship,
        );
      }
    });
  });

  group('notificationTypeOf', () {
    test('reads a top-level type', () {
      expect(
        notificationTypeOf({'type': 'guidance_reminder'}),
        'guidance_reminder',
      );
    });

    test('reads a type nested in data', () {
      expect(
        notificationTypeOf({
          'data': {'type': 'milestone:pending_review'},
        }),
        'milestone:pending_review',
      );
    });

    test('returns null for missing or odd payloads', () {
      expect(notificationTypeOf(null), isNull);
      expect(notificationTypeOf({}), isNull);
      expect(notificationTypeOf({'type': 42}), isNull);
      expect(notificationTypeOf({'data': 'x'}), isNull);
    });
  });

  group('notificationIconData', () {
    test('guidance types use the calendar icon', () {
      expect(
        notificationIconData('thesis-guidance:requested'),
        Icons.calendar_today_outlined,
      );
    });

    test('milestone types use the flag icon', () {
      expect(
        notificationIconData('milestone:pending_review'),
        Icons.flag_outlined,
      );
    });

    test('internship types use the work icon', () {
      expect(notificationIconData('internship_invitation'), Icons.work_outline);
    });

    test('unknown or missing types use the bell icon', () {
      expect(notificationIconData(null), Icons.notifications_outlined);
      expect(notificationIconData('???'), Icons.notifications_outlined);
    });
  });
}
