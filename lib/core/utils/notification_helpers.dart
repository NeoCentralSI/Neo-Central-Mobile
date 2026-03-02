import 'package:flutter/material.dart';

/// Maps notification type string to a Material icon.
IconData notificationIconData(String type) {
  switch (type) {
    case 'GUIDANCE_REQUEST':
      return Icons.calendar_today_outlined;
    case 'TRANSFER_REQUEST':
      return Icons.swap_horiz_outlined;
    case 'TOPIC_CHANGE_REQUEST':
      return Icons.edit_note_outlined;
    case 'VAL_SEMINAR':
      return Icons.school_outlined;
    case 'ADVISOR_REQUEST':
      return Icons.person_add_outlined;
    case 'MILESTONE_UPDATE':
      return Icons.check_circle_outline;
    default:
      return Icons.notifications_outlined;
  }
}
