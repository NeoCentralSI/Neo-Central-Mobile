import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/enums/user_role.dart';
import 'package:neocentral/core/utils/notification_helpers.dart';

void main() {
  group('notificationIconData', () {
    test('GUIDANCE_REQUEST → calendar icon', () {
      expect(
        notificationIconData('GUIDANCE_REQUEST'),
        Icons.calendar_today_outlined,
      );
    });

    test('TRANSFER_REQUEST → swap icon', () {
      expect(
        notificationIconData('TRANSFER_REQUEST'),
        Icons.swap_horiz_outlined,
      );
    });

    test('TOPIC_CHANGE_REQUEST → edit icon', () {
      expect(
        notificationIconData('TOPIC_CHANGE_REQUEST'),
        Icons.edit_note_outlined,
      );
    });

    test('VAL_SEMINAR → school icon', () {
      expect(notificationIconData('VAL_SEMINAR'), Icons.school_outlined);
    });

    test('ADVISOR_REQUEST → person add icon', () {
      expect(
        notificationIconData('ADVISOR_REQUEST'),
        Icons.person_add_outlined,
      );
    });

    test('MILESTONE_UPDATE → check circle icon', () {
      expect(
        notificationIconData('MILESTONE_UPDATE'),
        Icons.check_circle_outline,
      );
    });

    test('seminar assignment → gavel icon', () {
      expect(
        notificationIconData('seminar_examiner_assigned'),
        Icons.gavel_outlined,
      );
    });

    test('seminar schedule → event icon', () {
      expect(
        notificationIconData('seminar_scheduled'),
        Icons.event_available_outlined,
      );
    });

    test('defence document → description icon', () {
      expect(
        notificationIconData('defence_doc_verified'),
        Icons.description_outlined,
      );
    });

    test('defence assignment → gavel icon', () {
      expect(
        notificationIconData('defence_examiner_assigned'),
        Icons.gavel_outlined,
      );
    });

    test('defence schedule → event icon', () {
      expect(
        notificationIconData('defence_scheduled'),
        Icons.event_available_outlined,
      );
    });

    test('backend defence event-day reminder → event icon', () {
      expect(
        notificationIconData('thesis_defence_event_day_reminder'),
        Icons.event_available_outlined,
      );
    });

    test('backend seminar H-1 reminder → event icon', () {
      expect(
        notificationIconData('thesis_seminar_h_minus_one_reminder'),
        Icons.event_available_outlined,
      );
    });

    test('yudisium registration reminder → event icon', () {
      expect(
        notificationIconData('yudisium_registration_closing_h_1'),
        Icons.event_available_outlined,
      );
    });

    test('yudisium document verification → description icon', () {
      expect(
        notificationIconData('yudisium_doc_verified'),
        Icons.description_outlined,
      );
    });

    test('yudisium CPL validation → verified icon', () {
      expect(
        notificationIconData('yudisium_cpl_validated'),
        Icons.verified_outlined,
      );
    });

    test('yudisium appointment and rejection use outcome icons', () {
      expect(
        notificationIconData('yudisium_participant_appointed'),
        Icons.emoji_events_outlined,
      );
      expect(
        notificationIconData('yudisium_participant_rejected'),
        Icons.cancel_outlined,
      );
    });

    test('unknown type → notifications icon', () {
      expect(
        notificationIconData('UNKNOWN_TYPE'),
        Icons.notifications_outlined,
      );
    });

    test('empty string → notifications icon', () {
      expect(notificationIconData(''), Icons.notifications_outlined);
    });
  });

  group('isStudentYudisiumNotificationType', () {
    test('recognizes every student yudisium notification', () {
      const supported = {
        'yudisium_registration_open',
        'yudisium_registration_closing_h_1',
        'yudisium_registration_closed',
        'yudisium_h_minus_one_reminder',
        'yudisium_event_day_reminder',
        'yudisium_cpl_validated',
        'yudisium_participant_appointed',
        'yudisium_participant_rejected',
        'yudisium_doc_verified',
      };

      for (final type in supported) {
        expect(isStudentYudisiumNotificationType(type), isTrue);
      }
    });

    test('does not route administrative upload notifications', () {
      expect(isStudentYudisiumNotificationType('yudisium_doc_upload'), isFalse);
      expect(isStudentYudisiumNotificationType('seminar_scheduled'), isFalse);
    });
  });

  group('resolveNotificationDestination', () {
    test('student seminar schedule opens the audience announcement', () {
      expect(
        resolveNotificationDestination(
          type: 'seminar_scheduled',
          userRole: UserRole.student,
          seminarId: 'seminar-1',
        ),
        NotificationDestination.seminarAnnouncement,
      );
    });

    test('lecturer schedule with an ID opens seminar detail', () {
      expect(
        resolveNotificationDestination(
          type: 'seminar_scheduled',
          userRole: UserRole.lecturer,
          seminarId: 'seminar-1',
        ),
        NotificationDestination.seminarDetail,
      );
    });

    test('assignment without an ID opens the lecturer module', () {
      expect(
        resolveNotificationDestination(
          type: 'seminar_examiner_assigned',
          userRole: UserRole.lecturer,
        ),
        NotificationDestination.lecturerSeminar,
      );
    });

    test('defence notification with an ID opens defence detail', () {
      expect(
        resolveNotificationDestination(
          type: 'defence_doc_verified',
          userRole: UserRole.student,
          defenceId: 'defence-1',
        ),
        NotificationDestination.defenceDetail,
      );
    });

    test('HoD examiner alert opens the matching assignment tab', () {
      expect(
        resolveNotificationDestination(
          type: 'seminar_need_examiner',
          userRole: UserRole.headOfDepartment,
        ),
        NotificationDestination.assignSeminarExaminer,
      );
      expect(
        resolveNotificationDestination(
          type: 'defence_examiner_unavailable',
          userRole: UserRole.headOfDepartment,
        ),
        NotificationDestination.assignDefenceExaminer,
      );
      expect(
        resolveNotificationDestination(
          type: 'seminar_examiner_no_response',
          userRole: UserRole.headOfDepartment,
          seminarId: 'seminar-1',
        ),
        NotificationDestination.assignSeminarExaminer,
      );
      expect(
        resolveNotificationDestination(
          type: 'defence_examiner_no_response',
          userRole: UserRole.headOfDepartment,
          defenceId: 'defence-1',
        ),
        NotificationDestination.assignDefenceExaminer,
      );
    });

    test('student yudisium notification opens overview only for student', () {
      expect(
        resolveNotificationDestination(
          type: 'yudisium_participant_appointed',
          userRole: UserRole.student,
        ),
        NotificationDestination.yudisiumOverview,
      );
      expect(
        resolveNotificationDestination(
          type: 'yudisium_participant_appointed',
          userRole: UserRole.lecturer,
        ),
        NotificationDestination.none,
      );
    });
  });
}
