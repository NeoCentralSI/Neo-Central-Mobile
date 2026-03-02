import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(
        notificationIconData('VAL_SEMINAR'),
        Icons.school_outlined,
      );
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

    test('unknown type → notifications icon', () {
      expect(
        notificationIconData('UNKNOWN_TYPE'),
        Icons.notifications_outlined,
      );
    });

    test('empty string → notifications icon', () {
      expect(
        notificationIconData(''),
        Icons.notifications_outlined,
      );
    });
  });
}
