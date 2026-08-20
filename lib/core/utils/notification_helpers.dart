import 'package:flutter/material.dart';

import '../enums/user_role.dart';

enum NotificationDestination {
  none,
  seminarAnnouncement,
  seminarDetail,
  defenceDetail,
  yudisiumOverview,
  lecturerSeminar,
  lecturerDefence,
  assignSeminarExaminer,
  assignDefenceExaminer,
}

const _directSeminarNotificationTypes = {
  'seminar_examiner_assigned',
  'seminar_examiner_assigned_student',
  'seminar_doc_verified',
  'seminar_all_examiners_available',
  'seminar_all_examiners_available_supervisor',
  'seminar_scheduled',
  'thesis_seminar_h_minus_one_reminder',
  'thesis_seminar_event_day_reminder',
};

const _directDefenceNotificationTypes = {
  'defence_examiner_assigned',
  'defence_examiner_assigned_student',
  'defence_doc_upload',
  'defence_doc_verified',
  'defence_all_examiners_available_student',
  'defence_all_examiners_available_admin',
  'defence_all_examiners_available_supervisor',
  'defence_scheduled',
  'thesis_defence_h_minus_one_reminder',
  'thesis_defence_event_day_reminder',
};

/// Resolves FCM data into a deterministic mobile destination.
///
/// A scheduled seminar opens the announcement board for students because the
/// notification is broadcast to all students for audience registration. Other
/// recipients with a resource ID open the exact seminar/defence detail.
NotificationDestination resolveNotificationDestination({
  required String type,
  required UserRole userRole,
  String? seminarId,
  String? defenceId,
}) {
  if (type == 'seminar_scheduled' && userRole == UserRole.student) {
    return NotificationDestination.seminarAnnouncement;
  }
  if (seminarId != null && _directSeminarNotificationTypes.contains(type)) {
    return NotificationDestination.seminarDetail;
  }
  if (defenceId != null && _directDefenceNotificationTypes.contains(type)) {
    return NotificationDestination.defenceDetail;
  }
  if (userRole == UserRole.student && isStudentYudisiumNotificationType(type)) {
    return NotificationDestination.yudisiumOverview;
  }
  if (type == 'seminar_examiner_assigned') {
    return NotificationDestination.lecturerSeminar;
  }
  if (type == 'defence_examiner_assigned') {
    return NotificationDestination.lecturerDefence;
  }
  if (userRole == UserRole.headOfDepartment) {
    if (type == 'seminar_need_examiner' ||
        type == 'seminar_examiner_unavailable' ||
        type == 'seminar_examiner_no_response') {
      return NotificationDestination.assignSeminarExaminer;
    }
    if (type == 'defence_need_examiner' ||
        type == 'defence_examiner_unavailable' ||
        type == 'defence_examiner_no_response') {
      return NotificationDestination.assignDefenceExaminer;
    }
  }
  return NotificationDestination.none;
}

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
    case 'seminar_doc_upload':
    case 'seminar_doc_verified':
      return Icons.school_outlined;
    case 'seminar_examiner_assigned':
    case 'seminar_examiner_assigned_student':
    case 'seminar_need_examiner':
    case 'seminar_examiner_unavailable':
    case 'seminar_examiner_no_response':
      return Icons.gavel_outlined;
    case 'seminar_scheduled':
    case 'thesis_seminar_h_minus_one_reminder':
    case 'thesis_seminar_event_day_reminder':
      return Icons.event_available_outlined;
    case 'seminar_all_examiners_available':
    case 'seminar_all_examiners_available_admin':
    case 'seminar_all_examiners_available_supervisor':
      return Icons.verified_outlined;
    case 'defence_doc_upload':
    case 'defence_doc_verified':
      return Icons.description_outlined;
    case 'defence_examiner_assigned':
    case 'defence_examiner_assigned_student':
    case 'defence_need_examiner':
    case 'defence_examiner_unavailable':
    case 'defence_examiner_no_response':
      return Icons.gavel_outlined;
    case 'defence_scheduled':
    case 'thesis_defence_h_minus_one_reminder':
    case 'thesis_defence_event_day_reminder':
    case 'thesis_defence_upcoming_reminder':
    case 'thesis_defence_start_reminder':
      return Icons.event_available_outlined;
    case 'defence_all_examiners_available_student':
    case 'defence_all_examiners_available_admin':
    case 'defence_all_examiners_available_supervisor':
      return Icons.verified_outlined;
    case 'yudisium_registration_open':
    case 'yudisium_registration_closing_h_1':
    case 'yudisium_registration_closed':
    case 'yudisium_h_minus_one_reminder':
    case 'yudisium_event_day_reminder':
      return Icons.event_available_outlined;
    case 'yudisium_doc_upload':
    case 'yudisium_doc_verified':
      return Icons.description_outlined;
    case 'yudisium_cpl_validated':
      return Icons.verified_outlined;
    case 'yudisium_participant_appointed':
      return Icons.emoji_events_outlined;
    case 'yudisium_participant_rejected':
      return Icons.cancel_outlined;
    case 'ADVISOR_REQUEST':
      return Icons.person_add_outlined;
    case 'MILESTONE_UPDATE':
      return Icons.check_circle_outline;
    default:
      return Icons.notifications_outlined;
  }
}

/// Yudisium notifications that can safely open the student overview.
///
/// Administrative upload notifications are intentionally excluded because
/// mobile currently has no yudisium-management route for administrators.
bool isStudentYudisiumNotificationType(String type) => const {
  'yudisium_registration_open',
  'yudisium_registration_closing_h_1',
  'yudisium_registration_closed',
  'yudisium_h_minus_one_reminder',
  'yudisium_event_day_reminder',
  'yudisium_cpl_validated',
  'yudisium_participant_appointed',
  'yudisium_participant_rejected',
  'yudisium_doc_verified',
}.contains(type);
